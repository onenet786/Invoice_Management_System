import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../../providers/app_state_provider.dart';
import '../../models/company_model.dart';
import '../../models/user_model.dart';
import '../../utils/date_format_util.dart';

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
  late TextEditingController _googleClientIdController;
  late TextEditingController _googleClientSecretController;
  late TextEditingController _n8nWebhookUrlController;
  late TextEditingController _n8nApiKeyController;
  late String _selectedCurrency;

  // Change Password controllers and obscure states
  final _changePasswordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmNewPassword = true;

  @override
  void initState() {
    super.initState();
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final comp = state.company;

    _nameController = TextEditingController(text: comp.name);
    _taxIdController = TextEditingController(text: comp.taxId);
    _addressController = TextEditingController(text: comp.address);
    _logoController = TextEditingController(text: comp.logo);
    _googleClientIdController = TextEditingController(text: state.googleDriveClientId);
    _googleClientSecretController = TextEditingController(text: state.googleDriveClientSecret);
    _n8nWebhookUrlController = TextEditingController(text: state.n8nWebhookUrl);
    _n8nApiKeyController = TextEditingController(text: state.n8nApiKey);
    _selectedCurrency = comp.currency;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
    _logoController.dispose();
    _googleClientIdController.dispose();
    _googleClientSecretController.dispose();
    _n8nWebhookUrlController.dispose();
    _n8nApiKeyController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
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
                              _buildChangePasswordCard(theme, state),
                              const SizedBox(height: 20),
                              _buildTestingSandboxCard(theme, state),
                              const SizedBox(height: 20),
                              _buildBackupRestoreCard(theme, state),
                              const SizedBox(height: 20),
                              _buildCloudIntegrationCard(theme, state),
                              const SizedBox(height: 20),
                              _buildWhatsAppIntegrationCard(theme, state),
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
                        _buildChangePasswordCard(theme, state),
                        const SizedBox(height: 20),
                        _buildTestingSandboxCard(theme, state),
                        const SizedBox(height: 20),
                        _buildBackupRestoreCard(theme, state),
                        const SizedBox(height: 20),
                        _buildCloudIntegrationCard(theme, state),
                        const SizedBox(height: 20),
                        _buildWhatsAppIntegrationCard(theme, state),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLogoPreview(_logoController.text),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _logoController,
                          enabled: canEdit,
                          onChanged: (_) {
                            setState(() {});
                          },
                          decoration: const InputDecoration(
                            labelText: 'Company Logo Image URL or Base64 (Optional)',
                            prefixIcon: Icon(Icons.image_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (canEdit) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _pickLogoFromGallery,
                              icon: const Icon(Icons.photo_library_outlined, size: 18),
                              label: const Text('Browse Gallery / File'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.indigo),
                                foregroundColor: Colors.indigo,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
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
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(
                Icons.fingerprint_outlined,
                color: Colors.indigo,
              ),
              title: const Text('Biometric / Thumb Login'),
              subtitle: const Text(
                'Unlock app using device biometrics (fingerprint/face recognition)',
                style: TextStyle(fontSize: 12),
              ),
              value: state.biometricEnabled,
              activeThumbColor: Colors.indigo,
              onChanged: (val) async {
                if (val) {
                  final isHardwareAvailable = await state.isBiometricHardwareAvailable();
                  if (!isHardwareAvailable) {
                    if (mounted) {
                      final useSimulated = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Row(
                              children: const [
                                Icon(Icons.fingerprint, color: Colors.indigo, size: 28),
                                SizedBox(width: 10),
                                Text('Biometrics Setup'),
                              ],
                            ),
                            content: const Text(
                              'Biometric authentication hardware (fingerprint/face recognition) was not detected on this device.\n\n'
                              'Would you like to enable Simulated Biometric verification for testing purposes?',
                              style: TextStyle(fontSize: 13),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Enable Simulation'),
                              ),
                            ],
                          );
                        },
                      ) ?? false;
                      
                      if (useSimulated) {
                        await state.updateBiometricEnabled(true);
                      }
                    }
                    return;
                  }
                }
                await state.updateBiometricEnabled(val);
              },
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmResetDatabase(state),
                icon: const Icon(Icons.delete_forever_outlined, color: Colors.red, size: 18),
                label: const Text('Reset System Database', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmResetDatabase(AppStateProvider state) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text('Reset System Database?'),
              ),
            ],
          ),
          content: const Text(
            'This action will permanently delete all custom invoices, clients, products, and configurations.\n\n'
            'The database will be re-seeded to its original defaults: a single admin user (user/pass: admin) and default inventory items.\n\n'
            'Do you want to proceed?',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Reset Database'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await state.resetDatabase();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Database has been reset to system defaults.'),
          backgroundColor: Colors.green,
        ),
      );
      state.logout();
    }
  }

  void _exportBackup(AppStateProvider state) async {
    try {
      final String backupStr = state.exportBackupData();
      final Uint8List bytes = utf8.encode(backupStr);
      
      String? outputPath;
      String? initialDir;

      try {
        if (Platform.isAndroid) {
          const String path = '/storage/emulated/0/Download';
          final dir = Directory(path);
          if (await dir.exists()) {
            initialDir = path;
          }
        } else {
          final directory = await getDownloadsDirectory();
          if (directory != null) {
            initialDir = directory.path;
          }
        }
      } catch (e) {
        debugPrint('Error getting downloads directory: $e');
      }

      final String backupFileName = 'IMS-${DateFormatUtil.toBackupFileName(DateTime.now())}.json';

      try {
        outputPath = await FilePicker.saveFile(
          dialogTitle: 'Select Backup Destination',
          fileName: backupFileName,
          initialDirectory: initialDir,
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: bytes,
        );
      } catch (e) {
        debugPrint('FilePicker.saveFile failed, falling back: $e');
        final directory = await getApplicationDocumentsDirectory();
        outputPath = '${directory.path}/$backupFileName';
        final file = File(outputPath);
        await file.writeAsBytes(bytes);
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
      String? initialDir;
      try {
        if (Platform.isAndroid) {
          const String path = '/storage/emulated/0/Download';
          final dir = Directory(path);
          if (await dir.exists()) {
            initialDir = path;
          }
        } else {
          final directory = await getDownloadsDirectory();
          if (directory != null) {
            initialDir = directory.path;
          }
        }
      } catch (e) {
        debugPrint('Error getting downloads directory: $e');
      }

      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        initialDirectory: initialDir,
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

  Widget _buildCloudIntegrationCard(ThemeData theme, AppStateProvider state) {
    final canEdit = state.isAdmin;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.cloud_queue_outlined, color: Colors.indigo, size: 24),
                SizedBox(width: 8),
                Text(
                  'Google Cloud Integration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configure real Google Drive backup or run mock simulations for offline testing.',
              style: TextStyle(color: theme.hintColor, fontSize: 12),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Simulation Mode (Sandbox)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: const Text(
                'Simulates success without checking Google credentials.',
                style: TextStyle(fontSize: 12),
              ),
              value: state.googleDriveSimulate,
              activeThumbColor: Colors.indigo,
              onChanged: canEdit ? (val) {
                state.updateGoogleDriveSettings(
                  simulate: val,
                  clientId: _googleClientIdController.text.trim(),
                  clientSecret: _googleClientSecretController.text.trim(),
                );
              } : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _googleClientIdController,
              enabled: canEdit && !state.googleDriveSimulate,
              decoration: InputDecoration(
                labelText: 'Google OAuth Client ID',
                prefixIcon: const Icon(Icons.key_outlined),
                border: const OutlineInputBorder(),
                helperText: state.googleDriveSimulate
                    ? 'Disabled in Simulation Mode'
                    : 'Required for real Google authentication',
                helperStyle: TextStyle(
                  color: state.googleDriveSimulate ? theme.hintColor : Colors.indigo,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _googleClientSecretController,
              enabled: canEdit && !state.googleDriveSimulate,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Google OAuth Client Secret',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                helperText: state.googleDriveSimulate
                    ? 'Disabled in Simulation Mode'
                    : 'Optional client secret key',
              ),
            ),
            if (canEdit && !state.googleDriveSimulate) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    state.updateGoogleDriveSettings(
                      simulate: state.googleDriveSimulate,
                      clientId: _googleClientIdController.text.trim(),
                      clientSecret: _googleClientSecretController.text.trim(),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cloud credentials updated successfully.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Cloud Config'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppIntegrationCard(ThemeData theme, AppStateProvider state) {
    final canEdit = state.isAdmin;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.message_outlined, color: Colors.green, size: 24),
                SizedBox(width: 8),
                Text(
                  'WhatsApp & n8n Integration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configure a self-hosted n8n webhook with EvolutionAPI to dispatch invoice summaries and PDF documents directly to client WhatsApp numbers.',
              style: TextStyle(color: theme.hintColor, fontSize: 12),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable WhatsApp Dispatch', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: const Text(
                'Show WhatsApp send option on invoices.',
                style: TextStyle(fontSize: 12),
              ),
              value: state.n8nEnabled,
              activeThumbColor: Colors.green,
              onChanged: canEdit ? (val) {
                state.updateN8nSettings(
                  enabled: val,
                  webhookUrl: _n8nWebhookUrlController.text.trim(),
                  apiKey: _n8nApiKeyController.text.trim(),
                );
              } : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _n8nWebhookUrlController,
              enabled: canEdit && state.n8nEnabled,
              decoration: InputDecoration(
                labelText: 'n8n Webhook URL',
                prefixIcon: const Icon(Icons.link_outlined),
                border: const OutlineInputBorder(),
                helperText: !state.n8nEnabled
                    ? 'Disabled'
                    : 'Target POST webhook endpoint in n8n',
                helperStyle: TextStyle(
                  color: !state.n8nEnabled ? theme.hintColor : Colors.green,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _n8nApiKeyController,
              enabled: canEdit && state.n8nEnabled,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'n8n API Key / Bearer Token',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                helperText: 'Optional auth token sent in the headers',
              ),
            ),
            if (canEdit && state.n8nEnabled) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    state.updateN8nSettings(
                      enabled: state.n8nEnabled,
                      webhookUrl: _n8nWebhookUrlController.text.trim(),
                      apiKey: _n8nApiKeyController.text.trim(),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('WhatsApp & n8n settings updated successfully.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save WhatsApp Config'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _uploadBackupToGoogleDrive(AppStateProvider state) async {
    final messenger = ScaffoldMessenger.of(context);
    String? selectedEmail;

    if (state.googleDriveSimulate) {
      final emailController = TextEditingController();
      final formKey = GlobalKey<FormState>();
      final googleEmails = [
        'admin@invoice.com',
        'manager@invoice.com',
        'viewer@invoice.com',
        'user.demo@gmail.com',
      ];

      selectedEmail = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.account_circle_outlined, color: Colors.indigo, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Simulated Google Account Select'),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose a Google account to simulate your Google Drive backup:',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: googleEmails.map((email) {
                        return ActionChip(
                          label: Text(email, style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            emailController.text = email;
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Google Account Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Enter a valid email address';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context, emailController.text.trim());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Proceed'),
              ),
            ],
          );
        },
      );

      if (selectedEmail == null) return;
    } else {
      // Real API mode confirmation
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.cloud_upload_outlined, color: Colors.indigo, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Google Drive Backup'),
                ),
              ],
            ),
            content: const Text(
              'This will initiate Google OAuth in your default web browser to log in and authorize Google Drive access.\n\n'
              'Do you want to proceed?',
              style: TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Login & Upload'),
              ),
            ],
          );
        },
      ) ?? false;

      if (!proceed) return;
    }

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

    // If simulation mode is active, run the simulated flow immediately
    if (state.googleDriveSimulate) {
      await Future.delayed(const Duration(milliseconds: 1500));
      
      messenger.hideCurrentSnackBar();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Backup uploaded to Google Drive successfully for $selectedEmail (Simulated)! ID: mock-drive-${DateTime.now().millisecondsSinceEpoch}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

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
      driveFile.name = 'IMS-${DateFormatUtil.toBackupFileName(DateTime.now())}.json';
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
      
      if (!mounted) return;
      final useSimulated = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.cloud_off_outlined, color: Colors.amber, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Google Drive Setup Missing'),
                ),
              ],
            ),
            content: Text(
              'No Google OAuth credentials are configured for this app.\n'
              'Error details: $e\n\n'
              'Would you like to switch to Simulation Mode to simulate a successful Google Drive backup upload for testing?',
              style: const TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Switch to Simulation'),
              ),
            ],
          );
        },
      ) ?? false;

      if (useSimulated) {
        await state.updateGoogleDriveSettings(
          simulate: true,
          clientId: state.googleDriveClientId,
          clientSecret: state.googleDriveClientSecret,
        );

        if (!mounted) return;
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
                Text('Simulating Google Drive Upload...'),
              ],
            ),
            duration: Duration(seconds: 1),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (!mounted) return;
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Backup uploaded to Google Drive successfully (Simulated)! ID: mock-drive-${DateTime.now().millisecondsSinceEpoch}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
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

  Widget _buildChangePasswordCard(ThemeData theme, AppStateProvider state) {
    final user = state.currentUser;
    if (user == null) return const SizedBox.shrink();

    final hasCurrentPassword = user.password.isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _changePasswordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.lock_reset_outlined, color: Colors.indigo, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Change Password',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                hasCurrentPassword 
                    ? 'Update your account login password.' 
                    : 'Set up a local login password for your Google authorized account.',
                style: TextStyle(color: theme.hintColor, fontSize: 12),
              ),
              const SizedBox(height: 20),
              if (hasCurrentPassword) ...[
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrentPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: theme.hintColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureCurrentPassword = !_obscureCurrentPassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Current password is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_open_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: theme.hintColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'New password is required';
                  if (v.length < 4) return 'Password must be at least 4 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmNewPasswordController,
                obscureText: _obscureConfirmNewPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: theme.hintColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmNewPassword = !_obscureConfirmNewPassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm your new password';
                  if (v != _newPasswordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleChangePassword(state),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Update Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleChangePassword(AppStateProvider state) async {
    if (!_changePasswordFormKey.currentState!.validate()) return;
    
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    
    final success = await state.changePassword(currentPassword, newPassword);
    
    if (mounted) {
      if (success) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current password is incorrect.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickLogoFromGallery() async {
    try {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        final result = await FilePicker.pickFiles(
          type: FileType.image,
        );
        if (result != null && result.files.single.path != null) {
          final file = File(result.files.single.path!);
          final bytes = await file.readAsBytes();
          final base64String = base64Encode(bytes);
          final extension = result.files.single.extension?.toLowerCase() ?? 'png';
          final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
          final dataUrl = 'data:$mimeType;base64,$base64String';
          setState(() {
            _logoController.text = dataUrl;
          });
        }
      } else {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
        if (image != null) {
          final bytes = await image.readAsBytes();
          final base64String = base64Encode(bytes);
          final mimeType = image.name.endsWith('.png') ? 'image/png' : 'image/jpeg';
          final dataUrl = 'data:$mimeType;base64,$base64String';
          setState(() {
            _logoController.text = dataUrl;
          });
        }
      }
    } catch (e) {
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          final bytes = await image.readAsBytes();
          final base64String = base64Encode(bytes);
          setState(() {
            _logoController.text = 'data:image/png;base64,$base64String';
          });
        }
      } catch (innerError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to pick logo image: $innerError'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildLogoPreview(String logoData) {
    if (logoData.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Icon(Icons.business, size: 40, color: Colors.grey),
      );
    }
    
    try {
      if (logoData.startsWith('http://') || logoData.startsWith('https://')) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              logoData,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image, color: Colors.red, size: 40);
              },
            ),
          ),
        );
      } else {
        String cleanBase64 = logoData;
        if (logoData.contains('base64,')) {
          cleanBase64 = logoData.split('base64,').last;
        }
        final bytes = base64Decode(cleanBase64.trim());
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image, color: Colors.red, size: 40);
              },
            ),
          ),
        );
      }
    } catch (e) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: const Icon(Icons.broken_image, size: 40, color: Colors.red),
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
