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
  testWidgets('auth uses the shared navy hero and card treatment', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AuthScreen(authService: _FakeAuthService()),
      ),
    );

    final hero = find.byWidgetPredicate((widget) {
      if (widget is! Container || widget.decoration is! BoxDecoration) {
        return false;
      }
      final decoration = widget.decoration! as BoxDecoration;
      return decoration.color == AppColors.deepNavy &&
          decoration.borderRadius == BorderRadius.circular(AppTheme.cardRadius);
    });

    expect(hero, findsOneWidget);
    expect(_themeCard, findsOneWidget);
    expect(find.byType(AppBrandMark), findsOneWidget);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('passwordField')), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
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
  }) async => const AuthActionResult();

  @override
  Future<void> resetPassword({required String email}) async {}
}
