import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../models/invoice_model.dart';
import '../../models/client_model.dart';
import '../../utils/date_format_util.dart';
import 'invoice_detail_screen.dart';
import 'invoice_wizard/invoice_wizard_screen.dart';
import 'invoice_pdf_preview_screen.dart';
import 'scan_quotation_dialog.dart';
import '../../services/email_service.dart';
import '../../services/whatsapp_service.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  InvoiceStatus? _statusFilter;
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _openInvoiceWizard([InvoiceModel? invoice]) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    if (!state.canWrite) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Viewers cannot create or edit invoices.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InvoiceWizardScreen(invoice: invoice),
      ),
    );
  }

  void _deleteInvoice(InvoiceModel invoice) async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    if (!state.canWrite) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Viewers cannot delete invoices.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice?'),
        content: Text('Are you sure you want to delete invoice "${invoice.invoiceNumber}"? This action is permanent.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await state.deleteInvoice(invoice.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted invoice "${invoice.invoiceNumber}" successfully.')),
        );
      }
    }
  }

  void _sendInvoiceEmail(InvoiceModel invoice) async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final client = state.clients.firstWhere(
      (c) => c.id == invoice.clientId,
      orElse: () => ClientModel(id: '', name: 'Unknown', email: '', phone: '', billingAddress: '', shippingAddress: ''),
    );

    if (client.id.isEmpty || client.email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Selected client does not have a valid email address configured.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await EmailService.sendInvoiceEmail(
      invoice: invoice,
      client: client,
      company: state.company,
    );

    if (success && mounted) {
      // Mark as sent if it was in draft mode
      if (invoice.status == InvoiceStatus.draft) {
        final updated = invoice.copyWith(status: InvoiceStatus.sent);
        await state.updateInvoice(updated);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email client launched successfully.')),
      );
    }
  }

  void _sendInvoiceWhatsApp(InvoiceModel invoice) async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final invoiceClient = state.clients.firstWhere(
      (c) => c.id == invoice.clientId,
      orElse: () => ClientModel(id: '', name: 'Unknown', email: '', phone: '', billingAddress: '', shippingAddress: ''),
    );

    if (invoiceClient.id.isEmpty || invoiceClient.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Selected client does not have a valid phone number configured.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (state.n8nWebhookUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: n8n Webhook URL is not configured in Settings.'),
          backgroundColor: Colors.orange,
        ),
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
      invoice: invoice,
      client: invoiceClient,
      company: state.company,
      webhookUrl: state.n8nWebhookUrl,
      apiKey: state.n8nApiKey,
      template: state.selectedTemplate,
      sendText: state.whatsAppSendText,
      sendPdf: state.whatsAppSendPdf,
      sendImage: state.whatsAppSendImage,
    );

    // Pop loading
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (success && mounted) {
      // Mark as sent if it was in draft mode
      if (invoice.status == InvoiceStatus.draft) {
        final updated = invoice.copyWith(status: InvoiceStatus.sent);
        await state.updateInvoice(updated);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp message sent to n8n webhook successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send WhatsApp message via webhook. Check configuration.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final theme = Theme.of(context);
    final currency = state.company.currency;
    final formatter = NumberFormat.currency(symbol: currency, decimalDigits: 2);

    // Use cached client lookup map for O(1) performance
    final clientMap = state.clientMap;
    final unknownClient = ClientModel(id: '', name: 'Unknown', email: '', phone: '', billingAddress: '', shippingAddress: '');

    final filteredInvoices = state.invoices.where((inv) {
      final q = _searchQuery.toLowerCase();
      final client = clientMap[inv.clientId] ?? unknownClient;

      final matchesQuery = inv.invoiceNumber.toLowerCase().contains(q) ||
          client.name.toLowerCase().contains(q);
      final matchesStatus = _statusFilter == null || inv.status == _statusFilter;

      return matchesQuery && matchesStatus;
    }).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            LayoutBuilder(
              builder: (context, constraints) {
                final headerText = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoices',
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Monitor full invoice lifecycles, send payment reminders, and download PDFs.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                    ),
                  ],
                );

                final actionButtons = Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (state.canWrite) ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const ScanQuotationDialog(),
                          );
                        },
                        icon: const Icon(Icons.document_scanner),
                        label: const Text('Scan Quote'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.indigo),
                          foregroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _openInvoiceWizard(),
                        icon: const Icon(Icons.add_card),
                        label: const Text('Create Invoice'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ],
                );

                if (constraints.maxWidth > 700) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: headerText),
                      const SizedBox(width: 16),
                      actionButtons,
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      headerText,
                      const SizedBox(height: 16),
                      actionButtons,
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // Search and Status Filters
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          _searchDebounce?.cancel();
                          _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                            setState(() {
                              _searchQuery = val;
                            });
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search invoice by number or client name...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      ),
                    const VerticalDivider(width: 20, thickness: 1),
                    DropdownButton<InvoiceStatus>(
                      value: _statusFilter,
                      hint: const Text('Filter by Status'),
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All Statuses')),
                        DropdownMenuItem(value: InvoiceStatus.paid, child: Text('Paid')),
                        DropdownMenuItem(value: InvoiceStatus.sent, child: Text('Sent')),
                        DropdownMenuItem(value: InvoiceStatus.overdue, child: Text('Overdue')),
                        DropdownMenuItem(value: InvoiceStatus.partiallyPaid, child: Text('Partially Paid')),
                        DropdownMenuItem(value: InvoiceStatus.draft, child: Text('Draft')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _statusFilter = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Table Grid of Invoices
            Expanded(
              child: filteredInvoices.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      itemCount: filteredInvoices.length,
                      itemBuilder: (context, index) {
                        final inv = filteredInvoices[index];
                        final client = clientMap[inv.clientId] ?? ClientModel(id: '', name: 'Unknown Client', email: '', phone: '', billingAddress: '', shippingAddress: '');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => InvoiceDetailScreen(invoice: inv),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top row: Invoice number on left, Status badge & action menu on right
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        inv.invoiceNumber,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildStatusBadge(inv.status),
                                          const SizedBox(width: 8),
                                          _buildInvoiceActionMenu(inv),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1, thickness: 0.5),
                                  const SizedBox(height: 12),
                                  // Layout builder for details section
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isMobile = constraints.maxWidth < 500;

                                      final clientInfo = Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            client.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Items: ${inv.items.length}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.hintColor,
                                            ),
                                          ),
                                        ],
                                      );

                                      final datesInfo = Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Issued: ${DateFormatUtil.toIsoDate(inv.issueDate)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.hintColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Due: ${DateFormatUtil.toIsoDate(inv.dueDate)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: inv.status == InvoiceStatus.overdue
                                                  ? Colors.red
                                                  : theme.hintColor,
                                              fontWeight: inv.status == InvoiceStatus.overdue
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      );

                                      final totalInfo = Column(
                                        crossAxisAlignment: isMobile
                                            ? CrossAxisAlignment.start
                                            : CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            formatter.format(inv.grandTotal),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.indigo,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Grand Total',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: theme.hintColor,
                                            ),
                                          ),
                                        ],
                                      );

                                      if (isMobile) {
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            clientInfo,
                                            const SizedBox(height: 12),
                                            datesInfo,
                                            const SizedBox(height: 12),
                                            totalInfo,
                                          ],
                                        );
                                      } else {
                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(flex: 3, child: clientInfo),
                                            const SizedBox(width: 16),
                                            Expanded(flex: 3, child: datesInfo),
                                            const SizedBox(width: 16),
                                            Expanded(flex: 2, child: totalInfo),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildInvoiceActionMenu(InvoiceModel invoice) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    return PopupMenuButton<String>(
      onSelected: (action) {
        if (action == 'view') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => InvoiceDetailScreen(invoice: invoice),
            ),
          );
        } else if (action == 'pdf') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => InvoicePdfPreviewScreen(invoice: invoice),
            ),
          );
        } else if (action == 'email') {
          _sendInvoiceEmail(invoice);
        } else if (action == 'whatsapp') {
          _sendInvoiceWhatsApp(invoice);
        } else if (action == 'edit') {
          _openInvoiceWizard(invoice);
        } else if (action == 'delete') {
          _deleteInvoice(invoice);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility_outlined, size: 18), SizedBox(width: 8), Text('Open Details')])),
        const PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf_outlined, size: 18), SizedBox(width: 8), Text('Preview PDF')])),
        const PopupMenuItem(value: 'email', child: Row(children: [Icon(Icons.email_outlined, size: 18), SizedBox(width: 8), Text('Send Email')])),
        if (state.n8nEnabled)
          const PopupMenuItem(
            value: 'whatsapp',
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: Colors.green, size: 18),
                SizedBox(width: 8),
                Text('Send WhatsApp', style: TextStyle(color: Colors.green)),
              ],
            ),
          ),
        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit Wizard')])),
        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete Invoice', style: TextStyle(color: Colors.red))])),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: theme.hintColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No Invoices Found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.hintColor),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try checking spelling or status filters.'
                : 'Get started by creating your first client invoice.',
            style: TextStyle(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}
