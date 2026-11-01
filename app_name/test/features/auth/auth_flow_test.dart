import 'dart:async';
import 'dart:io';

import 'package:app_name/features/auth/data/auth_error.dart';
import 'package:app_name/features/auth/data/auth_service.dart';
import 'package:app_name/features/auth/presentation/auth_screen.dart';
import 'package:app_name/features/auth/presentation/email_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('authentication failures have actionable friendly messages', () {
    expect(
      authErrorMessage(
        const AuthException('invalid format', code: 'invalid_email'),
        operation: 'sign up',
      ),
      'Enter a valid email address.',
    );
    expect(
      authErrorMessage(
        AuthWeakPasswordException(
          message: 'Weak password',
          statusCode: '422',
          reasons: const ['password needs more characters'],
        ),
        operation: 'sign up',
      ),
      'Choose a stronger password and try again.',
    );
    expect(
      authErrorMessage(
        const AuthException('unverified', code: 'email_not_confirmed'),
        operation: 'sign in',
      ),
      'Verify your email address before signing in. Check your inbox for the confirmation link.',
    );
  });

  test(
    'development diagnostics redact credentials and personally identifying data',
    () {
      final previousDebugPrint = debugPrint;
      final lines = <String>[];
      debugPrint = (message, {wrapWidth}) {
        if (message != null) lines.add(message);
      };
      try {
        logAuthFailure(
          const AuthException(
            'alex@example.test password=do-not-log token=do-not-log '
            'com.prooffolio.app://login-callback/?access_token=do-not-log',
            statusCode: '422',
            code: 'invalid_email',
          ),
          operation: 'sign up',
        );
      } finally {
        debugPrint = previousDebugPrint;
      }

      final logLine = lines.join();
      expect(logLine, contains('status=422'));
      expect(logLine, contains('code=invalid_email'));
      expect(logLine, isNot(contains('alex@example.test')));
      expect(logLine, isNot(contains('do-not-log')));
      expect(logLine, contains('[email redacted]'));
      expect(logLine, contains('[url redacted]'));
    },
  );

  testWidgets('successful signup opens email verification instructions', (
    tester,
  ) async {
    final service = _FakeAuthService();
    addTearDown(service.verificationChanges.close);
    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(authService: service)),
    );

    await tester.ensureVisible(find.text('Create one'));
    await tester.tap(find.text('Create one'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('fullNameField')),
      'Alex Rivera',
    );
    await tester.enterText(
      find.byKey(const Key('usernameField')),
      'alexrivera',
    );
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'alex@example.test',
    );
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'A-secure-password-123',
    );
    await tester.enterText(
      find.byKey(const Key('confirmPasswordField')),
      'A-secure-password-123',
    );
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Create account'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(service.signUpCalls, 1);
    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.textContaining('alex@example.test'), findsOneWidget);
    expect(find.text('Resend verification email'), findsOneWidget);
    expect(find.text("I've verified my email"), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Back to Sign In'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Back to Sign In'), findsOneWidget);
    service.verificationChanges.add(true);
    await tester.pump();
    expect(find.text('Email verified!'), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign In'));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email verified!'), findsNothing);
    expect(service.signOutCalls, 1);
  });

  testWidgets('signup errors show specific friendly messages', (tester) async {
    final service = _FakeAuthService(
      signUpError: const AuthException(
        'User already registered',
        code: 'user_already_exists',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(authService: service)),
    );
    await _fillAndSubmitSignup(tester);

    expect(
      find.text('That email is already registered. Try signing in instead.'),
      findsOneWidget,
    );
    expect(service.signUpCalls, 1);
  });

  testWidgets('invalid signup fields fail locally without calling Supabase', (
    tester,
  ) async {
    final service = _FakeAuthService();
    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(authService: service)),
    );
    await tester.ensureVisible(find.text('Create one'));
    await tester.tap(find.text('Create one'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('emailField')), 'not-an-email');
    await tester.enterText(find.byKey(const Key('passwordField')), 'short');
    await tester.enterText(
      find.byKey(const Key('confirmPasswordField')),
      'different',
    );
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Create account'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(
      find.text('Enter a password of at least 8 characters'),
      findsOneWidget,
    );
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(service.signUpCalls, 0);
  });

  testWidgets('network signup errors explain the connection problem', (
    tester,
  ) async {
    final service = _FakeAuthService(
      signUpError: const SocketException('network unreachable'),
    );
    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(authService: service)),
    );
    await _fillAndSubmitSignup(tester);

    expect(
      find.text('Could not connect. Check your internet and try again.'),
      findsOneWidget,
    );
  });

  testWidgets('unverified sign-in shows an email verification message', (
    tester,
  ) async {
    final service = _FakeAuthService(
      signInError: const AuthException(
        'Email not confirmed',
        code: 'email_not_confirmed',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(authService: service)),
    );
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'alex@example.test',
    );
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'A-secure-password-123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Verify your email address before signing in.'),
      findsOneWidget,
    );
  });

  testWidgets('verification screen rate limits resend and confirms email', (
    tester,
  ) async {
    var resendCalls = 0;
    var verified = false;
    await tester.pumpWidget(
      MaterialApp(
        home: EmailVerificationScreen(
          email: 'alex@example.test',
          emailVerificationChanges: const Stream<bool>.empty(),
          onResend: () async => resendCalls++,
          onCheckVerification: () async => verified,
          onBackToSignIn: () async {},
          onSignIn: () async {},
        ),
      ),
    );

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.textContaining('alex@example.test'), findsOneWidget);
    await tester.tap(find.text('Resend verification email'));
    await tester.pump();
    expect(resendCalls, 1);
    expect(find.text('Resend in 60 sec'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );

    verified = true;
    await tester.scrollUntilVisible(
      find.text("I've verified my email"),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text("I've verified my email"));
    await tester.pumpAndSettle();
    expect(find.text('Email verified!'), findsOneWidget);
    expect(
      find.text('Your account is ready. Sign in to continue.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Sign In'), findsOneWidget);
  });
}

