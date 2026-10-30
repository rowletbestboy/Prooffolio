import 'package:app_name/features/dashboard/presentation/home_shell.dart';
import 'package:app_name/features/portfolio/data/portfolio_record_repository.dart';
import 'package:app_name/features/portfolio/domain/portfolio_record.dart';
import 'package:app_name/features/portfolio/presentation/portfolio_records_screen.dart';
import 'package:app_name/core/theme/app_colors.dart';
import 'package:app_name/core/theme/app_theme.dart';
import 'package:app_name/core/widgets/app_brand_mark.dart';
import 'package:app_name/core/widgets/app_icon_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('credential editor fits a narrow viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PortfolioRecordsScreen(
          repository: _FakePortfolioRecordRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(AppBrandMark),
      ),
      findsOneWidget,
    );
    final iconTile = tester.widget<AppIconTile>(find.byType(AppIconTile).first);
    expect(iconTile.color, AppColors.indigo);
    expect(iconTile.backgroundColor, AppColors.indigoContainer);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(AlertDialog)).width,
      lessThanOrEqualTo(320),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home opens certifications and achievements without a project', (
    WidgetTester tester,
  ) async {
    final repository = _FakePortfolioRecordRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: HomeShell(portfolioRecordRepository: repository),
      ),
    );
    await tester.pumpAndSettle();

    final credentialsLink = find.bySemanticsLabel('Certifications: 0');
    await tester.ensureVisible(credentialsLink);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Certifications: 0'));
    await tester.pumpAndSettle();

    expect(find.byType(PortfolioRecordsScreen), findsOneWidget);
    expect(find.text('No certifications yet'), findsOneWidget);
  });

  testWidgets('user can add an achievement without a source or project', (
    WidgetTester tester,
  ) async {
    final repository = _FakePortfolioRecordRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PortfolioRecordsScreen(repository: repository),
      ),
    );

    await tester.tap(find.text('Achievements'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(_dialogBackground(tester), AppColors.white);
    final titleDecorator = tester.widget<InputDecorator>(
      find
          .descendant(
            of: find.byKey(const Key('portfolioRecordTitleField')),
            matching: find.byType(InputDecorator),
          )
          .first,
    );
    expect(titleDecorator.decoration.fillColor, AppColors.surfaceSubtle);
    await tester.enterText(
      find.byKey(const Key('portfolioRecordTitleField')),
      'Community garden recognition',
    );
    await tester.tap(find.text('Save achievement'));
    await tester.pumpAndSettle();

    expect(
      repository.records.single.recordType,
      PortfolioRecordType.achievement,
    );
    expect(repository.records.single.title, 'Community garden recognition');
    expect(repository.records.single.source, '');
    expect(repository.records.single.isPublic, isFalse);
    expect(find.text('Community garden recognition'), findsOneWidget);
  });

  testWidgets('user can add and delete a certificate with an expiry date', (
    WidgetTester tester,
  ) async {
    final repository = _FakePortfolioRecordRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PortfolioRecordsScreen(repository: repository),
      ),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('portfolioRecordTitleField')),
      'Food safety certificate',
    );
    await tester.enterText(
      find.byKey(const Key('portfolioRecordExpiresOnField')),
      '2027-06-30',
    );
    await tester.tap(find.text('Save certification'));
    await tester.pumpAndSettle();

    expect(repository.records.single.expiresOn, DateTime.utc(2027, 6, 30));
    expect(find.text('Food safety certificate'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete record'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repository.records, isEmpty);
    expect(repository.listCalls, 3);
    expect(find.text('Food safety certificate'), findsNothing);
  });

  testWidgets('switching record type changes the list and add action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PortfolioRecordsScreen(
          repository: _FakePortfolioRecordRepository(),
        ),
      ),
    );

    await tester.tap(find.text('Achievements'));
    await tester.pumpAndSettle();

    expect(find.text('No achievements yet'), findsOneWidget);
    expect(find.text('Add achievement'), findsNWidgets(2));
  });
}

Color? _dialogBackground(WidgetTester tester) => Theme.of(
  tester.element(find.byType(AlertDialog)),
).dialogTheme.backgroundColor;

class _FakePortfolioRecordRepository implements PortfolioRecordRepository {
  final List<PortfolioRecord> records = [];
  int listCalls = 0;
  int _nextId = 0;

  @override
  Future<List<PortfolioRecord>> listRecords(PortfolioRecordType type) async {
    listCalls++;
    return records.where((record) => record.recordType == type).toList();
  }

  @override
  Future<PortfolioRecord> createRecord(PortfolioRecordDraft draft) async {
    final now = DateTime.utc(2026, 10, 20);
    final record = PortfolioRecord(
      id: 'record-${++_nextId}',
      userId: 'user-1',
      recordType: draft.recordType,
      title: draft.title,
      source: draft.source,
      description: draft.description,
      achievedOn: draft.achievedOn,
      expiresOn: draft.expiresOn,
      isPublic: draft.isPublic,
      createdAt: now,
      updatedAt: now,
    );
    records.add(record);
    return record;
  }

  @override
  Future<PortfolioRecord> updateRecord(
    String id,
    PortfolioRecordDraft draft,
  ) async {
    records.removeWhere((record) => record.id == id);
    return createRecord(draft);
  }

  @override
  Future<void> deleteRecord(String id) async {
    records.removeWhere((record) => record.id == id);
  }
}
