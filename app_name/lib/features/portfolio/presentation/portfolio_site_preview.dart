import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page_app_bar.dart';
import '../data/portfolio_publication_repository.dart';
import '../data/portfolio_site_generator.dart';
import '../domain/portfolio_content.dart';
import '../domain/portfolio_template.dart';
import 'site_preview_surface.dart';

class PortfolioSitePreview extends StatefulWidget {
  const PortfolioSitePreview({
    super.key,
    required this.content,
    this.previewBuilder,
    this.publicationRepository,
    this.userId,
  });

  final PortfolioContent content;
  final Widget Function(BuildContext context, String html)? previewBuilder;
  final PortfolioPublicationRepository? publicationRepository;
  final String? userId;

  @override
  State<PortfolioSitePreview> createState() => _PortfolioSitePreviewState();
}

class _PortfolioSitePreviewState extends State<PortfolioSitePreview> {
  late PortfolioSelection _selection;
  PortfolioSiteBundle? _bundle;
  Object? _generationError;
  int _generationRevision = 0;
  bool _generating = true;
  PortfolioPublication? _publication;
  Object? _publicationError;
  bool _loadingPublication = false;
  bool _publishing = false;
  String? _publicationMessage;
  bool _isMobilePreview = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _selectionOptionsKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selection = PortfolioSelection.allFrom(widget.content);
    _regenerate();
    _loadPublicationStatus();
  }

  Future<void> _loadPublicationStatus() async {
    final repository = widget.publicationRepository;
    final userId = widget.userId;
    if (repository == null || userId == null || userId.isEmpty) return;
    setState(() {
      _loadingPublication = true;
      _publicationError = null;
    });
    try {
      final publication = await repository.loadStatus(userId);
      if (!mounted) return;
      final restorePublishedSelection = publication?.isPublished == true;
      setState(() {
        _publication = publication;
        _loadingPublication = false;
        if (restorePublishedSelection) {
          _selection = publication!.selection;
          _generating = true;
        }
      });
      if (restorePublishedSelection) _regenerate();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _publicationError = error;
        _loadingPublication = false;
      });
    }
  }

  void _updateSelection(PortfolioSelection selection) {
    setState(() {
      _selection = selection;
      _generating = true;
    });
    _regenerate();
  }

  void _regenerate() {
    final revision = ++_generationRevision;
    final selection = _selection;
    unawaited(_generateBundle(revision, selection));
  }

  Future<void> _generateBundle(
    int revision,
    PortfolioSelection selection,
  ) async {
    try {
      final bundle = await PortfolioSiteGenerator.generate(
        widget.content,
        selection,
        PortfolioTemplate.light,
      );
      if (!mounted || revision != _generationRevision) return;
      setState(() {
        _bundle = bundle;
        _generationError = null;
        _generating = false;
      });
    } on Object catch (error) {
      if (!mounted || revision != _generationRevision) return;
      setState(() {
        _bundle = null;
        _generationError = error;
        _generating = false;
      });
    }
  }

  Future<void> _download() async {
    final bundle = _bundle;
    if (bundle == null || _generating) return;
    try {
      final saved = await FilePicker.saveFile(
        fileName: 'prooffolio-portfolio.zip',
        bytes: bundle.toZipBytes(),
        mimeType: 'application/zip',
        type: FileType.custom,
        allowedExtensions: ['zip'],
        dialogTitle: 'Save portfolio website',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved == null
                ? 'Website download cancelled.'
                : 'Website ZIP saved.',
          ),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Website ZIP could not be saved: $error')),
      );
    }
  }

  Future<void> _publish() async {
    final repository = widget.publicationRepository;
    final userId = widget.userId;
    final bundle = _bundle;
    if (repository == null ||
        userId == null ||
        userId.isEmpty ||
        bundle == null ||
        _generating ||
        _loadingPublication ||
        _publishing) {
      return;
    }
    if (_publicationError != null) {
      _showMessage(
        'Publication status is unavailable. Refresh it before publishing.',
      );
      return;
    }
    if (!repository.isConfigured) {
      _showMessage(
        'Live publishing needs PORTFOLIO_PUBLIC_BASE_URL configured first.',
      );
      return;
    }
    final active = _publication?.isPublished == true;
    final username =
        _publication?.username ?? widget.content.profile.value?.username;
    if (username == null || username.isEmpty) {
      _showMessage('Add a profile username before publishing a website.');
      return;
    }
    late final String url;
    try {
      url = repository.publicUrl(username);
    } on Object catch (error) {
      _showMessage('The website URL is invalid: $error');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          active ? 'Update your public website?' : 'Publish your website?',
        ),
        content: Text(
          'The selected content shown in the preview above will be public at '
          '$url. Private Evidence files are never included. Copies or cached '
          'versions outside Prooffolio may persist after unpublishing.',
        ),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Review again'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(active ? 'Update now' : 'Publish now'),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _publishing = true;
      _publicationMessage = null;
    });
    try {
      final publication = active
          ? await repository.updatePublished(
              widget.content,
              _selection,
              PortfolioTemplate.light,
            )
          : await repository.publish(
              widget.content,
              _selection,
              PortfolioTemplate.light,
            );
      if (!mounted) return;
      setState(() {
        _publication = publication;
        _publicationMessage = active
            ? 'Website updated.'
            : 'Website published.';
      });
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _publicationMessage = 'Website could not be published: $error',
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _unpublish() async {
    final repository = widget.publicationRepository;
    final userId = widget.userId;
    final publication = _publication;
    if (repository == null ||
        userId == null ||
        userId.isEmpty ||
        publication == null ||
        !publication.isPublished ||
        _publishing) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpublish your website?'),
        content: const Text(
          'Prooffolio will remove the files in your published website folder '
          'and deactivate its URL. Copies or cached versions may persist '
          'outside Prooffolio.',
        ),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep published'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm unpublish'),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _publishing = true);
    try {
      await repository.unpublish(userId);
      if (!mounted) return;
      setState(
        () => _publication = publication.copyWith(
          isPublished: false,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      _showMessage('Website unpublished and its files removed.');
    } on Object catch (error) {
      if (mounted) _showMessage('Website could not be unpublished: $error');
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _copyPublicUrl() async {
    final repository = widget.publicationRepository;
    final publication = _publication;
    if (repository == null || publication?.isPublished != true) return;
    try {
      await Clipboard.setData(
        ClipboardData(text: repository.publicUrl(publication!.username)),
      );
      if (mounted) _showMessage('Website URL copied.');
    } on Object catch (error) {
      if (mounted) _showMessage('Website URL could not be copied: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editPortfolio() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    if (!mounted) return;
    final target = _selectionOptionsKey.currentContext;
    if (target == null || !target.mounted) return;
    await Scrollable.ensureVisible(
      target,
      alignment: 0.05,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _toggleSet(
    Set<String> selected,
    String id,
    ValueChanged<Set<String>> onChanged,
  ) {
    final next = Set<String>.of(selected);
    if (!next.add(id)) next.remove(id);
    onChanged(next);
  }

  Widget _profileChoice({
    required String label,
    required String value,
    required bool selected,
    required ValueChanged<bool> onChanged,
  }) => CheckboxListTile(
    contentPadding: EdgeInsets.zero,
    value: selected,
    onChanged: value.trim().isEmpty ? null : (checked) => onChanged(checked!),
    title: Text(label),
    subtitle: Text(value.trim().isEmpty ? 'No value saved' : value),
    controlAffinity: ListTileControlAffinity.leading,
  );

  Widget _contactChoice({
    required String label,
    required String value,
    required bool selected,
    required ValueChanged<bool> onChanged,
  }) => CheckboxListTile(
    contentPadding: EdgeInsets.zero,
    value: selected,
    onChanged: value.trim().isEmpty ? null : (checked) => onChanged(checked!),
    title: Text(label),
    subtitle: Text(value.trim().isEmpty ? 'No value saved' : value),
    controlAffinity: ListTileControlAffinity.leading,
  );

  List<Widget> _recordChoices<T>({
    required PortfolioSource<List<T>> source,
    required String emptyMessage,
    required String Function(T record) idFor,
    required String Function(T record) titleFor,
    required Set<String> selectedIds,
    required ValueChanged<Set<String>> onChanged,
  }) {
    if (!source.isAvailable) {
      return [
        const ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'This information could not be loaded. Refresh and retry.',
          ),
        ),
      ];
    }
    final records = source.value ?? const [];
    if (records.isEmpty) {
      return [
        ListTile(contentPadding: EdgeInsets.zero, title: Text(emptyMessage)),
      ];
    }
    return records
        .map(
          (record) => CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: selectedIds.contains(idFor(record)),
            onChanged: (checked) =>
                _toggleSet(selectedIds, idFor(record), onChanged),
            title: Text(titleFor(record)),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        )
        .toList(growable: false);
  }

  Widget _publicationControls() {
    final repository = widget.publicationRepository;
    if (repository == null || widget.userId == null) {
      return const SizedBox.shrink();
    }
    final publication = _publication;
    final active = publication?.isPublished == true;
    final configured = repository.isConfigured;
    return _SelectionCard(
      title: 'Publishing',
      children: [
        if (_publicationMessage case final message?)
          Semantics(liveRegion: true, child: Text(message)),
        if (_loadingPublication)
          const LinearProgressIndicator()
        else if (_publicationError case final error?)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Publication status could not be loaded: $error'),
              TextButton(
                onPressed: _loadPublicationStatus,
                child: const Text('Try again'),
              ),
            ],
          )
        else if (active) ...[
          const Text('Your website is public.'),
          if (configured)
            SelectableText(repository.publicUrl(publication!.username))
          else
            const Text(
              'The public URL cannot be shown until '
              'PORTFOLIO_PUBLIC_BASE_URL is configured.',
            ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: configured && !_publishing ? _copyPublicUrl : null,
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copy website URL'),
              ),
              FilledButton.icon(
                onPressed: configured && !_publishing && !_generating
                    ? _publish
                    : null,
                icon: const Icon(Icons.publish_outlined),
                label: const Text('Update published website'),
              ),
              TextButton.icon(
                onPressed: !_publishing ? _unpublish : null,
                icon: const Icon(Icons.public_off_outlined),
                label: const Text('Unpublish website'),
              ),
            ],
          ),
        ] else if (!configured)
          const Text(
            'Live publishing is unavailable until PORTFOLIO_PUBLIC_BASE_URL '
            'is set to the published-portfolios bucket URL. You can still '
            'download your website ZIP.',
          )
        else
          const Text('Your website is ready to publish.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.content.profile.value;
    final html = _bundle == null
        ? null
        : PortfolioSiteGenerator.previewHtml(_bundle!);
    final photoPath = profile?.photoPath;
    final photoCanBeIncluded =
        photoPath != null &&
        photoPath.isNotEmpty &&
        widget.content.photoBytes.isAvailable &&
        widget.content.photoBytes.value != null;
    final canPublish =
        widget.publicationRepository != null &&
        widget.userId != null &&
        widget.userId!.isNotEmpty;
    final primaryActionLabel = canPublish
        ? _publication?.isPublished == true
              ? 'Update Portfolio'
              : 'Publish Portfolio'
        : 'Download Website';
    final primaryActionIcon = canPublish
        ? Icons.publish_outlined
        : Icons.download_outlined;

    return Scaffold(
      appBar: const AppPageAppBar(title: 'Portfolio Preview'),
      body: SizedBox.expand(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                _portfolioSummaryCard(profile),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final heading = Text(
                      'Website preview',
                      style: Theme.of(context).textTheme.titleLarge,
                    );
                    final toggle = SegmentedButton<String>(
                      key: const ValueKey('portfolio-preview-mode-toggle'),
                      segments: const [
                        ButtonSegment(
                          value: 'website',
                          icon: Icon(Icons.desktop_windows_outlined),
                          label: Text('Website'),
                        ),
                        ButtonSegment(
                          value: 'mobile',
                          icon: Icon(Icons.smartphone_outlined),
                          label: Text('Mobile'),
                        ),
                      ],
                      selected: {_isMobilePreview ? 'mobile' : 'website'},
                      onSelectionChanged: (selection) => setState(
                        () => _isMobilePreview = selection.single == 'mobile',
                      ),
                    );
                    if (constraints.maxWidth < 380) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          heading,
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: toggle,
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: heading),
                        toggle,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.indigoContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: AppColors.indigo),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Review how your portfolio will look. Changes stay '
                          'private until you publish.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildLivePreview(html),
                if (_generationError case final error?) ...[
                  const SizedBox(height: 12),
                  Text(
                    'The selected website could not be generated: $error',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _bundle == null || _generating
                        ? null
                        : _download,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Download website ZIP'),
                  ),
                ),
                const SizedBox(height: 12),
                _readinessCard(),
                const SizedBox(height: 20),
                KeyedSubtree(
                  key: _selectionOptionsKey,
                  child: _SelectionCard(
                    title: 'Choose what to include',
                    children: [
                      const Text(
                        'All saved profile and work details are selected '
                        'initially. Uncheck anything you do not want on your '
                        'website.',
                      ),
                      const SizedBox(height: 12),
                      _SelectionCard(
                        title: 'Profile',
                        children: [
                          _profileChoice(
                            label: 'Display name',
                            value: profile?.displayName ?? '',
                            selected: _selection.includeDisplayName,
                            onChanged: (value) => _updateSelection(
                              _selection.copyWith(includeDisplayName: value),
                            ),
                          ),
                          _profileChoice(
                            label: 'Headline',
                            value: profile?.headline ?? '',
                            selected: _selection.includeHeadline,
                            onChanged: (value) => _updateSelection(
                              _selection.copyWith(includeHeadline: value),
                            ),
                          ),
                          _profileChoice(
                            label: 'Role or occupation',
                            value: profile?.occupationTitle ?? '',
                            selected: _selection.includeOccupationTitle,
                            onChanged: (value) => _updateSelection(
                              _selection.copyWith(
                                includeOccupationTitle: value,
                              ),
                            ),
                          ),
                          _profileChoice(
                            label: 'Introduction',
                            value: profile?.bio ?? '',
                            selected: _selection.includeBio,
                            onChanged: (value) => _updateSelection(
                              _selection.copyWith(includeBio: value),
                            ),
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _selection.includePhoto,
                            onChanged: photoCanBeIncluded
                                ? (value) => _updateSelection(
                                    _selection.copyWith(includePhoto: value!),
                                  )
                                : null,
                            title: const Text('Profile photo'),
                            subtitle: Text(
                              photoCanBeIncluded
                                  ? 'Copy a selected image into the website files.'
                                  : 'No downloadable profile photo is available.',
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],
                      ),
                      _SelectionCard(
                        title: 'Contact',
                        children: [
                          if (profile == null)
                            const ListTile(
                              title: Text(
                                'Profile details could not be loaded.',
                              ),
                            )
                          else ...[
                            _contactChoice(
                              label: 'Email',
                              value: profile.contactEmail,
                              selected: _selection.includeEmail,
                              onChanged: (value) => _updateSelection(
                                _selection.copyWith(includeEmail: value),
                              ),
                            ),
                            _contactChoice(
                              label: 'Phone',
                              value: profile.phone,
                              selected: _selection.includePhone,
                              onChanged: (value) => _updateSelection(
                                _selection.copyWith(includePhone: value),
                              ),
                            ),
                            _contactChoice(
                              label: 'GitHub',
                              value: profile.githubUrl,
                              selected: _selection.includeGithub,
                              onChanged: (value) => _updateSelection(
                                _selection.copyWith(includeGithub: value),
                              ),
                            ),
                            _contactChoice(
                              label: 'LinkedIn',
                              value: profile.linkedInUrl,
                              selected: _selection.includeLinkedIn,
                              onChanged: (value) => _updateSelection(
                                _selection.copyWith(includeLinkedIn: value),
                              ),
                            ),
                            _contactChoice(
                              label: 'Upwork',
                              value: profile.upworkUrl,
                              selected: _selection.includeUpwork,
                              onChanged: (value) => _updateSelection(
                                _selection.copyWith(includeUpwork: value),
                              ),
                            ),
                            _contactChoice(
                              label: 'JobStreet',
                              value: profile.jobstreetUrl,
                              selected: _selection.includeJobstreet,
                              onChanged: (value) => _updateSelection(
                                _selection.copyWith(includeJobstreet: value),
                              ),
                            ),
                            _contactChoice(
                              label: 'WhatsApp',
                              value: profile.whatsAppNumber,
                              selected: _selection.includeWhatsApp,
                              onChanged: (value) => _updateSelection(
                                _selection.copyWith(includeWhatsApp: value),
                              ),
                            ),
                            if (profile.additionalLinks.isNotEmpty)
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                value: _selection.includeAdditionalLinks,
                                onChanged: (value) => _updateSelection(
                                  _selection.copyWith(
                                    includeAdditionalLinks: value!,
                                  ),
                                ),
                                title: const Text('Additional labeled links'),
                                subtitle: Text(
                                  profile.additionalLinks
                                      .map(
                                        (link) => '${link.label}: ${link.url}',
                                      )
                                      .join('\n'),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ),
                          ],
                        ],
                      ),
                      _SelectionCard(
                        title: 'Projects',
                        children: _recordChoices(
                          source: widget.content.projects,
                          emptyMessage: 'No projects saved.',
                          idFor: (record) => record.id,
                          titleFor: (record) => record.title,
                          selectedIds: _selection.projectIds,
                          onChanged: (ids) => _updateSelection(
                            _selection.copyWith(projectIds: ids),
                          ),
                        ),
                      ),
                      _SelectionCard(
                        title: 'Skills',
                        children: _recordChoices(
                          source: widget.content.skills,
                          emptyMessage: 'No skills saved.',
                          idFor: (record) => record.id,
                          titleFor: (record) => record.name,
                          selectedIds: _selection.skillIds,
                          onChanged: (ids) => _updateSelection(
                            _selection.copyWith(skillIds: ids),
                          ),
                        ),
                      ),
                      _SelectionCard(
                        title: 'Education',
                        children: _recordChoices(
                          source: widget.content.education,
                          emptyMessage: 'No education saved.',
                          idFor: (record) => record.id,
                          titleFor: (record) => record.title,
                          selectedIds: _selection.educationIds,
                          onChanged: (ids) => _updateSelection(
                            _selection.copyWith(educationIds: ids),
                          ),
                        ),
                      ),
                      _SelectionCard(
                        title: 'Experience',
                        children: _recordChoices(
                          source: widget.content.experience,
                          emptyMessage: 'No experience saved.',
                          idFor: (record) => record.id,
                          titleFor: (record) => record.title,
                          selectedIds: _selection.experienceIds,
                          onChanged: (ids) => _updateSelection(
                            _selection.copyWith(experienceIds: ids),
                          ),
                        ),
                      ),
                      _SelectionCard(
                        title: 'Certifications',
                        children: _recordChoices(
                          source: widget.content.certifications,
                          emptyMessage: 'No certifications saved.',
                          idFor: (record) => record.id,
                          titleFor: (record) => record.title,
                          selectedIds: _selection.certificationIds,
                          onChanged: (ids) => _updateSelection(
                            _selection.copyWith(certificationIds: ids),
                          ),
                        ),
                      ),
                      _SelectionCard(
                        title: 'Achievements',
                        children: _recordChoices(
                          source: widget.content.achievements,
                          emptyMessage: 'No achievements saved.',
                          idFor: (record) => record.id,
                          titleFor: (record) => record.title,
                          selectedIds: _selection.achievementIds,
                          onChanged: (ids) => _updateSelection(
                            _selection.copyWith(achievementIds: ids),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The published website uses one responsive design and '
                        'includes its own light/dark theme toggle.',
                      ),
                    ],
                  ),
                ),
                if (widget.publicationRepository != null &&
                    widget.userId != null) ...[
                  const SizedBox(height: 12),
                  _publicationControls(),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: const Border(top: BorderSide(color: AppColors.lightSlate)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Align(
            heightFactor: 1,
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _editPortfolio,
                      icon: const Icon(Icons.tune_outlined),
                      label: const Text('Edit Portfolio'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          _bundle == null ||
                              _generating ||
                              _publishing ||
                              (canPublish && _loadingPublication)
                          ? null
                          : canPublish
                          ? _publish
                          : _download,
                      icon: Icon(primaryActionIcon),
                      label: Text(
                        primaryActionLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _portfolioSummaryCard(PortfolioProfile? profile) => Card(
    color: AppColors.deepNavy,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.white.withValues(alpha: 0.14),
            child: const Icon(
              Icons.language_outlined,
              color: AppColors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Portfolio',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile?.displayName.trim().isNotEmpty == true
                      ? profile!.displayName
                      : 'Website draft',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.tealAccent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _publication?.isPublished == true ? 'LIVE' : 'DRAFT',
              style: TextStyle(
                color: AppColors.tealAccent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildLivePreview(String? html) {
    final previewHtml = html;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Live preview', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.lightSlate),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = _isMobilePreview
                  ? constraints.maxWidth.clamp(0, 375).toDouble()
                  : constraints.maxWidth;
              return Align(
                alignment: Alignment.topCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: width,
                  height: _isMobilePreview ? 620 : 700,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(
                      _isMobilePreview ? 24 : 12,
                    ),
                    border: Border.all(color: AppColors.lightSlate),
                  ),
                  child: previewHtml == null
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              _generating
                                  ? 'Preparing your portfolio preview...'
                                  : 'Select valid content to preview your website.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : widget.previewBuilder?.call(context, previewHtml) ??
                            SitePreviewSurface(html: previewHtml),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _readinessCard() {
    final suggestions = PortfolioReadiness.evaluate(widget.content);
    final covered = suggestions
        .where((suggestion) => suggestion.isCovered)
        .length;
    final progress = suggestions.isEmpty ? 0.0 : covered / suggestions.length;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portfolio readiness',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text('$covered of ${suggestions.length} areas covered'),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              color: AppColors.indigo,
              backgroundColor: AppColors.indigoContainer,
            ),
            const SizedBox(height: 8),
            const Text(
              'This checklist reflects saved content. Private evidence files '
              'are never added to your public website.',
            ),
            const SizedBox(height: 8),
            for (final suggestion in suggestions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  suggestion.isCovered
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                  color: suggestion.isCovered
                      ? AppColors.teal
                      : AppColors.slateGray,
                ),
                title: Text(suggestion.label),
                subtitle: Text(suggestion.explanation),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
}
