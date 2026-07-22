import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
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
  late Future<PackageInfo> _packageInfo;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _checkingBiometrics = false;

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
            const Divider(),
            DropdownButtonFormField<String>(
              initialValue: state.pdfTemplate,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Invoice PDF Template',
                prefixIcon: Icon(Icons.picture_as_pdf_outlined),
                helperText: 'Applied to PDF preview, printing, and downloads.',
              ),
              items:
                  const ['Classic', 'Modern', 'Minimal', 'Corporate', 'Elegant']
                      .map(
                        (template) => DropdownMenuItem(
                          value: template,
                          child: Text(template),
                        ),
                      )
                      .toList(),
              onChanged: (template) {
                if (template != null) state.setPdfTemplate(template);
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
}
