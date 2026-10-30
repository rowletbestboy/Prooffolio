import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_name/core/theme/app_colors.dart';
import 'package:app_name/core/theme/app_theme.dart';
import 'package:app_name/core/widgets/app_brand_mark.dart';
import 'package:app_name/features/profile/data/profile_repository.dart';
import 'package:app_name/features/profile/presentation/profile_setup_screen.dart';

void main() {
  testWidgets(
    'profile setup uses shared branding and card treatment at 320 dp',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ProfileSetupScreen(
            repository: _FakeProfileRepository(),
            onComplete: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBrandMark), findsOneWidget);
      expect(_themeCard, findsOneWidget);
      expect(find.text('Display name'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      await tester.ensureVisible(find.text('Continue'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('profile setup pre-fills details collected during sign-up', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ProfileSetupScreen(
          repository: _FakeProfileRepository(),
          onComplete: () {},
          initialDisplayName: 'Avery Student',
          initialUsername: 'avery_student',
        ),
      ),
    );

    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).first).controller!.text,
      'Avery Student',
    );
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).last).controller!.text,
      'avery_student',
    );
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

class _FakeProfileRepository implements ProfileRepository {
  @override
  Future<bool> hasProfile(String userId) async => false;

  @override
  Future<void> saveProfile({
    required String displayName,
    required String username,
  }) async {}
}
