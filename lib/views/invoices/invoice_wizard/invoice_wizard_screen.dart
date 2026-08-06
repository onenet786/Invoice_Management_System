import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/app_state_provider.dart';
import '../../../models/invoice_model.dart';
import '../../../models/invoice_item_model.dart';
import '../../../models/client_model.dart';
import '../../../models/product_model.dart';

class InvoiceWizardScreen extends StatefulWidget {
  final InvoiceModel? invoice;
  final InvoiceDocumentType documentType;

  const InvoiceWizardScreen({
    super.key,
    this.invoice,
    this.documentType = InvoiceDocumentType.invoice,
  });

  @override
  State<InvoiceWizardScreen> createState() => _InvoiceWizardScreenState();
}

class _InvoiceWizardScreenState extends State<InvoiceWizardScreen> {
  int _currentStep = 0;
  final _step1FormKey = GlobalKey<FormState>();

  // Form States
  late String _invoiceNumber;
  String? _selectedClientId;
  late DateTime _issueDate;
  late DateTime _dueDate;
  late String _notes;
  late List<InvoiceItemModel> _items;
  late InvoiceStatus _status;

  bool get _isQuote =>
      widget.invoice?.documentType == InvoiceDocumentType.quote ||
      (widget.invoice == null &&
          widget.documentType == InvoiceDocumentType.quote);

  String get _documentLabel => _isQuote ? 'Quote' : 'Invoice';

  // Add Item Temp State
  ProductModel? _tempSelectedProduct;
  final _tempQtyController = TextEditingController(text: '1');
  final _tempPriceController = TextEditingController();
  final _tempTaxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final inv = widget.invoice;

