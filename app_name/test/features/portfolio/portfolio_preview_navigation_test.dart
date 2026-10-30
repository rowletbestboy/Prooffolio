import 'package:app_name/features/dashboard/presentation/home_shell.dart';
import 'package:app_name/core/theme/app_colors.dart';
import 'package:app_name/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Portfolio destination opens a private preview workspace', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const HomeShell()),
    );
    await tester.tap(find.text('Portfolio').last);
    await tester.pumpAndSettle();

    expect(find.text('Portfolio Preview'), findsOneWidget);
    expect(find.text('Nothing public yet'), findsNothing);
    expect(find.text('Private preview'), findsOneWidget);
    for (final destination in ['Home', 'Projects', 'Skills', 'Portfolio']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(destination),
        ),
        findsOneWidget,
      );
    }
    expect(
      tester.widget<Text>(find.text('Private preview')).style?.color,
      AppColors.teal,
    );
  });

  testWidgets('Back control returns from Portfolio to Home', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const HomeShell()),
    );
    await tester.tap(find.text('Portfolio').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back to Home'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });
}
