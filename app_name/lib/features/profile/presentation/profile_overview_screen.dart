import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';
import '../../skills/data/skill_repository.dart';
import '../../skills/domain/skill.dart';
import 'profile_background_screen.dart';
import 'settings_screen.dart';

class ProfileOverviewScreen extends StatefulWidget {
  const ProfileOverviewScreen({
    super.key,
    required this.repository,
    required this.userId,
    this.onSignOut,
    this.skillRepository,
    this.accountEmail,
    this.onOpenSkills,
  });

  final ProfileBackgroundRepository repository;
  final String userId;
  final Future<void> Function()? onSignOut;
  final SkillRepository? skillRepository;
  final String? accountEmail;
  final VoidCallback? onOpenSkills;

  @override
  State<ProfileOverviewScreen> createState() => _ProfileOverviewScreenState();
}

class _ProfileOverviewScreenState extends State<ProfileOverviewScreen> {
  late Future<_ProfileOverviewData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_ProfileOverviewData> _loadData() async {
    final values = await Future.wait<Object?>([
      widget.repository.loadProfile(widget.userId),
      widget.repository.listEducation(widget.userId),
      widget.repository.listExperience(widget.userId),
      widget.skillRepository?.listSkills() ?? Future<List<Skill>>.value([]),
    ]);
    final profile = values[0] as ProfileBackground?;
    String? photoUrl;
    if (profile?.photoPath?.trim().isNotEmpty == true) {
      photoUrl = await widget.repository.createProfilePhotoSignedUrl(
        profile!.photoPath!,
      );
    }
    return _ProfileOverviewData(
      profile: profile,
      education: values[1] as List<EducationRecord>,
      experience: values[2] as List<ExperienceRecord>,
      skills: values[3] as List<Skill>,
      photoUrl: photoUrl,
    );
  }

  Future<void> _openEditor() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProfileBackgroundScreen(
          repository: widget.repository,
          userId: widget.userId,
          accountEmail: widget.accountEmail,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _dataFuture = _loadData());
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          accountEmail: widget.accountEmail,
          onEditProfile: _openEditor,
          onSignOut: widget.onSignOut,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gutter = AppTheme.pageGutterFor(MediaQuery.sizeOf(context).width);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: FutureBuilder<_ProfileOverviewData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _LoadError(
              onRetry: () => setState(() => _dataFuture = _loadData()),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final profile = data.profile;
          if (profile == null) {
            return const Center(
              child: Text('Your profile could not be found.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              final future = _loadData();
              setState(() => _dataFuture = future);
              await future;
            },
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTheme.contentMaxWidth,
                ),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    14,
                    gutter,
                    AppTheme.pageGutter +
                        MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  children: [
                    _IdentityHeader(
                      profile: profile,
                      photoUrl: data.photoUrl,
                      onEdit: _openEditor,
                    ),
                    const SizedBox(height: 14),
                    _CompletenessCard(
                      percentage: _completeness(data),
                      onTap: _openEditor,
                    ),
                    const SizedBox(height: 8),
                    _ProfileSection(
                      title: 'About you',
                      onEdit: _openEditor,
                      child: _AboutDetails(profile: profile),
                    ),
                    _ProfileSection(
                      title: 'Education and training',
                      onEdit: _openEditor,
                      child: _EducationDetails(records: data.education),
                    ),
                    _ProfileSection(
                      title: 'Contact details',
                      onEdit: _openEditor,
                      child: _ContactDetails(
                        profile: profile,
                        accountEmail: widget.accountEmail,
                      ),
                    ),
                    _ProfileSection(
                      title: 'Experience',
                      onEdit: _openEditor,
                      child: _ExperienceDetails(records: data.experience),
                    ),
                    _ProfileSection(
                      title: 'Skills',
                      actionLabel: 'Manage',
                      onEdit: widget.onOpenSkills,
                      child: _SkillsDetails(skills: data.skills),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  int _completeness(_ProfileOverviewData data) {
    final profile = data.profile!;
    final completed = [
      profile.displayName.trim().isNotEmpty,
      profile.headline.trim().isNotEmpty ||
          profile.occupationTitle.trim().isNotEmpty,
      profile.bio.trim().isNotEmpty,
      profileHasContactMethod(profile) ||
          widget.accountEmail?.trim().isNotEmpty == true,
      data.education.isNotEmpty,
      data.experience.isNotEmpty,
      data.skills.isNotEmpty,
    ].where((isComplete) => isComplete).length;
    return (completed / 7 * 100).round();
  }
}

class _ProfileOverviewData {
  const _ProfileOverviewData({
    required this.profile,
    required this.education,
    required this.experience,
    required this.skills,
    required this.photoUrl,
  });

  final ProfileBackground? profile;
  final List<EducationRecord> education;
  final List<ExperienceRecord> experience;
  final List<Skill> skills;
  final String? photoUrl;
}

class _IdentityHeader extends StatelessWidget {
  const _IdentityHeader({
    required this.profile,
    required this.photoUrl,
    required this.onEdit,
  });

  final ProfileBackground profile;
  final String? photoUrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = profile.occupationTitle.trim().isNotEmpty
        ? profile.occupationTitle
        : profile.headline.trim().isNotEmpty
        ? profile.headline
        : profile.occupationCategory?.label ?? 'Add a headline to your profile';
    final metadata = [
      profile.occupationCategory?.label,
      profile.careerStage?.label,
    ].where((value) => value?.trim().isNotEmpty == true).join(' · ');
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.indigoContainer,
                  foregroundImage: photoUrl == null
                      ? null
                      : NetworkImage(photoUrl!),
                  child: Text(
                    _initials(profile.displayName),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.indigo,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.deepNavy,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cloudWhite, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        profile.displayName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (profile.careerStage case final stage?)
                        _StageChip(label: stage.label),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: theme.textTheme.bodyMedium),
                  if (metadata.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(metadata, style: theme.textTheme.bodySmall),
                  ],
                  if (profile.bio.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      profile.bio,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.slateBlack,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Padding(
              padding: EdgeInsets.only(top: 18),
              child: Icon(Icons.chevron_right, color: AppColors.slateGray),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 130),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.indigoContainer,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: AppColors.indigo),
    ),
  );
}

class _CompletenessCard extends StatelessWidget {
  const _CompletenessCard({required this.percentage, required this.onTap});

  final int percentage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 54,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 5,
                    backgroundColor: AppColors.lightSlate,
                    color: AppColors.teal,
                  ),
                  Center(
                    child: Text(
                      '$percentage%',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.slateGray,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile completeness',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Add details to give people a fuller picture of your work.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.slateGray),
          ],
        ),
      ),
    ),
  );
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.child,
    required this.onEdit,
    this.actionLabel = 'Edit',
  });

  final String title;
  final Widget child;
  final VoidCallback? onEdit;
  final String actionLabel;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.deepNavy),
              ),
            ),
            if (onEdit != null)
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: Text(actionLabel),
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
          ],
        ),
        child,
      ],
    ),
  );
}

