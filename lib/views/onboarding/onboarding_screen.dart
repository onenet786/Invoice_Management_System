import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _showSetup = false;
  bool _submitting = false;
  String? _error;

  Future<void> _sample() async {
    setState(() => _submitting = true);
    try {
      await context.read<AppStateProvider>().useSampleCompany();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'We could not create the sample workspace. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _showSetup
                    ? CompanySetupForm(
                        key: const ValueKey('setup'),
                        onBack: () => setState(() {
                          _showSetup = false;
                          _error = null;
                        }),
                      )
                    : _choice(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _choice(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('choice'),
      children: [
        _InvoiceMark(colors: colors),
        const SizedBox(height: 24),
        Text(
          'Welcome to Invoicey',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'How would you like to begin?',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: colors.tertiaryContainer,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.tertiary.withValues(alpha: .35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: colors.onTertiaryContainer,
                size: 19,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Your data stays on this device',
                  style: TextStyle(
                    color: colors.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              _OptionCard(
                icon: Icons.business_rounded,
                title: 'Set up my company',
                description:
                    'Create a clean workspace with your business details and administrator account.',
                label: 'Recommended',
                primary: true,
                enabled: !_submitting,
                onTap: () => setState(() => _showSetup = true),
              ),
              _OptionCard(
                icon: Icons.explore_outlined,
                title: 'Explore sample company',
                description:
                    'Preview Invoicey with ready-made clients, products, users, and invoices.',
                enabled: !_submitting,
                loading: _submitting,
                onTap: _sample,
              ),
            ];
            return constraints.maxWidth > 680
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: cards[0]),
                      const SizedBox(width: 18),
                      Expanded(child: cards[1]),
                    ],
                  )
                : Column(
                    children: [cards[0], const SizedBox(height: 16), cards[1]],
                  );
          },
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Text(_error!, style: TextStyle(color: colors.error)),
          ),
      ],
    );
  }
}

class _InvoiceMark extends StatelessWidget {
  const _InvoiceMark({required this.colors});
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(15, 0),
            child: Transform.rotate(
              angle: .08,
              child: Container(
                width: 54,
                height: 66,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(-8, 0),
            child: Container(
              width: 58,
              height: 70,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.primary.withValues(alpha: .3)),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 34,
                color: colors.primary,
              ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 1,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: colors.primary,
              child: Icon(
                Icons.check_rounded,
                size: 17,
                color: colors.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.number,
    required this.label,
    required this.active,
  });
  final String number;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = active ? colors.primary : colors.onSurfaceVariant;
    return Column(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: active
              ? colors.primaryContainer
              : colors.surfaceContainerHighest,
          child: Text(
            number,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.enabled,
    required this.onTap,
    this.primary = false,
    this.loading = false,
    this.label,
  });
  final IconData icon;
  final String title;
  final String description;
  final bool enabled;
  final bool primary;
  final bool loading;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: primary ? 3 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: primary ? colors.primary : colors.outlineVariant,
          width: primary ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 34,
                    color: primary ? colors.primary : colors.onSurfaceVariant,
                  ),
                  const Spacer(),
                  if (label != null)
                    Chip(
                      label: Text(label!),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.45),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: loading
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            primary ? 'Start setup' : 'Load sample',
                            style: TextStyle(
                              color: primary
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: primary
                                ? colors.primary
                                : colors.onSurfaceVariant,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompanySetupForm extends StatefulWidget {
  const CompanySetupForm({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  State<CompanySetupForm> createState() => _CompanySetupFormState();
}

class _CompanySetupFormState extends State<CompanySetupForm> {
  final _key = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _tax = TextEditingController();
  final _address = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _customCurrency = TextEditingController();
  String _currency = '\$';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _company,
      _tax,
      _address,
      _name,
      _email,
      _password,
      _confirm,
      _customCurrency,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  Future<void> _save() async {
    if (_saving || !_key.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<AppStateProvider>().setupCompany(
        companyName: _company.text,
        taxId: _tax.text,
        address: _address.text,
        currency: _currency == 'Other'
            ? _customCurrency.text.trim()
            : _currency,
        adminName: _name.text,
        email: _email.text,
        password: _password.text,
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Setup could not be saved. Your details are still here—please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 500 ? 20 : 36,
        ),
        child: Form(
          key: _key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: _saving ? null : widget.onBack,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
              ),
              const SizedBox(height: 8),
              Text(
                'Set up your company',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your business profile and administrator account',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: _ProgressStep(
                      number: '1',
                      label: 'Business',
                      active: true,
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: colors.primary.withValues(alpha: .35),
                    ),
                  ),
                  const Expanded(
                    child: _ProgressStep(
                      number: '2',
                      label: 'Admin',
                      active: true,
                    ),
                  ),
                  Expanded(child: Divider(color: colors.outlineVariant)),
                  const Expanded(
                    child: _ProgressStep(
                      number: '3',
                      label: 'Ready',
                      active: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'BUSINESS DETAILS',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _company,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Company name *',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                validator: _required,
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final taxField = TextFormField(
                    controller: _tax,
                    decoration: const InputDecoration(
                      labelText: 'Tax / registration ID (Optional)',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  );
                  final currencyField = DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: const InputDecoration(labelText: 'Currency'),
                    items:
                        const [
                              '\$',
                              'EUR',
                              'GBP',
                              'PKR (Rs)',
                              'INR (₹)',
                              'AED',
                              'Other',
                            ]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _currency = value!),
                  );
                  return constraints.maxWidth < 560
                      ? Column(
                          children: [
                            taxField,
                            const SizedBox(height: 14),
                            currencyField,
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: taxField),
                            const SizedBox(width: 14),
                            Expanded(child: currencyField),
                          ],
                        );
                },
              ),
              if (_currency == 'Other') ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _customCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Custom currency symbol or code *',
                    prefixIcon: Icon(Icons.currency_exchange),
                  ),
                  validator: _required,
                ),
              ],
              const SizedBox(height: 14),
              TextFormField(
                controller: _address,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Business address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'ADMINISTRATOR',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Full name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: _required,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email address *',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (_required(value) != null) return _required(value);
                  return RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(value!.trim())
                      ? null
                      : 'Enter a valid email address';
                },
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final passwordField = TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password *',
                      helperText: 'At least 8 characters',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) => (value?.length ?? 0) < 8
                        ? 'Use at least 8 characters'
                        : null,
                  );
                  final confirmField = TextFormField(
                    controller: _confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password *',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                    ),
                    validator: (value) => value != _password.text
                        ? 'Passwords do not match'
                        : null,
                  );
                  return constraints.maxWidth < 560
                      ? Column(
                          children: [
                            passwordField,
                            const SizedBox(height: 14),
                            confirmField,
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: passwordField),
                            const SizedBox(width: 14),
                            Expanded(child: confirmField),
                          ],
                        );
                },
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _saving ? 'Creating workspace…' : 'Create my workspace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
