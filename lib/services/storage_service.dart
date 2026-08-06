import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/company_model.dart';
import '../models/client_model.dart';
import '../models/product_model.dart';
import '../models/invoice_model.dart';
import '../models/invoice_item_model.dart';

class StorageService {
  static const String _keyUsers = 'invoice_users';
  static const String _keyCompany = 'invoice_company';
  static const String _keyClients = 'invoice_clients';
  static const String _keyProducts = 'invoice_products';
  static const String _keyInvoices = 'invoice_invoices';
  static const String _keyFirstRun = 'invoice_first_run';
  static const String _keyBiometricEnabled = 'invoice_biometric_enabled';
  static const String _keyPdfTemplate = 'invoice_pdf_template';
  static const String _keyInvoiceNumberFormat = 'invoice_number_format';
  static const String defaultInvoiceNumberFormat = 'INV-{YYYY}-{NNNN}';

  final SharedPreferences _prefs;
  SharedPreferences get prefs => _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  bool get isSetupComplete => _prefs.getBool(_keyFirstRun) == false;
  bool get biometricEnabled => _prefs.getBool(_keyBiometricEnabled) ?? false;
  String get pdfTemplate {
    const templates = {'Classic', 'Modern', 'Minimal', 'Corporate', 'Elegant'};
    final saved = _prefs.getString(_keyPdfTemplate);
    return templates.contains(saved) ? saved! : 'Classic';
  }

  String get invoiceNumberFormat {
    final saved = _prefs.getString(_keyInvoiceNumberFormat)?.trim();
    return saved == null || saved.isEmpty ? defaultInvoiceNumberFormat : saved;
  }

  Future<void> saveBiometricEnabled(bool enabled) async {
    await _prefs.setBool(_keyBiometricEnabled, enabled);
  }

  Future<void> savePdfTemplate(String template) async {
    await _prefs.setString(_keyPdfTemplate, template);
  }

  Future<void> saveInvoiceNumberFormat(String format) async {
    await _prefs.setString(_keyInvoiceNumberFormat, format);
  }

