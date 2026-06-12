import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  String? _currentOtp;
  String? get currentOtp => _currentOtp;

  UserModel? _pendingOtpUser;
  UserModel? get pendingOtpUser => _pendingOtpUser;

  bool _googleDriveSimulate = true;
  bool get googleDriveSimulate => _googleDriveSimulate;

  String _googleDriveClientId = '';
  String get googleDriveClientId => _googleDriveClientId;

  String _googleDriveClientSecret = '';
  String get googleDriveClientSecret => _googleDriveClientSecret;

  AppStateProvider(this._storage)
      : _company = CompanyModel(name: 'My Solar & IT Corp', logo: '', taxId: '', address: '', currency: '\$') {
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
    _googleDriveSimulate = _storage.getGoogleDriveSimulate();
    _googleDriveClientId = _storage.getGoogleDriveClientId();
    _googleDriveClientSecret = _storage.getGoogleDriveClientSecret();

    // Check overdue invoices dynamically on load
    await _checkOverdueInvoices();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _checkOverdueInvoices() async {
    bool updated = false;
    final now = DateTime.now();
    for (int i = 0; i < _invoices.length; i++) {
      final inv = _invoices[i];
      if (inv.status == InvoiceStatus.sent || inv.status == InvoiceStatus.partiallyPaid) {
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
      (u) => u.email.toLowerCase().trim() == email.toLowerCase().trim() && u.password == password,
      orElse: () => UserModel(id: '', name: '', email: '', password: '', role: UserRole.viewer),
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

  Future<void> initiateGoogleSignIn(String email) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    // Search for existing user in database
    UserModel? match = _users.firstWhere(
      (u) => u.email.toLowerCase().trim() == email.toLowerCase().trim(),
      orElse: () => UserModel(id: '', name: '', email: '', password: '', role: UserRole.viewer),
    );

    // If user does not exist, auto-register them
    if (match.id.isEmpty) {
      final namePrefix = email.split('@')[0];
      final capitalizedName = namePrefix.isNotEmpty
          ? namePrefix[0].toUpperCase() + namePrefix.substring(1)
          : 'Google User';

      match = UserModel(
        id: 'u-google-${DateTime.now().millisecondsSinceEpoch}',
        name: capitalizedName,
        email: email,
        password: '', // Google users don't need a local password
        role: UserRole.viewer, // Default new user to Viewer role
      );
      _users.add(match);
      await _storage.saveUsers(_users);
    }

    // Generate random 6-digit OTP
    final random = Random();
    final otpVal = 100000 + random.nextInt(900000);
    _currentOtp = otpVal.toString();
    _pendingOtpUser = match;

    _isLoading = false;
    notifyListeners();
  }

  bool verifyOtp(String enteredCode) {
    if (_currentOtp != null && enteredCode.trim() == _currentOtp) {
      _currentUser = _pendingOtpUser;
      _currentOtp = null;
      _pendingOtpUser = null;
      notifyListeners();
      return true;
    }
    return false;
  }

  void cancelOtpSession() {
    _currentOtp = null;
    _pendingOtpUser = null;
    notifyListeners();
  }

  // Role verification helper
  bool get canWrite {
    if (_currentUser == null) return false;
    return _currentUser!.role == UserRole.admin || _currentUser!.role == UserRole.manager;
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
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Google Drive Config Settings
  Future<void> updateGoogleDriveSettings({
    required bool simulate,
    required String clientId,
    required String clientSecret,
  }) async {
    _googleDriveSimulate = simulate;
    _googleDriveClientId = clientId;
    _googleDriveClientSecret = clientSecret;
    await _storage.saveGoogleDriveSimulate(simulate);
    await _storage.saveGoogleDriveClientId(clientId);
    await _storage.saveGoogleDriveClientSecret(clientSecret);
    notifyListeners();
  }

  // Database Management
  Future<void> resetDatabase() async {
    _isLoading = true;
    notifyListeners();

    await _storage.resetDatabase();
    await _loadAllData();

    _isLoading = false;
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
    final datePrefix = DateFormat('ddMMMyyyy-').format(DateTime.now());
    int maxSeq = 0;

    for (var inv in _invoices) {
      if (inv.invoiceNumber.startsWith(datePrefix)) {
        final parts = inv.invoiceNumber.split('-');
        if (parts.length == 2) {
          final seqNum = int.tryParse(parts[1]);
          if (seqNum != null && seqNum > maxSeq) {
            maxSeq = seqNum;
          }
        }
      }
    }

    final nextSeq = maxSeq + 1;
    return '$datePrefix${nextSeq.toString().padLeft(4, '0')}';
  }

  // Analytics helper metrics
  double get totalRevenue => _invoices
      .where((inv) => inv.status == InvoiceStatus.paid)
      .fold(0.0, (sum, inv) => sum + inv.grandTotal);

  double get pendingPayments => _invoices
      .where((inv) => inv.status == InvoiceStatus.sent || inv.status == InvoiceStatus.partiallyPaid)
      .fold(0.0, (sum, inv) => sum + inv.grandTotal);

  double get overdueAmount => _invoices
      .where((inv) => inv.status == InvoiceStatus.overdue)
      .fold(0.0, (sum, inv) => sum + inv.grandTotal);

  int get paidCount => _invoices.where((inv) => inv.status == InvoiceStatus.paid).length;
  int get pendingCount => _invoices.where((inv) => inv.status == InvoiceStatus.sent || inv.status == InvoiceStatus.partiallyPaid).length;
  int get overdueCount => _invoices.where((inv) => inv.status == InvoiceStatus.overdue).length;

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

  // Export all application data as a JSON string
  String exportBackupData() {
    final Map<String, dynamic> backup = {
      'backupVersion': 1,
      'backupTimestamp': DateTime.now().toIso8601String(),
      'company': _company.toJson(),
      'clients': _clients.map((c) => c.toJson()).toList(),
      'products': _products.map((p) => p.toJson()).toList(),
      'invoices': _invoices.map((inv) => inv.toJson()).toList(),
      'users': _users.map((u) => u.toJson()).toList(),
    };
    return json.encode(backup);
  }

  // Restore application data from a JSON string
  Future<bool> restoreBackupData(String jsonString) async {
    try {
      final Map<String, dynamic> backup = json.decode(jsonString) as Map<String, dynamic>;
      
      // Validate backup version or basic keys
      if (!backup.containsKey('company') ||
          !backup.containsKey('clients') ||
          !backup.containsKey('products') ||
          !backup.containsKey('invoices')) {
        return false;
      }

      // Parse and load
      final CompanyModel company = CompanyModel.fromJson(backup['company'] as Map<String, dynamic>);
      
      final List<ClientModel> clients = (backup['clients'] as List)
          .map((e) => ClientModel.fromJson(e as Map<String, dynamic>))
          .toList();
          
      final List<ProductModel> products = (backup['products'] as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
          
      final List<InvoiceModel> invoices = (backup['invoices'] as List)
          .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
          .toList();

      List<UserModel> users = [];
      if (backup.containsKey('users')) {
        users = (backup['users'] as List)
            .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Save to storage
      await _storage.saveCompany(company);
      await _storage.saveClients(clients);
      await _storage.saveProducts(products);
      await _storage.saveInvoices(invoices);
      if (users.isNotEmpty) {
        await _storage.saveUsers(users);
      }

      // Re-load into local State
      _company = company;
      _clients = clients;
      _products = products;
      _invoices = invoices;
      if (users.isNotEmpty) {
        _users = users;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Backup restoration error: $e');
      return false;
    }
  }
}
