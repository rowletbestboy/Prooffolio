import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_name/core/theme/app_colors.dart';
import 'package:app_name/core/theme/app_theme.dart';
import 'package:app_name/core/widgets/app_brand_mark.dart';
import 'package:app_name/core/widgets/app_icon_tile.dart';
import 'package:app_name/features/evidence/data/evidence_repository.dart';
import 'package:app_name/features/evidence/domain/evidence.dart';
import 'package:app_name/features/evidence/presentation/evidence_library_screen.dart';
import 'package:app_name/features/dashboard/presentation/home_shell.dart';

void main() {
  testWidgets('Evidence editor fits a narrow viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(_FakeEvidenceRepository()));
    await tester.pumpAndSettle();
    final layoutError = tester.takeException();
    expect(layoutError, isNull);
    expect(find.text('Evidence library'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(AppBrandMark),
      ),
      findsOneWidget,
    );
    expect(find.text('No evidence added yet'), findsOneWidget);
    final iconTile = tester.widget<AppIconTile>(find.byType(AppIconTile).first);
    expect(iconTile.color, AppColors.teal);
    expect(iconTile.backgroundColor, AppColors.tealContainer);
    await tester.tap(find.byKey(const Key('evidenceAddButton')));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(AlertDialog)).width,
      lessThanOrEqualTo(320),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home opens the Evidence library', (WidgetTester tester) async {
    final repository = _FakeEvidenceRepository();
    await tester.pumpWidget(
      MaterialApp(home: HomeShell(evidenceRepository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Evidence'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Evidence'));
    await tester.pumpAndSettle();

    expect(find.text('Evidence library'), findsOneWidget);
  });

  testWidgets('user can add URL evidence and link it to a portfolio record', (
    WidgetTester tester,
  ) async {
    final repository = _FakeEvidenceRepository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('evidenceAddButton')));
    await tester.pumpAndSettle();
    expect(_dialogBackground(tester), AppColors.white);
    final titleDecorator = tester.widget<InputDecorator>(
      find
          .descendant(
            of: find.byKey(const Key('evidenceTitleField')),
            matching: find.byType(InputDecorator),
          )
          .first,
    );
    expect(titleDecorator.decoration.fillColor, AppColors.surfaceSubtle);
    await tester.enterText(
      find.byKey(const Key('evidenceTitleField')),
      'Food safety certificate',
    );
    await tester.enterText(
      find.byKey(const Key('evidenceUrlField')),
      'https://example.org/certificate',
    );
    final certificateTarget = find.byKey(
      const Key('evidenceTarget-portfolio_record-cert-1'),
    );
    await tester.scrollUntilVisible(
      certificateTarget,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(certificateTarget);
    await tester.tap(find.text('Save evidence'));
    await tester.pumpAndSettle();

    expect(repository.records.single.title, 'Food safety certificate');
    expect(repository.records.single.targets.single.id, 'cert-1');
    expect(find.text('Food safety certificate'), findsOneWidget);
  });

  testWidgets('user can upload a supported file linked to a project', (
    WidgetTester tester,
  ) async {
    final repository = _FakeEvidenceRepository();
    final picker = _FakeEvidenceFilePicker(
      PickedEvidenceFile(
        name: 'garden.png',
        mimeType: 'image/png',
        length: 3,
        readBytes: () async => Uint8List.fromList([1, 2, 3]),
      ),
    );
    await tester.pumpWidget(_app(repository, picker: picker));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('evidenceAddButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('File'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('evidenceChooseFileButton')));
    await tester.pumpAndSettle();
    final projectTarget = find.byKey(
      const Key('evidenceTarget-project-project-1'),
    );
    await tester.scrollUntilVisible(
      projectTarget,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(projectTarget);
    await tester.tap(find.text('Save evidence'));
    await tester.pumpAndSettle();

    expect(repository.records.single.kind, EvidenceKind.file);
    expect(repository.records.single.fileName, 'garden.png');
    expect(repository.records.single.targets.single.id, 'project-1');
    expect(repository.uploadCount, 1);
  });

  testWidgets('URL evidence requires a title and a valid HTTP(S) URL', (
    WidgetTester tester,
  ) async {
    final repository = _FakeEvidenceRepository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('evidenceAddButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save evidence'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a title for this evidence.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('evidenceTitleField')),
      'Garden photos',
    );
    await tester.enterText(
      find.byKey(const Key('evidenceUrlField')),
      'javascript:alert(1)',
    );
    await tester.tap(find.text('Save evidence'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter a valid link that starts with http:// or https://.'),
      findsOneWidget,
    );
    expect(repository.records, isEmpty);
  });

  testWidgets('unsupported files are rejected before upload', (
    WidgetTester tester,
  ) async {
    final repository = _FakeEvidenceRepository();
    final picker = _FakeEvidenceFilePicker(
      PickedEvidenceFile(
        name: 'installer.exe',
        mimeType: 'application/octet-stream',
        length: 3,
        readBytes: () async => Uint8List.fromList([1, 2, 3]),
      ),
    );
    await tester.pumpWidget(_app(repository, picker: picker));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('evidenceAddButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('File'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('evidenceChooseFileButton')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This file type is not supported. Choose a supported image, document, video, or audio file.',
      ),
      findsOneWidget,
    );
    expect(repository.uploadCount, 0);
  });

  testWidgets('deleting evidence requires confirmation', (
    WidgetTester tester,
  ) async {
    final repository = _FakeEvidenceRepository()..records.add(_urlRecord());
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete evidence'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this evidence?'), findsOneWidget);
    expect(_dialogBackground(tester), AppColors.white);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.records, hasLength(1));

    await tester.tap(find.byTooltip('Delete evidence'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(repository.records, isEmpty);
  });
}

