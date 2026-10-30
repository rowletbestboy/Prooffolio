import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../domain/portfolio_content.dart';
import '../domain/portfolio_template.dart';

class PortfolioSiteBundle {
  const PortfolioSiteBundle(this.files);

  final Map<String, Uint8List> files;

  Uint8List toZipBytes() {
    final archive = Archive();
    for (final entry in files.entries) {
      archive.addFile(
        ArchiveFile(
          entry.key,
          entry.value.length,
          Uint8List.fromList(entry.value),
        ),
      );
    }
    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw StateError('The portfolio website ZIP could not be created.');
    }
    return Uint8List.fromList(encoded);
  }
}

abstract final class PortfolioSiteGenerator {
  static PortfolioSiteBundle generate(
    PortfolioContent content,
    PortfolioSelection selection,
    PortfolioTemplate template,
  ) {
    final profile = content.profile.value;
    final photoAsset = _selectedPhoto(content, selection, profile);
    final files = <String, Uint8List>{
      'index.html': _bytes(_html(content, profile, selection, photoAsset)),
      'styles.css': _bytes(_styles()),
      'app.js': _bytes(_script),
      if (photoAsset != null) photoAsset.name: photoAsset.bytes,
    };
    return PortfolioSiteBundle(Map.unmodifiable(files));
  }

  static String previewHtml(PortfolioSiteBundle bundle) {
    var html = utf8.decode(bundle.files['index.html']!);
    final css = utf8.decode(bundle.files['styles.css']!);
    final script = utf8.decode(bundle.files['app.js']!);
    html = html.replaceFirst(
      '<link rel="stylesheet" href="styles.css">',
      '<style>$css</style>',
    );
    html = html.replaceFirst(
      '<script src="app.js" defer></script>',
      '<script>$script</script>',
    );
    for (final entry in bundle.files.entries) {
      if (entry.key == 'index.html' ||
          entry.key == 'styles.css' ||
          entry.key == 'app.js') {
        continue;
      }
      final mediaType = _mediaType(entry.key);
      final dataUri = 'data:$mediaType;base64,${base64Encode(entry.value)}';
      html = html.replaceAll(
        'src="${_escapeAttribute(entry.key)}"',
        'src="$dataUri"',
      );
    }
    return html;
  }

  static String _html(
    PortfolioContent content,
    PortfolioProfile? profile,
    PortfolioSelection selection,
    _PhotoAsset? photoAsset,
  ) {
    final projects = _selected(
      content.projects,
      selection.projectIds,
      (project) => project.id,
    );
    final skills = _selected(
      content.skills,
      selection.skillIds,
      (skill) => skill.id,
    );
    final education = _selected(
      content.education,
      selection.educationIds,
      (record) => record.id,
    );
    final experience = _selected(
      content.experience,
      selection.experienceIds,
      (record) => record.id,
    );
    final certifications = _selected(
      content.certifications,
      selection.certificationIds,
      (record) => record.id,
    );
    final achievements = _selected(
      content.achievements,
      selection.achievementIds,
      (record) => record.id,
    );
    final displayName = selection.includeDisplayName
        ? profile?.displayName.trim() ?? ''
        : '';
    final hasContact =
        profile != null && _hasSelectedContacts(profile, selection);
    final hasAbout =
        (selection.includeBio && profile?.bio.trim().isNotEmpty == true) ||
        experience.isNotEmpty ||
        education.isNotEmpty ||
        certifications.isNotEmpty ||
        achievements.isNotEmpty;
    final hasProfileCard =
        photoAsset != null ||
        (selection.includeOccupationTitle &&
            profile?.occupationTitle.trim().isNotEmpty == true) ||
        skills.isNotEmpty ||
        projects.isNotEmpty;
    final title = displayName.isEmpty
        ? 'Portfolio'
        : '$displayName — Portfolio';
    final output = StringBuffer('''<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <meta name="description" content="${_escapeAttribute(_description(profile, selection))}">
  <meta name="theme-color" content="#EEF1F5">
  <title>${_escapeText(title)}</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
''');
    _writeHeader(
      output,
      displayName,
      projects.isNotEmpty,
      skills.isNotEmpty,
      hasAbout,
      hasContact,
    );
    output
      ..write('<main id="top">')
      ..write(
        '<section class="hero"><div class="wrap hero-grid${hasProfileCard ? ' has-profile' : ''}"><div class="hero-copy">',
      );
    final eyebrow = <String>{
      if (selection.includeOccupationTitle &&
          profile?.occupationTitle.trim().isNotEmpty == true)
        profile!.occupationTitle.trim(),
      if (selection.includeHeadline &&
          profile?.headline.trim().isNotEmpty == true)
        profile!.headline.trim(),
    }.join(' · ');
    if (eyebrow.isNotEmpty) {
      output
        ..write(
          '<div class="eyebrow"><span class="bar" aria-hidden="true"></span>',
        )
        ..write('<span class="mono">${_escapeText(eyebrow)}</span></div>');
    }
    output.write(
      '<h1>${displayName.isEmpty ? 'Portfolio' : _escapeText(displayName)}',
    );
    if (selection.includeHeadline &&
        profile?.headline.trim().isNotEmpty == true &&
        displayName.isNotEmpty) {
      output.write('<br><em>${_escapeText(profile!.headline.trim())}</em>');
    }
    output.write('</h1>');
    if (selection.includeBio && profile?.bio.trim().isNotEmpty == true) {
      output.write('<p class="lead">${_escapeText(profile!.bio.trim())}</p>');
    } else if (selection.includeOccupationTitle &&
        profile?.occupationTitle.trim().isNotEmpty == true) {
      output.write(
        '<p class="lead">${_escapeText(profile!.occupationTitle.trim())}</p>',
      );
    }
    if (projects.isNotEmpty || hasContact) {
      output.write('<div class="actions">');
      if (projects.isNotEmpty) {
        output.write('<a class="btn primary" href="#work">See my projects</a>');
      }
      if (hasContact) {
        output.write('<a class="btn ghost" href="#contact">Contact me</a>');
      }
      output.write('</div>');
    }
    output.write('</div>');
    if (hasProfileCard) {
      _writeProfileCard(
        output,
        profile,
        selection,
        photoAsset,
        projects,
        skills,
        hasContact,
      );
    }
    output.write('</div></section>');
    if (projects.isNotEmpty) _writeProjects(output, projects);
    if (skills.isNotEmpty) _writeSkills(output, skills);
    if (hasAbout) {
      _writeAbout(
        output,
        profile,
        selection,
        experience,
        education,
        certifications,
        achievements,
      );
    }
    if (profile != null && hasContact) {
      _writeContacts(output, profile, selection);
    }
    output.write('''
  </main>
  <footer class="site-foot"><div class="wrap foot-in"><span>${displayName.isEmpty ? 'Portfolio' : _escapeText(displayName)}</span><a href="#top">Back to top ↑</a></div></footer>
  <script src="app.js" defer></script>
</body>
</html>
''');
    return output.toString();
  }

