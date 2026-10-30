import 'package:app_name/features/dashboard/presentation/home_shell.dart';
import 'package:app_name/core/theme/app_colors.dart';
import 'package:app_name/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Portfolio tab opens a private preview workspace', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const HomeShell()),
    );
    await _tapPortfolioShortcut(tester);
    await tester.pumpAndSettle();

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
    expect(find.text('Portfolio Preview'), findsOneWidget);
    expect(find.text('Nothing public yet'), findsNothing);
    expect(find.text('Private preview'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Private preview')).style?.color,
      AppColors.teal,
    );
    await tester.tap(find.byTooltip('Back to Home'));
    await tester.pumpAndSettle();
    for (final destination in ['Home', 'Projects', 'Skills', 'Portfolio']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(destination),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('Back control returns from Portfolio to Home', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const HomeShell()),
    );
    await _tapPortfolioShortcut(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back to Home'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });
}

Future<void> _tapPortfolioShortcut(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(Icons.public_outlined),
    ),
  );
}
