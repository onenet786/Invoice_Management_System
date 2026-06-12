import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  final _otpFormKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  String? _otpErrorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
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

  void _submitOtp(AppStateProvider state) {
    if (!_otpFormKey.currentState!.validate()) return;
    setState(() {
      _otpErrorMessage = null;
    });

    final success = state.verifyOtp(_otpController.text);
    if (success) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      setState(() {
        _otpErrorMessage = 'Invalid verification code. Please try again.';
      });
    }
  }

  void _quickFill(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
      _errorMessage = null;
    });
  }

  void _handleGoogleSignIn(AppStateProvider state) async {
    if (state.googleDriveSimulate) {
      final emailController = TextEditingController();
      final formKey = GlobalKey<FormState>();

      final googleEmails = [
        'admin@invoice.com',
        'manager@invoice.com',
        'viewer@invoice.com',
        'user.demo@gmail.com',
      ];

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.account_circle, color: Colors.indigo, size: 28),
                SizedBox(width: 10),
                Text('Google Sign In'),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select a mock account or type a custom Google email for testing:',
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
                      if (v == null || v.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
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
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context);
                    state.initiateGoogleSignIn(emailController.text.trim());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Sign In'),
              ),
            ],
          );
        },
      );
    } else {
      // Real Google Sign-in flow
      try {
        await GoogleSignIn.instance.initialize();
        final account = await GoogleSignIn.instance.authenticate();
        final email = account.email;
        state.initiateGoogleSignIn(email);
      } catch (e) {
        if (!mounted) return;
        final switchSimulated = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.cloud_off_outlined, color: Colors.amber, size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Google OAuth Error'),
                  ),
                ],
              ),
              content: Text(
                'Failed to perform real Google Authentication.\n'
                'Error: $e\n\n'
                'Ensure Google OAuth credentials are configured for this app, or switch to Simulation Mode for sandbox testing.',
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

        if (switchSimulated) {
          await state.updateGoogleDriveSettings(
            simulate: true,
            clientId: state.googleDriveClientId,
            clientSecret: state.googleDriveClientSecret,
          );
          if (!mounted) return;
          _handleGoogleSignIn(state);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final theme = Theme.of(context);
    final isOtpVerification = state.currentOtp != null;

    // Build floating mock email preview at the top of the stack
    Widget? emailNotification;
    if (isOtpVerification && state.pendingOtpUser != null) {
      emailNotification = Positioned(
        top: 24,
        left: 24,
        right: 24,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: -150.0, end: 0.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, value),
              child: child,
            );
          },
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(12),
            color: theme.brightness == Brightness.light ? Colors.grey.shade900 : const Color(0xFF0F172A),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.indigo.shade400, width: 1.5),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.mark_email_unread, color: Colors.amber.shade400, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'SIMULATED INBOX (no-reply@invoicey.com)',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade600,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'SENT',
                                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your Invoicey OTP Login Verification Code',
                          style: TextStyle(
                            color: Colors.amber.shade200,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                            children: [
                              const TextSpan(text: 'Hello, use the following code to authorize your login session: '),
                              TextSpan(
                                text: state.currentOtp,
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                  letterSpacing: 1.2,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const TextSpan(text: '. This code will expire in 2 minutes.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
                    onPressed: () {
                      if (state.currentOtp != null) {
                        Clipboard.setData(ClipboardData(text: state.currentOtp!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('OTP code copied to clipboard!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    tooltip: 'Copy Code',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                        child: isOtpVerification
                            ? _buildOtpForm(state, theme)
                            : _buildLoginForm(state, theme),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          ?emailNotification,
        ],
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
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(),
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

          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('OR', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),

          // Google Sign-In Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: state.isLoading ? null : () => _handleGoogleSignIn(state),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.dividerColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.g_mobiledata, color: Colors.indigo, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.brightness == Brightness.light ? Colors.grey.shade800 : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          Text(
            'Quick Seed Accounts (Tap to fill):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.hintColor),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickFillChip('Admin', 'admin@invoice.com', 'admin123', Colors.red.shade400),
              _buildQuickFillChip('Manager', 'manager@invoice.com', 'manager123', Colors.amber.shade700),
              _buildQuickFillChip('Viewer', 'viewer@invoice.com', 'viewer123', Colors.grey.shade600),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtpForm(AppStateProvider state, ThemeData theme) {
    return Form(
      key: _otpFormKey,
      child: Column(
        key: const ValueKey('otp_form_content'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.mark_email_read_rounded,
            size: 64,
            color: Colors.indigo,
          ),
          const SizedBox(height: 16),
          Text(
            'VERIFY EMAIL',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: theme.brightness == Brightness.light ? Colors.indigo.shade900 : Colors.indigo.shade200,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We have sent a 6-digit code to Google account:',
            style: TextStyle(
              fontSize: 12,
              color: theme.hintColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            state.pendingOtpUser?.email ?? '',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          if (_otpErrorMessage != null)
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
                      _otpErrorMessage!,
                      style: TextStyle(color: Colors.red.shade400, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 16.0,
              fontFamily: 'monospace',
            ),
            decoration: const InputDecoration(
              hintText: '000000',
              hintStyle: TextStyle(color: Colors.grey, letterSpacing: 16.0),
              counterText: '',
              prefixIcon: Icon(Icons.vpn_key_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().length != 6) {
                return 'Please enter the 6-digit verification code';
              }
              if (int.tryParse(value) == null) {
                return 'Code must contain digits only';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : () => _submitOtp(state),
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
                      'Verify & Login',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          TextButton(
            onPressed: () {
              setState(() {
                _otpErrorMessage = null;
                _otpController.clear();
              });
              state.cancelOtpSession();
            },
            child: const Text('Back to Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFillChip(String label, String email, String password, Color color) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color,
      onPressed: () => _quickFill(email, password),
    );
  }
}
