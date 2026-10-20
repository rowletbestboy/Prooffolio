import 'package:flutter/material.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prooffolio', style: textTheme.titleLarge),
                    const SizedBox(height: 40),
                    Text(
                      _isSignUp ? 'Create your account' : 'Welcome back',
                      style: textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUp
                          ? 'Start building a portfolio grounded in your real work.'
                          : 'Sign in to continue building your evidence trail.',
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      key: const Key('emailField'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('passwordField'),
                      controller: _passwordController,
                      obscureText: true,
                      autofillHints: _isSignUp
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: _validatePassword,
                    ),
                    if (_isSignUp) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('confirmPasswordField'),
                        controller: _confirmController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
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
                      Text(_error!, style: TextStyle(color: colorScheme.error)),
                    ],
                    if (_message != null) ...[
                      const SizedBox(height: 8),
                      Text(_message!, style: textTheme.bodyMedium),
                    ],
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: _busy ? null : () => _setMode(!_isSignUp),
                        child: Text(
                          _isSignUp
                              ? 'Already have an account? Sign in'
                              : 'Create account',
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
