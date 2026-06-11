import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../../providers/app_state_provider.dart';
import '../../models/company_model.dart';
import '../../models/user_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _taxIdController;
  late TextEditingController _addressController;
  late TextEditingController _logoController;
  late String _selectedCurrency;

  @override
  void initState() {
    super.initState();
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final comp = state.company;

    _nameController = TextEditingController(text: comp.name);
    _taxIdController = TextEditingController(text: comp.taxId);
    _addressController = TextEditingController(text: comp.address);
    _logoController = TextEditingController(text: comp.logo);
    _selectedCurrency = comp.currency;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  void _saveCompanyDetails() async {
    if (!_formKey.currentState!.validate()) return;
    final state = Provider.of<AppStateProvider>(context, listen: false);

    if (!state.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Only Admin accounts can modify company profiles.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedCompany = CompanyModel(
      name: _nameController.text,
      logo: _logoController.text,
      taxId: _taxIdController.text,
      address: _addressController.text,
      currency: _selectedCurrency,
    );

    await state.updateCompany(updatedCompany);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company profile updated successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'System Settings',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Customize layout details, company profile data, tax parameters, and test mock authorizations.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: 24),

              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildCompanyCard(theme, state),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildPreferencesCard(theme, state),
                              const SizedBox(height: 20),
                              _buildTestingSandboxCard(theme, state),
                              const SizedBox(height: 20),
                              _buildBackupRestoreCard(theme, state),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildCompanyCard(theme, state),
                        const SizedBox(height: 20),
                        _buildPreferencesCard(theme, state),
                        const SizedBox(height: 20),
                        _buildTestingSandboxCard(theme, state),
                        const SizedBox(height: 20),
                        _buildBackupRestoreCard(theme, state),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyCard(ThemeData theme, AppStateProvider state) {
    final canEdit = state.isAdmin;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Company Profile Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (!canEdit)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Read-Only',
                        style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'These details populate invoice headers, currency definitions, and tax records.',
                style: TextStyle(color: theme.hintColor, fontSize: 12),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                enabled: canEdit,
                decoration: const InputDecoration(
                  labelText: 'Company Legal Name',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Company name is required' : null,
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final taxField = TextFormField(
                    controller: _taxIdController,
                    enabled: canEdit,
                    decoration: const InputDecoration(
                      labelText: 'Company Tax ID (GST/VAT)',
                      prefixIcon: Icon(Icons.description_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Tax ID is required' : null,
                  );

                  final currencyDropdown = DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      prefixIcon: Icon(Icons.monetization_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: '\$', child: Text('USD (\$)')),
                      DropdownMenuItem(value: '€', child: Text('EUR (€)')),
                      DropdownMenuItem(value: '£', child: Text('GBP (£)')),
                      DropdownMenuItem(value: 'PKR', child: Text('PKR (Rs)')),
                      DropdownMenuItem(value: '¥', child: Text('JPY (¥)')),
                    ],
                    onChanged: canEdit
                        ? (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCurrency = val;
                              });
                            }
                          }
                        : null,
                  );

                  if (constraints.maxWidth > 500) {
                    return Row(
                      children: [
                        Expanded(flex: 2, child: taxField),
                        const SizedBox(width: 16),
                        Expanded(child: currencyDropdown),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        taxField,
                        const SizedBox(height: 16),
                        currencyDropdown,
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                enabled: canEdit,
                decoration: const InputDecoration(
                  labelText: 'Company Office Address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) => v == null || v.trim().isEmpty ? 'Office address is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _logoController,
                enabled: canEdit,
                decoration: const InputDecoration(
                  labelText: 'Company Logo Image URL or Base64 (Optional)',
                  prefixIcon: Icon(Icons.image_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              if (canEdit)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _saveCompanyDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: const Text('Save Profile Changes'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesCard(ThemeData theme, AppStateProvider state) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Preferences',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                state.themeMode == ThemeMode.light ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                color: Colors.indigo,
              ),
              title: const Text('Visual Theme Mode'),
              subtitle: Text(
                state.themeMode == ThemeMode.light ? 'Light Mode Enabled' : 'Dark Mode Enabled',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Switch(
                value: state.themeMode == ThemeMode.dark,
                onChanged: (_) => state.toggleTheme(),
                activeThumbColor: Colors.indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestingSandboxCard(ThemeData theme, AppStateProvider state) {
    final user = state.currentUser;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security Sandbox Testing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Simulate different role access behaviors in real time:',
              style: TextStyle(color: theme.hintColor, fontSize: 12),
            ),
            const SizedBox(height: 20),
            if (user != null) ...[
              _buildRoleSelectorChip(
                label: 'System Admin (Full Access)',
                role: UserRole.admin,
                isActive: user.role == UserRole.admin,
                color: Colors.red.shade600,
                onTap: () => state.setMockRole(UserRole.admin),
              ),
              const SizedBox(height: 8),
              _buildRoleSelectorChip(
                label: 'Project Manager (Add/Edit)',
                role: UserRole.manager,
                isActive: user.role == UserRole.manager,
                color: Colors.amber.shade700,
                onTap: () => state.setMockRole(UserRole.manager),
              ),
              const SizedBox(height: 8),
              _buildRoleSelectorChip(
                label: 'Viewer (Read-Only)',
                role: UserRole.viewer,
                isActive: user.role == UserRole.viewer,
                color: Colors.grey.shade600,
                onTap: () => state.setMockRole(UserRole.viewer),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelectorChip({
    required String label,
    required UserRole role,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(
            color: isActive ? color : Colors.grey.shade300,
            width: isActive ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isActive ? color : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? color : Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupRestoreCard(ThemeData theme, AppStateProvider state) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.backup_outlined, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Backup & Recovery',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Export or import your company profiles, clients list, inventory logs, and invoice histories to prevent data loss.',
              style: TextStyle(color: theme.hintColor, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportBackup(state),
                    icon: const Icon(Icons.save_alt, size: 18),
                    label: const Text('Save to File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _restoreBackup(state),
                    icon: const Icon(Icons.open_in_browser, size: 18),
                    label: const Text('Restore from File'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _uploadBackupToGoogleDrive(state),
                icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                label: const Text('Upload to Google Drive'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportBackup(AppStateProvider state) async {
    try {
      final String backupStr = state.exportBackupData();
      final Uint8List bytes = utf8.encode(backupStr);
      
      String? outputPath;
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        outputPath = await FilePicker.saveFile(
          dialogTitle: 'Select Backup Destination',
          fileName: 'ims_backup_${DateTime.now().millisecondsSinceEpoch}.json',
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: bytes,
        );
      } else {
        final directory = await getApplicationDocumentsDirectory();
        outputPath = '${directory.path}/ims_backup_${DateTime.now().millisecondsSinceEpoch}.json';
        final file = File(outputPath);
        await file.writeAsString(backupStr);
      }

      if (outputPath == null) {
        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup saved successfully to: $outputPath'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save backup file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _restoreBackup(AppStateProvider state) async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final String filePath = result.files.single.path!;
      final File file = File(filePath);
      final String jsonString = await file.readAsString();

      if (!mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Confirm Restore'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade800, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'WARNING: Restoring will overwrite all current settings, client lists, inventory logs, and invoice records. This action cannot be undone.',
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Are you sure you want to restore the database from the selected file?'),
                const SizedBox(height: 8),
                Text(
                  'File: ${filePath.split(Platform.pathSeparator).last}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Restore Database'),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        final bool success = await state.restoreBackupData(jsonString);
        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database restored successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid backup file structure. Please confirm JSON is valid.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading backup file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _uploadBackupToGoogleDrive(AppStateProvider state) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Connecting to Google Drive...'),
          ],
        ),
        duration: Duration(days: 1),
      ),
    );

    try {
      // Initialize the singleton instance (must be done before authenticate)
      await GoogleSignIn.instance.initialize();

      final account = await GoogleSignIn.instance.authenticate();

      // Request authorization for Google Drive API scope
      final authorization = await account.authorizationClient.authorizationForScopes([
        drive.DriveApi.driveFileScope,
      ]);

      if (authorization == null) {
        throw 'Failed to acquire access token for Google Drive.';
      }

      final authHeaders = {
        "Authorization": "Bearer ${authorization.accessToken}",
        "X-Goog-AuthUser": "0",
      };

      final authenticateClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      final driveFile = drive.File();
      driveFile.name = 'ims_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      driveFile.mimeType = 'application/json';

      final String backupStr = state.exportBackupData();
      final Uint8List bytes = utf8.encode(backupStr);
      final Stream<List<int>> mediaStream = Stream.value(bytes);
      final drive.Media media = drive.Media(mediaStream, bytes.length);

      final responseFile = await driveApi.files.create(driveFile, uploadMedia: media);

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Backup uploaded to Google Drive successfully! ID: ${responseFile.id}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Upload failed. Ensure Google OAuth credentials are configured for this app. Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
