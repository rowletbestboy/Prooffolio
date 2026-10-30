import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_name/core/theme/app_colors.dart';
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

    await _tapVisible(tester, find.text('Create one'));
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.widgetWithText(FilledButton, 'Create account'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enter your full name'), findsOneWidget);
    expect(find.text('Use 3 to 24 characters'), findsOneWidget);
    expect(
      find.text('Accept the Terms of Service and Privacy Policy'),
      findsOneWidget,
    );
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

    await _tapVisible(tester, find.text('Create one'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('fullNameField')),
      'Avery Student',
    );
    await tester.enterText(
      find.byKey(const Key('usernameField')),
      'avery_student',
    );
    await tester.enterText(find.byKey(const Key('emailField')), 'a@b.com');
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'good-pass-123',
    );
    await tester.enterText(
      find.byKey(const Key('confirmPasswordField')),
      'good-pass-123',
    );
    await _tapVisible(tester, find.byKey(const Key('termsCheckbox')));
    await _tapVisible(
      tester,
      find.widgetWithText(FilledButton, 'Create account'),
    );
    await tester.pumpAndSettle();

    expect(authService.signUpCalls, 1);
    expect(authService.displayName, 'Avery Student');
    expect(authService.username, 'avery_student');
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

    await _tapVisible(tester, find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your display name'), findsOneWidget);
    expect(find.text('Use 3 to 24 characters'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Avery Student');
    await tester.enterText(find.byType(TextFormField).last, 'bad-username');
    await _tapVisible(tester, find.text('Continue'));
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
    await _tapVisible(tester, find.text('Continue'));
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
    await _tapVisible(tester, find.text('Save new password'));
    await tester.pumpAndSettle();

    expect(find.text('Use at least 8 characters'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(updateCalls, 0);
  });

  testWidgets('Prooffolio starts on the Home dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));
    await tester.pumpAndSettle();

    expect(find.text('PORTFOLIO COMPLETION'), findsOneWidget);
    expect(find.text('Welcome to'), findsOneWidget);
    expect(find.text('Prooffolio'), findsOneWidget);
  });

  testWidgets('home content fills the page behind bottom navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));

    expect(
      tester.getSize(find.byType(IndexedStack)).height,
      tester.getSize(find.byKey(const ValueKey('home-shell-body'))).height,
    );
  });

  testWidgets('bottom navigation floats over the page content area', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));

    final body = tester.getRect(find.byKey(const ValueKey('home-shell-body')));
    final pageContent = tester.getRect(find.byType(IndexedStack));
    final navigation = tester.getRect(
      find.byKey(const ValueKey('floating-bottom-navigation')),
    );

    expect(navigation.bottom, lessThan(body.bottom));
    expect(pageContent.bottom, body.bottom);
    expect(pageContent.bottom, greaterThan(navigation.top));
  });

  testWidgets('home scroll content clears the floating navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));
    await tester.pumpAndSettle();

    final listView = tester.widget<ListView>(find.byType(ListView).first);
    final padding = listView.padding! as EdgeInsets;

    expect(padding.bottom, greaterThanOrEqualTo(104));

    await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
    await tester.pumpAndSettle();

    final lastContent = tester.getRect(
      find.text('Your portfolio stays private until you choose what to share.'),
    );
    final navigation = tester.getRect(
      find.byKey(const ValueKey('floating-bottom-navigation')),
    );
    expect(lastContent.bottom, lessThan(navigation.top));
  });

  testWidgets('bottom navigation opens all five primary destinations', (
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
    expect(
      find.descendant(of: navigation, matching: find.text('Profile')),
      findsOneWidget,
    );

    await _tapDestination(tester, Icons.folder_outlined);
    await tester.pumpAndSettle();
    expect(find.text('No projects yet'), findsOneWidget);
    expect(
      (tester
                  .widget<SingleChildScrollView>(
                    find.byType(SingleChildScrollView).first,
                  )
                  .padding!
              as EdgeInsets)
          .bottom,
      greaterThanOrEqualTo(104),
    );

    await _tapDestination(tester, Icons.lightbulb_outline);
    await tester.pumpAndSettle();
    expect(find.text('No skills yet'), findsOneWidget);
    expect(
      (tester
                  .widget<SingleChildScrollView>(
                    find.byType(SingleChildScrollView).first,
                  )
                  .padding!
              as EdgeInsets)
          .bottom,
      greaterThanOrEqualTo(104),
    );

    await _tapDestination(tester, Icons.public_outlined);
    await tester.pumpAndSettle();
    expect(find.text('Portfolio Preview'), findsOneWidget);
    expect(
      (tester.widget<ListView>(find.byType(ListView).first).padding!
              as EdgeInsets)
          .bottom,
      greaterThanOrEqualTo(104),
    );

    await _tapDestination(tester, Icons.person_outline);
    await tester.pumpAndSettle();
    expect(find.text('Your profile is not available'), findsOneWidget);
    expect(
      (tester
                  .widget<SingleChildScrollView>(
                    find.byType(SingleChildScrollView).first,
                  )
                  .padding!
              as EdgeInsets)
          .bottom,
      greaterThanOrEqualTo(104),
    );

    await _tapDestination(tester, Icons.home_outlined);
    await tester.pumpAndSettle();
    expect(find.text('PORTFOLIO COMPLETION'), findsOneWidget);
  });

  testWidgets('bottom navigation is a floating light icon-only capsule', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));

    final floatingBar = tester.widget<Container>(
      find.byKey(const ValueKey('floating-bottom-navigation')),
    );
    final decoration = floatingBar.decoration! as BoxDecoration;
    final navigation = tester.widget<NavigationBar>(find.byType(NavigationBar));

    expect(decoration.color, AppColors.cloudWhite);
    expect(decoration.borderRadius, BorderRadius.circular(28));
    expect(decoration.boxShadow, isNotEmpty);
    expect(
      navigation.labelBehavior,
      NavigationDestinationLabelBehavior.alwaysHide,
    );
    expect(navigation.backgroundColor, Colors.transparent);
    expect(navigation.height, 64);
  });
}

class _FakeAuthService implements AuthService {
  _FakeAuthService({this.result = const AuthActionResult()});

  final AuthActionResult result;
  int signUpCalls = 0;
  String? displayName;
  String? username;

  @override
  Future<AuthActionResult> signIn({
    required String email,
    required String password,
  }) async => result;

  @override
  Future<AuthActionResult> signUp({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    signUpCalls++;
    this.displayName = displayName;
    this.username = username;
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
