import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String authErrorMessage(Object error, {required String operation}) {
  final message = error is AuthException ? error.message.toLowerCase() : '';
  final code = error is AuthException ? error.code?.toLowerCase() : null;

  if (code == 'email_not_confirmed' ||
      message.contains('email not confirmed') ||
      message.contains('email_not_confirmed')) {
    return 'Verify your email address before signing in. Check your inbox for the confirmation link.';
  }
  if (code == 'email_exists' ||
      code == 'user_already_exists' ||
      message.contains('already registered') ||
      message.contains('already exists')) {
    return 'That email is already registered. Try signing in instead.';
  }
  if (code == 'weak_password' ||
      error is AuthWeakPasswordException ||
      message.contains('password') && message.contains('weak')) {
    return 'Choose a stronger password and try again.';
  }
  if (code == 'invalid_email' ||
      message.contains('invalid email') ||
      message.contains('email address is invalid') ||
      message.contains('email') && message.contains('invalid')) {
    return 'Enter a valid email address.';
  }
  if (code == 'invalid_credentials' ||
      message.contains('invalid login credentials')) {
    return 'That email and password combination was not recognized.';
  }
  if (code == 'redirect_to_url_not_allowed' ||
      message.contains('redirect') && message.contains('not allowed')) {
    return 'Email verification could not be started. Please contact support.';
  }
  if (error is SocketException ||
      error is TimeoutException ||
      message.contains('network') ||
      message.contains('socket')) {
    return 'Could not connect. Check your internet and try again.';
  }

  return switch (operation) {
    'sign up' =>
      'We could not create your account. Check your details and try again.',
    'resend verification' =>
      'We could not resend the verification email. Please try again later.',
    _ => 'We could not complete that request. Please try again.',
  };
}

void logAuthFailure(Object error, {required String operation}) {
  if (!kDebugMode) return;

  final diagnostic = switch (error) {
    AuthException(:final message, :final statusCode, :final code) =>
      'type=${error.runtimeType}, status=${statusCode ?? 'none'}, '
          'code=${_redact(code ?? 'none')}, message=${_redact(message)}',
    _ => 'type=${error.runtimeType}, message=${_redact(error.toString())}',
  };
  debugPrint('[auth] $operation failed: $diagnostic');
}

String _redact(String value) => value
    .replaceAll(RegExp(r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}'), '[email redacted]')
    .replaceAll(
      RegExp(r'\b[a-zA-Z][a-zA-Z0-9+.-]*://[^\s)]+'),
      '[url redacted]',
    )
    .replaceAll(
      RegExp(r'bearer\s+[A-Za-z0-9._~+/-]+=*', caseSensitive: false),
      'Bearer [redacted]',
    )
    .replaceAll(
      RegExp(
        r'(access_token|refresh_token|token|password|secret|api_key|publishable_key|service_role_key)\s*[:=]\s*[^&,\s]+',
        caseSensitive: false,
      ),
      '[credential redacted]',
    );