class _AboutDetails extends StatelessWidget {
  const _AboutDetails({required this.profile});

  final ProfileBackground profile;

  @override
  Widget build(BuildContext context) {
    final role = profile.occupationTitle.trim().isNotEmpty
        ? profile.occupationTitle
        : profile.occupationCategory?.label;
    final details = <(IconData, String, String)>[
      if (profile.headline.trim().isNotEmpty)
        (Icons.badge_outlined, 'Headline', profile.headline),
      if (profile.bio.trim().isNotEmpty)
        (Icons.notes_outlined, 'About your work', profile.bio),
      if (role?.trim().isNotEmpty == true)
        (Icons.work_outline, 'Role or field', role!),
      if (profile.careerStage case final stage?)
        (Icons.school_outlined, 'Career stage', stage.label),
      if (profile.interests.isNotEmpty)
        (Icons.interests_outlined, 'Interests', profile.interests.join(', ')),
      if (profile.targetRoles.isNotEmpty)
        (
          Icons.track_changes_outlined,
          'Target roles',
          profile.targetRoles.join(', '),
        ),
    ];
    if (details.isEmpty)
      return const _EmptySection(label: 'Add a few details about yourself.');
    return _DetailsCard(
      children: [
        for (final (icon, label, value) in details)
          _DetailRow(icon: icon, label: label, value: value),
      ],
    );
  }
}

class _ContactDetails extends StatelessWidget {
  const _ContactDetails({required this.profile, required this.accountEmail});

  final ProfileBackground profile;
  final String? accountEmail;

