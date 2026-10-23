import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_name/features/auth/data/auth_service.dart';
import 'package:app_name/features/auth/presentation/auth_screen.dart';
import 'package:app_name/features/auth/presentation/new_password_screen.dart';
import 'package:app_name/features/dashboard/presentation/home_shell.dart';
import 'package:app_name/features/profile/data/profile_repository.dart';
import 'package:app_name/features/profile/presentation/profile_setup_screen.dart';
import 'package:app_name/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('unconfigured app explains how to connect Supabase', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProoffolioApp());

    expect(find.text('Connect your Supabase project'), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL'), findsOneWidget);
  });

  testWidgets('sign-up validates email and matching password confirmation', (
    WidgetTester tester,
  ) async {
    final authService = _FakeAuthService();
    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(authService: authService)),
    );

    await _tapVisible(tester, find.text('New to Prooffolio? Create account'));
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.widgetWithText(FilledButton, 'Create account'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(
      find.text('Enter a password of at least 8 characters'),
      findsOneWidget,
    );
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(authService.signUpCalls, 0);
  });

  testWidgets('shows email confirmation guidance after successful sign-up', (
    WidgetTester tester,
  ) async {
    final authService = _FakeAuthService(
      result: const AuthActionResult(emailConfirmationRequired: true),
    );
    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(authService: authService)),
    );

    await _tapVisible(tester, find.text('New to Prooffolio? Create account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('emailField')), 'a@b.com');
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'good-pass-123',
    );
    await tester.enterText(
      find.byKey(const Key('confirmPasswordField')),
      'good-pass-123',
    );
    await _tapVisible(
      tester,
      find.widgetWithText(FilledButton, 'Create account'),
    );
    await tester.pumpAndSettle();

    expect(authService.signUpCalls, 1);
    expect(find.textContaining('Check your inbox'), findsOneWidget);
  });

  testWidgets('profile setup requires a display name and valid username', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileSetupScreen(
          repository: _FakeProfileRepository(),
          onComplete: () {},
        ),
      ),
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your display name'), findsOneWidget);
    expect(find.text('Use 3 to 24 characters'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Avery Student');
    await tester.enterText(find.byType(TextFormField).last, 'bad-username');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(
      find.text('Use letters, numbers, and underscores only'),
      findsOneWidget,
    );
  });

  testWidgets('profile setup explains when the profiles migration is missing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileSetupScreen(
          repository: _FakeProfileRepository(
            saveError: const PostgrestException(
              message: 'relation public.profiles does not exist',
              code: '42P01',
            ),
          ),
          onComplete: () {},
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'Avery Student');
    await tester.enterText(find.byType(TextFormField).last, 'avery_student');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.textContaining('profiles migration'), findsOneWidget);
  });

  testWidgets('new password screen requires matching secure passwords', (
    WidgetTester tester,
  ) async {
    var updateCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: NewPasswordScreen(
          onUpdate: (_) async => updateCalls++,
          onComplete: () {},
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('newPasswordField')), 'short');
    await tester.enterText(
      find.byKey(const Key('confirmNewPasswordField')),
      'different',
    );
    await tester.tap(find.text('Save new password'));
    await tester.pumpAndSettle();

    expect(find.text('Use at least 8 characters'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(updateCalls, 0);
  });

  testWidgets('Prooffolio starts on the progress Home destination', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));

    expect(find.text('Your progress'), findsOneWidget);
    expect(
      find.text('Build a clear picture of your work, one piece at a time.'),
      findsOneWidget,
    );
  });

  testWidgets('bottom navigation opens all four first-run destinations', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));

    final navigation = find.byType(NavigationBar);
    expect(
      find.descendant(of: navigation, matching: find.text('Home')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navigation, matching: find.text('Projects')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navigation, matching: find.text('Skills')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navigation, matching: find.text('Portfolio')),
      findsOneWidget,
    );

    await _tapDestination(tester, Icons.folder_outlined);
    await tester.pumpAndSettle();
    expect(find.text('No projects yet'), findsOneWidget);

    await _tapDestination(tester, Icons.lightbulb_outline);
    await tester.pumpAndSettle();
    expect(find.text('No skills yet'), findsOneWidget);

    await _tapDestination(tester, Icons.public_outlined);
    await tester.pumpAndSettle();
    expect(find.text('Your private portfolio'), findsOneWidget);
    expect(find.text('Private preview'), findsOneWidget);
    final portfolioIntro = find.text(
      'Review how your saved work comes together. Nothing here is public unless you choose to publish it later.',
    );
    await tester.scrollUntilVisible(
      portfolioIntro,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(portfolioIntro, findsOneWidget);
    final savedWorkMessage = find.text(
      'Your saved profile and work will appear here.',
    );
    await tester.scrollUntilVisible(
      savedWorkMessage,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(savedWorkMessage, findsOneWidget);

    await _tapDestination(tester, Icons.home_outlined);
    await tester.pumpAndSettle();
    expect(find.text('Your progress'), findsOneWidget);
  });
}

class _FakeAuthService implements AuthService {
  _FakeAuthService({this.result = const AuthActionResult()});

  final AuthActionResult result;
  int signUpCalls = 0;

  @override
  Future<AuthActionResult> signIn({
    required String email,
    required String password,
  }) async => result;

  @override
  Future<AuthActionResult> signUp({
    required String email,
    required String password,
  }) async {
    signUpCalls++;
    return result;
  }

  @override
  Future<void> resetPassword({required String email}) async {}
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository({this.saveError});

  final Object? saveError;

  @override
  Future<bool> hasProfile(String userId) async => false;

  @override
  Future<void> saveProfile({
    required String displayName,
    required String username,
  }) async {
    if (saveError case final error?) throw error;
  }
}

Future<void> _tapDestination(WidgetTester tester, IconData icon) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(icon),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
}
