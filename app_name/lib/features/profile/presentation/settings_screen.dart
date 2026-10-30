import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_icon_tile.dart';
import '../../../core/widgets/app_page_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.onSignOut,
    required this.onEditProfile,
    this.accountEmail,
  });

  final Future<void> Function()? onSignOut;
  final Future<void> Function() onEditProfile;
  final String? accountEmail;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _signingOut = false;

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out of Prooffolio?'),
        content: const Text(
          'You can log back in anytime to continue building your portfolio.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    final onSignOut = widget.onSignOut;
    if (confirmed != true || !mounted || onSignOut == null) return;
    setState(() => _signingOut = true);
    try {
      await onSignOut();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Settings',
          context: ErrorDescription('while logging out of Prooffolio'),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not log out. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  Future<void> _editProfile() async {
    await widget.onEditProfile();
  }

  @override
  Widget build(BuildContext context) {
    final gutter = AppTheme.pageGutterFor(MediaQuery.sizeOf(context).width);
    return Scaffold(
      appBar: const AppPageAppBar(title: 'Settings', showBrand: false),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.contentMaxWidth),
          child: ListView(
            padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 32),
            children: [
              Text(
                'Your account',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const AppIconTile(
                        icon: Icons.person_outline,
                        color: AppColors.indigo,
                        size: 46,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Signed in as',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.accountEmail?.trim().isNotEmpty == true
                                  ? widget.accountEmail!
                                  : 'Email not available',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Profile', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.person_outline,
                        color: AppColors.indigo,
                      ),
                      title: const Text('Profile and background'),
                      subtitle: const Text(
                        'Update your about, contact, education, and experience details.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _editProfile,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    const ListTile(
                      leading: Icon(Icons.lock_outline, color: AppColors.teal),
                      title: Text('Privacy and sharing'),
                      subtitle: Text(
                        'Your portfolio stays private until you choose what to share.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('About', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Card(
                child: const ListTile(
                  leading: Icon(
                    Icons.auto_awesome_outlined,
                    color: AppColors.indigo,
                  ),
                  title: Text('Prooffolio'),
                  subtitle: Text(
                    'Build a portfolio grounded in your skills, work, and proof.',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Session', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _signingOut || widget.onSignOut == null
                    ? null
                    : _confirmSignOut,
                icon: _signingOut
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_outlined),
                label: Text(_signingOut ? 'Logging out…' : 'Log out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
