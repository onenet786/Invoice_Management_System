import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

class _ScanQuotationDialogState extends State<ScanQuotationDialog> with SingleTickerProviderStateMixin {
  ScannedQuoteTemplate? _selectedTemplate;
  bool _isScanning = false;
  bool _isScanned = false;
  double _progress = 0.0;
  List<String> _logs = [];
  bool _isCameraMode = false;
  bool _isCameraCaptured = false;
  String? _infoMessage;
  XFile? _pickedImage;

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
      'Quotation OCR mapping completed successfully!'
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
      (c) => c.name.toLowerCase().contains(_selectedTemplate!.clientName.split(' ')[0].toLowerCase()),
      orElse: () => state.clients.isNotEmpty 
          ? state.clients.first 
          : ClientModel(id: 'c-default', name: 'EcoPower Solutions Inc.', email: 'billing@ecopower.com', phone: '', billingAddress: 'Austin, TX', shippingAddress: 'Austin, TX'),
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

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _pickedImage = image;
          _isCameraMode = false;
          _isCameraCaptured = false;
          _selectedTemplate = OcrScanService.sampleTemplates[0];
          _isScanned = false;
          _isScanning = false;
          _logs.clear();
          _progress = 0.0;
          _infoMessage = 'Gallery image loaded successfully!';
        });
      }
    } catch (e) {
      setState(() {
        _infoMessage = 'Error accessing gallery: $e';
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _pickedImage = image;
          _isCameraMode = false;
          _isCameraCaptured = true;
          _selectedTemplate = OcrScanService.sampleTemplates[0];
          _isScanned = false;
          _isScanning = false;
          _logs.clear();
          _progress = 0.0;
          _infoMessage = 'Camera snapshot captured successfully!';
        });
      }
    } catch (e) {
      setState(() {
        _infoMessage = 'Error accessing camera: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return LayoutBuilder(
      builder: (context, screenConstraints) {
        final isWide = screenConstraints.maxWidth > 750 && screenHeight > 600;

        // 1. Left section: source selection, camera, preview
        Widget leftSection(bool isExpanded) {
          final child = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('1. Choose Handwriting Source:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isCameraMode = true;
                          _isCameraCaptured = false;
                          _selectedTemplate = null;
                          _isScanned = false;
                          _isScanning = false;
                          _logs.clear();
                          _progress = 0.0;
                          _pickedImage = null;
                        });
                      },
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Use Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Upload Photo'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ScannedQuoteTemplate>(
                isExpanded: true,
                initialValue: _selectedTemplate,
                hint: const Text('Or select notebook estimate template...'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: OcrScanService.sampleTemplates.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(t.title),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedTemplate = val;
                    _isCameraMode = false;
                    _isCameraCaptured = false;
                    _isScanned = false;
                    _isScanning = false;
                    _logs.clear();
                    _progress = 0.0;
                    _pickedImage = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 250, // Fix height of the preview sheet
                child: Stack(
                  children: [
                    _buildHandwritingSheet(theme),
                    if (_isScanning)
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return Positioned(
                            top: 240 * _animController.value,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withValues(alpha: 0.8),
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

          return isExpanded
              ? Expanded(
                  flex: 11,
                  child: SingleChildScrollView(
                    child: child,
                  ),
                )
              : child;
        }

        // 2. Right section: OCR logs, status, analysis
        Widget rightSection(bool isExpanded) {
          final child = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('2. AI Scanner Logs & Extraction:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              SizedBox(
                height: isExpanded ? 260 : 180, // Scrollable height for logs
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light ? Colors.grey.shade900 : const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _logs.isEmpty
                      ? const Center(
                          child: Text(
                            'Awaiting quotation scan...',
                            style: TextStyle(color: Colors.green, fontFamily: 'monospace', fontSize: 12),
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
                LinearProgressIndicator(value: _progress, color: Colors.green, backgroundColor: Colors.grey.shade300),
              ],
              if (_isScanned) ...[
                const SizedBox(height: 12),
                _buildScanResultsSummary(theme),
              ],
            ],
          );

          return isExpanded
              ? Expanded(
                  flex: 12,
                  child: SingleChildScrollView(
                    child: child,
                  ),
                )
              : child;
        }

        // 3. Assemble dialog body
        Widget mainLayout;
        if (isWide) {
          mainLayout = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftSection(true),
              const SizedBox(width: 20),
              rightSection(true),
            ],
          );
        } else {
          mainLayout = SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leftSection(false),
                const SizedBox(height: 24),
                rightSection(false),
              ],
            ),
          );
        }

        final double maxDialogHeight = isWide
            ? (screenHeight - 140).clamp(300.0, 560.0)
            : (screenHeight - 160).clamp(250.0, 520.0);

        final Widget dialogBody = ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isWide ? 850 : 450,
            maxHeight: maxDialogHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoBanner(theme),
              Expanded(
                child: mainLayout,
              ),
            ],
          ),
        );

        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.document_scanner, color: Colors.indigo, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: const Text('Scan Handwritten Quotation'),
              ),
            ],
          ),
          content: dialogBody,
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              ),
            if (_isScanned)
              ElevatedButton.icon(
                onPressed: _convertToInvoice,
                icon: const Icon(Icons.forward_to_inbox),
                label: const Text('Import to Invoice Wizard'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInfoBanner(ThemeData theme) {
    if (_infoMessage == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.1),
        border: Border.all(color: Colors.indigo.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.indigo, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _infoMessage!,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.indigo),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _infoMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHandwritingSheet(ThemeData theme) {
    if (_isCameraMode) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Ruled paper document in background representing the camera feed
            Opacity(
              opacity: 0.6,
              child: Container(
                width: 160,
                height: 160,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEFCE8), // Yellowish ruled paper
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.amber.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTIMATE QUOTE #902\nClient: EcoPower Solutions\n\n1. 10x Solar Panels\n2. 2x Inverters\n\nTotal: \$6,900.00\nTax: 15% (USD)',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 2. Alignment Target frame
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green.withValues(alpha: 0.8), width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // 3. Status Indicator (Top-Left)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _FlashingRedDot(),
                    const SizedBox(width: 6),
                    Text(
                      'CAMERA ACTIVE',
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 4. Instruction text (Top-Right)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Align quote in grid',
                  style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // 5. Camera Button (Bottom-Center)
            Positioned(
              bottom: 12,
              child: ElevatedButton.icon(
                onPressed: _pickImageFromCamera,
                icon: const Icon(Icons.camera, size: 18),
                label: const Text('Capture Photo', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_pickedImage != null) {
      final isLight = theme.brightness == Brightness.light;
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFFEFCE8) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade300),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.file(
                File(_pickedImage!.path),
                fit: BoxFit.cover,
              ),
            ),
            if (_isCameraCaptured)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt, color: Colors.white, size: 12),
                      SizedBox(width: 6),
                      Text(
                        'Captured Photo Preview',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              )
            else
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade600,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library, color: Colors.white, size: 12),
                      SizedBox(width: 6),
                      Text(
                        'Uploaded Photo Preview',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (_selectedTemplate == null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.document_scanner, size: 40, color: theme.hintColor.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Select estimate template, use camera, or upload image to preview document.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isLight = theme.brightness == Brightness.light;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFFEFCE8) : const Color(0xFF1E293B), // Yellowish ruled paper or dark slate
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 24.0),
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
          ),
          if (_isCameraCaptured)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.white, size: 12),
                    SizedBox(width: 6),
                    Text(
                      'Captured Photo Preview',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
        color: theme.brightness == Brightness.light ? Colors.green.shade50 : Colors.green.withValues(alpha: 0.1),
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
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

class _FlashingRedDot extends StatefulWidget {
  const _FlashingRedDot();

  @override
  State<_FlashingRedDot> createState() => _FlashingRedDotState();
}

class _FlashingRedDotState extends State<_FlashingRedDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