  // Seed the original demonstration workspace only after the user chooses it.
  Future<void> seedSampleCompany() async {
    // Seed default users
    final users = [
      UserModel(
        id: 'u-1',
        name: 'Super Admin',
        email: 'admin@invoice.com',
        password: 'admin123',
        role: UserRole.admin,
      ),
      UserModel(
        id: 'u-2',
        name: 'Project Manager',
        email: 'manager@invoice.com',
        password: 'manager123',
        role: UserRole.manager,
      ),
      UserModel(
        id: 'u-3',
        name: 'General Viewer',
        email: 'viewer@invoice.com',
        password: 'viewer123',
        role: UserRole.viewer,
      ),
    ];
    await saveUsers(users);

    // Seed default company
    final company = CompanyModel(
      name: 'My Solar & IT Corp',
      logo: '', // Base64 logo placeholder or blank
      taxId: 'TAX-2026-SOLARIT',
      address: '123 Renewable Energy Way, Suite 4B, Austin, TX 78701',
      currency: '\$',
    );
    await saveCompany(company);

    // Seed default clients
    final clients = [
      ClientModel(
        id: 'c-1',
        name: 'EcoPower Solutions Inc.',
        email: 'procurement@ecopower.com',
        phone: '+1 (512) 555-0192',
        billingAddress: '456 Green Way, Suite A, Austin, TX 78744',
        shippingAddress: '456 Green Way, Suite A, Austin, TX 78744',
      ),
      ClientModel(
        id: 'c-2',
        name: 'Apex Data Systems',
        email: 'billing@apexdata.net',
        phone: '+1 (206) 555-0143',
        billingAddress: '789 Cloud Tower Blvd, Seattle, WA 98101',
        shippingAddress: '789 Cloud Tower Blvd, Seattle, WA 98101',
      ),
      ClientModel(
        id: 'c-3',
        name: 'Global Tech Consulting',
        email: 'ap@globaltech.com',
        phone: '+1 (415) 555-0288',
        billingAddress: '55 Mission St, San Francisco, CA 94105',
        shippingAddress: '55 Mission St, San Francisco, CA 94105',
      ),
    ];
    await saveClients(clients);

    // Seed products (Solar + IT Hardware)
    final products = [
      // Category A: Solar System Equipment
      ProductModel(
        id: 'p-sol-1',
        name: 'Tier-1 Monocrystalline Solar Panel (550W)',
        description:
            'High-efficiency monocrystalline PV module for residential and commercial systems.',
        sku: 'SOL-PV-550M',
        unitPrice: 249.99,
        category: 'Solar',
        taxRate: 15.0,
      ),
      ProductModel(
        id: 'p-sol-2',
        name: 'Hybrid Solar Inverter (10kW, Three-Phase)',
        description:
            'Smart grid-tied inverter with battery integration backup system.',
        sku: 'SOL-INV-10K3P',
        unitPrice: 1350.00,
        category: 'Solar',
        taxRate: 15.0,
      ),
      ProductModel(
        id: 'p-sol-3',
        name: 'Lithium-ion LiFePO4 Battery Storage Bank (5.12kWh, 48V)',
        description: 'Long-life wall-mounted lithium energy storage system.',
        sku: 'SOL-BAT-5KWH',
        unitPrice: 1999.00,
        category: 'Solar',
        taxRate: 15.0,
      ),
      ProductModel(
        id: 'p-sol-4',
        name: 'Aluminum Solar Roof Mounting Structure (4-Panel Kit)',
        description:
            'Anodized aluminum rails, clamps, and brackets for rooftop mounting.',
        sku: 'SOL-MNT-4PK',
        unitPrice: 179.50,
        category: 'Solar',
        taxRate: 15.0,
      ),
      ProductModel(
        id: 'p-sol-5',
        name: 'MPPT Solar Charge Controller (60A, 150V)',
        description:
            'Max power point tracking controller with LCD screen and temperature sensor.',
        sku: 'SOL-MPPT-60A',
        unitPrice: 320.00,
        category: 'Solar',
        taxRate: 15.0,
      ),
      ProductModel(
        id: 'p-sol-6',
        name: 'Solar DC Cable (4mm², Weatherproof, 100m Roll)',
        description: 'UV-resistant, dual-insulated halogen-free solar cable.',
        sku: 'SOL-CBL-4MM',
        unitPrice: 110.00,
        category: 'Solar',
        taxRate: 15.0,
      ),
      ProductModel(
        id: 'p-sol-7',
        name: 'MC4 Connectors (Waterproof, Pack of 10 Pairs)',
        description: 'IP67 male/female solar cable panel pin connectors.',
        sku: 'SOL-MC4-10P',
        unitPrice: 24.99,
        category: 'Solar',
        taxRate: 15.0,
      ),

      // Category B: IT Hardware Equipment
      ProductModel(
        id: 'p-it-1',
        name: 'Enterprise Rack Server (2U, 2x Intel Xeon, 128GB RAM, 2TB NVMe)',
        description:
            'High-performance database and virtualization platform, redundant PSU.',
        sku: 'IT-SRV-2U-XEON',
        unitPrice: 4799.00,
        category: 'IT',
        taxRate: 10.0,
      ),
      ProductModel(
        id: 'p-it-2',
        name: 'Managed L3 Network Switch (48-Port Gigabit, PoE+)',
        description:
            'High-capacity backbone switch with 4x 10G SFP+ uplink ports.',
        sku: 'IT-SWT-48P-L3',
        unitPrice: 899.99,
        category: 'IT',
        taxRate: 10.0,
      ),
      ProductModel(
        id: 'p-it-3',
        name: 'Wi-Fi 6E Enterprise Access Point (Dual-Band)',
        description:
            'High-density MU-MIMO wireless router with power over ethernet.',
        sku: 'IT-AP-WIFI6E',
        unitPrice: 289.00,
        category: 'IT',
        taxRate: 10.0,
      ),
      ProductModel(
        id: 'p-it-4',
        name: 'Business Desktop PC (Intel i7, 16GB RAM, 512GB SSD)',
        description:
            'Compact micro form-factor workstation with Windows 11 Pro preloaded.',
        sku: 'IT-PC-I7DT',
        unitPrice: 1150.00,
        category: 'IT',
        taxRate: 10.0,
      ),
      ProductModel(
        id: 'p-it-5',
        name: 'Professional 27-inch 4K Color-Accurate Monitor',
        description:
            'IPS pane with 99% sRGB coverage, built-in USB-C hub connectivity.',
        sku: 'IT-MON-27K4P',
        unitPrice: 649.99,
        category: 'IT',
        taxRate: 10.0,
      ),
      ProductModel(
        id: 'p-it-6',
        name: 'Cat6A STP Network Cable Shielded (305m / 1000ft Drum)',
        description:
            'Solid bare copper wire spool for Gigabit network infrastructure installation.',
        sku: 'IT-CBL-6ASTP',
        unitPrice: 220.00,
        category: 'IT',
        taxRate: 10.0,
      ),
      ProductModel(
        id: 'p-it-7',
        name: 'Uninterruptible Power Supply (UPS) (2000VA / 1200W, Rackmount)',
        description:
            'Line-interactive sine wave power backup with LCD screen status indicators.',
        sku: 'IT-UPS-2KVA',
        unitPrice: 450.00,
        category: 'IT',
        taxRate: 10.0,
      ),
    ];
    await saveProducts(products);

    // Seed 2 mock invoices so that dashboards look awesome on initial load
    final mockInvoices = [
      InvoiceModel(
        id: 'inv-1',
        invoiceNumber: 'INV-2026-0001',
        clientId: 'c-1',
        issueDate: DateTime.now().subtract(const Duration(days: 15)),
        dueDate: DateTime.now().add(const Duration(days: 15)),
        status: InvoiceStatus.paid,
        notes: 'Initial deployment equipment invoice. Standard Solar setup.',
        items: [
          InvoiceItemModel(
            id: 'item-1-1',
            productId: 'p-sol-1',
            productName: 'Tier-1 Monocrystalline Solar Panel (550W)',
            quantity: 8,
            unitPrice: 249.99,
            taxRate: 15.0,
          ),
          InvoiceItemModel(
            id: 'item-1-2',
            productId: 'p-sol-2',
            productName: 'Hybrid Solar Inverter (10kW, Three-Phase)',
            quantity: 1,
            unitPrice: 1350.00,
            taxRate: 15.0,
          ),
          InvoiceItemModel(
            id: 'item-1-3',
            productId: 'p-sol-3',
            productName:
                'Lithium-ion LiFePO4 Battery Storage Bank (5.12kWh, 48V)',
            quantity: 2,
            unitPrice: 1999.00,
            taxRate: 15.0,
          ),
        ],
        subTotal: 7347.92,
        taxTotal: 1102.19,
        grandTotal: 8450.11,
      ),
      InvoiceModel(
        id: 'inv-2',
        invoiceNumber: 'INV-2026-0002',
        clientId: 'c-2',
        issueDate: DateTime.now().subtract(const Duration(days: 5)),
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        status: InvoiceStatus.overdue,
        notes: 'Enterprise server hardware and networking upgrade.',
        items: [
          InvoiceItemModel(
            id: 'item-2-1',
            productId: 'p-it-1',
            productName:
                'Enterprise Rack Server (2U, 2x Intel Xeon, 128GB RAM, 2TB NVMe)',
            quantity: 1,
            unitPrice: 4799.00,
            taxRate: 10.0,
          ),
          InvoiceItemModel(
            id: 'item-2-2',
            productId: 'p-it-2',
            productName: 'Managed L3 Network Switch (48-Port Gigabit, PoE+)',
            quantity: 2,
            unitPrice: 899.99,
            taxRate: 10.0,
          ),
          InvoiceItemModel(
            id: 'item-2-3',
            productId: 'p-it-3',
            productName: 'Wi-Fi 6E Enterprise Access Point (Dual-Band)',
            quantity: 3,
            unitPrice: 289.00,
            taxRate: 10.0,
          ),
        ],
        subTotal: 7465.98,
        taxTotal: 746.60,
        grandTotal: 8212.58,
      ),
    ];
    await saveInvoices(mockInvoices);

    await _prefs.setBool(_keyFirstRun, false);
  }

