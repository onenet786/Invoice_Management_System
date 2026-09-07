import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/client_model.dart';
import '../models/company_model.dart';
import '../models/invoice_model.dart';
import '../models/product_model.dart';
import 'storage_service.dart';

class RemoteSyncException implements Exception {
  final String message;

  const RemoteSyncException(this.message);

  @override
  String toString() => message;
}

class RemoteSyncService {
  static const _apiUrlKey = 'invoice_sync_api_url';
  static const _sessionTokenKey = 'invoice_sync_session_token';
  static const _revisionKey = 'invoice_sync_workspace_revision';

  final StorageService _storage;
  final SharedPreferences _prefs;

  RemoteSyncService(this._storage, this._prefs);

  String get apiUrl => _prefs.getString(_apiUrlKey) ?? '';
  bool get isConfigured => Uri.tryParse(apiUrl)?.hasScheme ?? false;
  bool get isConnected =>
      isConfigured && (_prefs.getString(_sessionTokenKey)?.isNotEmpty ?? false);

  Future<void> setApiUrl(String value) async {
    final normalized = value.trim().replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const RemoteSyncException('Enter a valid HTTPS API URL.');
    }
    await _prefs.setString(_apiUrlKey, normalized);
    await _prefs.remove(_sessionTokenKey);
    await _prefs.remove(_revisionKey);
  }

  Future<void> signInWithGoogle(String idToken) async {
    final response = await _post('/v1/auth/google', {'idToken': idToken});
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw RemoteSyncException(body['error'] as String? ?? 'Server sign-in failed.');
    }
    await _prefs.setString(_sessionTokenKey, body['token'] as String);
  }

  Future<void> uploadWorkspace() async {
    _requireConnection();
    final payload = await _workspacePayload();
    final revision = _prefs.getInt(_revisionKey);
    final response = await _put('/v1/workspace', {
      'payload': payload,
      'expectedRevision': ?revision,
    });
    final body = _decode(response);
    if (response.statusCode == 409) {
      throw const RemoteSyncException(
        'Cloud data changed on another device. Download it before uploading again.',
      );
    }
    if (response.statusCode != 200) {
      throw RemoteSyncException(body['error'] as String? ?? 'Could not upload workspace.');
    }
    await _prefs.setInt(_revisionKey, (body['revision'] as num).toInt());
  }

  Future<bool> downloadWorkspace() async {
    _requireConnection();
    final response = await _get('/v1/workspace');
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw RemoteSyncException(body['error'] as String? ?? 'Could not download workspace.');
    }
    final payload = body['payload'];
    final revision = (body['revision'] as num).toInt();
    if (payload == null) {
      await _prefs.setInt(_revisionKey, revision);
      return false;
    }
    await _restorePayload(Map<String, dynamic>.from(payload as Map));
    await _prefs.setInt(_revisionKey, revision);
    return true;
  }

  Future<void> disconnect() async {
    await _prefs.remove(_sessionTokenKey);
    await _prefs.remove(_revisionKey);
  }

  Future<Map<String, dynamic>> _workspacePayload() async {
    final company = await _storage.getCompany();
    final clients = await _storage.getClients();
    final products = await _storage.getProducts();
    final invoices = await _storage.getInvoices();
    return {
      'company': company.toJson(),
      'clients': clients.map((item) => item.toJson()).toList(),
      'products': products.map((item) => item.toJson()).toList(),
      'invoices': invoices.map((item) => item.toJson()).toList(),
      'preferences': {
        'pdfTemplate': _storage.pdfTemplate,
        'invoiceNumberFormat': _storage.invoiceNumberFormat,
      },
    };
  }

  Future<void> _restorePayload(Map<String, dynamic> payload) async {
    if (payload['company'] case final Map company) {
      await _storage.saveCompany(CompanyModel.fromJson(Map<String, dynamic>.from(company)));
    }
    if (payload['clients'] case final List clients) {
      await _storage.saveClients(clients.map((item) => ClientModel.fromJson(Map<String, dynamic>.from(item as Map))).toList());
    }
    if (payload['products'] case final List products) {
      await _storage.saveProducts(products.map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item as Map))).toList());
    }
    if (payload['invoices'] case final List invoices) {
      await _storage.saveInvoices(invoices.map((item) => InvoiceModel.fromJson(Map<String, dynamic>.from(item as Map))).toList());
    }
    if (payload['preferences'] case final Map preferences) {
      final values = Map<String, dynamic>.from(preferences);
      if (values['pdfTemplate'] case final String template) await _storage.savePdfTemplate(template);
      if (values['invoiceNumberFormat'] case final String format) await _storage.saveInvoiceNumberFormat(format);
    }
  }

  void _requireConnection() {
    if (!isConnected) throw const RemoteSyncException('Connect your account to the sync server first.');
  }

  Uri _uri(String path) => Uri.parse('$apiUrl$path');

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${_prefs.getString(_sessionTokenKey)}',
  };

  Future<http.Response> _get(String path) => http.get(_uri(path), headers: _headers);
  Future<http.Response> _post(String path, Map<String, dynamic> body) =>
      http.post(_uri(path), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
  Future<http.Response> _put(String path, Map<String, dynamic> body) =>
      http.put(_uri(path), headers: _headers, body: jsonEncode(body));

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      return {};
    }
  }
}
