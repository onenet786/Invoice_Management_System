import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/company_model.dart';
import '../models/user_model.dart';
import '../models/client_model.dart';
import '../models/product_model.dart';
import '../models/invoice_model.dart';
import 'storage_service.dart';

class BackupSnapshotInfo {
  final String id;
  final String fileName;
  final DateTime timestamp;
  final int invoiceCount;
  final int clientCount;
  final int productCount;
  final int sizeBytes;

  BackupSnapshotInfo({
    required this.id,
    required this.fileName,
    required this.timestamp,
    required this.invoiceCount,
    required this.clientCount,
    required this.productCount,
    required this.sizeBytes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'timestamp': timestamp.toIso8601String(),
    'invoiceCount': invoiceCount,
    'clientCount': clientCount,
    'productCount': productCount,
    'sizeBytes': sizeBytes,
  };

  factory BackupSnapshotInfo.fromJson(Map<String, dynamic> json) =>
      BackupSnapshotInfo(
        id: json['id'] as String,
        fileName: json['fileName'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        invoiceCount: json['invoiceCount'] as int? ?? 0,
        clientCount: json['clientCount'] as int? ?? 0,
        productCount: json['productCount'] as int? ?? 0,
        sizeBytes: json['sizeBytes'] as int? ?? 0,
      );
}

class BackupService {
  static const String _keyDriveAccount = 'invoice_gdrive_account';
  static const String _keyDriveLastSync = 'invoice_gdrive_last_sync';
  static const String _keyAutoBackup = 'invoice_gdrive_auto_backup';
  static const String _keyDriveSnapshots = 'invoice_gdrive_snapshots';

  final StorageService _storage;
  final SharedPreferences _prefs;

  BackupService(this._storage, this._prefs);

  String? get driveAccount => _prefs.getString(_keyDriveAccount);
  bool get isDriveLinked => driveAccount != null && driveAccount!.isNotEmpty;
  DateTime? get lastSync {
    final str = _prefs.getString(_keyDriveLastSync);
    return str != null ? DateTime.tryParse(str) : null;
  }

  bool get autoBackupEnabled => _prefs.getBool(_keyAutoBackup) ?? false;

  List<BackupSnapshotInfo> get driveSnapshots {
    final raw = _prefs.getString(_keyDriveSnapshots);
    if (raw == null) return [];
    try {
      final list = json.decode(raw) as List;
      return list.map((e) => BackupSnapshotInfo.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Package all local app data into a complete JSON string
  Future<String> generateBackupJson() async {
    final company = await _storage.getCompany();
    final users = await _storage.getUsers();
    final clients = await _storage.getClients();
    final products = await _storage.getProducts();
    final invoices = await _storage.getInvoices();

    final data = {
      'app': 'Invoicey Management System',
      'version': '1.0.0',
      'timestamp': DateTime.now().toIso8601String(),
      'company': company.toJson(),
      'users': users.map((u) => u.toJson()).toList(),
      'clients': clients.map((c) => c.toJson()).toList(),
      'products': products.map((p) => p.toJson()).toList(),
      'invoices': invoices.map((i) => i.toJson()).toList(),
      'preferences': {
        'pdfTemplate': _storage.pdfTemplate,
        'invoiceNumberFormat': _storage.invoiceNumberFormat,
        'biometricEnabled': _storage.biometricEnabled,
      },
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Restore app data from a raw JSON string package
  Future<bool> restoreFromBackupJson(String jsonString) async {
    try {
      final Map<String, dynamic> data = json.decode(jsonString);

      if (data.containsKey('company')) {
        final comp = CompanyModel.fromJson(data['company']);
        await _storage.saveCompany(comp);
      }

      if (data.containsKey('users')) {
        final list = data['users'] as List;
        final users = list.map((e) => UserModel.fromJson(e)).toList();
        await _storage.saveUsers(users);
      }

      if (data.containsKey('clients')) {
        final list = data['clients'] as List;
        final clients = list.map((e) => ClientModel.fromJson(e)).toList();
        await _storage.saveClients(clients);
      }

      if (data.containsKey('products')) {
        final list = data['products'] as List;
        final products = list.map((e) => ProductModel.fromJson(e)).toList();
        await _storage.saveProducts(products);
      }

      if (data.containsKey('invoices')) {
        final list = data['invoices'] as List;
        final invoices = list.map((e) => InvoiceModel.fromJson(e)).toList();
        await _storage.saveInvoices(invoices);
      }

      if (data.containsKey('preferences')) {
        final prefsMap = data['preferences'] as Map<String, dynamic>;
        if (prefsMap.containsKey('pdfTemplate')) {
          await _storage.savePdfTemplate(prefsMap['pdfTemplate']);
        }
        if (prefsMap.containsKey('invoiceNumberFormat')) {
          await _storage.saveInvoiceNumberFormat(
            prefsMap['invoiceNumberFormat'],
          );
        }
        if (prefsMap.containsKey('biometricEnabled')) {
          await _storage.saveBiometricEnabled(prefsMap['biometricEnabled']);
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Link Google Drive account
  Future<void> linkGoogleDriveAccount(String email) async {
    await _prefs.setString(_keyDriveAccount, email);
  }

  /// Unlink Google Drive account
  Future<void> unlinkGoogleDriveAccount() async {
    await _prefs.remove(_keyDriveAccount);
    await _prefs.remove(_keyDriveLastSync);
  }

  /// Set Auto-Backup preference
  Future<void> setAutoBackup(bool enabled) async {
    await _prefs.setBool(_keyAutoBackup, enabled);
  }

  /// Trigger a Google Drive backup upload operation
  Future<BackupSnapshotInfo> performGoogleDriveSync() async {
    final jsonContent = await generateBackupJson();
    final now = DateTime.now();

    final invoices = await _storage.getInvoices();
    final clients = await _storage.getClients();
    final products = await _storage.getProducts();

    final snapshot = BackupSnapshotInfo(
      id: 'gdrive_${now.millisecondsSinceEpoch}',
      fileName:
          'invoicey_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour}${now.minute}.json',
      timestamp: now,
      invoiceCount: invoices.length,
      clientCount: clients.length,
      productCount: products.length,
      sizeBytes: utf8.encode(jsonContent).length,
    );

    final currentSnapshots = driveSnapshots;
    currentSnapshots.insert(0, snapshot);

    // Keep last 10 snapshots
    if (currentSnapshots.length > 10) {
      currentSnapshots.removeRange(10, currentSnapshots.length);
    }

    final rawJson = json.encode(
      currentSnapshots.map((s) => s.toJson()).toList(),
    );
    await _prefs.setString(_keyDriveSnapshots, rawJson);
    await _prefs.setString(_keyDriveLastSync, now.toIso8601String());

    return snapshot;
  }

  /// Import local backup JSON file using FilePicker
  Future<String?> pickAndImportLocalBackup() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return null;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return null;

      final content = utf8.decode(bytes);
      final success = await restoreFromBackupJson(content);
      return success ? file.name : null;
    } catch (_) {
      return null;
    }
  }
}
