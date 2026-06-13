import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../models/user_model.dart';
import '../../utils/password_util.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  final _registerFormKey = GlobalKey<FormState>();
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();
  String? _registerErrorMessage;
  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureRegisterConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoBiometricAuthenticate();
    });
  }

  void _autoBiometricAuthenticate() async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    if (state.biometricEnabled && state.users.isNotEmpty) {
      final isHardwareAvailable = await state.isBiometricHardwareAvailable();
      if (isHardwareAvailable) {
        final success = await state.authenticateWithBiometrics();
        if (success && mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        _showSimulatedBiometricDialog(state);
      }
    }
  }

  void _showSimulatedBiometricDialog(AppStateProvider state) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        bool scanning = false;
        bool success = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Simulated Thumb Scanner',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the fingerprint icon below to simulate a biometric thumb scan.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () async {
                      if (scanning || success) return;
                      setDialogState(() {
                        scanning = true;
                      });
                      
                      await Future.delayed(const Duration(milliseconds: 1200));
                      
                      if (context.mounted) {
                        setDialogState(() {
                          scanning = false;
                          success = true;
                        });
                        
                        await Future.delayed(const Duration(milliseconds: 600));
                        
                        if (context.mounted) {
                          Navigator.pop(context); // Close dialog
                          final ok = state.loginBiometricUser();
                          if (ok && context.mounted) {
                            Navigator.of(context).pushReplacementNamed('/home');
                          }
                        }
                      }
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: success
                            ? Colors.green.shade50
                            : scanning
                                ? Colors.indigo.shade50
                                : Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: success
                              ? Colors.green
                              : scanning
                                  ? Colors.indigo
                                  : Colors.grey.shade300,
                          width: 2.5,
                        ),
                      ),
                      child: Center(
                        child: success
                            ? const Icon(Icons.check_circle_outline, color: Colors.green, size: 50)
                            : scanning
                                ? const CircularProgressIndicator(color: Colors.indigo)
                                : const Icon(Icons.fingerprint, color: Colors.indigo, size: 50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    success
                        ? 'Authentication Successful!'
                        : scanning
                            ? 'Scanning thumb...'
                            : 'Place Thumb to Scan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: success
                          ? Colors.green
                          : scanning
                              ? Colors.indigo
                              : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _handleBiometricLoginPress(AppStateProvider state) async {
    if (state.biometricEnabled) {
      _autoBiometricAuthenticate();
    } else {
      showDialog(
        context: context,
        builder: (context) {
          final passwordController = TextEditingController();
          final formKey = GlobalKey<FormState>();
          bool obscure = true;
          String? dialogError;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: const [
                    Icon(Icons.fingerprint, color: Colors.indigo, size: 28),
                    SizedBox(width: 10),
                    Text('Enable Biometrics'),
                  ],
                ),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'To enable Biometric Login, please verify your password first:',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      if (dialogError != null) ...[
                        Text(
                          dialogError!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                      ],
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Theme.of(context).hintColor,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscure = !obscure;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      
                      final primaryUser = state.users.firstWhere(
                        (u) => u.role == UserRole.admin,
                        orElse: () => state.users.first,
                      );
                      
                      if (PasswordUtil.verifyPassword(passwordController.text, primaryUser.password)) {
                        Navigator.pop(context);
                        await state.updateBiometricEnabled(true);
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Biometric Login enabled successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _autoBiometricAuthenticate();
                        }
                      } else {
                        setDialogState(() {
                          dialogError = 'Incorrect password. Please try again.';
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Verify & Enable'),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _errorMessage = null;
    });

    final state = Provider.of<AppStateProvider>(context, listen: false);
    final success = await state.login(
      _emailController.text,
      _passwordController.text,
    );

    if (success) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      setState(() {
        _errorMessage = 'Invalid email or password. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.indigo.shade900,
              Colors.purple.shade900,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: theme.brightness == Brightness.light
                    ? Colors.white.withValues(alpha: 0.92)
                    : Colors.grey.shade900.withValues(alpha: 0.92),
                child: Container(
                  width: 450,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: state.users.isEmpty
                        ? _buildRegisterAdminForm(state, theme)
                        : _buildLoginForm(state, theme),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(AppStateProvider state, ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('login_form_content'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            size: 64,
            color: Colors.indigo,
          ),
          const SizedBox(height: 16),
          Text(
            'INVOICEY',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: theme.brightness == Brightness.light ? Colors.indigo.shade900 : Colors.indigo.shade200,
            ),
          ),
          Text(
            'Enterprise Invoice Control Center',
            style: TextStyle(
              fontSize: 12,
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 32),

          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade400.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade400, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email or Username',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email or username';
              }
              final val = value.trim().toLowerCase();
              if (val != 'admin' && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscureLoginPassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLoginPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: theme.hintColor,
                ),
                onPressed: () {
                  setState(() {
                    _obscureLoginPassword = !_obscureLoginPassword;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: state.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Sign In',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),

          if (state.users.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _handleBiometricLoginPress(state),
                icon: const Icon(Icons.fingerprint, color: Colors.indigo, size: 24),
                label: const Text(
                  'Sign in with Biometrics / Thumb',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.indigo),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRegisterAdminForm(AppStateProvider state, ThemeData theme) {
    return Form(
      key: _registerFormKey,
      child: Column(
        key: const ValueKey('register_admin_form'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.admin_panel_settings_outlined,
            size: 64,
            color: Colors.indigo,
          ),
          const SizedBox(height: 16),
          Text(
            'Create Admin Account',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: theme.brightness == Brightness.light ? Colors.indigo.shade900 : Colors.indigo.shade200,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Set up initial admin credentials to start using Invoicey.',
            style: TextStyle(
              fontSize: 12,
              color: theme.hintColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          if (_registerErrorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade400.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _registerErrorMessage!,
                      style: TextStyle(color: Colors.red.shade400, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          TextFormField(
            controller: _registerNameController,
            decoration: const InputDecoration(
              labelText: 'Administrator Name',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Administrator name is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registerEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Username or Email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Username/Email is required';
              final val = v.trim().toLowerCase();
              if (val != 'admin' && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                return 'Please enter a valid email or username';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registerPasswordController,
            obscureText: _obscureRegisterPassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureRegisterPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: theme.hintColor,
                ),
                onPressed: () {
                  setState(() {
                    _obscureRegisterPassword = !_obscureRegisterPassword;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 4) return 'Password must be at least 4 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registerConfirmPasswordController,
            obscureText: _obscureRegisterConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureRegisterConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: theme.hintColor,
                ),
                onPressed: () {
                  setState(() {
                    _obscureRegisterConfirmPassword = !_obscureRegisterConfirmPassword;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _registerPasswordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : () => _submitRegisterAdmin(state),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: state.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Create & Login',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitRegisterAdmin(AppStateProvider state) async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() {
      _registerErrorMessage = null;
    });

    try {
      await state.registerInitialAdmin(
        _registerNameController.text,
        _registerEmailController.text,
        _registerPasswordController.text,
      );
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _registerErrorMessage = 'Failed to create admin: $e';
      });
    }
  }
}
