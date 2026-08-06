import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../models/invoice_model.dart';
import '../../models/client_model.dart';
import 'invoice_detail_screen.dart';
import 'invoice_wizard/invoice_wizard_screen.dart';
import 'invoice_pdf_preview_screen.dart';
import 'scan_quotation_dialog.dart';
import '../../services/email_service.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  InvoiceStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openInvoiceWizard([InvoiceModel? invoice]) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    if (!state.canWrite) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Access Denied: Viewers cannot create or edit invoices.',
          ),
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
        content: Text(
          'Are you sure you want to delete invoice "${invoice.invoiceNumber}"? This action is permanent.',
        ),
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
          SnackBar(
            content: Text(
              'Deleted invoice "${invoice.invoiceNumber}" successfully.',
            ),
          ),
        );
      }
    }
  }

  void _sendInvoiceEmail(InvoiceModel invoice) async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final client = state.clients.firstWhere(
      (c) => c.id == invoice.clientId,
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
          content: Text(
            'Error: Selected client does not have a valid email address configured.',
          ),
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

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final theme = Theme.of(context);
    final currency = state.company.currency;
    final formatter = NumberFormat.currency(symbol: currency, decimalDigits: 2);

    final filteredInvoices = state.invoices.where((inv) {
      final q = _searchQuery.toLowerCase();
      final client = state.clients.firstWhere(
        (c) => c.id == inv.clientId,
        orElse: () => ClientModel(
          id: '',
          name: 'Unknown',
          email: '',
          phone: '',
          billingAddress: '',
          shippingAddress: '',
        ),
      );

      final matchesQuery =
          inv.invoiceNumber.toLowerCase().contains(q) ||
          client.name.toLowerCase().contains(q);
      final matchesStatus =
          _statusFilter == null || inv.status == _statusFilter;

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
                final heading = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoices',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Monitor full invoice lifecycles, send payment reminders, and download PDFs.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                );
                final actions = Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const ScanQuotationDialog(),
                        );
                      },
                      icon: const Icon(Icons.document_scanner),
                      label: const Text('Scan Quote'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openInvoiceWizard(),
                      icon: const Icon(Icons.add_card),
                      label: const Text('Create Invoice'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const InvoiceWizardScreen(
                            documentType: InvoiceDocumentType.quote,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.request_quote_outlined),
                      label: const Text('Create Quote'),
                    ),
                  ],
                );
                if (constraints.maxWidth < 700) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      heading,
                      if (state.canWrite) ...[
                        const SizedBox(height: 16),
                        actions,
                      ],
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: heading),
                    if (state.canWrite) ...[const SizedBox(width: 20), actions],
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Search and Status Filters
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final searchField = TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search invoice by number or client name...',
                        border: InputBorder.none,
                      ),
                    );
                    final statusFilter = DropdownButton<InvoiceStatus>(
                      value: _statusFilter,
                      isExpanded: constraints.maxWidth < 600,
                      hint: const Text('Filter by Status'),
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('All Statuses'),
                        ),
                        DropdownMenuItem(
                          value: InvoiceStatus.paid,
                          child: Text('Paid'),
                        ),
                        DropdownMenuItem(
                          value: InvoiceStatus.sent,
                          child: Text('Sent'),
                        ),
                        DropdownMenuItem(
                          value: InvoiceStatus.overdue,
                          child: Text('Overdue'),
                        ),
                        DropdownMenuItem(
                          value: InvoiceStatus.partiallyPaid,
                          child: Text('Partially Paid'),
                        ),
                        DropdownMenuItem(
                          value: InvoiceStatus.draft,
                          child: Text('Draft'),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _statusFilter = val;
                        });
                      },
                    );
                    if (constraints.maxWidth < 600) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.search, color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(child: searchField),
                              if (_searchQuery.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                ),
                            ],
                          ),
                          const Divider(height: 1),
                          SizedBox(width: double.infinity, child: statusFilter),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(child: searchField),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                        const VerticalDivider(width: 20, thickness: 1),
                        statusFilter,
                      ],
                    );
                  },
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
                        final client = state.clients.firstWhere(
                          (c) => c.id == inv.clientId,
                          orElse: () => ClientModel(
                            id: '',
                            name: 'Unknown Client',
                            email: '',
                            phone: '',
                            billingAddress: '',
                            shippingAddress: '',
                          ),
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      InvoiceDetailScreen(invoice: inv),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                                vertical: 14.0,
                              ),
                              child: Row(
                                children: [
                                  // Leading sequential details
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          inv.invoiceNumber,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.indigo,
                                          ),
                                        ),
                                        Text(
                                          inv.documentType ==
                                                  InvoiceDocumentType.quote
                                              ? 'QUOTE'
                                              : 'INVOICE',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                inv.documentType ==
                                                    InvoiceDocumentType.quote
                                                ? Colors.deepPurple
                                                : theme.hintColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          client.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Dates
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Issued: ${inv.issueDate.toIso8601String().split("T")[0]}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.hintColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Due: ${inv.dueDate.toIso8601String().split("T")[0]}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                inv.status ==
                                                    InvoiceStatus.overdue
                                                ? Colors.red
                                                : theme.hintColor,
                                            fontWeight:
                                                inv.status ==
                                                    InvoiceStatus.overdue
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Status Badge
                                  Expanded(
                                    child: Center(
                                      child: _buildStatusBadge(inv.status),
                                    ),
                                  ),
                                  // Totals
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          formatter.format(inv.grandTotal),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          'Items: ${inv.items.length}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: theme.hintColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  // Actions drop menu
                                  _buildInvoiceActionMenu(inv),
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
        } else if (action == 'edit') {
          _openInvoiceWizard(invoice);
        } else if (action == 'delete') {
          _deleteInvoice(invoice);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility_outlined, size: 18),
              SizedBox(width: 8),
              Text('Open Details'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_outlined, size: 18),
              SizedBox(width: 8),
              Text('Preview PDF'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'email',
          child: Row(
            children: [
              Icon(Icons.email_outlined, size: 18),
              SizedBox(width: 8),
              Text('Send Email'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 8),
              Text('Edit Wizard'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Text('Delete Invoice', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: theme.hintColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Invoices Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.hintColor,
            ),
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