  static void _writeHeader(
    StringBuffer output,
    String displayName,
    bool hasProjects,
    bool hasSkills,
    bool hasAbout,
    bool hasContact,
  ) {
    output
      ..write('<header class="site-head"><div class="wrap head-in">')
      ..write(
        '<a class="brand" href="#top">${displayName.isEmpty ? 'Portfolio' : _escapeText(displayName)}</a>',
      )
      ..write('<nav class="nav" aria-label="Primary">');
    if (hasProjects) output.write('<a href="#work">Projects</a>');
    if (hasSkills) output.write('<a href="#skills">Skills</a>');
    if (hasAbout) output.write('<a href="#about">About</a>');
    if (hasContact) output.write('<a class="cta" href="#contact">Contact</a>');
    output.write(
      '<button class="icon-btn" id="theme-btn" type="button" aria-label="Switch theme"></button>',
    );
    output.write('</nav></div></header>');
  }

  static void _writeProfileCard(
    StringBuffer output,
    PortfolioProfile? profile,
    PortfolioSelection selection,
    _PhotoAsset? photoAsset,
    List<PortfolioProject> projects,
    List<PortfolioSkill> skills,
    bool hasContact,
  ) {
    output.write('<aside class="profile" aria-label="Profile at a glance">');
    if (photoAsset != null) {
      final alt =
          selection.includeDisplayName &&
              profile?.displayName.trim().isNotEmpty == true
          ? profile!.displayName.trim()
          : 'Profile photo';
      output.write(
        '<div class="profile-photo-wrap"><img class="profile-photo" src="${_escapeAttribute(photoAsset.name)}" alt="${_escapeAttribute(alt)}" width="160" height="160"></div>',
      );
    }
    output
      ..write(
        '<div class="prof-head"><span class="dot" aria-hidden="true"></span><span class="mono">At a glance</span></div>',
      )
      ..write('<dl class="prof-list">');
    if (selection.includeOccupationTitle &&
        profile?.occupationTitle.trim().isNotEmpty == true) {
      _writeFact(output, 'Focus', profile!.occupationTitle.trim());
    }
    if (skills.isNotEmpty) {
      _writeFact(
        output,
        'Skills',
        skills
            .take(4)
            .map((skill) => skill.name.trim())
            .where((name) => name.isNotEmpty)
            .join(', '),
      );
    }
    if (projects.isNotEmpty) {
      _writeFact(
        output,
        'Featured',
        projects
            .take(2)
            .map((project) => project.title.trim())
            .where((title) => title.isNotEmpty)
            .join(', '),
      );
    }
    if (selection.includeHeadline &&
        profile?.headline.trim().isNotEmpty == true &&
        !selection.includeOccupationTitle) {
      _writeFact(output, 'Headline', profile!.headline.trim());
    }
    output.write('</dl>');
    if (hasContact) {
      output.write(
        '<a class="prof-link" href="#contact">Start a conversation <span aria-hidden="true">→</span></a>',
      );
    }
    output.write('</aside>');
  }

  static void _writeFact(StringBuffer output, String label, String value) {
    if (value.trim().isEmpty) return;
    output.write(
      '<div><dt>${_escapeText(label)}</dt><dd>${_escapeText(value.trim())}</dd></div>',
    );
  }

