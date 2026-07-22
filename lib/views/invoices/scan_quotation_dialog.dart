import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../models/invoice_model.dart';
import '../../models/invoice_item_model.dart';
import '../../models/client_model.dart';
import '../../services/ocr_scan_service.dart';
import 'invoice_wizard/invoice_wizard_screen.dart';

class ScanQuotationDialog extends StatefulWidget {
  const ScanQuotationDialog({super.key});

  @override
  State<ScanQuotationDialog> createState() => _ScanQuotationDialogState();
}

class _ScanQuotationDialogState extends State<ScanQuotationDialog>
    with SingleTickerProviderStateMixin {
  ScannedQuoteTemplate? _selectedTemplate;
  bool _isScanning = false;
  bool _isScanned = false;
  double _progress = 0.0;
  List<String> _logs = [];

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _triggerScan() async {
    if (_selectedTemplate == null) return;
    setState(() {
      _isScanning = true;
      _isScanned = false;
      _progress = 0.0;
      _logs = ['[1] Initializing high-accuracy layout scan...'];
    });
    _animController.repeat(reverse: true);

    // Simulate scanning logs and progress updates
    final steps = [
      'Raw binarization of pixel arrays... Done.',
      'Analyzing alignment margins and tilt angles (Detected: 1.2° skew)... Correcting.',
      'Running handwriting recognition parser (Neural OCR engine V4.2)...',
      'Recognized Client: ${_selectedTemplate!.clientName} (Confidence: 98.4%)',
      'Extracted line item: ${_selectedTemplate!.items.first.productName} (x${_selectedTemplate!.items.first.quantity})',
      'Extracted line item: ${_selectedTemplate!.items[1].productName} (x${_selectedTemplate!.items[1].quantity})',
      'Parsed currency: \$ (Standard USD rate mappings)',
      'Parsed Terms: ${_selectedTemplate!.notes}',
      'Quotation OCR mapping completed successfully!',
    ];

    for (int i = 0; i < steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _progress = (i + 1) / steps.length;
        _logs.add('[${i + 2}] ${steps[i]}');
      });
    }

    if (mounted) {
      setState(() {
        _isScanning = false;
        _isScanned = true;
      });
      _animController.stop();
    }
  }

  void _convertToInvoice() {
    if (_selectedTemplate == null) return;
    final state = Provider.of<AppStateProvider>(context, listen: false);

    // Try to match selected template client with client list
    final client = state.clients.firstWhere(
      (c) => c.name.toLowerCase().contains(
        _selectedTemplate!.clientName.split(' ')[0].toLowerCase(),
      ),
      orElse: () => state.clients.isNotEmpty
          ? state.clients.first
          : ClientModel(
              id: 'c-default',
              name: 'EcoPower Solutions Inc.',
              email: 'billing@ecopower.com',
              phone: '',
              billingAddress: 'Austin, TX',
              shippingAddress: 'Austin, TX',
            ),
    );

    // Create InvoiceItems
    List<InvoiceItemModel> parsedItems = _selectedTemplate!.items.map((item) {
      return InvoiceItemModel(
        id: 'item-${DateTime.now().millisecondsSinceEpoch}-${item.sku}',
        productId: item.sku,
        productName: item.productName,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        taxRate: _selectedTemplate!.taxRate,
      );
    }).toList();

    // Sum details
    double sub = parsedItems.fold(0.0, (sum, item) => sum + item.lineSubtotal);
    double tax = parsedItems.fold(0.0, (sum, item) => sum + item.lineTax);
    double grand = parsedItems.fold(0.0, (sum, item) => sum + item.lineTotal);

    final mockInvoice = InvoiceModel(
      id: 'inv-${DateTime.now().millisecondsSinceEpoch}',
      invoiceNumber: state.generateNextInvoiceNumber(),
      clientId: client.id,
      issueDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 15)),
      status: InvoiceStatus.draft,
      notes: _selectedTemplate!.notes,
      items: parsedItems,
      subTotal: sub,
      taxTotal: tax,
      grandTotal: grand,
    );

    Navigator.pop(context);

    // Push details directly to wizard
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InvoiceWizardScreen(invoice: mockInvoice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.document_scanner, color: Colors.indigo, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Scan Handwritten Quotation',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 850,
        height: 480,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 650;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 11, child: _buildLeftPanel(theme)),
                  const SizedBox(width: 20),
                  Expanded(flex: 12, child: _buildRightPanel(theme)),
                ],
              );
            } else {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 380, child: _buildLeftPanel(theme)),
                    const SizedBox(height: 20),
                    SizedBox(height: 380, child: _buildRightPanel(theme)),
                  ],
                ),
              );
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (_selectedTemplate != null && !_isScanning && !_isScanned)
          ElevatedButton.icon(
            onPressed: _triggerScan,
            icon: const Icon(Icons.document_scanner),
            label: const Text('Initiate OCR Scan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        if (_isScanned)
          ElevatedButton.icon(
            onPressed: _convertToInvoice,
            icon: const Icon(Icons.forward_to_inbox),
            label: const Text('Import to Invoice Wizard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildLeftPanel(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. Select handwritten quote template to scan:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ScannedQuoteTemplate>(
          initialValue: _selectedTemplate,
          isExpanded: true,
          hint: const Text(
            'Select notebook estimate quote...',
            overflow: TextOverflow.ellipsis,
          ),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: OcrScanService.sampleTemplates.map((t) {
            return DropdownMenuItem(
              value: t,
              child: Text(t.title, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedTemplate = val;
              _isScanned = false;
              _isScanning = false;
              _logs.clear();
              _progress = 0.0;
            });
          },
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildHandwritingSheet(theme),
              if (_isScanning)
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return Positioned(
                      top: 310 * _animController.value,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(
                                alpha: 0.8,
                              ),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightPanel(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2. AI Scanner Logs & Extraction:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light
                  ? Colors.grey.shade900
                  : const Color(0xFF020617),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'Awaiting quotation scan...',
                      style: TextStyle(
                        color: Colors.green,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Text(
                          _logs[index],
                          style: const TextStyle(
                            color: Colors.green,
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        if (_isScanning) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _progress,
            color: Colors.green,
            backgroundColor: Colors.grey.shade300,
          ),
        ],
        if (_isScanned) ...[
          const SizedBox(height: 12),
          _buildScanResultsSummary(theme),
        ],
      ],
    );
  }

  Widget _buildHandwritingSheet(ThemeData theme) {
    if (_selectedTemplate == null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('Select estimate template above to preview document.'),
        ),
      );
    }

    final isLight = theme.brightness == Brightness.light;

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isLight
            ? const Color(0xFFFEFCE8)
            : const Color(0xFF1E293B), // Yellowish ruled paper or dark slate
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: SingleChildScrollView(
        child: Text(
          _selectedTemplate!.handwrittenText,
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: isLight ? Colors.blue.shade900 : Colors.amber.shade100,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildScanResultsSummary(ThemeData theme) {
    final currency = _selectedTemplate!.taxRate == 15.0 ? '\$' : '\$';
    double totalEstimate = _selectedTemplate!.items.fold(0.0, (sum, item) {
      double sub = item.unitPrice * item.quantity;
      double tax = sub * (_selectedTemplate!.taxRate / 100);
      return sum + sub + tax;
    });

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? Colors.green.shade50
            : Colors.green.withValues(alpha: 0.1),
        border: Border.all(color: Colors.green.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recognized Quote Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'Items Found: ${_selectedTemplate!.items.length} | Estimate Total: $currency${totalEstimate.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
