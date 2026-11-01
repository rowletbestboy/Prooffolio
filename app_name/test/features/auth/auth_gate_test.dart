import 'dart:convert';

import 'package:app_name/features/auth/presentation/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('saving first profile continues to the Home dashboard', (
    tester,
  ) async {
    var profileExists = false;
    final httpClient = MockClient((request) async {
      if (request.url.path == '/rest/v1/profiles' && request.method == 'GET') {
        return http.Response(
          jsonEncode(profileExists ? [_profileRow()] : <Object>[]),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }
      if (request.url.path == '/rest/v1/profiles' && request.method == 'POST') {
        profileExists = true;
        return http.Response('', 201, request: request);
      }
      if (request.method == 'GET') {
        return http.Response(
          '[]',
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }
      return http.Response('', 204, request: request);
    });
    final client = SupabaseClient(
      'https://auth.example.test',
      'test-publishable-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: httpClient,
    );
    addTearDown(httpClient.close);
    await client.auth.setInitialSession(jsonEncode(_verifiedSession()));

    await tester.pumpWidget(MaterialApp(home: AuthGate(client: client)));
    await tester.pumpAndSettle();
    expect(find.text('Make it yours'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Avery Student');
    await tester.enterText(find.byType(TextFormField).last, 'avery_student');
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(tester.takeException(), isNull);
    expect(find.text('Make it yours'), findsNothing);
    expect(find.text('PORTFOLIO COMPLETION'), findsOneWidget);
  });
}

Map<String, dynamic> _verifiedSession() {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final accessToken = _jwt({
    'sub': 'test-user',
    'role': 'authenticated',
    'aud': 'authenticated',
    'iat': now,
    'exp': now + 3600,
  });
  return {
    'access_token': accessToken,
    'expires_in': 3600,
    'refresh_token': 'test-refresh-token',
    'token_type': 'bearer',
    'user': {
      'id': 'test-user',
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'avery@example.test',
      'email_confirmed_at': '2026-11-01T00:00:00.000Z',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'created_at': '2026-11-01T00:00:00.000Z',
      'identities': <Object>[],
    },
  };
}

Map<String, dynamic> _profileRow() => {
  'user_id': 'test-user',
  'display_name': 'Avery Student',
  'username': 'avery_student',
};

String _jwt(Map<String, Object> payload) {
  String encode(Map<String, Object> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

  return '${encode({'alg': 'HS256', 'typ': 'JWT'})}.'
      '${encode(payload)}.'
      '${base64Url.encode(utf8.encode('test-signature')).replaceAll('=', '')}';
}
