import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../models/product_model.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openProductForm([ProductModel? product]) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    if (!state.canWrite) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Access Denied: Viewers cannot manage the product catalog.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _ProductFormDialog(product: product),
    );
  }

  void _deleteProduct(ProductModel product) async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    if (!state.canWrite) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Viewers cannot delete products.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text(
          'Are you sure you want to delete product "${product.name}"? This action cannot be undone.',
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
      await state.deleteProduct(product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted product "${product.name}" successfully.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final theme = Theme.of(context);
    final currency = state.company.currency;
    final formatter = NumberFormat.currency(symbol: currency, decimalDigits: 2);

    // Dynamically collect unique categories
    final categoryTabs = <String>[
      'All',
      ...<String>{
        'Solar',
        'IT',
        'Hardware',
        'Services',
        'Software',
        'General',
        ...state.products.map((p) => p.category.trim()).where((c) => c.isNotEmpty),
      },
    ];

    // Filter items
    List<ProductModel> filterProductsByCategory(String? category) {
      return state.products.where((p) {
        final matchesCategory =
            category == null ||
            p.category.toLowerCase() == category.toLowerCase();
        final q = _searchQuery.toLowerCase();
        final matchesSearch =
            p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q);
        return matchesCategory && matchesSearch;
      }).toList();
    }

    return DefaultTabController(
      length: categoryTabs.length,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 650;
                  final heading = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inventory Catalog',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Configure products, standard rates, automatic SKUs, and categories.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  );
                  final addButton = ElevatedButton.icon(
                    onPressed: () => _openProductForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        heading,
                        if (state.canWrite) ...[
                          const SizedBox(height: 16),
                          addButton,
                        ],
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: heading),
                      if (state.canWrite) ...[
                        const SizedBox(width: 20),
                        addButton,
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Tab navigation & Search
              Row(
                children: [
                  Expanded(
                    child: TabBar(
                      isScrollable: true,
                      labelColor: Colors.indigo,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.indigo,
                      tabs: categoryTabs.map((cat) {
                        return Tab(text: cat == 'All' ? 'All Items' : cat);
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search input field
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search catalog by SKU, name, or description...',
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // TabBarView implementation
              Expanded(
                child: TabBarView(
                  children: categoryTabs.map((cat) {
                    final filterCat = cat == 'All' ? null : cat;
                    return _buildProductGrid(
                      filterProductsByCategory(filterCat),
                      formatter,
                      theme,
                      state,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(
    List<ProductModel> products,
    NumberFormat formatter,
    ThemeData theme,
    AppStateProvider state,
  ) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: theme.hintColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Products Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try refining your search text.'
                  : 'Get started by creating your first product listing.',
              style: TextStyle(color: theme.hintColor),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Choose grid layout columns based on width
        final crossCount = constraints.maxWidth > 1200
            ? 3
            : (constraints.maxWidth > 700 ? 2 : 1);
        final cardAspectRatio = crossCount == 1
            ? 1.45
            : (crossCount == 2 ? 1.75 : 2.1);
        return GridView.builder(
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: cardAspectRatio,
          ),
          itemBuilder: (context, index) {
            final prod = products[index];
            return Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SKU and Category badge row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              prod.sku,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(child: _buildCategoryBadge(prod.category)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Name and description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prod.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            prod.description.isNotEmpty
                                ? prod.description
                                : 'No description provided.',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.hintColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // Price, Tax, Edit actions row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatter.format(prod.unitPrice),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.indigo,
                              ),
                            ),
                            Text(
                              'Tax: ${prod.taxRate.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.indigo,
                                size: 20,
                              ),
                              onPressed: () => _openProductForm(prod),
                              tooltip: 'Edit Details',
                            ),
                            if (state.canWrite)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () => _deleteProduct(prod),
                                tooltip: 'Delete Product',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryBadge(String cat) {
    final isSolar = cat.toLowerCase() == 'solar';
    final isIt = cat.toLowerCase() == 'it';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSolar
            ? Colors.amber.withValues(alpha: 0.12)
            : Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isSolar ? 'Solar System' : (isIt ? 'IT Hardware' : cat),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isSolar ? Colors.amber.shade900 : Colors.purple.shade900,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _ProductFormDialog extends StatefulWidget {
  final ProductModel? product;

  const _ProductFormDialog({this.product});

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _taxController;
  late TextEditingController _newCategoryController;
  late String _category;
  bool _addingCategory = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(
      text: p?.unitPrice.toString() ?? '',
    );
    _taxController = TextEditingController(
      text: p?.taxRate.toString() ?? '15.0',
    );
    _newCategoryController = TextEditingController();
    _category = p?.category ?? 'Solar';
    _nameController.addListener(_refreshGeneratedSku);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _taxController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  void _refreshGeneratedSku() {
    if (!mounted ||
        widget.product != null &&
            _nameController.text == widget.product!.name &&
            _category == widget.product!.category) {
      return;
    }
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _skuController.clear();
      return;
    }
    final state = Provider.of<AppStateProvider>(context, listen: false);
    _skuController.text = state.generateProductSku(
      name: name,
      category: _category,
      excludeProductId: widget.product?.id,
    );
  }

  void _addCategory() {
    final category = _newCategoryController.text.trim();
    if (category.isEmpty) return;
    setState(() {
      _category = category;
      _addingCategory = false;
      _newCategoryController.clear();
    });
    _refreshGeneratedSku();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final state = Provider.of<AppStateProvider>(context, listen: false);
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final tax = double.tryParse(_taxController.text) ?? 0.0;

    if (widget.product == null) {
      final newProd = ProductModel(
        id: 'p-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text,
        description: _descController.text,
        sku: _skuController.text.trim().toUpperCase(),
        unitPrice: price,
        category: _category,
        taxRate: tax,
      );
      await state.addProduct(newProd);
    } else {
      final updated = widget.product!.copyWith(
        name: _nameController.text,
        description: _descController.text,
        sku: _skuController.text.trim().toUpperCase(),
        unitPrice: price,
        category: _category,
        taxRate: tax,
      );
      await state.updateProduct(updated);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.product == null
                ? 'Product added successfully!'
                : 'Product updated successfully!',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final theme = Theme.of(context);
    final currencySymbol = state.company.currency;
    final categories =
        <String>{
            'Solar',
            'Hardware',
            'IT',
            'Services',
            'Software',
            'General',
            ...state.products.map((product) => product.category.trim()),
            if (_category.isNotEmpty) _category,
          }.where((category) => category.isNotEmpty).toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(isEdit ? Icons.edit_note : Icons.add_shopping_cart, color: Colors.indigo, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Catalog Product' : 'Add Catalog Product',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isEdit ? 'Update product pricing & details' : 'Register new item in inventory database',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Product Name *',
                    prefixIcon: const Icon(Icons.shopping_bag_outlined, color: Colors.indigo),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: theme.brightness == Brightness.light ? Colors.grey.shade50 : Colors.grey.shade900,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Product name is required'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _skuController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Auto-generated SKU',
                    prefixIcon: const Icon(Icons.qr_code_scanner_outlined, color: Colors.blueGrey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: theme.brightness == Brightness.light ? Colors.grey.shade50 : Colors.grey.shade900,
                    helperText: 'Generated from category and product name',
                    suffixIcon: IconButton(
                      tooltip: 'Generate SKU again',
                      onPressed: _refreshGeneratedSku,
                      icon: const Icon(Icons.refresh, color: Colors.indigo),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'SKU Code is required'
                      : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  key: ValueKey(_category),
                  initialValue: categories.contains(_category) ? _category : (categories.isNotEmpty ? categories.first : 'General'),
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Product Category *',
                    prefixIcon: const Icon(Icons.category_outlined, color: Colors.indigo),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: theme.brightness == Brightness.light ? Colors.grey.shade50 : Colors.grey.shade900,
                  ),
                  items: [
                    ...categories.map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    const DropdownMenuItem(
                      value: '__add_category__',
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 18, color: Colors.indigo),
                          SizedBox(width: 8),
                          Text('Add new category', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val == '__add_category__') {
                      setState(() => _addingCategory = true);
                    } else if (val != null) {
                      setState(() {
                        _category = val;
                        _addingCategory = false;
                      });
                      _refreshGeneratedSku();
                    }
                  },
                ),
                if (_addingCategory) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newCategoryController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'New category name',
                      hintText: 'Example: Hardware',
                      prefixIcon: const Icon(Icons.create_new_folder_outlined, color: Colors.indigo),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: theme.brightness == Brightness.light ? Colors.grey.shade50 : Colors.grey.shade900,
                      suffixIcon: IconButton(
                        tooltip: 'Add category',
                        onPressed: _addCategory,
                        icon: const Icon(Icons.check, color: Colors.green),
                      ),
                    ),
                    onFieldSubmitted: (_) => _addCategory(),
                  ),
                ],
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final priceField = TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Unit Price ($currencySymbol) *',
                        prefixIcon: const Icon(Icons.payments_outlined, color: Colors.green),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: theme.brightness == Brightness.light ? Colors.grey.shade50 : Colors.grey.shade900,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Price is required';
                        }
                        if (double.tryParse(v) == null) {
                          return 'Enter a number';
                        }
                        return null;
                      },
                    );
                    final taxField = TextFormField(
                      controller: _taxController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Tax Rate (%)',
                        prefixIcon: const Icon(Icons.percent, color: Colors.orange),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: theme.brightness == Brightness.light ? Colors.grey.shade50 : Colors.grey.shade900,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Tax rate is required';
                        }
                        if (double.tryParse(v) == null) {
                          return 'Enter a number';
                        }
                        return null;
                      },
                    );
                    if (constraints.maxWidth < 420) {
                      return Column(
                        children: [
                          priceField,
                          const SizedBox(height: 14),
                          taxField,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: priceField),
                        const SizedBox(width: 12),
                        Expanded(child: taxField),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descController,
                  decoration: InputDecoration(
                    labelText: 'Description / Specifications',
                    prefixIcon: const Icon(Icons.notes, color: Colors.blueGrey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: theme.brightness == Brightness.light ? Colors.grey.shade50 : Colors.grey.shade900,
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(isEdit ? 'Save Changes' : 'Add to Catalog'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _save,
        ),
      ],
    );
  }
}
