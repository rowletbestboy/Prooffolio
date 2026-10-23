import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../dashboard/presentation/home_shell.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/presentation/profile_setup_screen.dart';
import '../data/auth_service.dart';
import 'auth_screen.dart';
import 'new_password_screen.dart';
import '../../projects/data/project_repository.dart';
import '../../skills/data/skill_repository.dart';
import '../../portfolio/data/portfolio_record_repository.dart';
import '../../portfolio/data/portfolio_content_repository.dart';
import '../../portfolio/data/portfolio_publication_repository.dart';
import '../../evidence/data/evidence_repository.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.client});

  final SupabaseClient client;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final SupabaseProfileRepository _profiles = SupabaseProfileRepository(
    widget.client,
  );
  late final StreamSubscription<AuthState> _subscription;
  User? _user;
  bool _isPasswordRecovery = false;
  Future<bool>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _user = widget.client.auth.currentUser;
    _loadProfile();
    _subscription = widget.client.auth.onAuthStateChange.listen((event) {
      if (!mounted) return;
      setState(() {
        _user = event.session?.user;
        _isPasswordRecovery = event.event == AuthChangeEvent.passwordRecovery;
        _profileFuture = null;
      });
      _loadProfile();
    });
  }

  void _loadProfile() {
    final user = _user;
    if (user != null) _profileFuture = _profiles.hasProfile(user.id);
  }

  Future<void> _refreshProfile() async {
    setState(() => _profileFuture = _profiles.hasProfile(_user!.id));
  }

  void _finishPasswordRecovery() {
    setState(() {
      _isPasswordRecovery = false;
      _profileFuture = null;
    });
    _loadProfile();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (_isPasswordRecovery) {
      return NewPasswordScreen(
        onUpdate: (password) =>
            widget.client.auth.updateUser(UserAttributes(password: password)),
        onComplete: _finishPasswordRecovery,
      );
    }
    if (user == null) {
      return AuthScreen(authService: SupabaseAuthService(widget.client));
    }
    return FutureBuilder<bool>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('We could not load your profile.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _refreshProfile,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.data!) {
          return ProfileSetupScreen(
            repository: _profiles,
            onComplete: () => _refreshProfile(),
          );
        }
        final projects = SupabaseProjectRepository(widget.client);
        final skills = SupabaseSkillRepository(widget.client);
        final records = SupabasePortfolioRecordRepository(widget.client);
        final evidence = SupabaseEvidenceRepository(widget.client);
        final portfolioContentRepository = PortfolioContentRepository(
          profileRepository: _profiles,
          projectRepository: projects,
          skillRepository: skills,
          portfolioRecordRepository: records,
          evidenceRepository: evidence,
        );
        return HomeShell(
          onSignOut: () => widget.client.auth.signOut(),
          projectRepository: projects,
          skillRepository: skills,
          portfolioRecordRepository: records,
          evidenceRepository: evidence,
          portfolioContentRepository: portfolioContentRepository,
          portfolioPublicationRepository:
              SupabasePortfolioPublicationRepository(
                store: SupabasePortfolioPublicationStore(widget.client),
                loadPrivateContent:
                    portfolioContentRepository.loadPrivateContent,
                publicBaseUrl: SupabaseConfig.portfolioPublicBaseUrl,
              ),
          profileRepository: _profiles,
          profileUserId: user.id,
          profileAccountEmail: user.email,
        );
      },
    );
  }
}
