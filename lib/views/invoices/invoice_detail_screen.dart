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

  void _updateStatus(InvoiceStatus newStatus) async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    if (!state.canWrite) {
      _showViewerRestriction();
      return;
    }

    final updated = _currentInvoice.copyWith(status: newStatus);
    await state.updateInvoice(updated);
    setState(() {
      _currentInvoice = updated;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice status updated to ${_getStatusLabel(newStatus)}.')),
      );
    }
  }

  String _getStatusLabel(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.sent:
        return 'Sent';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.partiallyPaid:
        return 'Partially Paid';
      case InvoiceStatus.draft:
        return 'Draft';
    }
  }

  Widget _buildStatusBadge(InvoiceStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case InvoiceStatus.paid:
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        label = 'Paid';
        break;
      case InvoiceStatus.sent:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        label = 'Sent';
        break;
      case InvoiceStatus.overdue:
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        label = 'Overdue';
        break;
      case InvoiceStatus.partiallyPaid:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade800;
        label = 'Part. Paid';
        break;
      case InvoiceStatus.draft:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        label = 'Draft';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _sendEmail() async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final client = state.clients.firstWhere(
      (c) => c.id == _currentInvoice.clientId,
      orElse: () => ClientModel(id: '', name: 'Unknown', email: '', phone: '', billingAddress: '', shippingAddress: ''),
    );

    if (client.id.isEmpty || client.email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client email is not configured.'), backgroundColor: Colors.orange),
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

  void _sendWhatsApp() async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final invoiceClient = state.clients.firstWhere(
      (c) => c.id == _currentInvoice.clientId,
      orElse: () => ClientModel(id: '', name: 'Unknown', email: '', phone: '', billingAddress: '', shippingAddress: ''),
    );

    if (invoiceClient.id.isEmpty || invoiceClient.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client phone number is not configured.'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (state.n8nWebhookUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('n8n Webhook URL is not configured in Settings.'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.green),
      ),
    );

    final success = await WhatsAppService.sendInvoiceWhatsApp(
      invoice: _currentInvoice,
      client: invoiceClient,
      company: state.company,
      webhookUrl: state.n8nWebhookUrl,
      apiKey: state.n8nApiKey,
      template: state.selectedTemplate,
      sendText: state.whatsAppSendText,
      sendPdf: state.whatsAppSendPdf,
      sendImage: state.whatsAppSendImage,
    );

    // Pop the loading indicator
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (success) {
      if (_currentInvoice.status == InvoiceStatus.draft) {
        final updated = _currentInvoice.copyWith(status: InvoiceStatus.sent);
        await state.updateInvoice(updated);
        if (!mounted) return;
        setState(() {
          _currentInvoice = updated;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp message sent to n8n webhook successfully!'), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send WhatsApp message via webhook. Check configuration.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showViewerRestriction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Access Denied: Viewers cannot perform invoice mutations.'),
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
        title: Text('Invoice Details: ${_currentInvoice.invoiceNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => InvoicePdfPreviewScreen(invoice: _currentInvoice),
                ),
              );
            },
            tooltip: 'Preview PDF',
          ),
          IconButton(
            icon: const Icon(Icons.email_outlined),
            onPressed: _sendEmail,
            tooltip: 'Send Email to Client',
          ),
          if (state.n8nEnabled)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.green),
              onPressed: _sendWhatsApp,
              tooltip: 'Send via WhatsApp',
            ),
          if (state.canWrite)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final result = await Navigator.of(context).push<InvoiceModel?>(
                  MaterialPageRoute(
                    builder: (context) => InvoiceWizardScreen(invoice: _currentInvoice),
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
              _buildActionsBanner(state, theme),
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
                        Expanded(
                          child: _buildSummaryCard(formatter, theme),
                        ),
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

  Widget _buildActionsBanner(AppStateProvider state, ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final bannerContent = [
          const Icon(Icons.receipt_long, color: Colors.indigo, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  const Text(
                    'Invoice Status:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  _buildStatusBadge(_currentInvoice.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Ensure details match client terms before dispatching.',
                style: TextStyle(fontSize: 11, color: theme.hintColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PopupMenuButton<InvoiceStatus>(
            onSelected: _updateStatus,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Update Status',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                ],
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: InvoiceStatus.draft,
                child: Row(
                  children: [
                    Icon(Icons.edit_note, color: Colors.grey, size: 18),
                    SizedBox(width: 8),
                    Text('Draft'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: InvoiceStatus.sent,
                child: Row(
                  children: [
                    Icon(Icons.send_outlined, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Text('Sent'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: InvoiceStatus.paid,
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Text('Paid'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: InvoiceStatus.partiallyPaid,
                child: Row(
                  children: [
                    Icon(Icons.star_half, color: Colors.amber, size: 18),
                    SizedBox(width: 8),
                    Text('Partially Paid'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: InvoiceStatus.overdue,
                child: Row(
                  children: [
                    Icon(Icons.report_gmailerrorred, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Overdue'),
                  ],
                ),
              ),
            ],
          ),
        ];

        return Card(
          color: Colors.indigo.shade50.withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.indigo.shade200.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          bannerContent[0], // Icon
                          const SizedBox(width: 12),
                          Expanded(child: bannerContent[2]), // Title and badge Column
                        ],
                      ),
                      if (state.canWrite) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: bannerContent[4], // Dropdown button
                          ),
                        ),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      bannerContent[0], // Icon
                      const SizedBox(width: 12),
                      Expanded(child: bannerContent[2]), // Column
                      if (state.canWrite) bannerContent[4], // Dropdown button
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildDetailsCard(ClientModel client, AppStateProvider state, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final fromCol = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FROM:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.hintColor)),
                    const SizedBox(height: 8),
                    Text(state.company.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(state.company.address, style: const TextStyle(fontSize: 12)),
                    Text('Tax ID: ${state.company.taxId}', style: const TextStyle(fontSize: 12)),
                  ],
                );

                final billToCol = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BILL TO:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.hintColor)),
                    const SizedBox(height: 8),
                    Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(client.email, style: const TextStyle(fontSize: 12)),
                    Text(client.phone, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('Billing Address:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.hintColor)),
                    Text(client.billingAddress, style: const TextStyle(fontSize: 12)),
                  ],
                );

                if (constraints.maxWidth > 500) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: fromCol),
                      const SizedBox(width: 16),
                      Expanded(child: billToCol),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      fromCol,
                      const SizedBox(height: 24),
                      billToCol,
                    ],
                  );
                }
              },
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
                      const Text('Issue Date:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      Text(_currentInvoice.issueDate.toIso8601String().split('T')[0], style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Due Date:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      Text(
                        _currentInvoice.dueDate.toIso8601String().split('T')[0],
                        style: TextStyle(
                          fontSize: 14,
                          color: _currentInvoice.status == InvoiceStatus.overdue ? Colors.red : null,
                          fontWeight: _currentInvoice.status == InvoiceStatus.overdue ? FontWeight.bold : null,
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
              const Text('Terms / Notes:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(_currentInvoice.notes, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo),
                ),
                Text(
                  formatter.format(_currentInvoice.grandTotal),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo),
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
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: constraints.maxWidth > 600 ? constraints.maxWidth : 600,
                    child: Table(
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
                            border: const Border(bottom: BorderSide(color: Colors.grey)),
                          ),
                          children: const [
                            Padding(padding: EdgeInsets.all(10), child: Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(10), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                            Padding(padding: EdgeInsets.all(10), child: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                            Padding(padding: EdgeInsets.all(10), child: Text('Tax %', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                            Padding(padding: EdgeInsets.all(10), child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                          ],
                        ),
                        ..._currentInvoice.items.map((item) {
                          return TableRow(
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'SKU ID: ${item.productId}',
                                      style: TextStyle(fontSize: 11, color: theme.hintColor, fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(item.quantity.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(formatter.format(item.unitPrice), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text('${item.taxRate.toStringAsFixed(0)}%', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(formatter.format(item.lineTotal), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
