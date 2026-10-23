import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/portfolio_content.dart';
import '../domain/portfolio_template.dart';
import 'portfolio_site_generator.dart';

const _publishedBucket = 'published-portfolios';
const _allowedSiteFiles = {
  'index.html',
  'styles.css',
  'app.js',
  'portfolio-photo.jpg',
  'portfolio-photo.png',
  'portfolio-photo.webp',
};

abstract interface class PortfolioPublicationRepository {
  bool get isConfigured;

  String publicUrl(String username);

  Future<PortfolioPublication?> loadStatus(String userId);

  Future<PortfolioPublication> publish(
    PortfolioContent content,
    PortfolioSelection selection,
    PortfolioTemplate template,
  );

  Future<PortfolioPublication> updatePublished(
    PortfolioContent content,
    PortfolioSelection selection,
    PortfolioTemplate template,
  );

  Future<void> unpublish(String userId);
}

abstract interface class PortfolioPublicationStore {
  String? get authenticatedUserId;

  Future<PortfolioPublication?> loadStatus(String userId);

  Future<void> saveStatus(PortfolioPublication publication);

  Future<Map<String, Uint8List>> loadFiles(String username);

  Future<void> syncFiles(String username, Map<String, Uint8List> files);

  Future<void> removeFiles(String username);
}

class PortfolioPublication {
  const PortfolioPublication({
    required this.userId,
    required this.username,
    required this.isPublished,
    required this.template,
    required this.selection,
    required this.selectedSnapshot,
    required this.updatedAt,
    this.publishedAt,
  });

  final String userId;
  final String username;
  final bool isPublished;
  final PortfolioTemplate template;
  final PortfolioSelection selection;
  final Map<String, dynamic> selectedSnapshot;
  final DateTime? publishedAt;
  final DateTime updatedAt;

