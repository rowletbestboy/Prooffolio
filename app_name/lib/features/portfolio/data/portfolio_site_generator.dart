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
      'styles.css': _bytes(_styles(template)),
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
    final output = StringBuffer('''<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="A professional portfolio">
  <title>Portfolio</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <main class="site">
''');
    final identity = <String>[];
    if (profile != null && selection.includeDisplayName) {
      identity.add(_element('h1', profile.displayName));
    }
    if (profile != null && selection.includeHeadline) {
      identity.add(_element('p', profile.headline, 'headline'));
    }
    if (profile != null && selection.includeOccupationTitle) {
      identity.add(_element('p', profile.occupationTitle, 'occupation'));
    }
    if (profile != null && selection.includeBio) {
      identity.add(_element('p', profile.bio, 'bio'));
    }
    output.write('<header class="hero">');
    if (photoAsset != null) {
      final alt =
          selection.includeDisplayName &&
              profile?.displayName.trim().isNotEmpty == true
          ? profile!.displayName
          : 'Profile photo';
      output.write(
        '<img class="profile-photo" src="${_escapeAttribute(photoAsset.name)}" '
        'alt="${_escapeAttribute(alt)}">',
      );
    }
    output.write('<div class="identity">');
    output.write(identity.isEmpty ? '<h1>Portfolio</h1>' : identity.join());
    output.write('</div></header>');

    if (profile != null) {
      _writeContacts(output, profile, selection);
    }
    _writeProjects(output, content.projects.value, selection.projectIds);
    _writeSkills(output, content.skills.value, selection.skillIds);
    _writeEducation(output, content.education.value, selection.educationIds);
    _writeExperience(output, content.experience.value, selection.experienceIds);
    _writeRecords(
      output,
      'Certifications',
      content.certifications.value,
      selection.certificationIds,
    );
    _writeRecords(
      output,
      'Achievements',
      content.achievements.value,
      selection.achievementIds,
    );
    output.write('''
  </main>
  <script src="app.js" defer></script>
</body>
</html>
''');
    return output.toString();
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
          '<li><span class="contact-label">${_escapeText(label)}:</span> '
          '${_escapeText(value.trim())}</li>',
        );
      }
    }

    void addLink(bool selected, String label, String value) {
      if (!selected || value.trim().isEmpty) return;
      final safeUrl = _safeHttpUrl(value);
      if (safeUrl == null) return;
      contacts.add(
        '<li><a href="${_escapeAttribute(safeUrl)}" target="_blank" '
        'rel="noopener noreferrer">${_escapeText(label)}</a></li>',
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
        ..write('<section class="contact"><h2>Contact</h2><ul>')
        ..write(contacts.join())
        ..write('</ul></section>');
    }
  }

  static void _writeProjects(
    StringBuffer output,
    List<PortfolioProject>? projects,
    Set<String> selectedIds,
  ) {
    final selected = projects
        ?.where((project) => selectedIds.contains(project.id))
        .toList();
    if (selected == null || selected.isEmpty) return;
    output.write('<section><h2>Projects</h2>');
    for (final project in selected) {
      output
        ..write('<article><h3>${_escapeText(project.title)}</h3>')
        ..write(_element('p', project.summary))
        ..write(_element('p', project.description))
        ..write(_element('p', project.contribution))
        ..write(_element('p', project.statusLabel, 'muted'))
        ..write(_dateRange(project.startDate, project.endDate));
      if (project.technologies.isNotEmpty) {
        output.write(
          '<p class="muted">${project.technologies.map(_escapeText).join(' · ')}</p>',
        );
      }
      output.write('</article>');
    }
    output.write('</section>');
  }

  static void _writeSkills(
    StringBuffer output,
    List<PortfolioSkill>? skills,
    Set<String> selectedIds,
  ) {
    final names = skills
        ?.where((skill) => selectedIds.contains(skill.id))
        .map((skill) => skill.name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    if (names == null || names.isEmpty) return;
    output
      ..write('<section><h2>Skills</h2><ul class="tag-list">')
      ..write(names.map((name) => '<li>${_escapeText(name)}</li>').join())
      ..write('</ul></section>');
  }

  static void _writeEducation(
    StringBuffer output,
    List<PortfolioEducation>? education,
    Set<String> selectedIds,
  ) {
    final selected = education
        ?.where((record) => selectedIds.contains(record.id))
        .toList();
    if (selected == null || selected.isEmpty) return;
    output.write('<section><h2>Education</h2>');
    for (final record in selected) {
      output
        ..write('<article><h3>${_escapeText(record.title)}</h3>')
        ..write(_element('p', record.institution))
        ..write(_element('p', record.level, 'muted'))
        ..write(_element('p', record.description))
        ..write(_dateRange(record.startDate, record.endDate))
        ..write('</article>');
    }
    output.write('</section>');
  }

  static void _writeExperience(
    StringBuffer output,
    List<PortfolioExperience>? experience,
    Set<String> selectedIds,
  ) {
    final selected = experience
        ?.where((record) => selectedIds.contains(record.id))
        .toList();
    if (selected == null || selected.isEmpty) return;
    output.write('<section><h2>Experience</h2>');
    for (final record in selected) {
      output
        ..write('<article><h3>${_escapeText(record.title)}</h3>')
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
    output.write('</section>');
  }

  static void _writeRecords(
    StringBuffer output,
    String heading,
    List<PortfolioRecordContent>? records,
    Set<String> selectedIds,
  ) {
    final selected = records
        ?.where((record) => selectedIds.contains(record.id))
        .toList();
    if (selected == null || selected.isEmpty) return;
    output.write('<section><h2>${_escapeText(heading)}</h2>');
    for (final record in selected) {
      output
        ..write('<article><h3>${_escapeText(record.title)}</h3>')
        ..write(_element('p', record.source))
        ..write(_element('p', record.description))
        ..write(_dateRange(record.achievedOn, record.expiresOn))
        ..write('</article>');
    }
    output.write('</section>');
  }

  static String _element(String tag, String text, [String? className]) {
    if (text.trim().isEmpty) return '';
    final classAttribute = className == null
        ? ''
        : ' class="${_escapeAttribute(className)}"';
    return '<$tag$classAttribute>${_escapeText(text.trim())}</$tag>';
  }

  static String _dateRange(
    DateTime? start,
    DateTime? end, {
    bool current = false,
  }) {
    final startText = _formatDate(start);
    final endText = current ? 'Present' : _formatDate(end);
    if (startText.isEmpty && endText.isEmpty) return '';
    final date = [
      if (startText.isNotEmpty) startText,
      if (endText.isNotEmpty) endText,
    ].join(' – ');
    return '<p class="muted">${_escapeText(date)}</p>';
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

  static String _styles(PortfolioTemplate template) {
    final colors = switch (template) {
      PortfolioTemplate.light => (
        background: '#f8fafc',
        surface: '#ffffff',
        foreground: '#0f172a',
        muted: '#475569',
        border: '#cbd5e1',
        accent: '#1e3a5f',
      ),
      PortfolioTemplate.dark => (
        background: '#111827',
        surface: '#1f2937',
        foreground: '#f8fafc',
        muted: '#cbd5e1',
        border: '#475569',
        accent: '#93c5fd',
      ),
    };
    return '''
:root {
  color-scheme: ${template == PortfolioTemplate.light ? 'light' : 'dark'};
  --page-background: ${colors.background};
  --surface: ${colors.surface};
  --foreground: ${colors.foreground};
  --muted: ${colors.muted};
  --border: ${colors.border};
  --accent: ${colors.accent};
  font-family: Inter, ui-sans-serif, system-ui, sans-serif;
}
* { box-sizing: border-box; }
body { margin: 0; background: var(--page-background); color: var(--foreground); line-height: 1.65; }
.site { width: min(100% - 40px, 920px); margin: 0 auto; padding: 64px 0; }
.hero { display: flex; align-items: center; gap: 28px; padding: 12px 0 36px; }
.identity { min-width: 0; }
h1, h2, h3 { line-height: 1.2; }
h1 { margin: 0 0 12px; font-size: clamp(2.2rem, 6vw, 4rem); letter-spacing: -.045em; }
h2 { margin: 0 0 22px; color: var(--accent); font-size: 1.5rem; }
h3 { margin: 0 0 8px; font-size: 1.15rem; }
p { margin: 8px 0; }
.headline { margin: 0; color: var(--accent); font-size: 1.2rem; }
.occupation, .muted { color: var(--muted); }
.bio { max-width: 68ch; }
.profile-photo { width: 112px; height: 112px; flex: 0 0 112px; border-radius: 50%; object-fit: cover; }
section { margin: 28px 0; padding: 28px; border: 1px solid var(--border); border-radius: 16px; background: var(--surface); }
article + article { margin-top: 24px; padding-top: 24px; border-top: 1px solid var(--border); }
.contact ul, .tag-list { display: flex; flex-wrap: wrap; gap: 10px 20px; padding: 0; margin: 0; list-style: none; }
.contact-label { color: var(--muted); }
.tag-list li { padding: 4px 12px; border: 1px solid var(--border); border-radius: 999px; }
a { color: var(--accent); text-decoration-thickness: .08em; text-underline-offset: .2em; }
a:focus-visible { outline: 3px solid var(--accent); outline-offset: 3px; }
@media (max-width: 680px) {
  .site { width: min(100% - 28px, 920px); padding: 32px 0; }
  .hero { align-items: flex-start; gap: 16px; }
  .profile-photo { width: 76px; height: 76px; flex-basis: 76px; }
  section { margin: 18px 0; padding: 20px; }
}
''';
  }

  static const _script = '''
'use strict';
document.documentElement.classList.add('site-ready');
''';
}

class _PhotoAsset {
  const _PhotoAsset(this.name, this.bytes);

  final String name;
  final Uint8List bytes;
}
