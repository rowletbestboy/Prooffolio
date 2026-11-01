import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_brand_mark.dart';
import '../data/auth_error.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.emailVerificationChanges,
    required this.onResend,
    required this.onCheckVerification,
    required this.onBackToSignIn,
    required this.onSignIn,
  });

  final String email;
  final Stream<bool> emailVerificationChanges;
  final Future<void> Function() onResend;
  final Future<bool> Function() onCheckVerification;
  final Future<void> Function() onBackToSignIn;
  final Future<void> Function() onSignIn;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const _resendCooldown = 60;

  Timer? _cooldownTimer;
  int _secondsUntilResend = 0;
  bool _resending = false;
  bool _checking = false;
  bool _verified = false;
  String? _message;
  String? _error;
  StreamSubscription<bool>? _verificationSubscription;

  @override
  void initState() {
    super.initState();
    _verificationSubscription = widget.emailVerificationChanges.listen((
      verified,
    ) {
      if (!verified || !mounted || _verified) return;
      _cooldownTimer?.cancel();
      setState(() {
        _verified = true;
        _secondsUntilResend = 0;
        _error = null;
        _message = null;
      });
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _verificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    if (_resending || _secondsUntilResend > 0) return;
    setState(() {
      _resending = true;
      _error = null;
      _message = null;
      _secondsUntilResend = _resendCooldown;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsUntilResend--;
        if (_secondsUntilResend <= 0) timer.cancel();
      });
    });
    try {
      await widget.onResend();
      if (!mounted) return;
      setState(() => _message = 'Verification email sent. Check your inbox.');
    } catch (error) {
      logAuthFailure(error, operation: 'resend verification');
      if (mounted) {
        setState(
          () => _error = authErrorMessage(
            error,
            operation: 'resend verification',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _checkVerification() async {
    setState(() {
      _checking = true;
      _error = null;
      _message = null;
    });
    try {
      final verified = await widget.onCheckVerification();
      if (!mounted) return;
      if (verified) {
        _cooldownTimer?.cancel();
        _secondsUntilResend = 0;
      }
      setState(() {
        _verified = verified;
        if (!verified) {
          _error =
              'We could not confirm your email yet. Open the verification link, then try again.';
        }
      });
    } catch (error) {
      logAuthFailure(error, operation: 'check email verification');
      if (mounted) {
        setState(
          () => _error = authErrorMessage(
            error,
            operation: 'check email verification',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      await widget.onSignIn();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      logAuthFailure(error, operation: 'return to sign in');
      if (mounted) {
        setState(() => _error = authErrorMessage(error, operation: 'sign in'));
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _backToSignIn() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      await widget.onBackToSignIn();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      logAuthFailure(error, operation: 'return to sign in');
      if (mounted) {
        setState(
          () =>
              _error = authErrorMessage(error, operation: 'return to sign in'),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gutter = AppTheme.pageGutterFor(MediaQuery.sizeOf(context).width);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to Sign In',
          onPressed: _checking || _resending ? null : _backToSignIn,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              padding: EdgeInsets.fromLTRB(gutter, 32, gutter, 32),
              children: [
                const Center(child: AppBrandMark()),
                const SizedBox(height: 28),
                Icon(
                  _verified
                      ? Icons.mark_email_read_outlined
                      : Icons.mark_email_unread_outlined,
                  size: 52,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  _verified ? 'Email verified!' : 'Verify your email',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _verified
                      ? 'Your account is ready. Sign in to continue.'
                      : "We've sent a verification link to ${widget.email}. Please check your inbox and click the link to activate your Prooffolio account.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (_verified)
                  FilledButton(
                    onPressed: _checking ? null : _signIn,
                    child: const Text('Sign In'),
                  )
                else ...[
                  OutlinedButton(
                    onPressed: _resending || _secondsUntilResend > 0
                        ? null
                        : _resend,
                    child: Text(
                      _resending
                          ? 'Sending…'
                          : _secondsUntilResend > 0
                          ? 'Resend in $_secondsUntilResend sec'
                          : 'Resend verification email',
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _checking ? null : _checkVerification,
                    child: Text(
                      _checking ? 'Checking…' : "I've verified my email",
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _checking || _resending ? null : _backToSignIn,
                    child: const Text('Back to Sign In'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
