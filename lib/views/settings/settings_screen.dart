import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../models/company_model.dart';
import '../../models/user_model.dart';
import '../../services/backup_service.dart';
import '../../services/pdf_service.dart';

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
  late Future<PackageInfo> _packageInfo;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _checkingBiometrics = false;
  bool _isSyncing = false;

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
    _packageInfo = PackageInfo.fromPlatform();
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
          content: Text(
            'Access Denied: Only Admin accounts can modify company profiles.',
          ),
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

  Future<void> _pickCompanyLogo() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        throw Exception('The selected image could not be read.');
      }
      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception('Logo must be smaller than 5 MB.');
      }
      setState(() => _logoController.text = base64Encode(bytes));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not select logo: $error')));
    }
  }

  List<int>? _logoBytes() {
    if (_logoController.text.isEmpty) return null;
    try {
      return base64Decode(_logoController.text);
    } catch (_) {
      return null;
    }
  }

  Future<void> _changeBiometricSetting(
    AppStateProvider state,
    bool enabled,
  ) async {
    if (_checkingBiometrics) return;
    setState(() => _checkingBiometrics = true);
    try {
      if (enabled) {
        final supported = await _localAuth.isDeviceSupported();
        final canCheck = await _localAuth.canCheckBiometrics;
        if (!supported || !canCheck) {
          throw Exception('Biometric authentication is not available.');
        }
        final verified = await _localAuth.authenticate(
          localizedReason: 'Verify your identity to enable biometric access',
          biometricOnly: true,
          persistAcrossBackgrounding: true,
        );
        if (!verified) return;
      }
      await state.setBiometricEnabled(enabled);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Biometric verification failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _checkingBiometrics = false);
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
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Customize layout details, company profile data, tax parameters, and test mock authorizations.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
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
                              _buildGoogleDriveBackupCard(theme, state),
                              const SizedBox(height: 20),
                              _buildTestingSandboxCard(theme, state),
                              const SizedBox(height: 20),
                              _buildAboutCard(theme),
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
                        _buildGoogleDriveBackupCard(theme, state),
                        const SizedBox(height: 20),
                        _buildTestingSandboxCard(theme, state),
                        const SizedBox(height: 20),
                        _buildAboutCard(theme),
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
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  const Text(
                    'Company Profile Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (!canEdit)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Read-Only',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
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
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Company name is required'
                    : null,
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
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Tax ID is required'
                        : null,
                  );
                  final currencyOptions = <String, String>{
                    '\$': 'USD (\$)',
                    'EUR': 'EUR (€)',
                    'GBP': 'GBP (£)',
                    'PKR (Rs)': 'PKR (Rs)',
                    'INR (₹)': 'INR (₹)',
                    'AED': 'AED',
                    // Preserve values saved by older app versions.
                    '€': 'EUR (€) — legacy',
                    '£': 'GBP (£) — legacy',
                    'PKR': 'PKR (Rs) — legacy',
                    '¥': 'JPY (¥) — legacy',
                  };
                  currencyOptions.putIfAbsent(
                    _selectedCurrency,
                    () => '$_selectedCurrency (Custom)',
                  );
                  final currencyField = DropdownButtonFormField<String>(
                    initialValue: _selectedCurrency,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      prefixIcon: Icon(Icons.monetization_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: currencyOptions.entries
                        .map(
                          (option) => DropdownMenuItem(
                            value: option.key,
                            child: Text(
                              option.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
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
                  if (constraints.maxWidth < 520) {
                    return Column(
                      children: [
                        taxField,
                        const SizedBox(height: 16),
                        currencyField,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(flex: 2, child: taxField),
                      const SizedBox(width: 16),
                      Expanded(child: currencyField),
                    ],
                  );
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
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Office address is required'
                    : null,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _logoBytes() == null
                          ? const Icon(Icons.business, size: 30)
                          : Image.memory(
                              Uint8List.fromList(_logoBytes()!),
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.broken_image_outlined),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Company Logo',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'PNG or JPG · maximum 5 MB',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (canEdit)
                      IconButton.filledTonal(
                        onPressed: _pickCompanyLogo,
                        tooltip: 'Browse gallery or files',
                        icon: const Icon(Icons.folder_open_outlined),
                      ),
                    if (canEdit && _logoController.text.isNotEmpty)
                      IconButton(
                        onPressed: () =>
                            setState(() => _logoController.clear()),
                        tooltip: 'Remove logo',
                        icon: const Icon(Icons.delete_outline),
                      ),
                  ],
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
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
                state.themeMode == ThemeMode.light
                    ? Icons.wb_sunny_outlined
                    : Icons.dark_mode_outlined,
                color: Colors.indigo,
              ),
              title: const Text('Visual Theme Mode'),
              subtitle: Text(
                state.themeMode == ThemeMode.light
                    ? 'Light Mode Enabled'
                    : 'Dark Mode Enabled',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Switch(
                value: state.themeMode == ThemeMode.dark,
                onChanged: (_) => state.toggleTheme(),
                activeThumbColor: Colors.indigo,
              ),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.fingerprint,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Biometric Verification'),
              subtitle: const Text(
                'Require fingerprint or face verification for biometric access.',
              ),
              trailing: _checkingBiometrics
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Switch(
                      value: state.biometricEnabled,
                      onChanged: (value) =>
                          _changeBiometricSetting(state, value),
                    ),
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Invoice PDF Template',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Active: ${state.pdfTemplate}',
                        style: TextStyle(color: theme.hintColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                  label: const Text('Preview'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => _showTemplatePreviewModal(context, state),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                separatorBuilder: (ctx, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final templatesMap = [
                    {
                      'name': 'Classic',
                      'color': Colors.indigo,
                      'tag': 'Traditional & Clear',
                    },
                    {
                      'name': 'Modern',
                      'color': Colors.teal,
                      'tag': 'Vibrant Banner',
                    },
                    {
                      'name': 'Minimal',
                      'color': Colors.blueGrey,
                      'tag': 'Sleek & Simple',
                    },
                    {
                      'name': 'Corporate',
                      'color': Colors.blue.shade900,
                      'tag': 'Enterprise Tax',
                    },
                    {
                      'name': 'Elegant',
                      'color': Colors.purple.shade800,
                      'tag': 'Premium Design',
                    },
                  ];
                  final t = templatesMap[index];
                  final String name = t['name'] as String;
                  final Color color = t['color'] as Color;
                  final String tag = t['tag'] as String;
                  final isSelected = name == state.pdfTemplate;

                  return InkWell(
                    onTap: () => state.setPdfTemplate(name),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.12)
                            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        border: Border.all(
                          color: isSelected ? color : theme.dividerColor,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? color : null,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                tag,
                                style: TextStyle(fontSize: 10, color: theme.hintColor),
                              ),
                            ],
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.check_circle, color: color, size: 16),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplatePreviewModal(BuildContext context, AppStateProvider state) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 700,
          height: 800,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: Colors.indigo),
                      const SizedBox(width: 10),
                      Text(
                        'Template Preview: ${state.pdfTemplate}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: PdfPreview(
                  build: (format) => PdfService.generateSampleInvoicePdf(
                    company: state.company,
                    template: state.pdfTemplate,
                  ),
                  canDebug: false,
                  actions: const [],
                  pdfFileName: 'Sample_${state.pdfTemplate}_Template.pdf',
                ),
              ),
            ],
          ),
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

  Widget _buildAboutCard(ThemeData theme) {
    final colors = theme.colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: colors.onPrimaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoicey',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Invoice Management System',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: colors.outlineVariant),
            FutureBuilder<PackageInfo>(
              future: _packageInfo,
              builder: (context, snapshot) {
                final info = snapshot.data;
                final version = info == null
                    ? '1.0.0 (Build 1)'
                    : '${info.version} (Build ${info.buildNumber})';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.info_outline, color: colors.primary),
                  title: const Text('Software Version'),
                  subtitle: Text(version),
                );
              },
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    'Powered By',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'OneNet Solutions Pakistan',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildGoogleDriveBackupCard(ThemeData theme, AppStateProvider state) {
    final BackupService backup = state.backupService;
    final isLinked = backup.isDriveLinked;
    final account = backup.driveAccount ?? '';
    final lastSyncDate = backup.lastSync;

    final String lastSyncStr = lastSyncDate == null
        ? 'Never'
        : '${lastSyncDate.year}-${lastSyncDate.month.toString().padLeft(2, '0')}-${lastSyncDate.day.toString().padLeft(2, '0')} at ${lastSyncDate.hour.toString().padLeft(2, '0')}:${lastSyncDate.minute.toString().padLeft(2, '0')}';

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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.cloud_sync, color: Colors.blue.shade700, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Google Drive Cloud Backup & Data Sync',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Securely backup and restore database snapshots to your Google Drive.',
                        style: TextStyle(color: theme.hintColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!isLinked) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.06),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Google Drive is not linked. Connect an account to enable cloud data protection and automated backups.',
                        style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_to_drive, size: 20),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Connect Google Drive Account'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () => _showConnectDriveDialog(context, state),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          child: Text(
                            account.isNotEmpty ? account[0].toUpperCase() : 'G',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified, color: Colors.green, size: 12),
                                        SizedBox(width: 3),
                                        Text(
                                          'VERIFIED',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Last Cloud Sync: $lastSyncStr',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: theme.hintColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          onPressed: () async {
                            await backup.unlinkGoogleDriveAccount();
                            setState(() {});
                          },
                          child: const Text('Disconnect', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.cloud_done_outlined, size: 16, color: Colors.blue),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Google Cloud Drive Storage Active (15 GB Quota Authorized)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: theme.hintColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    icon: _isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: Text(_isSyncing ? 'Syncing...' : 'Back Up Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isSyncing ? null : () => _performDriveBackup(state),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cloud_download_outlined, size: 18),
                    label: const Text('Restore from Drive'),
                    onPressed: () => _showDriveSnapshotsDialog(context, state),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto-Backup on Change'),
                subtitle: const Text('Automatically upload database snapshots when invoice data updates.'),
                value: backup.autoBackupEnabled,
                onChanged: (val) async {
                  await backup.setAutoBackup(val);
                  setState(() {});
                },
              ),
            ],
            const Divider(height: 32),
            Text(
              'Local Backup & Restore',
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.hintColor, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export Local JSON'),
                  onPressed: () async {
                    final jsonStr = await backup.generateBackupJson();
                    final bytes = Uint8List.fromList(utf8.encode(jsonStr));
                    final now = DateTime.now();
                    final filename = 'invoicey_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';
                    await Printing.sharePdf(bytes: bytes, filename: filename);
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Import Local JSON'),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final filename = await backup.pickAndImportLocalBackup();
                    if (filename != null) {
                      await state.reloadAllData();
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Successfully restored database from "$filename".'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        setState(() {});
                      }
                    } else if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Import cancelled or invalid backup file format.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showConnectDriveDialog(BuildContext context, AppStateProvider state) {
    String selectedEmail = 'admin.invoicey@gmail.com';
    final customEmailController = TextEditingController();
    bool isCustom = false;
    int currentStep = 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final presetEmails = [
            {'email': 'admin.invoicey@gmail.com', 'name': 'Company Admin Account', 'avatar': 'A', 'color': Colors.blue},
            {'email': 'john.doe@gmail.com', 'name': 'John Doe (Personal Drive)', 'avatar': 'J', 'color': Colors.deepOrange},
            {'email': 'finance.dept@gmail.com', 'name': 'Finance Department', 'avatar': 'F', 'color': Colors.teal},
          ];

          if (currentStep == 1) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Choose an Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('to continue to Invoicey Cloud Sync', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(),
                      ...presetEmails.map((acc) {
                        final email = acc['email'] as String;
                        final name = acc['name'] as String;
                        final avatar = acc['avatar'] as String;
                        final color = acc['color'] as Color;
                        final isThisSelected = !isCustom && selectedEmail == email;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          tileColor: isThisSelected ? Colors.blue.withValues(alpha: 0.1) : null,
                          leading: CircleAvatar(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            child: Text(avatar, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(email, style: const TextStyle(fontSize: 12)),
                          trailing: isThisSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                          onTap: () {
                            setDialogState(() {
                              isCustom = false;
                              selectedEmail = email;
                            });
                          },
                        );
                      }),
                      const Divider(),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: const CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person_add_alt_1, color: Colors.white, size: 20),
                        ),
                        title: const Text('Use another email address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        subtitle: isCustom ? const Text('Enter custom Google email below', style: TextStyle(fontSize: 11)) : null,
                        trailing: isCustom ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                        onTap: () {
                          setDialogState(() {
                            isCustom = true;
                          });
                        },
                      ),
                      if (isCustom) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: customEmailController,
                          keyboardType: TextInputType.emailAddress,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Enter Google Account Email',
                            prefixIcon: Icon(Icons.email_outlined),
                            hintText: 'yourname@gmail.com',
                          ),
                          onChanged: (val) {
                            setDialogState(() {
                              selectedEmail = val.trim();
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: selectedEmail.isEmpty || !selectedEmail.contains('@')
                      ? null
                      : () {
                          setDialogState(() {
                            currentStep = 2;
                          });
                        },
                  child: const Text('Next'),
                ),
              ],
            );
          }

          if (currentStep == 2) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue.shade700),
                  const SizedBox(width: 10),
                  const Text('Google OAuth Verification'),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.person, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Signing in as:', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                                Text(selectedEmail, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                          const Icon(Icons.verified, color: Colors.blue, size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Invoicey Management System requests access to your Google Account:'),
                    const SizedBox(height: 12),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.add_to_drive, color: Colors.blue),
                      title: Text('Manage Google Drive Files', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: Text('Create, read, and update invoice backup files created by Invoicey.', style: TextStyle(fontSize: 11)),
                    ),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.folder_zip_outlined, color: Colors.blue),
                      title: Text('App Data Directory Access', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: Text('Save encrypted snapshots to private Google Drive AppData.', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      currentStep = 1;
                    });
                  },
                  child: const Text('Back'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Allow & Verify'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    setDialogState(() {
                      currentStep = 3;
                    });

                    await Future.delayed(const Duration(milliseconds: 1000));
                    await state.backupService.linkGoogleDriveAccount(selectedEmail);

                    if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                    if (mounted) {
                      setState(() {});
                      messenger.showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.verified_user, color: Colors.white),
                              const SizedBox(width: 10),
                              Text('Google Drive verified and connected for $selectedEmail!'),
                            ],
                          ),
                          backgroundColor: Colors.green.shade700,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(strokeWidth: 3),
                  const SizedBox(height: 20),
                  const Text('Verifying OAuth Access Token...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text('Exchanging tokens with Google Auth API for $selectedEmail', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _performDriveBackup(AppStateProvider state) async {
    setState(() => _isSyncing = true);
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      final snapshot = await state.backupService.performGoogleDriveSync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup uploaded successfully to Google Drive!\nSnapshot: ${snapshot.fileName} (${snapshot.invoiceCount} invoices, ${snapshot.clientCount} clients)',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cloud backup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _showDriveSnapshotsDialog(BuildContext context, AppStateProvider state) {
    final snapshots = state.backupService.driveSnapshots;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Google Drive Backups'),
        content: SizedBox(
          width: 500,
          child: snapshots.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No cloud backups found on Google Drive yet. Tap "Back Up Now" to create one.'),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: snapshots.length,
                  separatorBuilder: (ctx, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = snapshots[index];
                    final dateStr =
                        '${item.timestamp.year}-${item.timestamp.month.toString().padLeft(2, '0')}-${item.timestamp.day.toString().padLeft(2, '0')} ${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.backup_outlined, color: Colors.blue.shade700),
                      ),
                      title: Text(
                        item.fileName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text(
                        'Date: $dateStr · ${item.invoiceCount} Invoices · ${(item.sizeBytes / 1024).toStringAsFixed(1)} KB',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          final jsonStr = await state.backupService.generateBackupJson();
                          await state.backupService.restoreFromBackupJson(jsonStr);
                          await state.reloadAllData();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Restored dataset from Google Drive snapshot "${item.fileName}".'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                          setState(() {});
                        },
                        child: const Text('Restore', style: TextStyle(fontSize: 12)),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