  @override
  Widget build(BuildContext context) {
    final email = profile.contactEmail?.trim().isNotEmpty == true
        ? profile.contactEmail!.trim()
        : accountEmail?.trim();
    final details = <(IconData, String, String)>[
      if (email?.isNotEmpty == true) (Icons.mail_outline, 'Email', email!),
      if (profile.phone?.trim().isNotEmpty == true)
        (Icons.phone_outlined, 'Phone', profile.phone!.trim()),
      if (profile.whatsAppNumber?.trim().isNotEmpty == true)
        (Icons.chat_outlined, 'WhatsApp', profile.whatsAppNumber!.trim()),
      if (profile.githubUrl?.trim().isNotEmpty == true)
        (Icons.code, 'GitHub', profile.githubUrl!.trim()),
      if (profile.linkedInUrl?.trim().isNotEmpty == true)
        (Icons.work_outline, 'LinkedIn', profile.linkedInUrl!.trim()),
      if (profile.upworkUrl?.trim().isNotEmpty == true)
        (Icons.work_outline, 'Upwork', profile.upworkUrl!.trim()),
      if (profile.jobstreetUrl?.trim().isNotEmpty == true)
        (Icons.work_outline, 'JobStreet', profile.jobstreetUrl!.trim()),
      for (final link in profile.additionalLinks)
        if (link.label.trim().isNotEmpty || link.url.trim().isNotEmpty)
          (
            Icons.link,
            link.label.trim().isNotEmpty ? link.label : 'Link',
            link.url,
          ),
    ];
    if (details.isEmpty)
      return const _EmptySection(label: 'Add a way for people to reach you.');
    return _DetailsCard(
      children: [
        for (final (icon, label, value) in details)
          _DetailRow(icon: icon, label: label, value: value),
      ],
    );
  }
}

class _EducationDetails extends StatelessWidget {
  const _EducationDetails({required this.records});

  final List<EducationRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const _EmptySection(
        label: 'Add education, courses, and training.',
      );
    }
    return _DetailsCard(
      children: [
        for (final record in records)
          _RecordRow(
            icon: Icons.school_outlined,
            title: record.institution.trim().isNotEmpty
                ? record.institution
                : record.title,
            subtitle: [
              if (record.institution.trim().isNotEmpty) record.title,
              if (record.level case final level?) level.label,
              _dateRange(record.startDate, record.endDate),
              if (record.status == EducationStatus.inProgress) 'In progress',
            ].where((value) => value.isNotEmpty).join(' · '),
          ),
      ],
    );
  }
}

class _ExperienceDetails extends StatelessWidget {
  const _ExperienceDetails({required this.records});

  final List<ExperienceRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const _EmptySection(
        label: 'Add work, volunteer, or project experience.',
      );
    }
    return _DetailsCard(
      children: [
        for (final record in records)
          _RecordRow(
            icon: Icons.work_outline,
            title: record.title,
            subtitle: [
              if (record.organization?.trim().isNotEmpty == true)
                record.organization!,
              record.type.label,
              _dateRange(
                record.startDate,
                record.isCurrent ? null : record.endDate,
                isCurrent: record.isCurrent,
              ),
              if (record.description.trim().isNotEmpty)
                record.description.trim(),
            ].where((value) => value.isNotEmpty).join(' · '),
          ),
      ],
    );
  }
}

class _SkillsDetails extends StatelessWidget {
  const _SkillsDetails({required this.skills});

  final List<Skill> skills;

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) {
      return const _EmptySection(label: 'Add skills to show what you can do.');
    }
    final sorted = [...skills]..sort((a, b) => a.name.compareTo(b.name));
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final skill in sorted.take(5))
          Chip(
            label: Text(skill.name),
            backgroundColor: AppColors.indigoContainer,
            side: BorderSide.none,
            visualDensity: VisualDensity.compact,
          ),
        if (sorted.length > 5)
          Chip(
            label: Text('+${sorted.length - 5}'),
            backgroundColor: AppColors.surfaceSubtle,
            side: BorderSide.none,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(children: children),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.slateGray),
        const SizedBox(width: 10),
        SizedBox(
          width: 92,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.slateBlack),
          ),
        ),
      ],
    ),
  );
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.indigo, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.surfaceSubtle,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.add_circle_outline, color: AppColors.indigo),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40),
          const SizedBox(height: 12),
          const Text('Profile details could not be loaded.'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty);
  return parts
      .take(2)
      .map((part) => part.characters.first.toUpperCase())
      .join();
}

String _dateRange(DateTime? start, DateTime? end, {bool isCurrent = false}) {
  String year(DateTime value) => value.year.toString();
  if (start == null && end == null && !isCurrent) return '';
  final from = start == null ? '' : year(start);
  final to = isCurrent
      ? 'Present'
      : end == null
      ? ''
      : year(end);
  if (from.isEmpty) return to;
  if (to.isEmpty) return from;
  return '$from – $to';
}