Widget _app(
  _FakeEvidenceRepository repository, {
  _FakeEvidenceFilePicker? picker,
}) => MaterialApp(
  theme: AppTheme.light,
  home: EvidenceLibraryScreen(
    repository: repository,
    filePicker: picker ?? _FakeEvidenceFilePicker(null),
  ),
);

Color? _dialogBackground(WidgetTester tester) => Theme.of(
  tester.element(find.byType(AlertDialog)),
).dialogTheme.backgroundColor;

EvidenceRecord _urlRecord() => EvidenceRecord(
  id: 'url-1',
  userId: 'user-1',
  kind: EvidenceKind.url,
  title: 'Garden article',
  description: '',
  sourceUrl: 'https://example.org/garden',
  createdAt: DateTime.utc(2026, 10, 21),
  updatedAt: DateTime.utc(2026, 10, 21),
);

class _FakeEvidenceRepository implements EvidenceRepository {
  final List<EvidenceRecord> records = [];
  int uploadCount = 0;

  final List<EvidenceTarget> targets = const [
    EvidenceTarget(
      type: EvidenceTargetType.project,
      id: 'project-1',
      title: 'Community garden',
    ),
    EvidenceTarget(
      type: EvidenceTargetType.portfolioRecord,
      id: 'cert-1',
      title: 'Food safety certificate',
    ),
  ];

  @override
  Future<EvidenceRecord> addUrl({
    required String title,
    required String sourceUrl,
    String description = '',
    List<EvidenceTarget> targets = const [],
  }) async {
    final record = EvidenceRecord(
      id: 'url-${records.length + 1}',
      userId: 'user-1',
      kind: EvidenceKind.url,
      title: title,
      description: description,
      sourceUrl: sourceUrl,
      targets: targets,
      createdAt: DateTime.utc(2026, 10, 21),
      updatedAt: DateTime.utc(2026, 10, 21),
    );
    records.insert(0, record);
    return record;
  }

  @override
  Future<void> deleteEvidence(EvidenceRecord record) async {
    records.removeWhere((item) => item.id == record.id);
  }

  @override
  Future<List<EvidenceRecord>> listEvidence() async => List.of(records);

  @override
  Future<List<EvidenceTarget>> listTargets() async => targets;

  @override
  Future<String> openUrl(EvidenceRecord record) async =>
      record.sourceUrl ?? 'https://storage.example/file';

  @override
  Future<EvidenceRecord> uploadFile({
    required String title,
    required String fileName,
    required String? mimeType,
    required Uint8List bytes,
    String description = '',
    List<EvidenceTarget> targets = const [],
  }) async {
    uploadCount++;
    final record = EvidenceRecord(
      id: 'file-${records.length + 1}',
      userId: 'user-1',
      kind: EvidenceKind.file,
      title: title,
      description: description,
      fileName: fileName,
      contentType: mimeType,
      sizeBytes: bytes.length,
      storagePath: 'user-1/$fileName',
      targets: targets,
      createdAt: DateTime.utc(2026, 10, 21),
      updatedAt: DateTime.utc(2026, 10, 21),
    );
    records.insert(0, record);
    return record;
  }
}

class _FakeEvidenceFilePicker implements EvidenceFilePicker {
  _FakeEvidenceFilePicker(this.file);

  final PickedEvidenceFile? file;

  @override
  Future<PickedEvidenceFile?> pickFile() async => file;
}
