import 'dart:convert';
import 'dart:typed_data';

import 'package:app_name/features/portfolio/data/portfolio_publication_repository.dart';
import 'package:app_name/features/portfolio/domain/portfolio_content.dart';
import 'package:app_name/features/portfolio/domain/portfolio_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final content = _portfolioContent();
  const selection = PortfolioSelection(
    includeDisplayName: true,
    projectIds: {'private-project-id'},
  );

  test(
    'publish reloads the owner snapshot and stores only generated files',
    () async {
      final store = _MemoryPublicationStore();
      final repository = _repository(store, content);

      final result = await repository.publish(
        content,
        selection,
        PortfolioTemplate.light,
      );

      expect(store.loadedUserIds, ['owner-id']);
      expect(result.isPublished, isTrue);
      expect(result.username, 'alex_doe');
      expect(
        repository.publicUrl(result.username),
        'https://portfolio.example.test/alex_doe/',
      );
      expect(store.files.keys.toSet(), {'index.html', 'styles.css', 'app.js'});
      final html = utf8.decode(store.files['index.html']!);
      expect(html, contains('Selected public project'));
      expect(html, isNot(contains('private-project-id')));
      expect(html, isNot(contains('Never publish this evidence')));
      expect(html, isNot(contains('Private attachment details')));
      expect(result.selectedSnapshot['indexHtml'], html);
      expect(result.selection.projectIds, {'private-project-id'});
    },
  );

  test('public URL handles a trailing slash on the Worker origin', () {
    final repository = _repository(
      _MemoryPublicationStore(),
      content,
      baseUrl: 'https://portfolio.example.test/',
    );

    expect(
      repository.publicUrl('alex_doe'),
      'https://portfolio.example.test/alex_doe/',
    );
  });

  test(
    'stale preview is rejected before any public object is written',
    () async {
      final store = _MemoryPublicationStore();
      final staleContent = _portfolioContent(
        displayName: 'Different saved name',
      );
      final repository = _repository(store, content);

      await expectLater(
        repository.publish(staleContent, selection, PortfolioTemplate.light),
        throwsA(isA<StateError>()),
      );

      expect(store.files, isEmpty);
      expect(store.savedPublication, isNull);
    },
  );

  test(
    'failed publication-state save restores the previous public site',
    () async {
      final oldFiles = {
        'index.html': Uint8List.fromList(
          utf8.encode('Previously published page'),
        ),
        'styles.css': Uint8List.fromList(utf8.encode('previous styles')),
      };
      final store = _MemoryPublicationStore(
        files: oldFiles,
        publication: _activePublication(),
        failNextSave: true,
      );
      final repository = _repository(store, content);

      await expectLater(
        repository.updatePublished(content, selection, PortfolioTemplate.dark),
        throwsA(isA<StateError>()),
      );

      expect(store.files, _sameBytes(oldFiles));
      expect(store.publication?.template, PortfolioTemplate.light);
      expect(store.publication?.isPublished, isTrue);
    },
  );

  test('partial upload failure removes the uncommitted public files', () async {
    final store = _MemoryPublicationStore(failNextSync: true);
    final repository = _repository(store, content);

    await expectLater(
      repository.publish(content, selection, PortfolioTemplate.light),
      throwsA(isA<StateError>()),
    );

    expect(store.files, isEmpty);
    expect(store.savedPublication, isNull);
  });

  test(
    'unpublish removes the user folder before deactivating the row',
    () async {
      final store = _MemoryPublicationStore(
        files: {
          'index.html': Uint8List.fromList(utf8.encode('Public site')),
          'styles.css': Uint8List.fromList(utf8.encode('Public styles')),
          'app.js': Uint8List.fromList(utf8.encode('Public script')),
        },
        publication: _activePublication(),
      );
      final repository = _repository(store, content);

      await repository.unpublish('owner-id');

      expect(store.files, isEmpty);
      expect(store.savedPublication?.isPublished, isFalse);
      expect(
        store.operations.indexOf('remove:alex_doe'),
        lessThan(store.operations.indexOf('save:inactive')),
      );
    },
  );
}

SupabasePortfolioPublicationRepository _repository(
  _MemoryPublicationStore store,
  PortfolioContent currentContent, {
  String baseUrl = publicBaseUrl,
}) => SupabasePortfolioPublicationRepository(
  store: store,
  loadPrivateContent: (userId) async {
    store.loadedUserIds.add(userId);
    return currentContent;
  },
  publicBaseUrl: baseUrl,
);

const publicBaseUrl = 'https://portfolio.example.test';

PortfolioContent _portfolioContent({String displayName = 'Alex Doe'}) =>
    PortfolioContent(
      profile: PortfolioSource.available(
        PortfolioProfile(
          displayName: displayName,
          username: 'alex_doe',
          headline: '',
          bio: '',
          occupationTitle: '',
          photoPath: null,
          contactEmail: '',
          phone: '',
          githubUrl: '',
          linkedInUrl: '',
          jobstreetUrl: '',
          whatsAppNumber: '',
          additionalLinks: const [],
        ),
      ),
      photoUrl: const PortfolioSource.available(null),
      projects: const PortfolioSource.available([
        PortfolioProject(
          id: 'private-project-id',
          title: 'Selected public project',
          summary: 'A short project summary.',
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
      evidence: const PortfolioSource.available([
        PortfolioEvidence(
          id: 'private-evidence-id',
          title: 'Never publish this evidence',
          description: 'Private attachment details',
          kind: 'File',
          targetTitles: ['Selected public project'],
        ),
      ]),
    );

PortfolioPublication _activePublication() => PortfolioPublication(
  userId: 'owner-id',
  username: 'alex_doe',
  isPublished: true,
  template: PortfolioTemplate.light,
  selection: const PortfolioSelection(),
  selectedSnapshot: const {'indexHtml': 'Previously published page'},
  publishedAt: DateTime.utc(2026, 10, 20),
  updatedAt: DateTime.utc(2026, 10, 20),
);

Map<String, Uint8List> _sameBytes(Map<String, Uint8List> source) => {
  for (final entry in source.entries)
    entry.key: Uint8List.fromList(entry.value),
};

class _MemoryPublicationStore implements PortfolioPublicationStore {
  _MemoryPublicationStore({
    this.files = const {},
    this.publication,
    this.failNextSave = false,
    this.failNextSync = false,
  });

  @override
  String? get authenticatedUserId => 'owner-id';

  Map<String, Uint8List> files;
  PortfolioPublication? publication;
  PortfolioPublication? savedPublication;
  bool failNextSave;
  bool failNextSync;
  final loadedUserIds = <String>[];
  final operations = <String>[];

  @override
  Future<PortfolioPublication?> loadStatus(String userId) async => publication;

  @override
  Future<Map<String, Uint8List>> loadFiles(String username) async =>
      _sameBytes(files);

  @override
  Future<void> syncFiles(
    String username,
    Map<String, Uint8List> desiredFiles,
  ) async {
    operations.add('sync:$username');
    if (failNextSync) {
      failNextSync = false;
      files = desiredFiles.isEmpty
          ? {}
          : {desiredFiles.keys.first: desiredFiles.values.first};
      throw StateError('Upload failed');
    }
    files = _sameBytes(desiredFiles);
  }

  @override
  Future<void> removeFiles(String username) async {
    operations.add('remove:$username');
    files = {};
  }

  @override
  Future<void> saveStatus(PortfolioPublication value) async {
    operations.add(value.isPublished ? 'save:active' : 'save:inactive');
    if (failNextSave) {
      failNextSave = false;
      throw StateError('Database write failed');
    }
    publication = value;
    savedPublication = value;
  }
}