    if (inv == null) {
      _invoiceNumber = _isQuote
          ? state.generateNextQuoteNumber()
          : state.generateNextInvoiceNumber();
      _issueDate = DateTime.now();
      _dueDate = DateTime.now().add(const Duration(days: 30));
      _notes = '';
      _items = [];
      _status = InvoiceStatus.draft;
    } else {
      _invoiceNumber = inv.invoiceNumber;
      _selectedClientId = inv.clientId;
      _issueDate = inv.issueDate;
      _dueDate = inv.dueDate;
      _notes = inv.notes;
      _items = List.from(inv.items);
      _status = inv.status;
    }
  }

  @override
  void dispose() {
    _tempQtyController.dispose();
    _tempPriceController.dispose();
    _tempTaxController.dispose();
    super.dispose();
  }

  void _onProductChanged(ProductModel? product) {
    if (product != null) {
      setState(() {
        _tempSelectedProduct = product;
        _tempPriceController.text = product.unitPrice.toString();
        _tempTaxController.text = product.taxRate.toString();
      });
    }
  }

  void _addTempItem() {
    if (_tempSelectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product from the catalog.'),
        ),
      );
      return;
    }

    final qty = int.tryParse(_tempQtyController.text) ?? 1;
    final price =
        double.tryParse(_tempPriceController.text) ??
        _tempSelectedProduct!.unitPrice;
    final tax =
        double.tryParse(_tempTaxController.text) ??
        _tempSelectedProduct!.taxRate;

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be greater than zero.')),
      );
      return;
    }

    setState(() {
      // Create new line item
      final newItem = InvoiceItemModel(
        id: 'item-${DateTime.now().millisecondsSinceEpoch}',
        productId: _tempSelectedProduct!.sku,
        productName: _tempSelectedProduct!.name,
        quantity: qty,
        unitPrice: price,
        taxRate: tax,
      );

      _items.add(newItem);

      // Reset temp inputs
      _tempSelectedProduct = null;
      _tempQtyController.text = '1';
      _tempPriceController.clear();
      _tempTaxController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  // Aggregate Calculations
  double get _subTotal =>
      _items.fold(0.0, (sum, item) => sum + item.lineSubtotal);
  double get _taxTotal => _items.fold(0.0, (sum, item) => sum + item.lineTax);
  double get _grandTotal =>
      _items.fold(0.0, (sum, item) => sum + item.lineTotal);

  void _saveInvoice() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Validation Error: Invoice must contain at least 1 item.',
          ),
        ),
      );
      return;
    }

    final state = Provider.of<AppStateProvider>(context, listen: false);

    if (widget.invoice == null) {
      // Create
      final newInvoice = InvoiceModel(
        id: 'inv-${DateTime.now().millisecondsSinceEpoch}',
        invoiceNumber: _invoiceNumber,
        clientId: _selectedClientId!,
        issueDate: _issueDate,
        dueDate: _dueDate,
        status: _status,
        notes: _notes,
        items: _items,
        subTotal: _subTotal,
        taxTotal: _taxTotal,
        grandTotal: _grandTotal,
        documentType: _isQuote
            ? InvoiceDocumentType.quote
            : InvoiceDocumentType.invoice,
      );
      await state.addInvoice(newInvoice);
    } else {
      // Edit
      final updatedInvoice = widget.invoice!.copyWith(
        clientId: _selectedClientId!,
        issueDate: _issueDate,
        dueDate: _dueDate,
        status: _status,
        notes: _notes,
        items: _items,
        subTotal: _subTotal,
        taxTotal: _taxTotal,
        grandTotal: _grandTotal,
      );
      await state.updateInvoice(updatedInvoice);
    }

    if (mounted) {
      // Pass back updated item
      Navigator.pop(
        context,
        widget.invoice?.copyWith(
          clientId: _selectedClientId!,
          issueDate: _issueDate,
          dueDate: _dueDate,
          status: _status,
          notes: _notes,
          items: _items,
          subTotal: _subTotal,
          taxTotal: _taxTotal,
          grandTotal: _grandTotal,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice saved successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final theme = Theme.of(context);
    final isEdit = widget.invoice != null;
    final formatter = NumberFormat.currency(
      symbol: state.company.currency,
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: Colors.indigo,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isEdit
                    ? 'Edit $_documentLabel $_invoiceNumber'
                    : 'Create New $_documentLabel',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Chip(
              backgroundColor: Colors.indigo.shade50,
              avatar: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 16,
                color: Colors.indigo,
              ),
              label: Text(
                'Total: ${formatter.format(_grandTotal)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.indigo,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              children: [
                // Custom Executive Step Navigation Bar
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.indigo.withValues(alpha: 0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildStepTab(
                        stepIndex: 0,
                        title: '1. Client Details',
                        subtitle: 'Customer & Dates',
                        icon: Icons.person_pin_outlined,
                        theme: theme,
                      ),
                      _buildStepConnector(0),
                      _buildStepTab(
                        stepIndex: 1,
                        title: '2. Line Items',
                        subtitle: '${_items.length} item(s) added',
                        icon: Icons.receipt_long_outlined,
                        theme: theme,
                      ),
                      _buildStepConnector(1),
                      _buildStepTab(
                        stepIndex: 2,
                        title: '3. Final Review',
                        subtitle: 'Status & Save',
                        icon: Icons.assignment_turned_in_outlined,
                        theme: theme,
                      ),
                    ],
                  ),
                ),

                // Active Step Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: IndexedStack(
                      index: _currentStep,
                      children: [
                        _buildStep1ClientDetails(state, theme),
                        _buildStep2LineItems(state, theme),
                        _buildStep3Review(state, theme),
                      ],
                    ),
                  ),
                ),

                // Executive Navigation Controls Footer
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    border: Border(
                      top: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Back'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => setState(() => _currentStep--),
                        )
                      else
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      const Spacer(),
                      ElevatedButton.icon(
                        icon: Icon(
                          _currentStep == 2
                              ? Icons.check_circle
                              : Icons.arrow_forward,
                          size: 18,
                        ),
                        label: Text(
                          _currentStep == 2
                              ? 'Finalize & Save $_documentLabel'
                              : 'Continue to Next Step',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          if (_currentStep == 0) {
                            if (_step1FormKey.currentState!.validate()) {
                              setState(() => _currentStep++);
                            }
                          } else if (_currentStep == 1) {
                            if (_items.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please add at least one line item to proceed.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } else {
                              setState(() => _currentStep++);
                            }
                          } else if (_currentStep == 2) {
                            _saveInvoice();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepTab({
    required int stepIndex,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeData theme,
  }) {
    final isActive = _currentStep == stepIndex;
    final isCompleted = _currentStep > stepIndex;
    final color = isActive
        ? Colors.indigo
        : (isCompleted ? Colors.green : theme.hintColor.withValues(alpha: 0.7));

    return Expanded(
      child: InkWell(
        onTap: () {
          if (stepIndex < _currentStep) {
            setState(() => _currentStep = stepIndex);
          } else if (stepIndex == 1 &&
              _step1FormKey.currentState?.validate() == true) {
            setState(() => _currentStep = 1);
          } else if (stepIndex == 2 && _items.isNotEmpty) {
            setState(() => _currentStep = 2);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.indigo
                      : (isCompleted
                            ? Colors.green.shade100
                            : theme.dividerColor.withValues(alpha: 0.2)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.check : icon,
                  size: 18,
                  color: isActive
                      ? Colors.white
                      : (isCompleted ? Colors.green.shade800 : theme.hintColor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 10, color: theme.hintColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepConnector(int stepIndex) {
    final isCompleted = _currentStep > stepIndex;
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isCompleted ? Colors.green : Colors.grey.shade300,
    );
  }

  // Step 1: Client & Dates Setup
  Widget _buildStep1ClientDetails(AppStateProvider state, ThemeData theme) {
    final bool hasClients = state.clients.isNotEmpty;
    final String? validClientId =
        hasClients && state.clients.any((c) => c.id == _selectedClientId)
        ? _selectedClientId
        : null;

    final daysDiff = _dueDate.difference(_issueDate).inDays;

    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            elevation: 0,
            color: Colors.indigo.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.indigo.withValues(alpha: 0.15)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invoice Reference: $_invoiceNumber',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        Text(
                          'Company: ${state.company.name} | Currency: ${state.company.currency}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Client Section Card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        color: Colors.indigo,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Bill To Client / Customer Directory *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.person_add_alt_1, size: 16),
                        label: const Text('Add Client'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.indigo,
                        ),
                        onPressed: () =>
                            _showQuickAddClientDialog(context, state),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: validClientId,
                    isExpanded: true,
                    hint: Text(
                      hasClients
                          ? 'Choose client from directory...'
                          : 'No clients found. Tap "Add Client" above.',
                      overflow: TextOverflow.ellipsis,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Select Customer *',
                      prefixIcon: const Icon(
                        Icons.business,
                        color: Colors.indigo,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: theme.brightness == Brightness.light
                          ? Colors.grey.shade50
                          : Colors.grey.shade900,
                    ),
                    items: state.clients.map((client) {
                      return DropdownMenuItem<String>(
                        value: client.id,
                        child: Text(
                          client.email.isNotEmpty
                              ? '${client.name} (${client.email})'
                              : client.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedClientId = val;
                      });
                    },
                    validator: (v) => v == null || v.isEmpty
                        ? 'Client selection is required'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Date Selection Section
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Invoice Billing Schedule:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Chip(
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        avatar: const Icon(
                          Icons.schedule,
                          size: 14,
                          color: Colors.indigo,
                        ),
                        label: Text(
                          '$daysDiff Days Term',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        backgroundColor: Colors.indigo.shade50,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final issuePicker = InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _issueDate,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() {
                              _issueDate = picked;
                              if (_dueDate.isBefore(_issueDate)) {
                                _dueDate = _issueDate.add(
                                  const Duration(days: 30),
                                );
                              }
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Invoice Issue Date *',
                            prefixIcon: const Icon(
                              Icons.calendar_today_outlined,
                              color: Colors.indigo,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: theme.brightness == Brightness.light
                                ? Colors.grey.shade50
                                : Colors.grey.shade900,
                          ),
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(_issueDate),
                          ),
                        ),
                      );

                      final duePicker = InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate,
                            firstDate: _issueDate,
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() {
                              _dueDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Payment Due Date *',
                            prefixIcon: const Icon(
                              Icons.calendar_month_outlined,
                              color: Colors.deepOrange,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: theme.brightness == Brightness.light
                                ? Colors.grey.shade50
                                : Colors.grey.shade900,
                          ),
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(_dueDate),
                            style: TextStyle(
                              color:
                                  _dueDate.isBefore(DateTime.now()) &&
                                      _status != InvoiceStatus.paid
                                  ? Colors.red
                                  : null,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );

                      if (constraints.maxWidth < 600) {
                        return Column(
                          children: [
                            issuePicker,
                            const SizedBox(height: 14),
                            duePicker,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: issuePicker),
                          const SizedBox(width: 14),
                          Expanded(child: duePicker),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Payment Terms & Notes
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Terms & Payment Instructions (Optional):',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text(
                          'Net 30 Days',
                          style: TextStyle(fontSize: 11),
                        ),
                        onPressed: () {
                          setState(() {
                            _notes =
                                'Payment due within 30 days via direct bank transfer or online payment.';
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text(
                          'Due Upon Receipt',
                          style: TextStyle(fontSize: 11),
                        ),
                        onPressed: () {
                          setState(() {
                            _notes =
                                'Payment is due immediately upon receipt of this invoice.';
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text(
                          '50% Upfront Deposit',
                          style: TextStyle(fontSize: 11),
                        ),
                        onPressed: () {
                          setState(() {
                            _notes =
                                '50% advance deposit required prior to project delivery.';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: _notes,
                    key: ValueKey(_notes),
                    decoration: InputDecoration(
                      labelText: 'Custom Terms / Bank Details',
                      prefixIcon: const Icon(
                        Icons.note_alt_outlined,
                        color: Colors.indigo,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: theme.brightness == Brightness.light
                          ? Colors.grey.shade50
                          : Colors.grey.shade900,
                      hintText: 'e.g. Bank Transfer: IBAN PK00-1234-5678-9000',
                    ),
                    maxLines: 2,
                    onChanged: (val) => _notes = val,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 2: Line Items builder
  Widget _buildStep2LineItems(AppStateProvider state, ThemeData theme) {
    final formatter = NumberFormat.currency(
      symbol: state.company.currency,
      decimalDigits: 2,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add Item Card
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.indigo.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.add_shopping_cart,
                      color: Colors.indigo,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Select Catalog Item / Add Custom Item:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('New Product'),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                      ),
                      onPressed: () =>
                          _showQuickAddProductDialog(context, state),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ProductModel>(
                  initialValue: _tempSelectedProduct,
                  isExpanded: true,
                  hint: const Text(
                    'Choose a product from catalog...',
                    overflow: TextOverflow.ellipsis,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: theme.brightness == Brightness.light
                        ? Colors.grey.shade50
                        : Colors.grey.shade900,
                  ),
                  items: state.products.map((p) {
                    return DropdownMenuItem<ProductModel>(
                      value: p,
                      child: Text(
                        '${p.name} (${p.sku}) - ${formatter.format(p.unitPrice)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: _onProductChanged,
                ),
                if (_tempSelectedProduct != null) ...[
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final priceField = TextFormField(
                        controller: _tempPriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Unit Price (${state.company.currency}) *',
                          prefixIcon: const Icon(
                            Icons.payments_outlined,
                            color: Colors.green,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: theme.brightness == Brightness.light
                              ? Colors.grey.shade50
                              : Colors.grey.shade900,
                        ),
                      );

                      final taxField = TextFormField(
                        controller: _tempTaxController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Tax Rate (%)',
                          prefixIcon: const Icon(
                            Icons.percent,
                            color: Colors.orange,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: theme.brightness == Brightness.light
                              ? Colors.grey.shade50
                              : Colors.grey.shade900,
                        ),
                      );

                      final qtyField = TextFormField(
                        controller: _tempQtyController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Quantity *',
                          prefixIcon: const Icon(
                            Icons.format_list_numbered,
                            color: Colors.indigo,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: theme.brightness == Brightness.light
                              ? Colors.grey.shade50
                              : Colors.grey.shade900,
                        ),
                      );

                      if (constraints.maxWidth < 600) {
                        return Column(
                          children: [
                            priceField,
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: taxField),
                                const SizedBox(width: 10),
                                Expanded(child: qtyField),
                              ],
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: priceField),
                          const SizedBox(width: 10),
                          Expanded(child: taxField),
                          const SizedBox(width: 10),
                          Expanded(child: qtyField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _addTempItem,
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: const Text('Add Item to Invoice'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Added Items List Table
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Added Line Items (${_items.length}):',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            if (_items.isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.clear_all, size: 16, color: Colors.red),
                label: const Text(
                  'Clear All',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
                onPressed: () => setState(() => _items.clear()),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_items.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: theme.hintColor.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No line items added yet.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select a product from the dropdown above to populate this invoice.',
                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            itemBuilder: (context, idx) {
              final line = _items[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade50,
                    child: Text(
                      '${idx + 1}',
                      style: const TextStyle(
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    line.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'Qty: ${line.quantity} × ${formatter.format(line.unitPrice)} | Tax: ${line.taxRate.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatter.format(line.lineTotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _removeItem(idx),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        // Financial Summary Box
        if (_items.isNotEmpty) ...[
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            color: Colors.indigo.shade900,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal:',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        formatter.format(_subTotal),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tax Total:',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        formatter.format(_taxTotal),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grand Total Due:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        formatter.format(_grandTotal),
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Step 3: Final Review and Status
  Widget _buildStep3Review(AppStateProvider state, ThemeData theme) {
    final formatter = NumberFormat.currency(
      symbol: state.company.currency,
      decimalDigits: 2,
    );
    final client = state.clients.firstWhere(
      (c) => c.id == _selectedClientId,
      orElse: () => ClientModel(
        id: '',
        name: 'No client selected',
        email: '',
        phone: '',
        billingAddress: '',
        shippingAddress: '',
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Invoice Document Summary Review:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 14),

        // Invoice Mock Sheet Preview
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.company.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        Text(
                          'Tax ID: ${state.company.taxId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _invoiceNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Billed To:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            client.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (client.email.isNotEmpty)
                            Text(
                              client.email,
                              style: const TextStyle(fontSize: 12),
                            ),
                          if (client.billingAddress.isNotEmpty)
                            Text(
                              client.billingAddress,
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Issue Date: ${DateFormat('yyyy-MM-dd').format(_issueDate)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Due Date: ${DateFormat('yyyy-MM-dd').format(_dueDate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Line Items Overview:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 8),
                ..._items.map((line) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${line.quantity}× ${line.productName}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          formatter.format(line.lineTotal),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: TextStyle(fontSize: 13)),
                    Text(
                      formatter.format(_subTotal),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Taxes Total:', style: TextStyle(fontSize: 13)),
                    Text(
                      formatter.format(_taxTotal),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Grand Total Balance Due:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatter.format(_grandTotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Status Selection
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Invoice Status:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<InvoiceStatus>(
                  initialValue: _status,
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.stars, color: Colors.indigo),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: theme.brightness == Brightness.light
                        ? Colors.grey.shade50
                        : Colors.grey.shade900,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: InvoiceStatus.draft,
                      child: Text(
                        'Draft (Saved locally for editing)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: InvoiceStatus.sent,
                      child: Text(
                        'Sent (Awaiting payment)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: InvoiceStatus.paid,
                      child: Text(
                        'Paid (Payment complete)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: InvoiceStatus.partiallyPaid,
                      child: Text(
                        'Partially Paid (Installment)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: InvoiceStatus.overdue,
                      child: Text(
                        'Overdue (Past payment term)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _status = val);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showQuickAddClientDialog(BuildContext context, AppStateProvider state) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_add_alt_1,
                  color: Colors.indigo,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Add Client',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Add customer listing to main directory',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Client / Company Name *',
                        prefixIcon: const Icon(
                          Icons.business,
                          color: Colors.indigo,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: theme.brightness == Brightness.light
                            ? Colors.grey.shade50
                            : Colors.grey.shade900,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Colors.indigo,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: theme.brightness == Brightness.light
                            ? Colors.grey.shade50
                            : Colors.grey.shade900,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: InputDecoration(
                        labelText: 'Phone Number (WhatsApp)',
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          color: Colors.green,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: theme.brightness == Brightness.light
                            ? Colors.grey.shade50
                            : Colors.grey.shade900,
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: addressCtrl,
                      decoration: InputDecoration(
                        labelText: 'Billing Address',
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          color: Colors.deepOrange,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: theme.brightness == Brightness.light
                            ? Colors.grey.shade50
                            : Colors.grey.shade900,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Save Client'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final newClient = ClientModel(
                  id: 'c-${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  billingAddress: addressCtrl.text.trim(),
                  shippingAddress: addressCtrl.text.trim(),
                );

                await state.addClient(newClient);
                setState(() {
                  _selectedClientId = newClient.id;
                });

                if (ctx.mounted) Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showQuickAddProductDialog(
    BuildContext context,
    AppStateProvider state,
  ) {
    final nameCtrl = TextEditingController();
    final skuCtrl = TextEditingController(
      text:
          'PRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
    final priceCtrl = TextEditingController();
    final taxCtrl = TextEditingController(text: '15.0');
    final descCtrl = TextEditingController();
    String category = 'General';
    bool saveToCatalog = true;
    final formKey = GlobalKey<FormState>();
    final categories = [
      'General',
      'Services',
      'Hardware',
      'Software',
      'Solar',
      'IT',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final theme = Theme.of(context);
          final currencySymbol = state.company.currency;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_shopping_cart,
                    color: Colors.indigo,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Product Item',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Add new catalog entry to invoice items',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Product / Service Name *',
                          prefixIcon: const Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.indigo,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: theme.brightness == Brightness.light
                              ? Colors.grey.shade50
                              : Colors.grey.shade900,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Product name is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        key: ValueKey(category),
                        initialValue: category,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Product Category *',
                          prefixIcon: const Icon(
                            Icons.category_outlined,
                            color: Colors.indigo,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: theme.brightness == Brightness.light
                              ? Colors.grey.shade50
                              : Colors.grey.shade900,
                        ),
                        items: [
                          ...categories.map(
                            (itemCategory) => DropdownMenuItem(
                              value: itemCategory,
                              child: Text(
                                itemCategory,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const DropdownMenuItem(
                            value: '__add_category__',
                            child: Row(
                              children: [
                                Icon(Icons.add, size: 18, color: Colors.indigo),
                                SizedBox(width: 8),
                                Text(
                                  'Add new category',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (selectedCategory) async {
                          if (selectedCategory != '__add_category__') {
                            if (selectedCategory != null) {
                              setDlgState(() => category = selectedCategory);
                            }
                            return;
                          }

                          final customController = TextEditingController();
                          final newCategory = await showDialog<String>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('New Category'),
                              content: TextField(
                                controller: customController,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  labelText: 'Category Name',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(
                                    dialogContext,
                                    customController.text.trim(),
                                  ),
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          );
                          customController.dispose();
                          if (newCategory != null && newCategory.isNotEmpty) {
                            setDlgState(() {
                              if (!categories.contains(newCategory)) {
                                categories.add(newCategory);
                              }
                              category = newCategory;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: priceCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: 'Unit Price ($currencySymbol) *',
                                prefixIcon: const Icon(
                                  Icons.payments_outlined,
                                  color: Colors.green,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: theme.brightness == Brightness.light
                                    ? Colors.grey.shade50
                                    : Colors.grey.shade900,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Price is required';
                                }
                                if (double.tryParse(v) == null) {
                                  return 'Invalid price';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: taxCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: 'Tax Rate (%)',
                                prefixIcon: const Icon(
                                  Icons.percent,
                                  color: Colors.orange,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: theme.brightness == Brightness.light
                                    ? Colors.grey.shade50
                                    : Colors.grey.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: skuCtrl,
                        decoration: InputDecoration(
                          labelText: 'SKU / Code',
                          prefixIcon: const Icon(
                            Icons.qr_code,
                            color: Colors.blueGrey,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.refresh, size: 18),
                            tooltip: 'Generate New SKU',
                            onPressed: () {
                              setDlgState(() {
                                skuCtrl.text =
                                    'PRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: theme.brightness == Brightness.light
                              ? Colors.grey.shade50
                              : Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: descCtrl,
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          prefixIcon: const Icon(
                            Icons.notes,
                            color: Colors.blueGrey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: theme.brightness == Brightness.light
                              ? Colors.grey.shade50
                              : Colors.grey.shade900,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.05),
                          border: Border.all(
                            color: Colors.indigo.withValues(alpha: 0.2),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          clipBehavior: Clip.antiAlias,
                          child: SwitchListTile(
                            value: saveToCatalog,
                            dense: true,
                            title: const Text(
                              'Save to Permanent Inventory Catalog',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: const Text(
                              'Keeps product stored in database for future invoices.',
                              style: TextStyle(fontSize: 10),
                            ),
                            onChanged: (val) {
                              setDlgState(() => saveToCatalog = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Add & Select Item'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final price = double.parse(priceCtrl.text.trim());
                  final tax = double.tryParse(taxCtrl.text.trim()) ?? 0.0;

                  final newProd = ProductModel(
                    id: 'p-${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    sku: skuCtrl.text.trim().isEmpty
                        ? 'PRD-NEW'
                        : skuCtrl.text.trim(),
                    unitPrice: price,
                    category: category,
                    taxRate: tax,
                  );

                  if (saveToCatalog) {
                    await state.addProduct(newProd);
                  }

                  setState(() {
                    _onProductChanged(newProd);
                  });

                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
