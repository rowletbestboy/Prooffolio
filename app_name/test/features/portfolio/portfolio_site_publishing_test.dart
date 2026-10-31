import 'package:app_name/features/portfolio/data/portfolio_site_generator.dart';
import 'package:app_name/features/portfolio/data/portfolio_publication_repository.dart';
import 'package:app_name/features/portfolio/domain/portfolio_content.dart';
import 'package:app_name/features/portfolio/domain/portfolio_template.dart';
import 'package:app_name/features/portfolio/presentation/portfolio_site_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _baseUrl = 'https://portfolio.example.test';

void main() {
  testWidgets(
    'publishing requires review confirmation and uses all default selections',
    (tester) async {
      _setLargeViewport(tester);
      final repository = _FakePublicationRepository();
      await _preparePortfolioTemplate(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: PortfolioSitePreview(
            content: _content,
            userId: 'owner-id',
            publicationRepository: repository,
            previewBuilder: (context, html) => Text(html),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _waitForPortfolioGeneration(tester);

      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile).first)
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Email'),
            )
            .value,
        isTrue,
      );
      await tester.tap(find.text('Publish Portfolio'));
      await tester.pumpAndSettle();

      expect(repository.publishCalls, 0);
      expect(find.textContaining('will be public'), findsOneWidget);
      expect(find.textContaining('alex_doe/'), findsOneWidget);
      final dialogRect = tester.getRect(find.byType(AlertDialog));
      expect(
        tester.getCenter(find.text('Review again')).dx,
        closeTo(dialogRect.center.dx, 1),
      );
      await tester.tap(find.text('Publish now'));
      await tester.pumpAndSettle();

      expect(repository.publishCalls, 1);
      expect(repository.publishedSelection?.includeDisplayName, isTrue);
      expect(repository.publishedSelection?.includeEmail, isTrue);
      expect(repository.publishedSelection?.projectIds, {'project-id'});
      expect(find.textContaining('alex_doe/'), findsOneWidget);
    },
  );

  testWidgets(
    'published snapshot restores its selection and requires confirmation to unpublish',
    (tester) async {
      _setLargeViewport(tester);
      final repository = _FakePublicationRepository(status: _activePublication);
      await _preparePortfolioTemplate(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: PortfolioSitePreview(
            content: _content,
            userId: 'owner-id',
            publicationRepository: repository,
            previewBuilder: (context, html) => Text(html),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _waitForPortfolioGeneration(tester);

      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile).first)
            .value,
        isTrue,
      );
      expect(find.text('Update published website'), findsOneWidget);
      expect(find.textContaining('alex_doe/'), findsOneWidget);

      await tester.tap(find.text('Update published website'));
      await tester.pumpAndSettle();
      expect(repository.updateCalls, 0);
      expect(find.textContaining('will be public'), findsOneWidget);
      await tester.tap(find.text('Update now'));
      await tester.pumpAndSettle();
      expect(repository.updateCalls, 1);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Website updated.'), findsOneWidget);

      await tester.tap(find.text('Unpublish website'));
      await tester.pumpAndSettle();
      expect(repository.unpublishCalls, 0);
      expect(
        find.textContaining('Copies or cached versions may persist'),
        findsOneWidget,
      );
      await tester.tap(find.text('Confirm unpublish'));
      await tester.pumpAndSettle();

      expect(repository.unpublishCalls, 1);
      expect(find.text('Publish Portfolio'), findsOneWidget);
    },
  );

  testWidgets('failed updates leave a visible error message', (tester) async {
    _setLargeViewport(tester);
    final repository = _FakePublicationRepository(
      status: _activePublication,
      updateError: StateError('Storage rejected upload'),
    );
    await _preparePortfolioTemplate(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: PortfolioSitePreview(
          content: _content,
          userId: 'owner-id',
          publicationRepository: repository,
          previewBuilder: (context, html) => Text(html),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _waitForPortfolioGeneration(tester);

    await tester.tap(find.text('Update published website'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update now'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'Website could not be published: Bad state: Storage rejected upload',
      ),
      findsOneWidget,
    );
  });
}

void _setLargeViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 5000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _preparePortfolioTemplate(WidgetTester tester) async {
  await tester.runAsync(
    () => PortfolioSiteGenerator.generate(
      _content,
      PortfolioSelection.allFrom(_content),
      PortfolioTemplate.light,
    ),
  );
}

Future<void> _waitForPortfolioGeneration(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

final _content = PortfolioContent(
  profile: const PortfolioSource.available(
    PortfolioProfile(
      displayName: 'Alex Doe',
      username: 'alex_doe',
      headline: '',
      bio: '',
      occupationTitle: '',
      photoPath: null,
      contactEmail: 'alex@example.test',
      phone: '',
      githubUrl: '',
      linkedInUrl: '',
      jobstreetUrl: '',
      whatsAppNumber: '',
      additionalLinks: [],
    ),
  ),
  photoUrl: const PortfolioSource.available(null),
  projects: const PortfolioSource.available([
    PortfolioProject(
      id: 'project-id',
      title: 'Shared project',
      summary: 'A saved project to include.',
      description: '',
      contribution: '',
      technologies: [],
      statusLabel: 'Completed',
      startDate: null,
      endDate: null,
    ),
  ]),
  skills: const PortfolioSource.available([]),
  education: const PortfolioSource.available([]),
  experience: const PortfolioSource.available([]),
  certifications: const PortfolioSource.available([]),
  achievements: const PortfolioSource.available([]),
  evidence: const PortfolioSource.available([]),
);

final _activePublication = PortfolioPublication(
  userId: 'owner-id',
  username: 'alex_doe',
  isPublished: true,
  template: PortfolioTemplate.light,
  selection: const PortfolioSelection(includeDisplayName: true),
  selectedSnapshot: const {'indexHtml': '<h1>Alex Doe</h1>'},
  publishedAt: DateTime.utc(2026, 10, 27),
  updatedAt: DateTime.utc(2026, 10, 27),
);

class _FakePublicationRepository implements PortfolioPublicationRepository {
  _FakePublicationRepository({this.status, this.updateError});

  PortfolioPublication? status;
  Object? updateError;
  int publishCalls = 0;
  int updateCalls = 0;
  int unpublishCalls = 0;
  PortfolioSelection? publishedSelection;

  @override
  bool get isConfigured => true;

  @override
  String publicUrl(String username) => '$_baseUrl/$username/';

  @override
  Future<PortfolioPublication?> loadStatus(String userId) async => status;

  @override
  Future<PortfolioPublication> publish(
    PortfolioContent content,
    PortfolioSelection selection,
    PortfolioTemplate template,
  ) async {
    publishCalls++;
    publishedSelection = selection;
    status = _activePublication;
    return status!;
  }

  @override
  Future<PortfolioPublication> updatePublished(
    PortfolioContent content,
    PortfolioSelection selection,
    PortfolioTemplate template,
  ) async {
    updateCalls++;
    if (updateError case final error?) throw error;
    publishedSelection = selection;
    status = _activePublication;
    return status!;
  }

  @override
  Future<void> unpublish(String userId) async {
    unpublishCalls++;
    status = _activePublication.copyWith(isPublished: false);
  }
}