  PortfolioPublication copyWith({
    bool? isPublished,
    DateTime? publishedAt,
    DateTime? updatedAt,
  }) => PortfolioPublication(
    userId: userId,
    username: username,
    isPublished: isPublished ?? this.isPublished,
    template: template,
    selection: selection,
    selectedSnapshot: selectedSnapshot,
    publishedAt: publishedAt ?? this.publishedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class SupabasePortfolioPublicationRepository
    implements PortfolioPublicationRepository {
  const SupabasePortfolioPublicationRepository({
    required this.store,
    required this.loadPrivateContent,
    required this.publicBaseUrl,
  });

  final PortfolioPublicationStore store;
  final Future<PortfolioContent> Function(String userId) loadPrivateContent;
  final String publicBaseUrl;

  @override
  bool get isConfigured => _publicBaseUri != null;

  @override
  String publicUrl(String username) {
    final base = _publicBaseUri;
    if (base == null) {
      throw StateError(
        'Website publishing is not configured. Set '
        'PORTFOLIO_PUBLIC_BASE_URL to the public published-portfolios bucket URL.',
      );
    }
    final slug = username.toLowerCase();
    if (!_isUsernameSlug(slug)) {
      throw FormatException(
        'The profile username is not a valid website slug.',
      );
    }
    return '${base.toString().replaceFirst(RegExp(r'/$'), '')}/$slug/index.html';
  }

  @override
  Future<PortfolioPublication?> loadStatus(String userId) {
    _requireOwner(userId);
    return store.loadStatus(userId);
  }

  @override
  Future<PortfolioPublication> publish(
    PortfolioContent content,
    PortfolioSelection selection,
    PortfolioTemplate template,
  ) async {
    final userId = _requireSignedIn();
    final current = await store.loadStatus(userId);
    if (current?.isPublished == true) {
      throw StateError(
        'This portfolio is already published. Use the update action instead.',
      );
    }
    return _writePublishedSnapshot(userId, content, selection, template);
  }

  @override
  Future<PortfolioPublication> updatePublished(
    PortfolioContent content,
    PortfolioSelection selection,
    PortfolioTemplate template,
  ) async {
    final userId = _requireSignedIn();
    final current = await store.loadStatus(userId);
    if (current?.isPublished != true) {
      throw StateError('Publish your website before updating it.');
    }
    return _writePublishedSnapshot(userId, content, selection, template);
  }

  @override
  Future<void> unpublish(String userId) async {
    _requireOwner(userId);
    final publication = await store.loadStatus(userId);
    if (publication == null) return;
    final previousFiles = await store.loadFiles(publication.username);
    try {
      await store.removeFiles(publication.username);
      if (publication.isPublished) {
        await store.saveStatus(
          publication.copyWith(
            isPublished: false,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
      }
    } on Object catch (error, stackTrace) {
      try {
        await store.syncFiles(publication.username, previousFiles);
      } on Object catch (rollbackError) {
        throw StateError(
          'Unpublishing failed ($error), and restoring the previous website '
          'also failed ($rollbackError). Retry unpublishing and verify the '
          'published files.',
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<PortfolioPublication> _writePublishedSnapshot(
    String userId,
    PortfolioContent previewContent,
    PortfolioSelection selection,
    PortfolioTemplate template,
  ) async {
    if (!isConfigured) {
      throw StateError(
        'Website publishing is not configured. Set '
        'PORTFOLIO_PUBLIC_BASE_URL before publishing.',
      );
    }
    final currentContent = await loadPrivateContent(userId);
    final previewProfile = previewContent.profile.value;
    final currentProfile = currentContent.profile.value;
    if (!previewContent.profile.isAvailable ||
        previewProfile == null ||
        !currentContent.profile.isAvailable ||
        currentProfile == null) {
      throw StateError(
        'Profile details could not be reloaded. Refresh the preview before publishing.',
      );
    }
    if (previewProfile.username.toLowerCase() !=
        currentProfile.username.toLowerCase()) {
      throw StateError(
        'Your username changed after this preview loaded. Refresh and review the website again.',
      );
    }
    final username = currentProfile.username.toLowerCase();
    if (!_isUsernameSlug(username)) {
      throw FormatException(
        'The profile username is not a valid website slug.',
      );
    }

    final previewBundle = PortfolioSiteGenerator.generate(
      previewContent,
      selection,
      template,
    );
    final currentBundle = PortfolioSiteGenerator.generate(
      currentContent,
      selection,
      template,
    );
    if (!_sameBundle(previewBundle, currentBundle)) {
      throw StateError(
        'Your saved portfolio changed after the preview loaded. Refresh and review the website again.',
      );
    }

    final previousFiles = await store.loadFiles(username);
    final now = DateTime.now().toUtc();
    final publication = PortfolioPublication(
      userId: userId,
      username: username,
      isPublished: true,
      template: template,
      selection: selection,
      selectedSnapshot: {
        'indexHtml': utf8.decode(currentBundle.files['index.html']!),
        'files': currentBundle.files.keys.toList(growable: false),
      },
      publishedAt: now,
      updatedAt: now,
    );
    try {
      await store.syncFiles(username, currentBundle.files);
      await store.saveStatus(publication);
      return publication;
    } on Object catch (error, stackTrace) {
      try {
        await store.syncFiles(username, previousFiles);
      } on Object catch (rollbackError) {
        throw StateError(
          'Publishing failed ($error), and restoring the previous website '
          'also failed ($rollbackError). Retry after checking Storage access.',
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  String _requireSignedIn() {
    final userId = store.authenticatedUserId;
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in again before publishing.');
    }
    return userId;
  }

  void _requireOwner(String userId) {
    if (userId.isEmpty || store.authenticatedUserId != userId) {
      throw StateError('You can only manage your own portfolio publication.');
    }
  }

  Uri? get _publicBaseUri {
    final uri = Uri.tryParse(publicBaseUrl.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    return uri.replace(path: uri.path.replaceFirst(RegExp(r'/+$'), ''));
  }

  static bool _isUsernameSlug(String username) =>
      RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(username);

  static bool _sameBundle(
    PortfolioSiteBundle first,
    PortfolioSiteBundle second,
  ) {
    if (first.files.length != second.files.length) return false;
    for (final entry in first.files.entries) {
      final other = second.files[entry.key];
      if (other == null || !_sameBytes(entry.value, other)) return false;
    }
    return true;
  }

  static bool _sameBytes(Uint8List first, Uint8List second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }
}

class SupabasePortfolioPublicationStore implements PortfolioPublicationStore {
  const SupabasePortfolioPublicationStore(this._client);

  final SupabaseClient _client;

  @override
  String? get authenticatedUserId => _client.auth.currentUser?.id;

  @override
  Future<PortfolioPublication?> loadStatus(String userId) async {
    _requireOwner(userId);
    final row = await _client
        .from('portfolio_publications')
        .select(
          'user_id, username, is_published, template, selection, '
          'selected_snapshot, published_at, updated_at',
        )
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    final selection = _readJsonObject(row['selection'], 'selection');
    final snapshot = _readJsonObject(
      row['selected_snapshot'],
      'selected_snapshot',
    );
    return PortfolioPublication(
      userId: row['user_id'] as String,
      username: row['username'] as String,
      isPublished: row['is_published'] as bool,
      template: PortfolioTemplate.values.byName(row['template'] as String),
      selection: PortfolioSelection.fromJson(selection),
      selectedSnapshot: snapshot,
      publishedAt: switch (row['published_at']) {
        final String value => DateTime.parse(value),
        _ => null,
      },
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Future<void> saveStatus(PortfolioPublication publication) async {
    _requireOwner(publication.userId);
    await _client.from('portfolio_publications').upsert({
      'user_id': publication.userId,
      'username': publication.username,
      'is_published': publication.isPublished,
      'template': publication.template.name,
      'selection': publication.selection.toJson(),
      'selected_snapshot': publication.selectedSnapshot,
      'published_at': publication.publishedAt?.toIso8601String(),
      'updated_at': publication.updatedAt.toIso8601String(),
    });
  }

  @override
  Future<Map<String, Uint8List>> loadFiles(String username) async {
    _requireSignedIn();
    final objects = await _client.storage
        .from(_publishedBucket)
        .list(path: username);
    final files = <String, Uint8List>{};
    for (final object in objects) {
      if (object.id == null || !_allowedSiteFiles.contains(object.name)) {
        throw StateError(
          'Unexpected item found in the published website folder. '
          'Resolve it before changing the publication.',
        );
      }
      files[object.name] = await _client.storage
          .from(_publishedBucket)
          .download('$username/${object.name}');
    }
    return files;
  }

  @override
  Future<void> syncFiles(String username, Map<String, Uint8List> files) async {
    _requireSignedIn();
    if (files.keys.any((name) => !_allowedSiteFiles.contains(name)) ||
        files.isNotEmpty &&
            !files.keys.toSet().containsAll({
              'index.html',
              'styles.css',
              'app.js',
            })) {
      throw ArgumentError('The generated website contains invalid file paths.');
    }
    final storage = _client.storage.from(_publishedBucket);
    final existing = await storage.list(path: username);
    final existingNames = <String>[];
    for (final object in existing) {
      if (object.id == null || !_allowedSiteFiles.contains(object.name)) {
        throw StateError(
          'Unexpected item found in the published website folder.',
        );
      }
      existingNames.add(object.name);
    }

    for (final entry in files.entries.where(
      (entry) => entry.key != 'index.html',
    )) {
      await storage.uploadBinary(
        '$username/${entry.key}',
        entry.value,
        fileOptions: FileOptions(
          cacheControl: '60',
          contentType: _contentType(entry.key),
          upsert: true,
        ),
      );
    }

    final removed = existingNames
        .where((name) => !files.containsKey(name))
        .map((name) => '$username/$name')
        .toList(growable: false);
    if (removed.isNotEmpty) await storage.remove(removed);

    if (files['index.html'] case final html?) {
      await storage.uploadBinary(
        '$username/index.html',
        html,
        fileOptions: const FileOptions(
          cacheControl: '60',
          contentType: 'text/html',
          upsert: true,
        ),
      );
    }
  }

  @override
  Future<void> removeFiles(String username) async {
    _requireSignedIn();
    final storage = _client.storage.from(_publishedBucket);
    final objects = await storage.list(path: username);
    final paths = <String>[];
    for (final object in objects) {
      if (object.id == null || !_allowedSiteFiles.contains(object.name)) {
        throw StateError(
          'Unexpected item found in the published website folder.',
        );
      }
      paths.add('$username/${object.name}');
    }
    if (paths.isNotEmpty) await storage.remove(paths);
  }

  void _requireSignedIn() {
    if (authenticatedUserId == null) {
      throw const AuthException('Please sign in again.');
    }
  }

  void _requireOwner(String userId) {
    if (authenticatedUserId != userId) {
      throw const AuthException('You can only manage your own publication.');
    }
  }

  static Map<String, dynamic> _readJsonObject(Object? value, String field) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    throw FormatException('The saved publication $field is invalid.');
  }

  static String _contentType(String fileName) => switch (fileName) {
    'styles.css' => 'text/css',
    'app.js' => 'text/javascript',
    'portfolio-photo.jpg' => 'image/jpeg',
    'portfolio-photo.png' => 'image/png',
    'portfolio-photo.webp' => 'image/webp',
    _ => 'application/octet-stream',
  };
}
