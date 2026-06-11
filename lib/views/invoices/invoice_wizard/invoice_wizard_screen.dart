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

  const InvoiceWizardScreen({super.key, this.invoice});

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
      _invoiceNumber = state.generateNextInvoiceNumber();
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
        const SnackBar(content: Text('Please select a product from the catalog.')),
      );
      return;
    }

    final qty = int.tryParse(_tempQtyController.text) ?? 1;
    final price = double.tryParse(_tempPriceController.text) ?? _tempSelectedProduct!.unitPrice;
    final tax = double.tryParse(_tempTaxController.text) ?? _tempSelectedProduct!.taxRate;

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
  double get _subTotal => _items.fold(0.0, (sum, item) => sum + item.lineSubtotal);
  double get _taxTotal => _items.fold(0.0, (sum, item) => sum + item.lineTax);
  double get _grandTotal => _items.fold(0.0, (sum, item) => sum + item.lineTotal);

  void _saveInvoice() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Validation Error: Invoice must contain at least 1 item.')),
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
      Navigator.pop(context, widget.invoice?.copyWith(
        clientId: _selectedClientId!,
        issueDate: _issueDate,
        dueDate: _dueDate,
        status: _status,
        notes: _notes,
        items: _items,
        subTotal: _subTotal,
        taxTotal: _taxTotal,
        grandTotal: _grandTotal,
      ));
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Invoice Wizard: Edit $_invoiceNumber' : 'Invoice Wizard: Create Invoice'),
      ),
      body: Stepper(
        type: isMobile ? StepperType.vertical : StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0) {
            if (_step1FormKey.currentState!.validate()) {
              setState(() => _currentStep++);
            }
          } else if (_currentStep == 1) {
            if (_items.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please add at least one item to proceed.')),
              );
            } else {
              setState(() => _currentStep++);
            }
          } else if (_currentStep == 2) {
            _saveInvoice();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          } else {
            Navigator.pop(context);
          }
        },
        controlsBuilder: (context, controls) {
          final isLastStep = _currentStep == 2;
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: controls.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(isLastStep ? 'Finalize & Save' : 'Continue'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    onPressed: controls.onStepCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(_currentStep == 0 ? 'Cancel' : 'Back'),
                  ),
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Client details'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: _buildStep1ClientDetails(state, theme),
          ),
          Step(
            title: const Text('Line Items'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: _buildStep2LineItems(state, theme),
          ),
          Step(
            title: const Text('Final Review'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: _buildStep3Review(state, theme),
          ),
        ],
      ),
    );
  }

  // Step 1: Client & Dates Setup
  Widget _buildStep1ClientDetails(AppStateProvider state, ThemeData theme) {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'General Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
          const SizedBox(height: 16),

          // Client Dropdown Selector
          DropdownButtonFormField<String>(
            initialValue: _selectedClientId,
            decoration: const InputDecoration(
              labelText: 'Select Client *',
              prefixIcon: Icon(Icons.people_outline),
              border: OutlineInputBorder(),
            ),
            items: state.clients.map((client) {
              return DropdownMenuItem<String>(
                value: client.id,
                child: Text(client.name),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedClientId = val;
              });
            },
            validator: (v) => v == null ? 'Client selection is required' : null,
          ),
          const SizedBox(height: 20),

          // Issue Date picker
          Row(
            children: [
              Expanded(
                child: InkWell(
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
                        // Automatically push due date forward if due date is behind issue date
                        if (_dueDate.isBefore(_issueDate)) {
                          _dueDate = _issueDate.add(const Duration(days: 30));
                        }
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Invoice Issue Date *',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(DateFormat('yyyy-MM-dd').format(_issueDate)),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Due Date picker
              Expanded(
                child: InkWell(
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
                    decoration: const InputDecoration(
                      labelText: 'Invoice Due Date *',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      DateFormat('yyyy-MM-dd').format(_dueDate),
                      style: TextStyle(
                        color: _dueDate.isBefore(DateTime.now()) && _status != InvoiceStatus.paid
                            ? Colors.red
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Memo notes
          TextFormField(
            initialValue: _notes,
            decoration: const InputDecoration(
              labelText: 'Terms / Payment Notes (Optional)',
              prefixIcon: Icon(Icons.note_alt_outlined),
              border: OutlineInputBorder(),
              hintText: 'e.g. Please send payment within 30 days via direct bank transfer.',
            ),
            maxLines: 3,
            onChanged: (val) {
              _notes = val;
            },
          ),
        ],
      ),
    );
  }

  // Step 2: Line Items builder
  Widget _buildStep2LineItems(AppStateProvider state, ThemeData theme) {
    final formatter = NumberFormat.currency(symbol: state.company.currency, decimalDigits: 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Invoice Items Builder',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        const SizedBox(height: 16),

        // Add Product Area
        Card(
          elevation: 1,
          color: theme.cardColor,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.indigo.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Product from Inventory Catalog:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 12),
                DropdownButtonFormField<ProductModel>(
                  initialValue: _tempSelectedProduct,
                  hint: const Text('Choose a pre-seeded product...'),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  items: state.products.map((p) {
                    return DropdownMenuItem<ProductModel>(
                      value: p,
                      child: Text('${p.name} (${p.sku})'),
                    );
                  }).toList(),
                  onChanged: _onProductChanged,
                ),
                if (_tempSelectedProduct != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Price
                      Expanded(
                        child: TextFormField(
                          controller: _tempPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Custom Unit Price',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Tax Rate
                      Expanded(
                        child: TextFormField(
                          controller: _tempTaxController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Custom Tax (%)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Qty
                      Expanded(
                        child: TextFormField(
                          controller: _tempQtyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _addTempItem,
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Add Line Item'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Added Items List Table
        const Text('Added Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        if (_items.isEmpty)
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('No items added. Use the form above to add items.'),
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
                child: ListTile(
                  title: Text(line.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(
                    'Qty: ${line.quantity} × ${formatter.format(line.unitPrice)} | Tax: ${line.taxRate.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatter.format(line.lineTotal),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _removeItem(idx),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        
        // Calculated real-time aggregates
        const SizedBox(height: 20),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:'),
                  Text(formatter.format(_subTotal)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tax Total:'),
                  Text(formatter.format(_taxTotal)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(formatter.format(_grandTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 3: Final Review and Status
  Widget _buildStep3Review(AppStateProvider state, ThemeData theme) {
    final formatter = NumberFormat.currency(symbol: state.company.currency, decimalDigits: 2);
    final client = state.clients.firstWhere(
      (c) => c.id == _selectedClientId,
      orElse: () => ClientModel(id: '', name: 'No client selected', email: '', phone: '', billingAddress: '', shippingAddress: ''),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Invoice Final Summary Review',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        const SizedBox(height: 16),

        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Invoice Number:'),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _invoiceNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bill To Customer:'),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        client.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Issue Date:'),
                    Text(DateFormat('yyyy-MM-dd').format(_issueDate)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Due Date:'),
                    Text(DateFormat('yyyy-MM-dd').format(_dueDate)),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Subtotal:'),
                    Text(formatter.format(_subTotal)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Taxes:'),
                    Text(formatter.format(_taxTotal)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Balance Due:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                    Text(formatter.format(_grandTotal), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Status Selection
        const Text('Select Initial Status:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<InvoiceStatus>(
          initialValue: _status,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.stars),
          ),
          items: const [
            DropdownMenuItem(value: InvoiceStatus.draft, child: Text('Draft (Saved locally for edits)')),
            DropdownMenuItem(value: InvoiceStatus.sent, child: Text('Sent (Awaiting payment)')),
            DropdownMenuItem(value: InvoiceStatus.paid, child: Text('Paid (Complete)')),
            DropdownMenuItem(value: InvoiceStatus.partiallyPaid, child: Text('Partially Paid')),
            DropdownMenuItem(value: InvoiceStatus.overdue, child: Text('Overdue (Past term)')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _status = val;
              });
            }
          },
        ),
      ],
    );
  }
}
