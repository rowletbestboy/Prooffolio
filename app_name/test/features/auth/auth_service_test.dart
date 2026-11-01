import 'dart:convert';

import 'package:app_name/features/auth/data/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'signup uses the Android callback and makes no profile request',
    () async {
      final requests = <http.Request>[];
      final httpClient = MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(_unconfirmedUser()),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final client = _client(httpClient);
      addTearDown(httpClient.close);
      addTearDown(client.dispose);

      final result = await SupabaseAuthService(client).signUp(
        email: 'alex@example.test',
        password: 'a-test-password',
        displayName: 'Alex Rivera',
        username: 'AlexRivera',
      );

      expect(result.emailConfirmationRequired, isTrue);
      expect(requests, hasLength(1));
      expect(requests.single.url.path, '/auth/v1/signup');
      expect(
        requests.single.url.queryParameters['redirect_to'],
        authRedirectUrl,
      );
      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(body['data'], {
        'display_name': 'Alex Rivera',
        'username': 'alexrivera',
      });
    },
  );

  test('resending signup verification uses the signup OTP endpoint', () async {
    final requests = <http.Request>[];
    final httpClient = MockClient((request) async {
      requests.add(request);
      return http.Response(
        '{}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final client = _client(httpClient);
    addTearDown(httpClient.close);
    addTearDown(client.dispose);

    await SupabaseAuthService(
      client,
    ).resendSignupVerification(email: 'alex@example.test');

    expect(requests, hasLength(1));
    expect(requests.single.url.path, '/auth/v1/resend');
    expect(requests.single.url.queryParameters['redirect_to'], authRedirectUrl);
    final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(body['email'], 'alex@example.test');
    expect(body['type'], 'signup');
    expect(body['code_challenge_method'], 's256');
  });

  test('an unverified login cannot keep an authenticated session', () async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final accessToken = _jwt({
      'sub': 'user-id',
      'role': 'authenticated',
      'aud': 'authenticated',
      'iat': now,
      'exp': now + 3600,
    });
    final httpClient = MockClient((request) async {
      if (request.url.path == '/auth/v1/token') {
        return http.Response(
          jsonEncode({
            'access_token': accessToken,
            'token_type': 'bearer',
            'expires_in': 3600,
            'refresh_token': 'test-refresh-token',
            'user': _unconfirmedUser(),
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/auth/v1/logout') {
        return http.Response(
          '{}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      throw StateError('Unexpected auth request: ${request.url.path}');
    });
    final client = _client(httpClient);
    addTearDown(httpClient.close);
    addTearDown(client.dispose);

    await expectLater(
      SupabaseAuthService(
        client,
      ).signIn(email: 'alex@example.test', password: 'a-test-password'),
      throwsA(
        isA<AuthException>().having(
          (error) => error.code,
          'code',
          'email_not_confirmed',
        ),
      ),
    );
    expect(client.auth.currentSession, isNull);
  });
}

SupabaseClient _client(http.Client httpClient) => SupabaseClient(
  'https://auth.example.test',
  'test-publishable-key',
  authOptions: const AuthClientOptions(
    autoRefreshToken: false,
    pkceAsyncStorage: _MemoryAuthStorage(),
  ),
  httpClient: httpClient,
);

Map<String, dynamic> _unconfirmedUser() => {
  'id': 'user-id',
  'aud': 'authenticated',
  'role': 'authenticated',
  'email': 'alex@example.test',
  'app_metadata': <String, dynamic>{},
  'user_metadata': <String, dynamic>{},
  'created_at': '2026-11-01T00:00:00.000Z',
  'identities': <Object>[],
};

String _jwt(Map<String, Object> payload) {
  String encode(Map<String, Object> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

  return '${encode({'alg': 'HS256', 'typ': 'JWT'})}.'
      '${encode(payload)}.'
      '${base64Url.encode(utf8.encode('test-signature')).replaceAll('=', '')}';
}

class _MemoryAuthStorage extends GotrueAsyncStorage {
  const _MemoryAuthStorage();

  @override
  Future<String?> getItem({required String key}) async => null;

  @override
  Future<void> setItem({required String key, required String value}) async {}

  @override
  Future<void> removeItem({required String key}) async {}
}
