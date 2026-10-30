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
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSignUp = false;
  bool _busy = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _setMode(bool isSignUp) {
    setState(() {
      _isSignUp = isSignUp;
      _error = null;
      _message = null;
      _passwordVisible = false;
      _confirmPasswordVisible = false;
    });
    _formKey.currentState?.reset();
  }

  String? _validateDisplayName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter your full name';
    if (name.length > 80) return 'Use 80 characters or fewer';
    return null;
  }

  String? _validateUsername(String? value) {
    final username = value?.trim() ?? '';
    if (username.length < 3 || username.length > 24) {
      return 'Use 3 to 24 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return 'Use letters, numbers, and underscores only';
    }
    return null;
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
          displayName: _displayNameController.text.trim(),
          username: _usernameController.text.trim().toLowerCase(),
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
      backgroundColor: AppColors.cloudWhite,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _AuthWavePainter(isSignUp: _isSignUp)),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(pageGutter, 12, pageGutter, 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 28).clamp(
                      0,
                      double.infinity,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isSignUp)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                tooltip: 'Back to sign in',
                                onPressed: _busy ? null : () => _setMode(false),
                                icon: const Icon(Icons.arrow_back),
                              ),
                            ),
                          _BrandHeader(),
                          SizedBox(height: _isSignUp ? 22 : 30),
                          Text(
                            _isSignUp ? 'Create your account' : 'Welcome back',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isSignUp
                                ? 'Join Prooffolio and start building your professional portfolio.'
                                : 'Sign in to continue building your portfolio and career opportunities.',
                            style: textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 22),
                          Form(
                            key: _formKey,
                            child: AutofillGroup(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_isSignUp) ...[
                                    _buildTextField(
                                      key: const Key('fullNameField'),
                                      controller: _displayNameController,
                                      label: 'Full name',
                                      icon: Icons.person_outline,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      autofillHints: const [AutofillHints.name],
                                      validator: _validateDisplayName,
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  _buildTextField(
                                    key: const Key('emailField'),
                                    controller: _emailController,
                                    label: 'Email address',
                                    icon: Icons.mail_outline,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    validator: _validateEmail,
                                  ),
                                  if (_isSignUp) ...[
                                    const SizedBox(height: 10),
                                    _buildTextField(
                                      key: const Key('usernameField'),
                                      controller: _usernameController,
                                      label: 'Username (your public URL)',
                                      icon: Icons.link,
                                      suffix: Text(
                                        'prooffolio.com/u/',
                                        style: textTheme.bodySmall?.copyWith(
                                          fontSize: 10,
                                        ),
                                      ),
                                      autocorrect: false,
                                      validator: _validateUsername,
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  _buildTextField(
                                    key: const Key('passwordField'),
                                    controller: _passwordController,
                                    label: 'Password',
                                    icon: Icons.lock_outline,
                                    obscureText: !_passwordVisible,
                                    autofillHints: _isSignUp
                                        ? const [AutofillHints.newPassword]
                                        : const [AutofillHints.password],
                                    validator: _validatePassword,
                                    suffix: IconButton(
                                      tooltip: _passwordVisible
                                          ? 'Hide password'
                                          : 'Show password',
                                      onPressed: () => setState(
                                        () => _passwordVisible =
                                            !_passwordVisible,
                                      ),
                                      icon: Icon(
                                        _passwordVisible
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                  if (_isSignUp) ...[
                                    const SizedBox(height: 10),
                                    _buildTextField(
                                      key: const Key('confirmPasswordField'),
                                      controller: _confirmController,
                                      label: 'Confirm password',
                                      icon: Icons.lock_outline,
                                      obscureText: !_confirmPasswordVisible,
                                      validator: (value) =>
                                          value == _passwordController.text &&
                                              (value?.isNotEmpty ?? false)
                                          ? null
                                          : 'Passwords do not match',
                                      suffix: IconButton(
                                        tooltip: _confirmPasswordVisible
                                            ? 'Hide confirm password'
                                            : 'Show confirm password',
                                        onPressed: () => setState(
                                          () => _confirmPasswordVisible =
                                              !_confirmPasswordVisible,
                                        ),
                                        icon: Icon(
                                          _confirmPasswordVisible
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    FormField<bool>(
                                      key: const Key('termsCheckbox'),
                                      initialValue: false,
                                      validator: (accepted) => accepted == true
                                          ? null
                                          : 'Accept the Terms of Service and Privacy Policy',
                                      builder: (field) => Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CheckboxListTile(
                                            value: field.value ?? false,
                                            onChanged: _busy
                                                ? null
                                                : field.didChange,
                                            controlAffinity:
                                                ListTileControlAffinity.leading,
                                            contentPadding: EdgeInsets.zero,
                                            visualDensity:
                                                VisualDensity.compact,
                                            title: Text(
                                              'I agree to the Terms of Service and Privacy Policy.',
                                              style: textTheme.bodySmall,
                                            ),
                                          ),
                                          if (field.errorText != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 12,
                                              ),
                                              child: Text(
                                                field.errorText!,
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: colorScheme.error,
                                                    ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ] else
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _busy
                                            ? null
                                            : _resetPassword,
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
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: _busy ? null : _submit,
                                      child: Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                _busy
                                                    ? 'Please wait…'
                                                    : _isSignUp
                                                    ? 'Create account'
                                                    : 'Sign in',
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward,
                                              size: 18,
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
                          const SizedBox(height: 18),
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  _isSignUp
                                      ? 'Already have an account?'
                                      : "Don't have an account?",
                                  style: textTheme.bodySmall,
                                ),
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _setMode(!_isSignUp),
                                  child: Text(
                                    _isSignUp ? 'Sign in' : 'Create one',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_isSignUp) ...[
                            const SizedBox(height: 32),
                            const _AuthFooter(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Iterable<String>? autofillHints,
    bool autocorrect = true,
    bool obscureText = false,
    Widget? suffix,
  }) => TextFormField(
    key: key,
    controller: controller,
    keyboardType: keyboardType,
    textCapitalization: textCapitalization,
    autofillHints: autofillHints,
    autocorrect: autocorrect,
    obscureText: obscureText,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
    ),
  );
}

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const AppBrandMark(compact: true),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prooffolio',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Your skills. Your work. Your proof.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ],
  );
}

class _AuthFooter extends StatelessWidget {
  const _AuthFooter();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, color: AppColors.slateGray, size: 21),
            SizedBox(width: 16),
            Icon(Icons.code, color: AppColors.slateGray, size: 21),
            SizedBox(width: 16),
            Icon(Icons.work_outline, color: AppColors.slateGray, size: 21),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Build. Showcase. Grow.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class _AuthWavePainter extends CustomPainter {
  const _AuthWavePainter({required this.isSignUp});

  final bool isSignUp;

  @override
  void paint(Canvas canvas, Size size) {
    final navyPaint = Paint()..color = AppColors.deepNavy;
    final tealPaint = Paint()..color = AppColors.teal;
    final tealAccentPaint = Paint()..color = AppColors.tealAccent;
    final waveHeight = size.height * .17;

    final navy = Path();
    if (isSignUp) {
      navy
        ..moveTo(size.width, size.height - waveHeight * .74)
        ..cubicTo(
          size.width * .86,
          size.height - waveHeight * 1.15,
          size.width * .90,
          size.height - waveHeight * .05,
          size.width,
          size.height,
        )
        ..lineTo(size.width, size.height)
        ..close();
    } else {
      navy
        ..moveTo(0, size.height - waveHeight * .85)
        ..cubicTo(
          size.width * .18,
          size.height - waveHeight * 1.15,
          size.width * .18,
          size.height - waveHeight * .05,
          size.width * .48,
          size.height,
        )
        ..lineTo(0, size.height)
        ..close();
    }
    canvas.drawPath(navy, navyPaint);

    final teal = Path();
    if (isSignUp) {
      teal
        ..moveTo(size.width * .62, size.height)
        ..cubicTo(
          size.width * .75,
          size.height - waveHeight * .15,
          size.width * .83,
          size.height - waveHeight * .78,
          size.width,
          size.height - waveHeight * .55,
        )
        ..lineTo(size.width, size.height)
        ..close();
    } else {
      teal
        ..moveTo(0, size.height - waveHeight * .42)
        ..cubicTo(
          size.width * .19,
          size.height - waveHeight * .10,
          size.width * .32,
          size.height - waveHeight * .45,
          size.width * .54,
          size.height - waveHeight * .10,
        )
        ..cubicTo(
          size.width * .66,
          size.height + waveHeight * .03,
          size.width * .68,
          size.height,
          size.width * .72,
          size.height,
        )
        ..lineTo(0, size.height)
        ..close();
    }
    canvas.drawPath(teal, tealPaint);

    final accent = Path();
    if (isSignUp) {
      accent
        ..moveTo(size.width * .70, size.height)
        ..cubicTo(
          size.width * .81,
          size.height - waveHeight * .12,
          size.width * .90,
          size.height - waveHeight * .37,
          size.width,
          size.height - waveHeight * .21,
        )
        ..lineTo(size.width, size.height)
        ..close();
    } else {
      accent
        ..moveTo(size.width * .30, size.height)
        ..cubicTo(
          size.width * .42,
          size.height - waveHeight * .12,
          size.width * .55,
          size.height - waveHeight * .12,
          size.width * .68,
          size.height,
        )
        ..close();
    }
    canvas.drawPath(accent, tealAccentPaint);
  }

  @override
  bool shouldRepaint(covariant _AuthWavePainter oldDelegate) =>
      oldDelegate.isSignUp != isSignUp;
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
      borderRadius: BorderRadius.circular(AppTheme.controlRadius),
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
