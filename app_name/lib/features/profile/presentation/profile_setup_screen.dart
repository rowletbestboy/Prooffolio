import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_brand_mark.dart';
import '../../../core/widgets/app_icon_tile.dart';
import '../data/profile_repository.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({
    super.key,
    required this.repository,
    required this.onComplete,
  });

  final ProfileRepository repository;
  final VoidCallback onComplete;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository
          .saveProfile(
            displayName: _displayNameController.text,
            username: _usernameController.text,
          )
          .timeout(const Duration(seconds: 20));
      if (mounted) widget.onComplete();
    } on PostgrestException catch (error) {
      if (mounted) {
        setState(() {
          _error = switch (error.code) {
            '23505' => 'That username is already in use. Try another.',
            'P0001' =>
              'Unpublish your portfolio before changing your username.',
            '42P01' || 'PGRST205' =>
              'The profiles table is missing. Run the profiles migration in your Supabase SQL Editor, then try again.',
            '23514' =>
              'Check your display name (1–80 characters) and username, then try again.',
            '42501' =>
              'Supabase denied profile access. Check the migration policies and sign in again.',
            'PGRST204' =>
              'The profiles table columns do not match this app. Recheck the latest profiles migration.',
            _ =>
              'Could not save your profile (Supabase error ${error.code ?? 'unknown'}). Check the profiles migration and policies, then try again.',
          };
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(
          () => _error =
              'Supabase took too long to respond. Check your connection and try again.',
        );
      }
    } on AuthException {
      if (mounted) {
        setState(() => _error = 'Your session expired. Please sign in again.');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not save your profile. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pageGutter = AppTheme.pageGutterFor(MediaQuery.sizeOf(context).width);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your profile'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => Supabase.instance.client.auth.signOut(),
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTheme.contentMaxWidth,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(pageGutter, 20, pageGutter, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppBrandMark(),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.lightSlate),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppIconTile(
                            icon: Icons.person_outline,
                            color: AppColors.indigo,
                          ),
                          const SizedBox(height: 18),
                          Text('Make it yours', style: textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          Text(
                            'Choose how your work will be credited. You can update these details later.',
                            style: textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _displayNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Display name',
                            ),
                            validator: (value) =>
                                (value?.trim().isNotEmpty ?? false)
                                ? null
                                : 'Enter your display name',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _usernameController,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixText: '@',
                              helperText: 'Letters, numbers, and underscores',
                            ),
                            validator: (value) {
                              final username = value?.trim() ?? '';
                              if (username.length < 3 || username.length > 24) {
                                return 'Use 3 to 24 characters';
                              }
                              if (!RegExp(
                                r'^[a-zA-Z0-9_]+$',
                              ).hasMatch(username)) {
                                return 'Use letters, numbers, and underscores only';
                              }
                              return null;
                            },
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _saving ? null : _save,
                              child: Text(_saving ? 'Saving…' : 'Continue'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
