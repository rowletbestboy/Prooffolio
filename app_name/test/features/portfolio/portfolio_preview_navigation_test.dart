import 'package:app_name/features/dashboard/presentation/home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Portfolio destination opens a private preview workspace', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));
    await tester.tap(find.text('Portfolio').last);
    await tester.pumpAndSettle();

    expect(find.text('Your private portfolio'), findsOneWidget);
    expect(find.text('Nothing public yet'), findsNothing);
    expect(find.text('Private preview'), findsOneWidget);
  });
}
