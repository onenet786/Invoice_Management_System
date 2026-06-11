import 'package:flutter/material.dart';
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
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _taxIdController,
                      enabled: canEdit,
                      decoration: const InputDecoration(
                        labelText: 'Company Tax ID (GST/VAT)',
                        prefixIcon: Icon(Icons.description_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Tax ID is required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
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
                    ),
                  ),
                ],
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
}
