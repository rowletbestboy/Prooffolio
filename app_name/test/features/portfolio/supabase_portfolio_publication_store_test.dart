import 'dart:convert';
import 'dart:typed_data';

import 'package:app_name/features/portfolio/data/portfolio_publication_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('replaces an existing index before uploading it as HTML', () async {
    final requests = <http.Request>[];
    final uploadClient = MockClient((request) async {
      requests.add(request);
      final path = request.url.path;
      if (path == '/auth/v1/user') {
        return http.Response(
          jsonEncode({
            'id': 'owner-id',
            'aud': 'authenticated',
            'role': 'authenticated',
            'email': 'owner@example.test',
            'app_metadata': {},
            'user_metadata': {},
            'created_at': '2026-10-31T00:00:00.000Z',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (path == '/storage/v1/object/list/published-portfolios') {
        return http.Response(
          jsonEncode([
            {'name': 'index.html', 'id': 'index.html'},
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'DELETE' &&
          path == '/storage/v1/object/published-portfolios') {
        return http.Response('[]', 200);
      }
      if (request.method == 'POST' &&
          path.startsWith('/storage/v1/object/published-portfolios/')) {
        return http.Response(
          jsonEncode({'Key': 'published-portfolios/alex_doe'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      throw StateError('Unexpected request: ${request.method} $path');
    });
    final client = SupabaseClient(
      'https://portfolio.example.test',
      'test-publishable-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: uploadClient,
    );
    addTearDown(uploadClient.close);
    addTearDown(client.dispose);

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final accessToken = _jwt({
      'sub': 'owner-id',
      'role': 'authenticated',
      'aud': 'authenticated',
      'iat': now,
      'exp': now + 3600,
    });
    await client.auth.setSession('refresh-token', accessToken: accessToken);

    final store = SupabasePortfolioPublicationStore(
      client,
      uploadClient: uploadClient,
    );
    await store.syncFiles('alex_doe', {
      'index.html': Uint8List.fromList(utf8.encode('<!doctype html>')),
      'styles.css': Uint8List.fromList(utf8.encode('body {}')),
      'app.js': Uint8List.fromList(utf8.encode('')),
    });

    final deleteIndex = requests.indexWhere(
      (request) =>
          request.method == 'DELETE' &&
          request.url.path == '/storage/v1/object/published-portfolios',
    );
    final uploadIndex = requests.indexWhere(
      (request) =>
          request.method == 'POST' &&
          request.url.path.endsWith('/alex_doe/index.html'),
    );
    expect(deleteIndex, greaterThanOrEqualTo(0));
    expect(deleteIndex, lessThan(uploadIndex));
    expect(
      RegExp(r'name="contentType"\r\n\r\ntext/html\r\n').hasMatch(
        requests[uploadIndex].body,
      ),
      isTrue,
    );
    expect(
      requests[uploadIndex].body,
      contains('content-type: text/html'),
    );
    expect(
      requests[uploadIndex].body,
      contains('name="file"; filename="index.html"'),
    );
    expect(
      requests[uploadIndex].body,
      contains('name="cacheControl"\r\n\r\n0'),
    );
  });
}

String _jwt(Map<String, Object> payload) {
  String encode(Map<String, Object> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

  return '${encode({'alg': 'HS256', 'typ': 'JWT'})}.'
      '${encode(payload)}.'
      '${base64Url.encode(utf8.encode('test-signature')).replaceAll('=', '')}';
}