  static bool _hasSelectedContacts(
    PortfolioProfile profile,
    PortfolioSelection selection,
  ) {
    bool hasText(bool selected, String value) =>
        selected && value.trim().isNotEmpty;
    bool hasUrl(bool selected, String value) =>
        selected && _safeHttpUrl(value) != null;
    return hasText(selection.includeEmail, profile.contactEmail) ||
        hasText(selection.includePhone, profile.phone) ||
        hasUrl(selection.includeGithub, profile.githubUrl) ||
        hasUrl(selection.includeLinkedIn, profile.linkedInUrl) ||
        hasUrl(selection.includeUpwork, profile.upworkUrl) ||
        hasUrl(selection.includeJobstreet, profile.jobstreetUrl) ||
        hasText(selection.includeWhatsApp, profile.whatsAppNumber) ||
        (selection.includeAdditionalLinks &&
            profile.additionalLinks.any(
              (link) => _safeHttpUrl(link.url) != null,
            ));
  }

  static String _description(
    PortfolioProfile? profile,
    PortfolioSelection selection,
  ) {
    if (selection.includeBio && profile?.bio.trim().isNotEmpty == true) {
      return profile!.bio.trim();
    }
    if (selection.includeHeadline &&
        profile?.headline.trim().isNotEmpty == true) {
      return profile!.headline.trim();
    }
    return 'Portfolio';
  }

  static void _writeContacts(
    StringBuffer output,
    PortfolioProfile profile,
    PortfolioSelection selection,
  ) {
    final contacts = <String>[];
    void addText(bool selected, String label, String value) {
      if (selected && value.trim().isNotEmpty) {
        contacts.add(
          '<div class="contact-row"><div><span class="mono lab">${_escapeText(label)}</span><span class="val">${_escapeText(value.trim())}</span></div><button class="copy" type="button" data-copy="${_escapeAttribute(value.trim())}">Copy</button></div>',
        );
      }
    }

    void addLink(bool selected, String label, String value) {
      if (!selected || value.trim().isEmpty) return;
      final safeUrl = _safeHttpUrl(value);
      if (safeUrl == null) return;
      contacts.add(
        '<div class="contact-row"><div><span class="mono lab">${_escapeText(label)}</span><a class="val" href="${_escapeAttribute(safeUrl)}" target="_blank" rel="noopener noreferrer">${_escapeText(value.trim())}</a></div><button class="copy" type="button" data-copy="${_escapeAttribute(value.trim())}">Copy</button></div>',
      );
    }

    addText(selection.includeEmail, 'Email', profile.contactEmail);
    addText(selection.includePhone, 'Phone', profile.phone);
    addLink(selection.includeGithub, 'GitHub', profile.githubUrl);
    addLink(selection.includeLinkedIn, 'LinkedIn', profile.linkedInUrl);
    addLink(selection.includeUpwork, 'Upwork', profile.upworkUrl);
    addLink(selection.includeJobstreet, 'JobStreet', profile.jobstreetUrl);
    addText(selection.includeWhatsApp, 'WhatsApp', profile.whatsAppNumber);
    if (selection.includeAdditionalLinks) {
      for (final link in profile.additionalLinks) {
        addLink(true, link.label, link.url);
      }
    }
    if (contacts.isNotEmpty) {
      output
        ..write(
          '<section class="section" id="contact"><div class="wrap contact"><div><h2>Let’s connect.</h2><p class="sub">Contact details selected for sharing.</p></div><div class="c-list">',
        )
        ..write(contacts.join())
        ..write('</div></div></section>');
    }
  }

  static void _writeProjects(
    StringBuffer output,
    List<PortfolioProject> projects,
  ) {
    output
      ..write('<section class="section" id="work"><div class="wrap">')
      ..write(
        '<div class="sec-head"><h2>Selected projects</h2><span class="mono">${projects.length} ${projects.length == 1 ? 'project' : 'projects'}</span></div>',
      );
    for (var index = 0; index < projects.length; index++) {
      final project = projects[index];
      final details = <(String, String)>[
        if (project.contribution.trim().isNotEmpty)
          ('Contribution', project.contribution.trim()),
        if (project.technologies.isNotEmpty)
          ('Tools', project.technologies.join(', ')),
        if (project.statusLabel.trim().isNotEmpty)
          ('Status', project.statusLabel.trim()),
        if (_formatDate(project.startDate).isNotEmpty ||
            _formatDate(project.endDate).isNotEmpty)
          ('Dates', _dateText(project.startDate, project.endDate)),
      ];
      output
        ..write(
          '<article class="case"><div class="case-main"><div class="case-text"><span class="mono">Selected project</span>',
        )
        ..write('<h3>${_escapeText(project.title.trim())}</h3>')
        ..write(_element('p', project.summary, 'full-title'))
        ..write(_element('p', project.description, 'desc'))
        ..write('</div>');
      if (details.isNotEmpty) {
        output.write(
          '<div class="case-panel"><div class="tabs" role="tablist" aria-label="${_escapeAttribute(project.title)} details">',
        );
        for (var detailIndex = 0; detailIndex < details.length; detailIndex++) {
          final tabId = 'project-$index-tab-$detailIndex';
          output.write(
            '<button class="tab" role="tab" id="$tabId" aria-controls="project-$index-panel-$detailIndex" aria-selected="${detailIndex == 0 ? 'true' : 'false'}"${detailIndex == 0 ? '' : ' tabindex="-1"'}>${_escapeText(details[detailIndex].$1)}</button>',
          );
        }
        output.write('</div>');
        for (var detailIndex = 0; detailIndex < details.length; detailIndex++) {
          final (label, value) = details[detailIndex];
          output
            ..write(
              '<div class="tabpanel" role="tabpanel" id="project-$index-panel-$detailIndex" aria-labelledby="project-$index-tab-$detailIndex"${detailIndex == 0 ? '' : ' hidden'}>',
            )
            ..write(
              '<ul class="highlights"><li><strong>${_escapeText(label)}</strong><span>${_escapeText(value)}</span></li></ul></div>',
            );
        }
        output.write('</div>');
      }
      output.write('</div></article>');
    }
    output.write('</div></section>');
  }

