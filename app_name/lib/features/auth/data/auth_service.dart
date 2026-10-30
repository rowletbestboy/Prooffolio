import 'package:supabase_flutter/supabase_flutter.dart';

class AuthActionResult {
  const AuthActionResult({this.emailConfirmationRequired = false});

  final bool emailConfirmationRequired;
}

abstract interface class AuthService {
  Future<AuthActionResult> signIn({
    required String email,
    required String password,
  });

  Future<AuthActionResult> signUp({
    required String email,
    required String password,
    required String displayName,
    required String username,
  });

  Future<void> resetPassword({required String email});
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client);

  final SupabaseClient _client;

  @override
  Future<AuthActionResult> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
    return const AuthActionResult();
  }

  @override
  Future<AuthActionResult> signUp({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'display_name': displayName.trim(),
        'username': username.trim().toLowerCase(),
      },
      emailRedirectTo: 'com.prooffolio.app://login-callback/',
    );
    return AuthActionResult(
      emailConfirmationRequired: response.session == null,
    );
  }

  @override
  Future<void> resetPassword({required String email}) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'com.prooffolio.app://login-callback/',
    );
  }
}
