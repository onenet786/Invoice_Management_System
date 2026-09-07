import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/company_model.dart';
import '../models/client_model.dart';
import '../models/product_model.dart';
import '../models/invoice_model.dart';
import '../services/storage_service.dart';
import '../services/backup_service.dart';
import '../services/remote_sync_service.dart';

class AppStateProvider extends ChangeNotifier {
  final StorageService _storage;
  late final BackupService _backupService;
  BackupService get backupService => _backupService;
  late final RemoteSyncService _remoteSyncService;
  RemoteSyncService get remoteSyncService => _remoteSyncService;

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

  String _invoiceNumberFormat = StorageService.defaultInvoiceNumberFormat;
  String get invoiceNumberFormat => _invoiceNumberFormat;

  AppStateProvider(this._storage)
    : _company = CompanyModel(
        name: 'My Solar & IT Corp',
        logo: '',
        taxId: '',
        address: '',
        currency: '\$',
      ) {
    _backupService = BackupService(_storage, _storage.prefs);
    _remoteSyncService = RemoteSyncService(_storage, _storage.prefs);
    _loadAllData();
  }

  Future<void> reloadAllData() => _loadAllData();

  Future<void> _triggerAutoBackupIfEnabled() async {
    if (_backupService.isDriveLinked && _backupService.autoBackupEnabled) {
      await _backupService.performGoogleDriveSync();
    }
    if (_remoteSyncService.isConnected) {
      try {
        await _remoteSyncService.uploadWorkspace();
      } on RemoteSyncException {
        // The user can resolve a version conflict from the sync controls.
      }
    }
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
    _invoiceNumberFormat = _storage.invoiceNumberFormat;

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

  Future<bool> loginWithBiometrics() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    final match = _users.firstWhere(
      (u) => u.role == UserRole.admin,
      orElse: () => _users.isNotEmpty
          ? _users.first
          : UserModel(
              id: 'u-admin-default',
              name: 'Admin User',
              email: 'admin@invoice.com',
              password: '',
              role: UserRole.admin,
            ),
    );

    _currentUser = match;
    _isLoading = false;
    notifyListeners();
    return true;
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

  Future<void> setInvoiceNumberFormat(String format) async {
    final normalizedFormat = format.trim();
    if (!isAdmin || !_isValidInvoiceNumberFormat(normalizedFormat)) return;
    _invoiceNumberFormat = normalizedFormat;
    await _storage.saveInvoiceNumberFormat(normalizedFormat);
    notifyListeners();
  }

  // Company management
  Future<void> updateCompany(CompanyModel updatedCompany) async {
    if (!isAdmin) return; // Only Admin can change company profile
    _company = updatedCompany;
    await _storage.saveCompany(_company);
    await _triggerAutoBackupIfEnabled();
    notifyListeners();
  }

  // Clients CRUD
  Future<void> addClient(ClientModel client) async {
    if (!canWrite) return;
    _clients.add(client);
    await _storage.saveClients(_clients);
    await _triggerAutoBackupIfEnabled();
    notifyListeners();
  }

  Future<void> updateClient(ClientModel updatedClient) async {
    if (!canWrite) return;
    final index = _clients.indexWhere((c) => c.id == updatedClient.id);
    if (index != -1) {
      _clients[index] = updatedClient;
      await _storage.saveClients(_clients);
      await _triggerAutoBackupIfEnabled();
      notifyListeners();
    }
  }

  Future<void> deleteClient(String id) async {
    if (!canWrite) return;
    _clients.removeWhere((c) => c.id == id);
    await _storage.saveClients(_clients);
    await _triggerAutoBackupIfEnabled();
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
    await _triggerAutoBackupIfEnabled();
    notifyListeners();
  }

  Future<void> updateInvoice(InvoiceModel updatedInvoice) async {
    if (!canWrite) return;
    final index = _invoices.indexWhere((inv) => inv.id == updatedInvoice.id);
    if (index != -1) {
      _invoices[index] = updatedInvoice;
      await _storage.saveInvoices(_invoices);
      await _triggerAutoBackupIfEnabled();
      notifyListeners();
    }
  }

  Future<void> deleteInvoice(String id) async {
    if (!canWrite) return;
    _invoices.removeWhere((inv) => inv.id == id);
    await _storage.saveInvoices(_invoices);
    await _triggerAutoBackupIfEnabled();
    notifyListeners();
  }

  Future<InvoiceModel?> convertQuoteToInvoice(InvoiceModel quote) async {
    if (!canWrite ||
        quote.documentType != InvoiceDocumentType.quote ||
        quote.convertedInvoiceId != null) {
      return null;
    }

    final now = DateTime.now();
    final invoice = InvoiceModel(
      id: 'inv-${now.millisecondsSinceEpoch}',
      invoiceNumber: generateNextInvoiceNumber(),
      clientId: quote.clientId,
      issueDate: now,
      dueDate: now.add(const Duration(days: 30)),
      status: InvoiceStatus.draft,
      notes: quote.notes,
      items: quote.items,
      subTotal: quote.subTotal,
      taxTotal: quote.taxTotal,
      grandTotal: quote.grandTotal,
    );
    final quoteIndex = _invoices.indexWhere((item) => item.id == quote.id);
    if (quoteIndex == -1) return null;

    _invoices[quoteIndex] = quote.copyWith(convertedInvoiceId: invoice.id);
    _invoices.add(invoice);
    await _storage.saveInvoices(_invoices);
    await _triggerAutoBackupIfEnabled();
    notifyListeners();
    return invoice;
  }

  String generateNextQuoteNumber() {
    final year = DateTime.now().year;
    final expression = RegExp(
      '^QTE-$year-(\\d+)'
      r'$',
    );
    var maxSequence = 0;
    for (final document in _invoices) {
      final match = expression.firstMatch(document.invoiceNumber);
      final sequence = match == null ? null : int.tryParse(match.group(1)!);
      if (sequence != null && sequence > maxSequence) maxSequence = sequence;
    }
    return 'QTE-$year-${(maxSequence + 1).toString().padLeft(4, '0')}';
  }

  bool _isValidInvoiceNumberFormat(String format) {
    return RegExp(r'\{N{1,6}\}').allMatches(format).length == 1;
  }

  String _replaceDateTokens(String value, DateTime date) {
    return value
        .replaceAll('{YYYY}', date.year.toString())
        .replaceAll('{YY}', (date.year % 100).toString().padLeft(2, '0'))
        .replaceAll('{MM}', date.month.toString().padLeft(2, '0'));
  }

  String _escapeRegExp(String value) => value.replaceAllMapped(
    RegExp(r'[\\^\$.*+?()[\]{}|]'),
    (match) => '\\${match[0]}',
  );

  // Sequential Invoice Number Generator
  String generateNextInvoiceNumber() {
    final now = DateTime.now();
    final sequenceToken = RegExp(
      r'\{N{1,6}\}',
    ).firstMatch(_invoiceNumberFormat);
    if (sequenceToken == null) return 'INV-${now.year}-0001';

    final prefix = _replaceDateTokens(
      _invoiceNumberFormat.substring(0, sequenceToken.start),
      now,
    );
    final suffix = _replaceDateTokens(
      _invoiceNumberFormat.substring(sequenceToken.end),
      now,
    );
    final sequenceWidth = sequenceToken.group(0)!.length - 2;
    final expression = RegExp(
      '^${_escapeRegExp(prefix)}(\\d+)${_escapeRegExp(suffix)}\$',
    );
    int maxSeq = 0;

    for (final invoice in _invoices) {
      final match = expression.firstMatch(invoice.invoiceNumber);
      final sequence = match == null ? null : int.tryParse(match.group(1)!);
      if (sequence != null && sequence > maxSeq) {
        maxSeq = sequence;
      }
    }

    final nextSeq = maxSeq + 1;
    return '$prefix${nextSeq.toString().padLeft(sequenceWidth, '0')}$suffix';
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
