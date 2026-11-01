import 'package:supabase_flutter/supabase_flutter.dart';

const authRedirectUrl = 'com.prooffolio.app://login-callback/';

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

  Future<void> resendSignupVerification({required String email});

  bool get currentUserEmailVerified;

  Stream<bool> get emailVerificationChanges;

  Future<void> signOut();
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client);

  final SupabaseClient _client;

  @override
  Future<AuthActionResult> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user?.emailConfirmedAt == null) {
      await _client.auth.signOut();
      throw const AuthException(
        'Verify your email address before signing in.',
        code: 'email_not_confirmed',
      );
    }
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
      emailRedirectTo: authRedirectUrl,
    );
    return AuthActionResult(
      emailConfirmationRequired:
          response.session == null || response.user?.emailConfirmedAt == null,
    );
  }

  @override
  Future<void> resetPassword({required String email}) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: authRedirectUrl,
    );
  }

  @override
  Future<void> resendSignupVerification({required String email}) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: authRedirectUrl,
    );
  }

  @override
  bool get currentUserEmailVerified =>
      _client.auth.currentUser?.emailConfirmedAt != null;

  @override
  Stream<bool> get emailVerificationChanges => _client.auth.onAuthStateChange
      .map((state) => state.session?.user.emailConfirmedAt != null)
      .distinct();

  @override
  Future<void> signOut() => _client.auth.signOut();
}
