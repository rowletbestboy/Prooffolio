import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_brand_mark.dart';
import '../data/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSignUp = false;
  bool _busy = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _setMode(bool isSignUp) {
    setState(() {
      _isSignUp = isSignUp;
      _message = null;
      _error = null;
    });
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
        ? null
        : 'Enter a valid email address';
  }

  String? _validatePassword(String? value) => (value?.length ?? 0) >= 8
      ? null
      : 'Enter a password of at least 8 characters';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
      _error = null;
    });
    try {
      if (_isSignUp) {
        final result = await widget.authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (result.emailConfirmationRequired && mounted) {
          setState(
            () => _message =
                'Check your inbox to confirm your email, then sign in to continue.',
          );
        }
      } else {
        await widget.authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'That email and password combination was not recognized.';
    }
    if (message.contains('already registered') ||
        message.contains('user already registered')) {
      return 'An account already uses this email. Try signing in.';
    }
    if (message.contains('network') || message.contains('socket')) {
      return 'Could not connect. Check your internet and try again.';
    }
    return 'We could not complete that request. Please try again.';
  }

  Future<void> _resetPassword() async {
    final emailError = _validateEmail(_emailController.text);
    if (emailError != null) {
      setState(() => _error = 'Enter your email above to reset your password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      await widget.authService.resetPassword(
        email: _emailController.text.trim(),
      );
      if (mounted) {
        setState(
          () => _message = 'Password reset link sent. Check your inbox.',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final pageGutter = AppTheme.pageGutterFor(MediaQuery.sizeOf(context).width);
    return Scaffold(
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(pageGutter, 20, pageGutter, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 62),
                      decoration: BoxDecoration(
                        color: AppColors.indigoBright,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppBrandMark(inverse: true),
                          const SizedBox(height: 26),
                          Text(
                            'A clearer story of your work.',
                            style: textTheme.headlineSmall?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Build a portfolio grounded in what you have done.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -38),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.lightSlate),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x120F172A),
                              blurRadius: 28,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isSignUp
                                    ? 'Create your account'
                                    : 'Welcome back',
                                style: textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isSignUp
                                    ? 'Start with the work and experiences that matter to you.'
                                    : 'Sign in to continue building your evidence trail.',
                                style: textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                key: const Key('emailField'),
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                autocorrect: false,
                                decoration: const InputDecoration(
                                  labelText: 'Email address',
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                key: const Key('passwordField'),
                                controller: _passwordController,
                                obscureText: true,
                                autofillHints: _isSignUp
                                    ? const [AutofillHints.newPassword]
                                    : const [AutofillHints.password],
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                validator: _validatePassword,
                              ),
                              if (_isSignUp) ...[
                                const SizedBox(height: 14),
                                TextFormField(
                                  key: const Key('confirmPasswordField'),
                                  controller: _confirmController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Confirm password',
                                    prefixIcon: Icon(
                                      Icons.verified_user_outlined,
                                    ),
                                  ),
                                  validator: (value) =>
                                      value == _passwordController.text &&
                                          (value?.isNotEmpty ?? false)
                                      ? null
                                      : 'Passwords do not match',
                                ),
                              ],
                              if (!_isSignUp)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _busy ? null : _resetPassword,
                                    child: const Text('Forgot password?'),
                                  ),
                                ),
                              if (_error != null) ...[
                                const SizedBox(height: 8),
                                _AuthNotice(
                                  icon: Icons.error_outline,
                                  color: colorScheme.error,
                                  text: _error!,
                                ),
                              ],
                              if (_message != null) ...[
                                const SizedBox(height: 8),
                                _AuthNotice(
                                  icon: Icons.mark_email_read_outlined,
                                  color: colorScheme.primary,
                                  text: _message!,
                                ),
                              ],
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _busy ? null : _submit,
                                  child: Text(
                                    _busy
                                        ? 'Please wait…'
                                        : _isSignUp
                                        ? 'Create account'
                                        : 'Sign in',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _setMode(!_isSignUp),
                                  child: Text(
                                    _isSignUp
                                        ? 'Already have an account? Sign in'
                                        : 'New to Prooffolio? Create account',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthNotice extends StatelessWidget {
  const _AuthNotice({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    ),
  );
}
