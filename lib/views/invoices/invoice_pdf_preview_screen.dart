import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../../providers/app_state_provider.dart';
import '../../models/invoice_model.dart';
import '../../models/client_model.dart';
import '../../services/pdf_service.dart';
import '../../services/whatsapp_service.dart';

class InvoicePdfPreviewScreen extends StatefulWidget {
  final InvoiceModel invoice;

  const InvoicePdfPreviewScreen({super.key, required this.invoice});

  @override
  State<InvoicePdfPreviewScreen> createState() => _InvoicePdfPreviewScreenState();
}

class _InvoicePdfPreviewScreenState extends State<InvoicePdfPreviewScreen> {
  late String _selectedTemplate;

  final List<Map<String, dynamic>> _templates = [
    {
      'name': 'Classic',
      'color': Colors.indigo,
      'description': 'Traditional, professional look with clear layout.',
    },
    {
      'name': 'Modern',
      'color': Colors.teal,
      'description': 'Vibrant banner header with sleek typography.',
    },
    {
      'name': 'Minimal',
      'color': Colors.blueGrey,
      'description': 'Clean, subtle design with maximum readability.',
    },
    {
      'name': 'Corporate',
      'color': Colors.blue.shade900,
      'description': 'Formal tax invoice structure for enterprise.',
    },
    {
      'name': 'Elegant',
      'color': Colors.purple.shade800,
      'description': 'Sophisticated accents for premium services.',
    },
  ];

  @override
  void initState() {
    super.initState();
    final state = Provider.of<AppStateProvider>(context, listen: false);
    _selectedTemplate = state.pdfTemplate;
  }

  void _onSelectTemplate(String templateName) {
    setState(() {
      _selectedTemplate = templateName;
    });
  }

  void _saveAsDefaultTemplate() async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    await state.setPdfTemplate(_selectedTemplate);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_selectedTemplate set as default template for all invoices.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final theme = Theme.of(context);

    final client = state.clients.firstWhere(
      (c) => c.id == widget.invoice.clientId,
      orElse: () => ClientModel(
        id: '',
        name: 'Unknown Client',
        email: 'N/A',
        phone: 'N/A',
        billingAddress: 'No address',
        shippingAddress: 'No address',
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Preview - ${widget.invoice.invoiceNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_outlined, color: Color(0xFF25D366)),
            tooltip: 'Share to WhatsApp',
            onPressed: () {
              WhatsappService.showWhatsappShareSheet(
                context: context,
                invoice: widget.invoice,
                client: client,
                company: state.company,
                template: _selectedTemplate,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Set as Default Template',
            onPressed: _saveAsDefaultTemplate,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Interactive Template Selection Strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(
                bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Invoice Template Preview:',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _saveAsDefaultTemplate,
                      icon: const Icon(Icons.bookmark_outline, size: 16),
                      label: Text(
                        _selectedTemplate == state.pdfTemplate
                            ? 'Default Active'
                            : 'Set Default',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 62,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _templates.length,
                    separatorBuilder: (ctx, index) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final item = _templates[index];
                      final String name = item['name'];
                      final Color color = item['color'];
                      final isSelected = name == _selectedTemplate;

                      return InkWell(
                        onTap: () => _onSelectTemplate(name),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.12)
                                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            border: Border.all(
                              color: isSelected ? color : Colors.transparent,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? color
                                          : theme.textTheme.bodyMedium?.color,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    isSelected ? 'Active Preview' : 'Tap to Preview',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isSelected
                                          ? color.withValues(alpha: 0.8)
                                          : theme.hintColor,
                                    ),
                                  ),
                                ],
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.check_circle, color: color, size: 16),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // PDF Render Area
          Expanded(
            child: PdfPreview(
              build: (format) => PdfService.generateInvoicePdf(
                invoice: widget.invoice,
                client: client,
                company: state.company,
                template: _selectedTemplate,
              ),
              canDebug: false,
              actions: const [],
              pdfFileName: '${widget.invoice.invoiceNumber}.pdf',
            ),
          ),
        ],
      ),
    );
  }
}