Future<void> _fillAndSubmitSignup(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Create one'));
  await tester.tap(find.text('Create one'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('fullNameField')), 'Alex Rivera');
  await tester.enterText(find.byKey(const Key('usernameField')), 'alexrivera');
  await tester.enterText(
    find.byKey(const Key('emailField')),
    'alex@example.test',
  );
  await tester.enterText(
    find.byKey(const Key('passwordField')),
    'A-secure-password-123',
  );
  await tester.enterText(
    find.byKey(const Key('confirmPasswordField')),
    'A-secure-password-123',
  );
  await tester.ensureVisible(find.byType(CheckboxListTile));
  await tester.tap(find.byType(CheckboxListTile));
  await tester.pumpAndSettle();
  await tester.ensureVisible(
    find.widgetWithText(FilledButton, 'Create account'),
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
  await tester.pumpAndSettle();
}

class _FakeAuthService implements AuthService {
  _FakeAuthService({this.signUpError, this.signInError});

  int signUpCalls = 0;
  int signOutCalls = 0;
  bool emailVerified = false;
  final verificationChanges = StreamController<bool>.broadcast();
  final Object? signUpError;
  final Object? signInError;

  @override
  Future<AuthActionResult> signIn({
    required String email,
    required String password,
  }) async {
    if (signInError case final error?) throw error;
    return const AuthActionResult();
  }

  @override
  Future<AuthActionResult> signUp({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    signUpCalls++;
    if (signUpError case final error?) throw error;
    return const AuthActionResult(emailConfirmationRequired: true);
  }

  @override
  Future<void> resetPassword({required String email}) async {}

  @override
  Future<void> resendSignupVerification({required String email}) async {}

  @override
  bool get currentUserEmailVerified => emailVerified;

  @override
  Stream<bool> get emailVerificationChanges => verificationChanges.stream;

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}
