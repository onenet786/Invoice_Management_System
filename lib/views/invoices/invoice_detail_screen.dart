import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../models/invoice_model.dart';
import '../../models/client_model.dart';
import 'invoice_wizard/invoice_wizard_screen.dart';
import 'invoice_pdf_preview_screen.dart';
import '../../services/email_service.dart';
import '../../services/whatsapp_service.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final InvoiceModel invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late InvoiceModel _currentInvoice;

  @override
  void initState() {
    super.initState();
    _currentInvoice = widget.invoice;
  }

  void _markAsPaid() async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    if (!state.canWrite) {
      _showViewerRestriction();
      return;
    }

    final updated = _currentInvoice.copyWith(status: InvoiceStatus.paid);
    await state.updateInvoice(updated);
    setState(() {
      _currentInvoice = updated;
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invoice marked as Paid.')));
    }
  }

  void _convertQuoteToInvoice() async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final invoice = await state.convertQuoteToInvoice(_currentInvoice);
    if (!mounted || invoice == null) return;
    setState(() {
      _currentInvoice = _currentInvoice.copyWith(
        convertedInvoiceId: invoice.id,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Created invoice ${invoice.invoiceNumber} from this quote.',
        ),
      ),
    );
  }

  void _sendEmail() async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final client = state.clients.firstWhere(
      (c) => c.id == _currentInvoice.clientId,
      orElse: () => ClientModel(
        id: '',
        name: 'Unknown',
        email: '',
        phone: '',
        billingAddress: '',
        shippingAddress: '',
      ),
    );

    if (client.id.isEmpty || client.email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client email is not configured.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await EmailService.sendInvoiceEmail(
      invoice: _currentInvoice,
      client: client,
      company: state.company,
    );

    if (success && mounted) {
      if (_currentInvoice.status == InvoiceStatus.draft) {
        final updated = _currentInvoice.copyWith(status: InvoiceStatus.sent);
        await state.updateInvoice(updated);
        if (!mounted) return;
        setState(() {
          _currentInvoice = updated;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email client opened successfully.')),
      );
    }
  }

  void _showViewerRestriction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Access Denied: Viewers cannot perform invoice mutations.',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final theme = Theme.of(context);

    // Fetch the client data
    final client = state.clients.firstWhere(
      (c) => c.id == _currentInvoice.clientId,
      orElse: () => ClientModel(
        id: '',
        name: 'Unknown Client',
        email: 'N/A',
        phone: 'N/A',
        billingAddress: 'No address configured.',
        shippingAddress: 'No address configured.',
      ),
    );

    final currency = state.company.currency;
    final formatter = NumberFormat.currency(symbol: currency, decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_currentInvoice.documentType == InvoiceDocumentType.quote ? 'Quote' : 'Invoice'} Details: ${_currentInvoice.invoiceNumber}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      InvoicePdfPreviewScreen(invoice: _currentInvoice),
                ),
              );
            },
            tooltip: 'Preview PDF',
          ),
          IconButton(
            icon: const Icon(Icons.chat_outlined, color: Color(0xFF25D366)),
            onPressed: () {
              WhatsappService.showWhatsappShareSheet(
                context: context,
                invoice: _currentInvoice,
                client: client,
                company: state.company,
                template: state.pdfTemplate,
              );
            },
            tooltip: 'Send via WhatsApp',
          ),
          IconButton(
            icon: const Icon(Icons.email_outlined),
            onPressed: _sendEmail,
            tooltip: 'Send Email to Client',
          ),
          if (state.canWrite)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final result = await Navigator.of(context).push<InvoiceModel?>(
                  MaterialPageRoute(
                    builder: (context) =>
                        InvoiceWizardScreen(invoice: _currentInvoice),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _currentInvoice = result;
                  });
                }
              },
              tooltip: 'Edit Invoice',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Actions Header Row
              _buildActionsBanner(state, client, theme),
              const SizedBox(height: 24),

              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildDetailsCard(client, state, theme),
                        ),
                        const SizedBox(width: 20),
                        Expanded(child: _buildSummaryCard(formatter, theme)),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildDetailsCard(client, state, theme),
                        const SizedBox(height: 20),
                        _buildSummaryCard(formatter, theme),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 24),

              // Items table Card
              _buildItemsTableCard(formatter, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsBanner(
    AppStateProvider state,
    ClientModel client,
    ThemeData theme,
  ) {
    return Card(
      color: Colors.indigo.shade50.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.indigo.shade200.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                const Icon(Icons.receipt_long, color: Colors.indigo, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_currentInvoice.documentType == InvoiceDocumentType.quote ? 'Quote' : 'Invoice'} Status: ${_currentInvoice.status.name.toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    Text(
                      _currentInvoice.documentType == InvoiceDocumentType.quote
                          ? 'Approve this quote to generate an invoice.'
                          : 'Dispatch or preview invoice details.',
                      style: TextStyle(fontSize: 11, color: theme.hintColor),
                    ),
                  ],
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(
                    Icons.chat,
                    color: Color(0xFF25D366),
                    size: 18,
                  ),
                  label: const Text(
                    'WhatsApp',
                    style: TextStyle(
                      color: Color(0xFF25D366),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF25D366)),
                  ),
                  onPressed: () {
                    WhatsappService.showWhatsappShareSheet(
                      context: context,
                      invoice: _currentInvoice,
                      client: client,
                      company: state.company,
                      template: state.pdfTemplate,
                    );
                  },
                ),
                if (state.canWrite &&
                    _currentInvoice.documentType == InvoiceDocumentType.quote &&
                    _currentInvoice.convertedInvoiceId == null) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Approve & Create Invoice'),
                    onPressed: _convertQuoteToInvoice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                if (state.canWrite &&
                    _currentInvoice.documentType ==
                        InvoiceDocumentType.invoice &&
                    _currentInvoice.status != InvoiceStatus.paid) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Mark as Paid'),
                    onPressed: _markAsPaid,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(
    ClientModel client,
    AppStateProvider state,
    ThemeData theme,
  ) {
    final comp = state.company;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company & Client columns
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FROM:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        comp.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(comp.address, style: const TextStyle(fontSize: 12)),
                      Text(
                        'Tax ID: ${comp.taxId}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BILL TO:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        client.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(client.email, style: const TextStyle(fontSize: 12)),
                      Text(client.phone, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        'Billing Address:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.hintColor,
                        ),
                      ),
                      Text(
                        client.billingAddress,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            // Invoice Metadata fields
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Issue Date:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _currentInvoice.issueDate.toIso8601String().split(
                          'T',
                        )[0],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Due Date:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _currentInvoice.dueDate.toIso8601String().split('T')[0],
                        style: TextStyle(
                          fontSize: 14,
                          color: _currentInvoice.status == InvoiceStatus.overdue
                              ? Colors.red
                              : null,
                          fontWeight:
                              _currentInvoice.status == InvoiceStatus.overdue
                              ? FontWeight.bold
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_currentInvoice.notes.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Terms / Notes:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _currentInvoice.notes,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(NumberFormat formatter, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calculation Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text(formatter.format(_currentInvoice.subTotal)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Tax:'),
                Text(formatter.format(_currentInvoice.taxTotal)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grand Total:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.indigo,
                  ),
                ),
                Text(
                  formatter.format(_currentInvoice.grandTotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTableCard(NumberFormat formatter, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invoice Items / Products',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.2),
                4: FlexColumnWidth(1.8),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.05),
                    border: const Border(
                      bottom: BorderSide(color: Colors.grey),
                    ),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'Item Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'Qty',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'Rate',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'Tax %',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'Total',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                ..._currentInvoice.items.map((item) {
                  return TableRow(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'SKU ID: ${item.productId}',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.hintColor,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          item.quantity.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          formatter.format(item.unitPrice),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '${item.taxRate.toStringAsFixed(0)}%',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          formatter.format(item.lineTotal),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
