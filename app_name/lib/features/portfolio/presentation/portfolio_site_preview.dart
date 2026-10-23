import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

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
  PortfolioTemplate _template = PortfolioTemplate.light;
  late PortfolioSiteBundle? _bundle;
  Object? _generationError;
  PortfolioPublication? _publication;
  Object? _publicationError;
  bool _loadingPublication = false;
  bool _publishing = false;

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
      setState(() {
        _publication = publication;
        _loadingPublication = false;
        if (publication?.isPublished == true) {
          _selection = publication!.selection;
          _template = publication.template;
          _regenerate();
        }
      });
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
      _regenerate();
    });
  }

  void _updateTemplate(PortfolioTemplate template) {
    setState(() {
      _template = template;
      _regenerate();
    });
  }

  void _regenerate() {
    try {
      _bundle = PortfolioSiteGenerator.generate(
        widget.content,
        _selection,
        _template,
      );
      _generationError = null;
    } on Object catch (error) {
      _bundle = null;
      _generationError = error;
    }
  }

  Future<void> _download() async {
    final bundle = _bundle;
    if (bundle == null) return;
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
    );
    if (confirmed != true || !mounted) return;
    setState(() => _publishing = true);
    try {
      final publication = active
          ? await repository.updatePublished(
              widget.content,
              _selection,
              _template,
            )
          : await repository.publish(widget.content, _selection, _template);
      if (!mounted) return;
      setState(() => _publication = publication);
      _showMessage(active ? 'Website updated.' : 'Website published.');
    } on Object catch (error) {
      if (mounted) {
        _showMessage('Website could not be published: $error');
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
                onPressed: configured && !_publishing ? _publish : null,
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
          FilledButton.icon(
            onPressed: _publishing || _bundle == null ? null : _publish,
            icon: const Icon(Icons.publish_outlined),
            label: const Text('Publish website'),
          ),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Website preview')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Choose what to include',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'All saved profile and work details are selected initially. '
                'Uncheck anything you do not want in your website. You control '
                'who sees downloaded files; live publishing always requires '
                'review and confirmation.',
              ),
              const SizedBox(height: 20),
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
                      _selection.copyWith(includeOccupationTitle: value),
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
                      title: Text('Profile details could not be loaded.'),
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
                          _selection.copyWith(includeAdditionalLinks: value!),
                        ),
                        title: const Text('Additional labeled links'),
                        subtitle: Text(
                          profile.additionalLinks
                              .map((link) => '${link.label}: ${link.url}')
                              .join('\n'),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
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
                  onChanged: (ids) =>
                      _updateSelection(_selection.copyWith(projectIds: ids)),
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
                  onChanged: (ids) =>
                      _updateSelection(_selection.copyWith(skillIds: ids)),
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
                  onChanged: (ids) =>
                      _updateSelection(_selection.copyWith(educationIds: ids)),
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
                  onChanged: (ids) =>
                      _updateSelection(_selection.copyWith(experienceIds: ids)),
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
              const SizedBox(height: 12),
              SegmentedButton<PortfolioTemplate>(
                segments: const [
                  ButtonSegment(
                    value: PortfolioTemplate.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: PortfolioTemplate.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {_template},
                onSelectionChanged: (selected) =>
                    _updateTemplate(selected.single),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _bundle == null ? null : _download,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Download website ZIP'),
              ),
              if (widget.publicationRepository != null &&
                  widget.userId != null) ...[
                const SizedBox(height: 12),
                _publicationControls(),
              ],
              if (_generationError case final error?) ...[
                const SizedBox(height: 12),
                Text(
                  'The selected website could not be generated: $error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Live preview',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (html case final previewHtml?)
                SizedBox(
                  height: 700,
                  child:
                      widget.previewBuilder?.call(context, previewHtml) ??
                      SitePreviewSurface(html: previewHtml),
                )
              else
                const SizedBox(
                  height: 220,
                  child: Center(
                    child: Text(
                      'Select valid content to preview your website.',
                    ),
                  ),
                ),
            ],
          ),
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
