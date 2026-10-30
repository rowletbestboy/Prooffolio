import 'package:app_name/core/theme/app_colors.dart';
import 'package:app_name/core/widgets/app_brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('full and compact variants render accessible logo assets', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: [AppBrandMark(), AppBrandMark(compact: true)],
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsNWidgets(2));
      expect(find.bySemanticsLabel('Prooffolio'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('inverse logo has a light backing on a dark surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ColoredBox(
          color: AppColors.deepNavy,
          child: const Center(child: AppBrandMark(inverse: true)),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(Image),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).color == AppColors.white,
        ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
