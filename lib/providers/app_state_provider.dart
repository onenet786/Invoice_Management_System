import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/company_model.dart';
import '../models/client_model.dart';
import '../models/product_model.dart';
import '../models/invoice_model.dart';
import '../services/storage_service.dart';

class AppStateProvider extends ChangeNotifier {
  final StorageService _storage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool get isSetupComplete => _storage.isSetupComplete;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  CompanyModel _company;
  CompanyModel get company => _company;

  List<UserModel> _users = [];
  List<ClientModel> _clients = [];
  List<ProductModel> _products = [];
  List<InvoiceModel> _invoices = [];

  List<ClientModel> get clients => _clients;
  List<ProductModel> get products => _products;
  List<InvoiceModel> get invoices => _invoices;

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  bool _biometricEnabled = false;
  bool get biometricEnabled => _biometricEnabled;

  String _pdfTemplate = 'Classic';
  String get pdfTemplate => _pdfTemplate;

  AppStateProvider(this._storage)
    : _company = CompanyModel(
        name: 'My Solar & IT Corp',
        logo: '',
        taxId: '',
        address: '',
        currency: '\$',
      ) {
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    _isLoading = true;
    notifyListeners();

    _users = await _storage.getUsers();
    _company = await _storage.getCompany();
    _clients = await _storage.getClients();
    _products = await _storage.getProducts();
    _invoices = await _storage.getInvoices();
    _biometricEnabled = _storage.biometricEnabled;
    _pdfTemplate = _storage.pdfTemplate;

    // Check overdue invoices dynamically on load
    await _checkOverdueInvoices();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> useSampleCompany() async {
    _isLoading = true;
    notifyListeners();
    await _storage.seedSampleCompany();
    await _loadAllData();
  }

  Future<void> setupCompany({
    required String companyName,
    required String taxId,
    required String address,
    required String currency,
    required String adminName,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    await _storage.setupCompany(
      company: CompanyModel(
        name: companyName.trim(),
        logo: '',
        taxId: taxId.trim(),
        address: address.trim(),
        currency: currency,
      ),
      administrator: UserModel(
        id: 'u-admin-${DateTime.now().millisecondsSinceEpoch}',
        name: adminName.trim(),
        email: email.trim().toLowerCase(),
        password: password,
        role: UserRole.admin,
      ),
    );
    await _loadAllData();
  }

  Future<void> _checkOverdueInvoices() async {
    bool updated = false;
    final now = DateTime.now();
    for (int i = 0; i < _invoices.length; i++) {
      final inv = _invoices[i];
      if (inv.status == InvoiceStatus.sent ||
          inv.status == InvoiceStatus.partiallyPaid) {
        if (inv.dueDate.isBefore(now)) {
          _invoices[i] = inv.copyWith(status: InvoiceStatus.overdue);
          updated = true;
        }
      }
    }
    if (updated) {
      await _storage.saveInvoices(_invoices);
    }
  }

  // Authentication & Session
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simulate database lookup network latency
    await Future.delayed(const Duration(milliseconds: 600));

    final match = _users.firstWhere(
      (u) =>
          u.email.toLowerCase().trim() == email.toLowerCase().trim() &&
          u.password == password,
      orElse: () => UserModel(
        id: '',
        name: '',
        email: '',
        password: '',
        role: UserRole.viewer,
      ),
    );

    _isLoading = false;
    if (match.id.isNotEmpty) {
      _currentUser = match;
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // Role verification helper
  bool get canWrite {
    if (_currentUser == null) return false;
    return _currentUser!.role == UserRole.admin ||
        _currentUser!.role == UserRole.manager;
  }

  bool get isAdmin {
    if (_currentUser == null) return false;
    return _currentUser!.role == UserRole.admin;
  }

  // Set mock role (for sandbox testing in Settings)
  void setMockRole(UserRole role) {
    if (_currentUser != null) {
      _currentUser = UserModel(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        password: _currentUser!.password,
        role: role,
      );
      notifyListeners();
    }
  }

  // Theme Management
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    _biometricEnabled = enabled;
    await _storage.saveBiometricEnabled(enabled);
    notifyListeners();
  }

  Future<void> setPdfTemplate(String template) async {
    _pdfTemplate = template;
    await _storage.savePdfTemplate(template);
    notifyListeners();
  }

  // Company management
  Future<void> updateCompany(CompanyModel updatedCompany) async {
    if (!isAdmin) return; // Only Admin can change company profile
    _company = updatedCompany;
    await _storage.saveCompany(_company);
    notifyListeners();
  }

  // Clients CRUD
  Future<void> addClient(ClientModel client) async {
    if (!canWrite) return;
    _clients.add(client);
    await _storage.saveClients(_clients);
    notifyListeners();
  }

  Future<void> updateClient(ClientModel updatedClient) async {
    if (!canWrite) return;
    final index = _clients.indexWhere((c) => c.id == updatedClient.id);
    if (index != -1) {
      _clients[index] = updatedClient;
      await _storage.saveClients(_clients);
      notifyListeners();
    }
  }

  Future<void> deleteClient(String id) async {
    if (!canWrite) return;
    _clients.removeWhere((c) => c.id == id);
    await _storage.saveClients(_clients);
    notifyListeners();
  }

  // Products CRUD
  Future<void> addProduct(ProductModel product) async {
    if (!canWrite) return;
    _products.add(product);
    await _storage.saveProducts(_products);
    notifyListeners();
  }

  Future<void> updateProduct(ProductModel updatedProduct) async {
    if (!canWrite) return;
    final index = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (index != -1) {
      _products[index] = updatedProduct;
      await _storage.saveProducts(_products);
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    if (!canWrite) return;
    _products.removeWhere((p) => p.id == id);
    await _storage.saveProducts(_products);
    notifyListeners();
  }

  String generateProductSku({
    required String name,
    required String category,
    String? excludeProductId,
  }) {
    String code(String value, {required int maxLength}) {
      final cleaned = value.toUpperCase().replaceAll(
        RegExp(r'[^A-Z0-9 ]'),
        ' ',
      );
      final parts = cleaned
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.isEmpty) return 'GEN';
      final combined = parts.length == 1
          ? parts.first
          : parts
                .take(3)
                .map((part) => part.substring(0, part.length.clamp(1, 3)))
                .join();
      return combined.substring(0, combined.length.clamp(1, maxLength));
    }

    final categoryCode = code(category, maxLength: 3).padRight(3, 'X');
    final productCode = code(name, maxLength: 8).padRight(3, 'X');
    final usedSkus = _products
        .where((product) => product.id != excludeProductId)
        .map((product) => product.sku.toUpperCase())
        .toSet();

    var sequence = 1;
    String candidate;
    do {
      candidate =
          '$categoryCode-$productCode-${sequence.toString().padLeft(3, '0')}';
      sequence++;
    } while (usedSkus.contains(candidate));
    return candidate;
  }

  // Invoices CRUD
  Future<void> addInvoice(InvoiceModel invoice) async {
    if (!canWrite) return;
    _invoices.add(invoice);
    await _storage.saveInvoices(_invoices);
    notifyListeners();
  }

  Future<void> updateInvoice(InvoiceModel updatedInvoice) async {
    if (!canWrite) return;
    final index = _invoices.indexWhere((inv) => inv.id == updatedInvoice.id);
    if (index != -1) {
      _invoices[index] = updatedInvoice;
      await _storage.saveInvoices(_invoices);
      notifyListeners();
    }
  }

  Future<void> deleteInvoice(String id) async {
    if (!canWrite) return;
    _invoices.removeWhere((inv) => inv.id == id);
    await _storage.saveInvoices(_invoices);
    notifyListeners();
  }

  // Sequential Invoice Number Generator
  String generateNextInvoiceNumber() {
    final year = DateTime.now().year;
    final prefix = 'INV-$year-';
    int maxSeq = 0;

    for (var inv in _invoices) {
      if (inv.invoiceNumber.startsWith(prefix)) {
        final parts = inv.invoiceNumber.split('-');
        if (parts.length == 3) {
          final seqNum = int.tryParse(parts[2]);
          if (seqNum != null && seqNum > maxSeq) {
            maxSeq = seqNum;
          }
        }
      }
    }

    final nextSeq = maxSeq + 1;
    return '$prefix${nextSeq.toString().padLeft(4, '0')}';
  }

  // Analytics helper metrics
  double get totalRevenue => _invoices
      .where((inv) => inv.status == InvoiceStatus.paid)
      .fold(0.0, (sum, inv) => sum + inv.grandTotal);

  double get pendingPayments => _invoices
      .where(
        (inv) =>
            inv.status == InvoiceStatus.sent ||
            inv.status == InvoiceStatus.partiallyPaid,
      )
      .fold(0.0, (sum, inv) => sum + inv.grandTotal);

  double get overdueAmount => _invoices
      .where((inv) => inv.status == InvoiceStatus.overdue)
      .fold(0.0, (sum, inv) => sum + inv.grandTotal);

  int get paidCount =>
      _invoices.where((inv) => inv.status == InvoiceStatus.paid).length;
  int get pendingCount => _invoices
      .where(
        (inv) =>
            inv.status == InvoiceStatus.sent ||
            inv.status == InvoiceStatus.partiallyPaid,
      )
      .length;
  int get overdueCount =>
      _invoices.where((inv) => inv.status == InvoiceStatus.overdue).length;

  // Monthly Sales calculation for Chart
  // Returns map of month indices (1..12) to sum of sales
  Map<int, double> getMonthlySalesData(int year) {
    Map<int, double> monthlySales = {for (var i = 1; i <= 12; i++) i: 0.0};
    for (var inv in _invoices) {
      if (inv.issueDate.year == year && inv.status != InvoiceStatus.draft) {
        final m = inv.issueDate.month;
        monthlySales[m] = (monthlySales[m] ?? 0.0) + inv.grandTotal;
      }
    }
    return monthlySales;
  }
}