  Future<void> setupCompany({
    required CompanyModel company,
    required UserModel administrator,
  }) async {
    await saveUsers([administrator]);
    await saveCompany(company);
    await saveClients([]);
    await saveProducts([]);
    await saveInvoices([]);
    await _prefs.setBool(_keyFirstRun, false);
  }

  // Users Storage
  Future<List<UserModel>> getUsers() async {
    final str = _prefs.getString(_keyUsers);
    if (str == null) return [];
    final list = json.decode(str) as List;
    return list
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveUsers(List<UserModel> users) async {
    final list = users.map((e) => e.toJson()).toList();
    await _prefs.setString(_keyUsers, json.encode(list));
  }

  // Company Profile Storage
  Future<CompanyModel> getCompany() async {
    final str = _prefs.getString(_keyCompany);
    if (str == null) {
      return CompanyModel(
        name: 'My Solar & IT Corp',
        logo: '',
        taxId: 'TAX-2026-SOLARIT',
        address: '123 Renewable Energy Way, Suite 4B, Austin, TX 78701',
        currency: '\$',
      );
    }
    return CompanyModel.fromJson(json.decode(str) as Map<String, dynamic>);
  }

  Future<void> saveCompany(CompanyModel company) async {
    await _prefs.setString(_keyCompany, json.encode(company.toJson()));
  }

  // Clients Storage
  Future<List<ClientModel>> getClients() async {
    final str = _prefs.getString(_keyClients);
    if (str == null) return [];
    final list = json.decode(str) as List;
    return list
        .map((e) => ClientModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveClients(List<ClientModel> clients) async {
    final list = clients.map((e) => e.toJson()).toList();
    await _prefs.setString(_keyClients, json.encode(list));
  }

  // Products Storage
  Future<List<ProductModel>> getProducts() async {
    final str = _prefs.getString(_keyProducts);
    if (str == null) return [];
    final list = json.decode(str) as List;
    return list
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveProducts(List<ProductModel> products) async {
    final list = products.map((e) => e.toJson()).toList();
    await _prefs.setString(_keyProducts, json.encode(list));
  }

  // Invoices Storage
  Future<List<InvoiceModel>> getInvoices() async {
    final str = _prefs.getString(_keyInvoices);
    if (str == null) return [];
    final list = json.decode(str) as List;
    return list
        .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveInvoices(List<InvoiceModel> invoices) async {
    final list = invoices.map((e) => e.toJson()).toList();
    await _prefs.setString(_keyInvoices, json.encode(list));
  }
}
