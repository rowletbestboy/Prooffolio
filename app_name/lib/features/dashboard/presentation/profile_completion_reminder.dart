import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_icon_tile.dart';
import '../../profile/domain/profile.dart';

class ProfileCompletionReminder extends StatelessWidget {
  const ProfileCompletionReminder({
    super.key,
    required this.profile,
    required this.isLoading,
    required this.hasError,
    required this.onOpenProfile,
    required this.onRetry,
  });

  final ProfileBackground? profile;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onOpenProfile;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const SizedBox.shrink();
    if (hasError) return _errorCard(context);

    final missing = _missingDetails(profile);
    if (missing.isEmpty) return _readyCard(context, profile);
    return _incompleteCard(context, missing);
  }

  Widget _incompleteCard(BuildContext context, List<String> missing) => Card(
    color: AppColors.indigoContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIconTile(
                icon: Icons.person_outline,
                color: AppColors.indigo,
                backgroundColor: AppColors.white,
                size: 42,
                iconSize: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Complete your profile',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppColors.deepNavy),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Add ${_joinDetails(missing)} to prepare your portfolio and resume. '
            'A profile photo is optional.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.deepNavy),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onOpenProfile,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Open profile'),
              style: TextButton.styleFrom(foregroundColor: AppColors.deepNavy),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _readyCard(BuildContext context, ProfileBackground? profile) {
    final hasPhoto = profile?.photoPath?.trim().isNotEmpty == true;
    return Card(
      color: AppColors.tealContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppIconTile(
              icon: Icons.check_circle_outline,
              color: AppColors.teal,
              backgroundColor: AppColors.white,
              size: 42,
              iconSize: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile details ready',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasPhoto
                        ? 'Your saved headline, work summary, and contact details are ready for your portfolio and resume.'
                        : 'Your saved headline, work summary, and contact details are ready. A profile photo is optional.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.deepNavy),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorCard(BuildContext context) => Card(
    color: AppColors.amberContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIconTile(
            icon: Icons.cloud_off_outlined,
            color: AppColors.amber,
            backgroundColor: AppColors.white,
            size: 42,
            iconSize: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile details could not be checked',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppColors.deepNavy),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check your connection before reviewing profile completion.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.deepNavy),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.deepNavy,
                    ),
                    child: const Text('Try again'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

List<String> _missingDetails(ProfileBackground? profile) {
  final missing = <String>[];
  if (profile == null || profile.displayName.trim().isEmpty) {
    missing.add('your name');
  }
  if (profile == null || profile.headline.trim().isEmpty) {
    missing.add('a professional headline');
  }
  if (profile == null || profile.bio.trim().isEmpty) {
    missing.add('a short work summary');
  }
  if (!_hasContact(profile)) missing.add('at least one contact method');
  return missing;
}

bool _hasContact(ProfileBackground? profile) {
  if (profile == null) return false;
  return [
        profile.contactEmail,
        profile.phone,
        profile.githubUrl,
        profile.linkedInUrl,
        profile.upworkUrl,
        profile.jobstreetUrl,
        profile.whatsAppNumber,
      ].any((value) => value?.trim().isNotEmpty == true) ||
      profile.additionalLinks.any((link) => link.url.trim().isNotEmpty);
}

String _joinDetails(List<String> missing) {
  if (missing.length == 1) return missing.single;
  if (missing.length == 2) return '${missing[0]} and ${missing[1]}';
  return '${missing.sublist(0, missing.length - 1).join(', ')}, and ${missing.last}';
}
