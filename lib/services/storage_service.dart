import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/company_model.dart';
import '../models/client_model.dart';
import '../models/product_model.dart';
import '../models/invoice_model.dart';

class StorageService {
  static const String _keyUsers = 'invoice_users';
  static const String _keyCompany = 'invoice_company';
  static const String _keyClients = 'invoice_clients';
  static const String _keyProducts = 'invoice_products';
  static const String _keyInvoices = 'invoice_invoices';
  static const String _keyFirstRun = 'invoice_first_run';
  static const String _keyGoogleDriveSimulate = 'google_drive_simulate';
  static const String _keyGoogleDriveClientId = 'google_drive_client_id';
  static const String _keyGoogleDriveClientSecret = 'google_drive_client_secret';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyN8nWebhookUrl = 'n8n_webhook_url';
  static const String _keyN8nApiKey = 'n8n_api_key';
  static const String _keyN8nEnabled = 'n8n_enabled';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService(prefs);
    await service._checkAndSeed();
    return service;
  }

  // Check and seed default data on first run
  Future<void> _checkAndSeed() async {
    final firstRun = _prefs.getBool(_keyFirstRun) ?? true;
    if (firstRun) {
      // Seed default users as empty, to be created on first launch
      await saveUsers([]);

      // Seed default company
      final company = CompanyModel(
        name: 'My Solar & IT Corp',
        logo: '', // Base64 logo placeholder or blank
        taxId: 'TAX-2026-SOLARIT',
        address: '123 Renewable Energy Way, Suite 4B, Austin, TX 78701',
        currency: 'PKR',
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
          description: 'High-efficiency monocrystalline PV module for residential and commercial systems.',
          sku: 'SOL-PV-550M',
          unitPrice: 249.99,
          category: 'Solar',
          taxRate: 15.0,
        ),
        ProductModel(
          id: 'p-sol-2',
          name: 'Hybrid Solar Inverter (10kW, Three-Phase)',
          description: 'Smart grid-tied inverter with battery integration backup system.',
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
          description: 'Anodized aluminum rails, clamps, and brackets for rooftop mounting.',
          sku: 'SOL-MNT-4PK',
          unitPrice: 179.50,
          category: 'Solar',
          taxRate: 15.0,
        ),
        ProductModel(
          id: 'p-sol-5',
          name: 'MPPT Solar Charge Controller (60A, 150V)',
          description: 'Max power point tracking controller with LCD screen and temperature sensor.',
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
          description: 'High-performance database and virtualization platform, redundant PSU.',
          sku: 'IT-SRV-2U-XEON',
          unitPrice: 4799.00,
          category: 'IT',
          taxRate: 10.0,
        ),
        ProductModel(
          id: 'p-it-2',
          name: 'Managed L3 Network Switch (48-Port Gigabit, PoE+)',
          description: 'High-capacity backbone switch with 4x 10G SFP+ uplink ports.',
          sku: 'IT-SWT-48P-L3',
          unitPrice: 899.99,
          category: 'IT',
          taxRate: 10.0,
        ),
        ProductModel(
          id: 'p-it-3',
          name: 'Wi-Fi 6E Enterprise Access Point (Dual-Band)',
          description: 'High-density MU-MIMO wireless router with power over ethernet.',
          sku: 'IT-AP-WIFI6E',
          unitPrice: 289.00,
          category: 'IT',
          taxRate: 10.0,
        ),
        ProductModel(
          id: 'p-it-4',
          name: 'Business Desktop PC (Intel i7, 16GB RAM, 512GB SSD)',
          description: 'Compact micro form-factor workstation with Windows 11 Pro preloaded.',
          sku: 'IT-PC-I7DT',
          unitPrice: 1150.00,
          category: 'IT',
          taxRate: 10.0,
        ),
        ProductModel(
          id: 'p-it-5',
          name: 'Professional 27-inch 4K Color-Accurate Monitor',
          description: 'IPS pane with 99% sRGB coverage, built-in USB-C hub connectivity.',
          sku: 'IT-MON-27K4P',
          unitPrice: 649.99,
          category: 'IT',
          taxRate: 10.0,
        ),
        ProductModel(
          id: 'p-it-6',
          name: 'Cat6A STP Network Cable Shielded (305m / 1000ft Drum)',
          description: 'Solid bare copper wire spool for Gigabit network infrastructure installation.',
          sku: 'IT-CBL-6ASTP',
          unitPrice: 220.00,
          category: 'IT',
          taxRate: 10.0,
        ),
        ProductModel(
          id: 'p-it-7',
          name: 'Uninterruptible Power Supply (UPS) (2000VA / 1200W, Rackmount)',
          description: 'Line-interactive sine wave power backup with LCD screen status indicators.',
          sku: 'IT-UPS-2KVA',
          unitPrice: 450.00,
          category: 'IT',
          taxRate: 10.0,
        ),
      ];
      await saveProducts(products);

      // Seed an empty list of invoices on first run
      await saveInvoices([]);

      await _prefs.setBool(_keyFirstRun, false);
    }
  }

  // Users Storage
  Future<List<UserModel>> getUsers() async {
    final str = _prefs.getString(_keyUsers);
    if (str == null) return [];
    final list = json.decode(str) as List;
    return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
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
        currency: 'PKR',
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
    return list.map((e) => ClientModel.fromJson(e as Map<String, dynamic>)).toList();
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
    return list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
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
    return list.map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveInvoices(List<InvoiceModel> invoices) async {
    final list = invoices.map((e) => e.toJson()).toList();
    await _prefs.setString(_keyInvoices, json.encode(list));
  }

  Future<void> resetDatabase() async {
    await _prefs.remove(_keyUsers);
    await _prefs.remove(_keyCompany);
    await _prefs.remove(_keyClients);
    await _prefs.remove(_keyProducts);
    await _prefs.remove(_keyInvoices);
    await _prefs.setBool(_keyFirstRun, true);
    await _checkAndSeed();
  }

  // Google Drive Cloud Backup Config
  bool getGoogleDriveSimulate() {
    return _prefs.getBool(_keyGoogleDriveSimulate) ?? true;
  }

  Future<void> saveGoogleDriveSimulate(bool value) async {
    await _prefs.setBool(_keyGoogleDriveSimulate, value);
  }

  String getGoogleDriveClientId() {
    return _prefs.getString(_keyGoogleDriveClientId) ?? '';
  }

  Future<void> saveGoogleDriveClientId(String value) async {
    await _prefs.setString(_keyGoogleDriveClientId, value);
  }

  String getGoogleDriveClientSecret() {
    return _prefs.getString(_keyGoogleDriveClientSecret) ?? '';
  }

  Future<void> saveGoogleDriveClientSecret(String value) async {
    await _prefs.setString(_keyGoogleDriveClientSecret, value);
  }

  // Biometrics Storage
  bool getBiometricEnabled() {
    return _prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  Future<void> saveBiometricEnabled(bool value) async {
    await _prefs.setBool(_keyBiometricEnabled, value);
  }

  // Theme Mode Persistence
  ThemeMode getThemeMode() {
    final value = _prefs.getString(_keyThemeMode);
    if (value == 'dark') return ThemeMode.dark;
    return ThemeMode.light;
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setString(_keyThemeMode, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  // n8n WhatsApp Webhook Integration Settings
  String getN8nWebhookUrl() {
    return _prefs.getString(_keyN8nWebhookUrl) ?? '';
  }

  Future<void> saveN8nWebhookUrl(String value) async {
    await _prefs.setString(_keyN8nWebhookUrl, value);
  }

  String getN8nApiKey() {
    return _prefs.getString(_keyN8nApiKey) ?? '';
  }

  Future<void> saveN8nApiKey(String value) async {
    await _prefs.setString(_keyN8nApiKey, value);
  }

  bool getN8nEnabled() {
    return _prefs.getBool(_keyN8nEnabled) ?? false;
  }

  Future<void> saveN8nEnabled(bool value) async {
    await _prefs.setBool(_keyN8nEnabled, value);
  }
}
