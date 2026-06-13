import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/company_model.dart';
import '../models/client_model.dart';
import '../models/product_model.dart';
import '../models/invoice_model.dart';
import '../services/storage_service.dart';
import '../utils/password_util.dart';
import '../utils/date_format_util.dart';
import 'package:local_auth/local_auth.dart';

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

  List<UserModel> get users => _users;
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

  bool _biometricEnabled = false;
  bool get biometricEnabled => _biometricEnabled;

  String _n8nWebhookUrl = '';
  String get n8nWebhookUrl => _n8nWebhookUrl;

  String _n8nApiKey = '';
  String get n8nApiKey => _n8nApiKey;

  bool _n8nEnabled = false;
  bool get n8nEnabled => _n8nEnabled;

  // Cached client lookup map for O(1) client resolution
  Map<String, ClientModel> _clientMap = {};
  Map<String, ClientModel> get clientMap => _clientMap;

  AppStateProvider(this._storage)
      : _company = CompanyModel(name: 'My Solar & IT Corp', logo: '', taxId: '', address: '', currency: 'PKR') {
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
    _biometricEnabled = _storage.getBiometricEnabled();
    _n8nWebhookUrl = _storage.getN8nWebhookUrl();
    _n8nApiKey = _storage.getN8nApiKey();
    _n8nEnabled = _storage.getN8nEnabled();

    // Load persisted theme preference
    _themeMode = _storage.getThemeMode();

    // Rebuild client lookup map
    _rebuildClientMap();

    // Check overdue invoices dynamically on load
    await _checkOverdueInvoices();

    // Migrate any plaintext passwords to hashed format
    await _migratePasswordsIfNeeded();

    _isLoading = false;
    notifyListeners();
  }

  /// Migrates legacy plaintext passwords to SHA-256 hashed format.
  Future<void> _migratePasswordsIfNeeded() async {
    bool migrated = false;
    for (int i = 0; i < _users.length; i++) {
      final user = _users[i];
      if (user.password.isNotEmpty && !PasswordUtil.isHashed(user.password)) {
        _users[i] = user.copyWith(
          password: PasswordUtil.hashPassword(user.password),
        );
        migrated = true;
      }
    }
    if (migrated) {
      await _storage.saveUsers(_users);
    }
  }

  /// Rebuilds the client ID → ClientModel lookup map.
  void _rebuildClientMap() {
    _clientMap = {for (var c in _clients) c.id: c};
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

    UserModel? match;
    for (final u in _users) {
      if (u.email.toLowerCase().trim() == email.toLowerCase().trim()) {
        // Verify password using secure hash comparison
        if (PasswordUtil.verifyPassword(password, u.password)) {
          match = u;
        }
        break;
      }
    }

    _isLoading = false;
    if (match != null) {
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

  Future<void> registerInitialAdmin(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    final admin = UserModel(
      id: 'u-${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim(),
      password: PasswordUtil.hashPassword(password), // Store hashed password
      role: UserRole.admin,
    );

    _users = [admin];
    await _storage.saveUsers(_users);
    
    // Automatically log in the newly registered admin
    _currentUser = admin;

    _isLoading = false;
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
      _currentUser = _currentUser!.copyWith(role: role);
      notifyListeners();
    }
  }

  // Change password for active user
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null) return false;

    // Check current password if it is set (non-empty)
    if (_currentUser!.password.isNotEmpty) {
      if (!PasswordUtil.verifyPassword(currentPassword, _currentUser!.password)) {
        return false;
      }
    }

    final updatedUser = _currentUser!.copyWith(
      password: PasswordUtil.hashPassword(newPassword),
    );

    // Update in user list
    final index = _users.indexWhere((u) => u.id == _currentUser!.id);
    if (index != -1) {
      _users[index] = updatedUser;
    } else {
      _users.add(updatedUser);
    }

    _currentUser = updatedUser;
    await _storage.saveUsers(_users);
    notifyListeners();
    return true;
  }

  // Biometrics Management
  Future<void> updateBiometricEnabled(bool enabled) async {
    _biometricEnabled = enabled;
    await _storage.saveBiometricEnabled(enabled);
    notifyListeners();
  }

  Future<bool> isBiometricHardwareAvailable() async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool canCheck = await auth.canCheckBiometrics;
      final bool isSupported = await auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  bool loginBiometricUser() {
    if (_users.isNotEmpty) {
      final adminUser = _users.firstWhere(
        (u) => u.role == UserRole.admin,
        orElse: () => _users.first,
      );
      _currentUser = adminUser;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> authenticateWithBiometrics() async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool canCheck = await auth.canCheckBiometrics;
      final bool isSupported = await auth.isDeviceSupported();
      if (!canCheck && !isSupported) return false;

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to log in to Invoicey',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        return loginBiometricUser();
      }
      return false;
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }

  // Theme Management (now persisted)
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _storage.saveThemeMode(_themeMode);
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
    _rebuildClientMap();
    await _storage.saveClients(_clients);
    notifyListeners();
  }

  Future<void> updateClient(ClientModel updatedClient) async {
    if (!canWrite) return;
    final index = _clients.indexWhere((c) => c.id == updatedClient.id);
    if (index != -1) {
      _clients[index] = updatedClient;
      _rebuildClientMap();
      await _storage.saveClients(_clients);
      notifyListeners();
    }
  }

  Future<void> deleteClient(String id) async {
    if (!canWrite) return;
    _clients.removeWhere((c) => c.id == id);
    _rebuildClientMap();
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
    final datePrefix = DateFormatUtil.toInvoicePrefix(DateTime.now());
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

  /// Returns a sorted list of distinct years present in invoice data.
  /// Always includes the current year.
  List<int> getAvailableYears() {
    final currentYear = DateTime.now().year;
    final years = <int>{currentYear};
    for (var inv in _invoices) {
      years.add(inv.issueDate.year);
    }
    final sorted = years.toList()..sort();
    return sorted;
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
      'biometricEnabled': _biometricEnabled,
      'googleDriveSimulate': _googleDriveSimulate,
      'googleDriveClientId': _googleDriveClientId,
      'googleDriveClientSecret': _googleDriveClientSecret,
    };
    return json.encode(backup);
  }

  // Restore application data from a JSON string
  Future<bool> restoreBackupData(String jsonString) async {
    try {
      final Map<String, dynamic> backup = json.decode(jsonString) as Map<String, dynamic>;
      
      // Parse company (fallback to keeping current company if not in backup)
      CompanyModel company = _company;
      if (backup.containsKey('company')) {
        company = CompanyModel.fromJson(backup['company'] as Map<String, dynamic>);
      }
      
      // Parse clients (fallback to keeping current clients if not in backup)
      List<ClientModel> clients = _clients;
      if (backup.containsKey('clients')) {
        clients = (backup['clients'] as List)
            .map((e) => ClientModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
          
      // Parse products (fallback to keeping current products if not in backup)
      List<ProductModel> products = _products;
      if (backup.containsKey('products')) {
        products = (backup['products'] as List)
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
          
      // Parse invoices (fallback to keeping current invoices if not in backup)
      List<InvoiceModel> invoices = _invoices;
      if (backup.containsKey('invoices')) {
        invoices = (backup['invoices'] as List)
            .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Parse users (fallback to keeping current users if not in backup)
      List<UserModel> users = _users;
      if (backup.containsKey('users')) {
        users = (backup['users'] as List)
            .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Parse biometric choice
      if (backup.containsKey('biometricEnabled')) {
        _biometricEnabled = backup['biometricEnabled'] as bool? ?? false;
        await _storage.saveBiometricEnabled(_biometricEnabled);
      }

      // Parse google drive preferences
      if (backup.containsKey('googleDriveSimulate')) {
        _googleDriveSimulate = backup['googleDriveSimulate'] as bool? ?? true;
        await _storage.saveGoogleDriveSimulate(_googleDriveSimulate);
      }
      if (backup.containsKey('googleDriveClientId')) {
        _googleDriveClientId = backup['googleDriveClientId'] as String? ?? '';
        await _storage.saveGoogleDriveClientId(_googleDriveClientId);
      }
      if (backup.containsKey('googleDriveClientSecret')) {
        _googleDriveClientSecret = backup['googleDriveClientSecret'] as String? ?? '';
        await _storage.saveGoogleDriveClientSecret(_googleDriveClientSecret);
      }

      // Save collections to storage
      await _storage.saveCompany(company);
      await _storage.saveClients(clients);
      await _storage.saveProducts(products);
      await _storage.saveInvoices(invoices);
      await _storage.saveUsers(users);

      // Re-load into local State
      _company = company;
      _clients = clients;
      _products = products;
      _invoices = invoices;
      _users = users;
      _rebuildClientMap();
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Backup restoration error: $e');
      return false;
    }
  }

  Future<void> updateN8nSettings({
    required bool enabled,
    required String webhookUrl,
    required String apiKey,
  }) async {
    _n8nEnabled = enabled;
    _n8nWebhookUrl = webhookUrl.trim();
    _n8nApiKey = apiKey.trim();

    await _storage.saveN8nEnabled(_n8nEnabled);
    await _storage.saveN8nWebhookUrl(_n8nWebhookUrl);
    await _storage.saveN8nApiKey(_n8nApiKey);

    notifyListeners();
  }
}
