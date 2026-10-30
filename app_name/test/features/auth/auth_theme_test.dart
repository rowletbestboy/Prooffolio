import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_name/core/theme/app_colors.dart';
import 'package:app_name/core/theme/app_theme.dart';
import 'package:app_name/core/widgets/app_brand_mark.dart';
import 'package:app_name/features/auth/data/auth_service.dart';
import 'package:app_name/features/auth/presentation/auth_screen.dart';
import 'package:app_name/features/auth/presentation/new_password_screen.dart';
import 'package:app_name/features/auth/presentation/supabase_setup_screen.dart';

void main() {
  testWidgets('auth uses the light branded form treatment', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AuthScreen(authService: _FakeAuthService()),
      ),
    );

    expect(find.text('Prooffolio'), findsOneWidget);
    expect(find.text('Your skills. Your work. Your proof.'), findsOneWidget);
    expect(find.byType(AppBrandMark), findsOneWidget);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('passwordField')), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
  });

  testWidgets('registration shows profile fields and no social sign-in', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AuthScreen(authService: _FakeAuthService()),
      ),
    );

    await tester.ensureVisible(find.text('Create one'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create one'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fullNameField')), findsOneWidget);
    expect(find.byKey(const Key('usernameField')), findsOneWidget);
    expect(find.byKey(const Key('termsCheckbox')), findsOneWidget);
    expect(
      find.text('I agree to the Terms of Service and Privacy Policy.'),
      findsOneWidget,
    );
    expect(find.text('Continue with Google'), findsNothing);
  });

  testWidgets('sign-in password can be revealed and hidden', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AuthScreen(authService: _FakeAuthService()),
      ),
    );

    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('passwordField')),
              matching: find.byType(EditableText),
            ),
          )
          .obscureText,
      isTrue,
    );
    expect(find.byTooltip('Show password'), findsOneWidget);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('passwordField')),
              matching: find.byType(EditableText),
            ),
          )
          .obscureText,
      isFalse,
    );
    await tester.tap(find.byTooltip('Hide password'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('passwordField')),
              matching: find.byType(EditableText),
            ),
          )
          .obscureText,
      isTrue,
    );
  });

  testWidgets('new-password form uses the shared branded card treatment', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: NewPasswordScreen(onUpdate: (_) async {}, onComplete: () {}),
      ),
    );

    expect(_themeCard, findsOneWidget);
    expect(find.byType(AppBrandMark), findsOneWidget);
    expect(find.byKey(const Key('newPasswordField')), findsOneWidget);
    expect(find.byKey(const Key('confirmNewPasswordField')), findsOneWidget);
    expect(find.text('Save new password'), findsOneWidget);
  });

  testWidgets('Supabase setup uses the shared branded card treatment', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const SupabaseSetupScreen()),
    );

    expect(_themeCard, findsOneWidget);
    expect(find.byType(AppBrandMark), findsOneWidget);
    expect(find.text('Connect your Supabase project'), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL'), findsOneWidget);
  });

  testWidgets('auth remains scrollable and exception-free at 320 dp', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AuthScreen(authService: _FakeAuthService()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('registration remains scrollable and exception-free at 320 dp', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AuthScreen(authService: _FakeAuthService()),
      ),
    );
    await tester.tap(find.text('Create one'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Create account'),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('auth CTA arrow does not overlap its label at large text size', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: AuthScreen(authService: _FakeAuthService()),
      ),
    );

    void expectCtaLabelAndArrowDoNotOverlap(String label) {
      final button = find.widgetWithText(FilledButton, label);
      final labelRect = tester.getRect(
        find.descendant(of: button, matching: find.text(label)),
      );
      final arrowRect = tester.getRect(
        find.descendant(of: button, matching: find.byIcon(Icons.arrow_forward)),
      );
      expect(labelRect.overlaps(arrowRect), isFalse);
    }

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
    expectCtaLabelAndArrowDoNotOverlap('Sign in');

    await tester.ensureVisible(find.text('Create one'));
    await tester.tap(find.text('Create one'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Create account'),
    );
    expectCtaLabelAndArrowDoNotOverlap('Create account');
  });
}

Finder get _themeCard => find.byWidgetPredicate((widget) {
  if (widget is! Container || widget.decoration is! BoxDecoration) {
    return false;
  }
  final decoration = widget.decoration! as BoxDecoration;
  return decoration.color == AppColors.white &&
      decoration.border == Border.all(color: AppColors.lightSlate) &&
      decoration.borderRadius == BorderRadius.circular(AppTheme.cardRadius);
});

class _FakeAuthService implements AuthService {
  @override
  Future<AuthActionResult> signIn({
    required String email,
    required String password,
  }) async => const AuthActionResult();

  @override
  Future<AuthActionResult> signUp({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async => const AuthActionResult();

  @override
  Future<void> resetPassword({required String email}) async {}
}