  static void _writeSkills(StringBuffer output, List<PortfolioSkill> skills) {
    final grouped = <String, List<PortfolioSkill>>{};
    for (final skill in skills) {
      if (skill.name.trim().isEmpty) continue;
      final category = skill.category.trim().isEmpty
          ? 'Skills'
          : skill.category.trim();
      grouped.putIfAbsent(category, () => []).add(skill);
    }
    if (grouped.isEmpty) return;
    output
      ..write('<section class="section" id="skills"><div class="wrap">')
      ..write(
        '<div class="sec-head"><h2>Skills</h2><span class="mono">What I bring to a team</span></div><div class="tools">',
      );
    for (final entry in grouped.entries) {
      output.write(
        '<div class="tool-group"><h3>${_escapeText(entry.key)}</h3><ul>',
      );
      for (final skill in entry.value) {
        output
          ..write('<li>${_escapeText(skill.name.trim())}')
          ..write(_element('small', skill.status))
          ..write('</li>');
      }
      output.write('</ul></div>');
    }
    output.write('</div></div></section>');
  }

  static void _writeAbout(
    StringBuffer output,
    PortfolioProfile? profile,
    PortfolioSelection selection,
    List<PortfolioExperience> experience,
    List<PortfolioEducation> education,
    List<PortfolioRecordContent> certifications,
    List<PortfolioRecordContent> achievements,
  ) {
    output.write(
      '<section class="section" id="about"><div class="wrap about"><h2>About</h2><div class="about-body">',
    );
    if (selection.includeBio && profile?.bio.trim().isNotEmpty == true) {
      output.write('<p>${_escapeText(profile!.bio.trim())}</p>');
    }
    _writeExperience(output, experience);
    _writeEducation(output, education);
    _writeRecords(output, 'Certifications', certifications);
    _writeRecords(output, 'Achievements', achievements);
    output.write('</div></div></section>');
  }

  static void _writeExperience(
    StringBuffer output,
    List<PortfolioExperience> experience,
  ) {
    if (experience.isEmpty) return;
    output.write('<div class="background-group"><h3>Experience</h3>');
    for (final record in experience) {
      output
        ..write(
          '<article class="background-item"><h4>${_escapeText(record.title)}</h4>',
        )
        ..write(_element('p', record.organization))
        ..write(_element('p', record.type, 'muted'))
        ..write(_element('p', record.description))
        ..write(
          _dateRange(
            record.startDate,
            record.isCurrent ? null : record.endDate,
            current: record.isCurrent,
          ),
        )
        ..write('</article>');
    }
    output.write('</div>');
  }

  static void _writeEducation(
    StringBuffer output,
    List<PortfolioEducation> education,
  ) {
    if (education.isEmpty) return;
    output.write('<div class="background-group"><h3>Education</h3>');
    for (final record in education) {
      output
        ..write(
          '<article class="background-item"><h4>${_escapeText(record.title)}</h4>',
        )
        ..write(_element('p', record.institution))
        ..write(_element('p', record.level, 'muted'))
        ..write(_element('p', record.description))
        ..write(_dateRange(record.startDate, record.endDate))
        ..write('</article>');
    }
    output.write('</div>');
  }

  static void _writeRecords(
    StringBuffer output,
    String heading,
    List<PortfolioRecordContent> records,
  ) {
    if (records.isEmpty) return;
    output.write(
      '<div class="background-group"><h3>${_escapeText(heading)}</h3>',
    );
    for (final record in records) {
      output
        ..write(
          '<article class="background-item"><h4>${_escapeText(record.title)}</h4>',
        )
        ..write(_element('p', record.source))
        ..write(_element('p', record.description))
        ..write(_dateRange(record.achievedOn, record.expiresOn))
        ..write('</article>');
    }
    output.write('</div>');
  }

  static List<T> _selected<T>(
    PortfolioSource<List<T>> source,
    Set<String> selectedIds,
    String Function(T item) idFor,
  ) =>
      source.value
          ?.where((item) => selectedIds.contains(idFor(item)))
          .toList(growable: false) ??
      const [];

  static String _dateText(DateTime? start, DateTime? end) => [
    if (_formatDate(start).isNotEmpty) _formatDate(start),
    if (_formatDate(end).isNotEmpty) _formatDate(end),
  ].join(' – ');

  static String _dateRange(
    DateTime? start,
    DateTime? end, {
    bool current = false,
  }) {
    final date = [
      if (_formatDate(start).isNotEmpty) _formatDate(start),
      if (current)
        'Present'
      else if (_formatDate(end).isNotEmpty)
        _formatDate(end),
    ].join(' – ');
    if (date.isEmpty) return '';
    return '<p class="mono muted">${_escapeText(date)}</p>';
  }

  static String _element(String tag, String text, [String? className]) {
    if (text.trim().isEmpty) return '';
    final classAttribute = className == null
        ? ''
        : ' class="${_escapeAttribute(className)}"';
    return '<$tag$classAttribute>${_escapeText(text.trim())}</$tag>';
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  static String _escapeText(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');

  static String _escapeAttribute(String value) => _escapeText(value);

  static String? _safeHttpUrl(String value) {
    if (RegExp(r'[\u0000-\u0020]').hasMatch(value)) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !const {'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri.replace(scheme: uri.scheme.toLowerCase()).toString();
  }

  static _PhotoAsset? _selectedPhoto(
    PortfolioContent content,
    PortfolioSelection selection,
    PortfolioProfile? profile,
  ) {
    if (!selection.includePhoto) return null;
    if (profile?.photoPath == null || profile!.photoPath!.isEmpty) {
      throw StateError('Choose a profile photo before including it.');
    }
    if (!content.photoBytes.isAvailable) {
      throw StateError('The selected profile photo could not be loaded.');
    }
    final bytes = content.photoBytes.value;
    if (bytes == null) {
      throw StateError('The selected profile photo could not be loaded.');
    }
    final name = _photoFileName(bytes);
    return _PhotoAsset(name, Uint8List.fromList(bytes));
  }

  static String _photoFileName(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'portfolio-photo.jpg';
    }
    if (bytes.length >= 8 &&
        const [
          0x89,
          0x50,
          0x4e,
          0x47,
          0x0d,
          0x0a,
          0x1a,
          0x0a,
        ].asMap().entries.every((entry) => bytes[entry.key] == entry.value)) {
      return 'portfolio-photo.png';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'portfolio-photo.webp';
    }
    throw FormatException(
      'The selected profile photo is not a supported JPEG, PNG, or WebP image.',
    );
  }

  static String _mediaType(String name) => switch (name.split('.').last) {
    'jpg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'application/octet-stream',
  };

  static Uint8List _bytes(String value) =>
      Uint8List.fromList(utf8.encode(value));

  static String _styles() {
    return '''
:root {
  color-scheme: light;
  --bg: #EEF1F5;
  --surface: #FFFFFF;
  --surface-2: #E5E9F0;
  --ink: #0D1220;
  --muted: #545E73;
  --line: #D3D9E4;
  --accent: #2433E6;
  --accent-ink: #FFFFFF;
  --ok: #0B7F57;
  --ok-bg: #DCF2E9;
  --todo: #8F5600;
  --todo-bg: #FAEACB;
  --later: #475169;
  --later-bg: #E2E7EF;
  --font-display: "Segoe UI", system-ui, sans-serif;
  --font-body: "Segoe UI", system-ui, sans-serif;
  --font-mono: ui-monospace, Consolas, monospace;
  box-sizing: border-box;
  padding-top: env(safe-area-inset-top, 0px);
  padding-bottom: env(safe-area-inset-bottom, 0px);
}
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    --bg: #0A0E18; --surface: #121827; --surface-2: #1A2133; --ink: #E7EBF5;
    --muted: #AEB8CC; --line: #303B54; --accent: #A0AAFF; --accent-ink: #0A0E18;
    --ok: #5FD4A1; --ok-bg: #12312A; --todo: #F0B45A; --todo-bg: #34270F;
    --later: #A9B4CC; --later-bg: #1D263A; color-scheme: dark;
  }
}
:root[data-theme="dark"] {
  --bg: #0A0E18; --surface: #121827; --surface-2: #1A2133; --ink: #E7EBF5;
  --muted: #AEB8CC; --line: #303B54; --accent: #A0AAFF; --accent-ink: #0A0E18;
  --ok: #5FD4A1; --ok-bg: #12312A; --todo: #F0B45A; --todo-bg: #34270F;
  --later: #A9B4CC; --later-bg: #1D263A; color-scheme: dark;
}
*, *::before, *::after { box-sizing: border-box; }
html { scroll-behavior: smooth; scroll-padding-top: 76px; }
body {
  margin: 0; background: var(--bg); color: var(--ink); font-family: var(--font-body);
  font-size: 1rem; line-height: 1.6; -webkit-font-smoothing: antialiased;
  overflow-wrap: anywhere;
}
body::before {
  content: ""; position: fixed; inset: 0 0 auto; height: env(safe-area-inset-top, 0px);
  z-index: 30; background: var(--bg);
}
a { color: inherit; }
:focus-visible { outline: 2px solid var(--accent); outline-offset: 3px; border-radius: 4px; }
h1, h2, h3, h4 { font-family: var(--font-display); text-wrap: balance; margin: 0; letter-spacing: -0.02em; line-height: 1.08; }
p { margin: 0; }
.wrap {
  width: min(100%, 1120px); margin-inline: auto;
  padding-left: max(16px, env(safe-area-inset-left, 0px));
  padding-right: max(16px, env(safe-area-inset-right, 0px));
}
.mono { font-family: var(--font-mono); font-size: 0.75rem; letter-spacing: 0.06em; text-transform: uppercase; color: var(--muted); }
.site-head {
  position: sticky; top: env(safe-area-inset-top, 0px); z-index: 20;
  background: color-mix(in srgb, var(--bg) 88%, transparent);
  -webkit-backdrop-filter: blur(12px); backdrop-filter: blur(12px);
  border-bottom: 1px solid var(--line);
}
.head-in { display: flex; align-items: center; justify-content: space-between; gap: 16px; min-height: 60px; }
.brand { min-width: 0; overflow-wrap: anywhere; font-family: var(--font-display); font-weight: 700; font-size: 1.25rem; letter-spacing: -0.03em; text-decoration: none; }
.nav { display: flex; align-items: center; justify-content: flex-end; gap: clamp(12px, 3vw, 28px); }
.nav a { text-decoration: none; font-size: 0.9rem; color: var(--muted); transition: color .15s; }
.nav a:hover { color: var(--ink); }
.nav .cta { color: var(--accent-ink); background: var(--accent); padding: 7px 14px; border-radius: 6px; font-weight: 600; }
.nav .cta:hover { color: var(--accent-ink); filter: brightness(1.08); }
.icon-btn {
  display: inline-grid; place-items: center; flex: none; width: 40px; height: 40px; border-radius: 6px;
  border: 1px solid var(--line); background: var(--surface); color: var(--ink); cursor: pointer;
}
.icon-btn:hover { border-color: var(--accent); }
.icon-btn svg { width: 18px; height: 18px; }
.hero { padding-block: clamp(40px, 7vw, 96px) clamp(40px, 6vw, 72px); }
.hero-grid { display: grid; grid-template-columns: minmax(0, 1fr); gap: clamp(32px, 5vw, 72px); align-items: center; }
.hero-grid.has-profile { grid-template-columns: minmax(0, 1.2fr) minmax(0, 0.8fr); }
.hero-copy { min-width: 0; }
.eyebrow { display: flex; align-items: center; gap: 10px; margin-bottom: 22px; }
.eyebrow .bar { width: 28px; height: 2px; flex: none; background: var(--accent); }
.hero h1 { font-weight: 700; font-size: clamp(2.5rem, 6.4vw, 4.9rem); line-height: 1; letter-spacing: -0.035em; overflow-wrap: anywhere; }
.hero h1 em { font-style: normal; color: var(--accent); }
.lead { margin-top: 24px; max-width: 54ch; font-size: clamp(1.05rem, 1.6vw, 1.2rem); color: var(--muted); }
.actions { display: flex; flex-wrap: wrap; gap: 12px; margin-top: 32px; }
.btn {
  display: inline-flex; align-items: center; justify-content: center; min-height: 44px; gap: 8px;
  text-decoration: none; font-weight: 600; font-size: 0.95rem; padding: 10px 20px;
  border-radius: 6px; border: 1px solid var(--ink); transition: transform .15s, background .15s;
}
.btn.primary { background: var(--ink); color: var(--bg); }
.btn.primary:hover { transform: translateY(-2px); }
.btn.ghost { background: transparent; color: var(--ink); border-color: var(--line); }
.btn.ghost:hover { border-color: var(--ink); }
.profile { min-width: 0; overflow: hidden; background: var(--surface); border: 1px solid var(--line); border-radius: 10px; }
.profile-photo-wrap { padding: 20px 20px 0; }
.profile-photo { display: block; width: min(100%, 184px); aspect-ratio: 1; height: auto; margin: 0 auto; border: 1px solid var(--line); border-radius: 10px; object-fit: cover; }
.prof-head { display: flex; align-items: center; gap: 12px; padding: 16px 20px; border-bottom: 1px solid var(--line); }
.prof-head .dot { position: relative; width: 10px; height: 10px; border-radius: 50%; background: var(--ok); flex: none; }
.prof-head .dot::after { content: ""; position: absolute; inset: -5px; border-radius: 50%; border: 2px solid var(--ok); opacity: 0; animation: ping 2.4s ease-out infinite; }
@keyframes ping { 0% { transform: scale(0.5); opacity: 0.7; } 80%, 100% { transform: scale(1.3); opacity: 0; } }
.prof-head .mono { color: var(--ink); }
.prof-list { margin: 0; display: grid; }
.prof-list div { padding: 14px 20px; min-width: 0; }
.prof-list div + div { border-top: 1px solid var(--line); }
.prof-list dt { font-family: var(--font-mono); font-size: 0.68rem; letter-spacing: 0.08em; text-transform: uppercase; color: var(--muted); }
.prof-list dd { margin: 3px 0 0; font-weight: 500; overflow-wrap: anywhere; }
.prof-link { display: block; min-height: 48px; padding: 14px 20px; border-top: 1px solid var(--line); text-decoration: none; font-weight: 600; color: var(--accent); background: var(--surface-2); transition: filter .15s; }
.prof-link:hover { filter: brightness(0.97); text-decoration: underline; text-underline-offset: 4px; }
.section { padding-block: clamp(48px, 7vw, 96px); border-top: 1px solid var(--line); }
.sec-head { display: flex; align-items: baseline; justify-content: space-between; gap: 16px; flex-wrap: wrap; margin-bottom: clamp(24px, 4vw, 44px); }
.sec-head h2, .about h2 { font-weight: 700; font-size: clamp(1.9rem, 4vw, 2.9rem); }
.case { background: var(--surface); border: 1px solid var(--line); border-radius: 10px; transition: border-color .2s; }
.case:hover { border-color: color-mix(in srgb, var(--accent) 55%, var(--line)); }
.case + .case { margin-top: 24px; }
.case-main { display: grid; grid-template-columns: minmax(0, 0.9fr) minmax(0, 1.1fr); }
.case-text { min-width: 0; padding: clamp(20px, 3.4vw, 40px); display: flex; flex-direction: column; gap: 18px; }
.case-text h3 { font-weight: 700; font-size: clamp(1.6rem, 3vw, 2.2rem); overflow-wrap: anywhere; }
.case-text .full-title { color: var(--muted); font-size: 0.95rem; }
.case-text .desc { max-width: 56ch; }
.case-panel { min-width: 0; display: flex; flex-direction: column; border-left: 1px solid var(--line); }
.tabs { display: flex; overflow-x: auto; border-bottom: 1px solid var(--line); }
.tab { appearance: none; min-height: 48px; background: transparent; border: 0; border-bottom: 2px solid transparent; margin-bottom: -1px; padding: 12px 16px; font: 500 0.82rem var(--font-mono); letter-spacing: 0.04em; text-transform: uppercase; color: var(--muted); cursor: pointer; white-space: nowrap; }
.tab:hover { color: var(--ink); }
.tab[aria-selected="true"] { color: var(--ink); border-bottom-color: var(--accent); }
.tabpanel { min-width: 0; padding: clamp(16px, 2.6vw, 28px); }
.highlights { list-style: none; margin: 0; padding: 0; display: grid; }
.highlights li { display: grid; gap: 4px; padding: 14px 0; border-top: 1px solid var(--line); }
.highlights li:first-child { border-top: 0; padding-top: 0; }
.highlights li:last-child { padding-bottom: 0; }
.highlights strong { font-weight: 600; }
.highlights span { color: var(--muted); font-size: 0.95rem; }
.tools { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 0; border-top: 1px solid var(--ink); }
.tool-group { min-width: 0; padding: 20px 20px 8px 0; }
.tool-group + .tool-group { padding-left: 20px; border-left: 1px solid var(--line); }
.tool-group h3 { margin-bottom: 14px; font: 500 0.75rem var(--font-mono); letter-spacing: 0.08em; text-transform: uppercase; color: var(--accent); overflow-wrap: anywhere; }
.tool-group ul { list-style: none; margin: 0; padding: 0; display: grid; gap: 8px; }
.tool-group li { min-width: 0; font-weight: 500; overflow-wrap: anywhere; }
.tool-group li small { display: block; font-weight: 400; font-size: 0.82rem; color: var(--muted); }
.about { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: clamp(28px, 6vw, 88px); }
.about-body { display: grid; align-content: start; gap: 18px; max-width: 58ch; color: var(--muted); font-size: 1.05rem; }
.background-group + .background-group { margin-top: 24px; padding-top: 24px; border-top: 1px solid var(--line); }
.background-group h3 { margin-bottom: 16px; color: var(--ink); font-size: 1.2rem; }
.background-item + .background-item { margin-top: 18px; padding-top: 18px; border-top: 1px solid var(--line); }
.background-item h4 { margin-bottom: 6px; font-size: 1.05rem; }
.background-item p + p { margin-top: 6px; }
.contact { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: clamp(28px, 6vw, 88px); align-items: start; }
.contact h2 { font-weight: 700; font-size: clamp(2.2rem, 5.4vw, 4rem); line-height: 1; letter-spacing: -0.035em; }
.contact p.sub { margin-top: 18px; color: var(--muted); max-width: 42ch; }
.c-list { min-width: 0; display: grid; overflow: hidden; border: 1px solid var(--line); border-radius: 10px; background: var(--surface); }
.contact-row { min-width: 0; display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 16px 18px; }
.contact-row + .contact-row { border-top: 1px solid var(--line); }
.contact-row > div { min-width: 0; }
.contact-row .lab { display: block; margin-bottom: 2px; }
.contact-row .val { max-width: 100%; font-weight: 500; overflow-wrap: anywhere; user-select: all; }
.copy { flex: none; min-width: 84px; min-height: 40px; appearance: none; background: transparent; border: 1px solid var(--line); border-radius: 6px; padding: 6px 12px; font: 500 0.75rem var(--font-mono); letter-spacing: 0.06em; text-transform: uppercase; color: var(--ink); cursor: pointer; }
.copy:hover { border-color: var(--accent); color: var(--accent); }
.site-foot { border-top: 1px solid var(--line); padding-block: 28px 40px; }
.foot-in { display: flex; justify-content: space-between; gap: 16px; flex-wrap: wrap; font-size: 0.88rem; color: var(--muted); }
.foot-in a { text-decoration: none; }
.foot-in a:hover { color: var(--accent); }
@media (max-width: 960px) {
  .case-main { grid-template-columns: minmax(0, 1fr); }
  .case-panel { border-left: 0; border-top: 1px solid var(--line); }
  .tools { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .tool-group:nth-child(odd) { padding-left: 0; border-left: 0; }
  .tool-group:nth-child(n+3) { border-top: 1px solid var(--line); }
}
@media (max-width: 780px) {
  .hero-grid.has-profile, .about, .contact { grid-template-columns: minmax(0, 1fr); }
  .profile { max-width: 560px; }
}
@media (max-width: 560px) {
  .nav { gap: 8px; }
  .nav a:not(.cta) { display: none; }
  .nav .cta { padding: 8px 10px; }
  .tools { grid-template-columns: minmax(0, 1fr); }
  .tool-group, .tool-group + .tool-group { padding-left: 0; border-left: 0; }
  .tool-group + .tool-group { border-top: 1px solid var(--line); }
  .case-text { gap: 14px; }
  .contact-row { padding-inline: 12px; }
  .copy { min-width: 68px; padding-inline: 8px; }
}
@media (prefers-reduced-motion: reduce) {
  html { scroll-behavior: auto; }
  .btn, .nav a, .case, .prof-link { transition: none; }
  .prof-head .dot::after { animation: none; }
}
''';
  }

  static const _script = '''
'use strict';
(function () {
  var root = document.documentElement;
  var mq = window.matchMedia('(prefers-color-scheme: dark)');
  var btn = document.getElementById('theme-btn');
  var SUN = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></svg>';
  var MOON = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"/></svg>';

  function effective() { return root.getAttribute('data-theme') || (mq.matches ? 'dark' : 'light'); }
  var themeKey = 'portfolio-theme:' + window.location.pathname;
  function paintBtn() {
    var dark = effective() === 'dark';
    btn.innerHTML = dark ? SUN : MOON;
    btn.setAttribute('aria-label', dark ? 'Switch to light theme' : 'Switch to dark theme');
  }
  try {
    var saved = localStorage.getItem(themeKey);
    if (saved === 'dark' || saved === 'light') root.setAttribute('data-theme', saved);
  } catch (e) {}
  btn.addEventListener('click', function () {
    var next = effective() === 'dark' ? 'light' : 'dark';
    root.setAttribute('data-theme', next);
    try { localStorage.setItem(themeKey, next); } catch (e) {}
    paintBtn();
  });
  if (mq.addEventListener) mq.addEventListener('change', paintBtn);
  paintBtn();

  Array.prototype.forEach.call(document.querySelectorAll('[role="tablist"]'), function (list) {
    var tabs = Array.prototype.slice.call(list.querySelectorAll('[role="tab"]'));
    function select(tab, focus) {
      tabs.forEach(function (item) {
        var on = item === tab;
        item.setAttribute('aria-selected', on ? 'true' : 'false');
        item.tabIndex = on ? 0 : -1;
        document.getElementById(item.getAttribute('aria-controls')).hidden = !on;
      });
      if (focus) tab.focus();
    }
    tabs.forEach(function (tab, i) {
      tab.addEventListener('click', function () { select(tab, false); });
      tab.addEventListener('keydown', function (e) {
        var j = null;
        if (e.key === 'ArrowRight') j = (i + 1) % tabs.length;
        if (e.key === 'ArrowLeft') j = (i - 1 + tabs.length) % tabs.length;
        if (e.key === 'Home') j = 0;
        if (e.key === 'End') j = tabs.length - 1;
        if (j !== null) { e.preventDefault(); select(tabs[j], true); }
      });
    });
  });

  Array.prototype.forEach.call(document.querySelectorAll('[data-copy]'), function (button) {
    button.addEventListener('click', function () {
      var done = function (ok) {
        button.textContent = ok ? 'Copied' : 'Selected';
        window.setTimeout(function () { button.textContent = 'Copy'; }, 1600);
      };
      var fallback = function () {
        try {
          var range = document.createRange();
          range.selectNodeContents(button.closest('.contact-row').querySelector('.val'));
          var selection = window.getSelection();
          selection.removeAllRanges();
          selection.addRange(range);
        } catch (e) {}
        done(false);
      };
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(button.getAttribute('data-copy')).then(function () { done(true); }, fallback);
      } else {
        fallback();
      }
    });
  });
})();
''';
}

class _PhotoAsset {
  const _PhotoAsset(this.name, this.bytes);

  final String name;
  final Uint8List bytes;
}
