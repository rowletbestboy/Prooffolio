import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart' show rootBundle;

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
  static const _templateAsset = 'assets/Template Portfolio Editorial.html';
  static final Future<_EditorialTemplate> _editorialTemplate = rootBundle
      .loadString(_templateAsset)
      .then(_parseTemplate);

  static Future<PortfolioSiteBundle> generate(
    PortfolioContent content,
    PortfolioSelection selection,
    PortfolioTemplate template,
  ) async {
    final editorialTemplate = await _editorialTemplate;
    final profile = content.profile.value;
    final photoAsset = _selectedPhoto(content, selection, profile);
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
    final contacts = profile == null
        ? const <(String, String, String?)>[]
        : _selectedContacts(profile, selection);
    final displayName = selection.includeDisplayName
        ? profile?.displayName.trim() ?? ''
        : '';
    final files = <String, Uint8List>{
      'index.html': _bytes(
        _renderHtml(
          editorialTemplate.html,
          profile: profile,
          selection: selection,
          displayName: displayName,
          photoAsset: photoAsset,
          projects: projects,
          skills: skills,
          education: education,
          experience: experience,
          certifications: certifications,
          achievements: achievements,
          contacts: contacts,
        ),
      ),
      'styles.css': _bytes(editorialTemplate.styles),
      'app.js': _bytes(editorialTemplate.script),
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
      if (const {'index.html', 'styles.css', 'app.js'}.contains(entry.key)) {
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

  static _EditorialTemplate _parseTemplate(String source) {
    final stylePattern = RegExp(
      r'<style\b[^>]*>([\s\S]*?)</style>',
      caseSensitive: false,
    );
    final styleMatches = stylePattern.allMatches(source).toList();
    if (styleMatches.isEmpty) {
      throw FormatException('The editorial portfolio template has no styles.');
    }
    final styles = styleMatches
        .map((match) => match.group(1)!.trim())
        .where((style) => style.isNotEmpty)
        .join('\n\n');

    final scriptPattern = RegExp(
      r'<script\b[^>]*>([\s\S]*?)</script>',
      caseSensitive: false,
    );
    final scriptMatches = scriptPattern.allMatches(source).toList();
    if (scriptMatches.length != 1) {
      throw FormatException(
        'The editorial portfolio template must contain one inline script.',
      );
    }
    final script = scriptMatches.single.group(1)!.trim();
    var html = source
        .replaceAll(stylePattern, '')
        .replaceFirst(
          scriptPattern,
          '<script src="app.js" defer></script>',
        );
    if (!html.contains('<link rel="stylesheet" href="styles.css">')) {
      throw FormatException(
        'The editorial portfolio template is missing its stylesheet link.',
      );
    }
    return _EditorialTemplate(html: html, styles: styles, script: script);
  }

  static String _renderHtml(
    String template, {
    required PortfolioProfile? profile,
    required PortfolioSelection selection,
    required String displayName,
    required _PhotoAsset? photoAsset,
    required List<PortfolioProject> projects,
    required List<PortfolioSkill> skills,
    required List<PortfolioEducation> education,
    required List<PortfolioExperience> experience,
    required List<PortfolioRecordContent> certifications,
    required List<PortfolioRecordContent> achievements,
    required List<(String, String, String?)> contacts,
  }) {
    final safeName = displayName.isEmpty ? 'Portfolio' : _escapeText(displayName);
    final hasAbout =
        education.isNotEmpty ||
        experience.isNotEmpty ||
        certifications.isNotEmpty ||
        achievements.isNotEmpty;
    final values = <String, String>{
      '<!-- PORTFOLIO_TITLE -->': _escapeText(
        displayName.isEmpty ? 'Portfolio Editorial' : '$displayName — Portfolio',
      ),
      '<!-- PORTFOLIO_DESCRIPTION -->': _escapeAttribute(
        selection.includeBio && profile?.bio.trim().isNotEmpty == true
            ? profile!.bio.trim()
            : selection.includeHeadline &&
                  profile?.headline.trim().isNotEmpty == true
            ? profile!.headline.trim()
            : 'Portfolio by $safeName',
      ),
      '<!-- PORTFOLIO_HEADER -->': _writeHeader(
        safeName,
        hasProjects: projects.isNotEmpty,
        hasSkills: skills.isNotEmpty,
        hasAbout: hasAbout,
        hasContact: contacts.isNotEmpty,
      ),
      '<!-- PORTFOLIO_MASTHEAD -->': _writeMasthead(
        profile: profile,
        selection: selection,
        displayName: displayName,
        photoAsset: photoAsset,
        projects: projects,
        skills: skills,
        experience: experience,
        education: education,
        hasContact: contacts.isNotEmpty,
      ),
      '<!-- PORTFOLIO_PROJECTS -->': _writeProjects(projects),
      '<!-- PORTFOLIO_SKILLS -->': _writeSkills(skills),
      '<!-- PORTFOLIO_ABOUT -->': _writeAbout(
        education: education,
        experience: experience,
        certifications: certifications,
        achievements: achievements,
      ),
      '<!-- PORTFOLIO_CONTACT -->': _writeContacts(contacts),
      '<!-- PORTFOLIO_FOOTER -->':
          '&copy; ${DateTime.now().year} $safeName',
    };
    var html = template;
    for (final entry in values.entries) {
      if (!html.contains(entry.key)) {
        throw FormatException(
          'The editorial portfolio template is missing ${entry.key}.',
        );
      }
      html = html.replaceFirst(entry.key, entry.value);
    }
    if (RegExp(r'<!-- PORTFOLIO_[A-Z_]+ -->').hasMatch(html)) {
      throw StateError('The editorial portfolio template was not fully filled.');
    }
    return html;
  }

  static String _writeHeader(
    String displayName, {
    required bool hasProjects,
    required bool hasSkills,
    required bool hasAbout,
    required bool hasContact,
  }) {
    final output = StringBuffer(
      '<header class="site-head"><div class="wrap head-in">'
      '<a class="brand" href="#top">$displayName</a>'
      '<nav class="nav" aria-label="Primary">',
    );
    if (hasProjects) output.write('<a href="#work">Projects</a>');
    if (hasSkills) output.write('<a href="#skills">Skills</a>');
    if (hasAbout) output.write('<a href="#about">About</a>');
    if (hasContact) output.write('<a class="cta" href="#contact">Contact</a>');
    output.write(
      '<button class="icon-btn" id="theme-btn" type="button" '
      'aria-label="Switch theme"></button></nav></div></header>',
    );
    return output.toString();
  }

  static String _writeMasthead({
    required PortfolioProfile? profile,
    required PortfolioSelection selection,
    required String displayName,
    required _PhotoAsset? photoAsset,
    required List<PortfolioProject> projects,
    required List<PortfolioSkill> skills,
    required List<PortfolioExperience> experience,
    required List<PortfolioEducation> education,
    required bool hasContact,
  }) {
    final headline = selection.includeHeadline
        ? profile?.headline.trim() ?? ''
        : '';
    final occupation = selection.includeOccupationTitle
        ? profile?.occupationTitle.trim() ?? ''
        : '';
    final bio = selection.includeBio ? profile?.bio.trim() ?? '' : '';
    final shownName = displayName.isEmpty ? 'Portfolio' : _escapeText(displayName);
    final output = StringBuffer()
      ..write('<section class="masthead"><div class="wrap">')
      ..write(
        '<div class="mast-meta"><span class="label">Portfolio &middot; '
        '${DateTime.now().year}</span>',
      );
    if (occupation.isNotEmpty) {
      output.write(
        '<span class="label">${_escapeText(occupation)}</span>',
      );
    } else if (headline.isNotEmpty) {
      output.write('<span class="label">${_escapeText(headline)}</span>');
    }
    output.write('</div><div class="mast-body"><div class="mast-copy">');
    output.write('<h1 class="headline">$shownName');
    if (headline.isNotEmpty && displayName.isNotEmpty) {
      output.write('<br><em>${_escapeText(headline)}</em>');
    }
    output.write('</h1>');
    if (bio.isNotEmpty) {
      output.write('<p class="standfirst">${_escapeText(bio)}</p>');
    } else if (occupation.isNotEmpty && occupation != headline) {
      output.write(
        '<p class="standfirst">${_escapeText(occupation)}</p>',
      );
    }
    if (projects.isNotEmpty || hasContact) {
      output.write('<div class="actions">');
      if (projects.isNotEmpty) {
        output.write('<a class="btn primary" href="#work">Read the work</a>');
      }
      if (hasContact) {
        output.write('<a class="btn ghost" href="#contact">Get in touch</a>');
      }
      output.write('</div>');
    }
    output.write('</div><div class="hero-aside">');
    if (photoAsset != null) {
      final alt = selection.includeDisplayName && displayName.isNotEmpty
          ? _escapeAttribute(displayName)
          : 'Profile photo';
      output.write(
        '<figure class="hero-photo-frame">'
        '<img class="hero-photo" src="${_escapeAttribute(photoAsset.name)}" '
        'alt="$alt" width="640" height="480"></figure>',
      );
    }
    output.write('<dl class="facts">');
    if (occupation.isNotEmpty) _writeFact(output, 'Focus', occupation);
    if (experience.isNotEmpty) {
      _writeFact(output, 'Experience', experience.first.title);
    }
    if (education.isNotEmpty) {
      _writeFact(output, 'Education', education.first.title);
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
    output.write('</dl></div></div></div></section>');
    return output.toString();
  }

  static void _writeFact(StringBuffer output, String label, String value) {
    if (value.trim().isEmpty) return;
    output.write(
      '<div><dt class="label">${_escapeText(label)}</dt>'
      '<dd>${_escapeText(value.trim())}</dd></div>',
    );
  }

  static String _writeProjects(List<PortfolioProject> projects) {
    if (projects.isEmpty) return '';
    final output = StringBuffer()
      ..write(
        '<section class="section" id="work"><div class="wrap section-grid">'
        '<div class="section-aside"><h2 class="section-title">Selected work</h2>'
        '<span class="label">${projects.length} '
        '${projects.length == 1 ? 'project' : 'projects'}</span></div><div>',
      );
    for (var index = 0; index < projects.length; index++) {
      final project = projects[index];
      final details = <(String, String)>[
        if (project.statusLabel.trim().isNotEmpty)
          ('Status', project.statusLabel.trim()),
        if (project.technologies.isNotEmpty)
          ('Tools', project.technologies.join(', ')),
        if (_formatDate(project.startDate).isNotEmpty ||
            _formatDate(project.endDate).isNotEmpty)
          ('Dates', _dateText(project.startDate, project.endDate)),
      ];
      output.write(
        '<article class="entry" id="work-${index + 1}"><dl class="entry-meta">'
        '<div><dt class="label">Type</dt><dd>Project</dd></div>',
      );
      if (project.contribution.trim().isNotEmpty) {
        output.write(
          '<div><dt class="label">Contribution</dt>'
          '<dd>${_escapeText(project.contribution.trim())}</dd></div>',
        );
      }
      for (final detail in details) {
        output.write(
          '<div><dt class="label">${_escapeText(detail.$1)}</dt>'
          '<dd>${_escapeText(detail.$2)}</dd></div>',
        );
      }
      output.write('</dl><div>');
      if (project.title.trim().isNotEmpty) {
        output.write('<h3>${_escapeText(project.title.trim())}</h3>');
      }
      if (project.summary.trim().isNotEmpty) {
        output.write(
          '<p class="deck">${_escapeText(project.summary.trim())}</p>',
        );
      }
      final descriptions = <String>[
        if (project.description.trim().isNotEmpty)
          project.description.trim(),
        if (project.contribution.trim().isNotEmpty)
          project.contribution.trim(),
      ];
      if (descriptions.isNotEmpty) {
        output.write('<div class="copy">');
        for (final paragraph in descriptions) {
          output.write('<p>${_escapeText(paragraph)}</p>');
        }
        output.write('</div>');
      }
      if (project.technologies.isNotEmpty) {
        output
          ..write(
            '<div class="cols"><div><h4>Built with</h4><ul>',
          )
          ..writeAll(
            project.technologies
                .where((technology) => technology.trim().isNotEmpty)
                .map((technology) => '<li>${_escapeText(technology.trim())}</li>'),
          )
          ..write('</ul></div></div>');
      }
      final links = <(String, String)>[
        if (_safeHttpUrl(project.repositoryUrl) case final url?)
          ('Repository', url),
        if (_safeHttpUrl(project.demoUrl) case final url?) ('Live project', url),
      ];
      if (links.isNotEmpty) {
        output.write('<div class="actions">');
        for (final link in links) {
          output.write(
            '<a class="btn ghost" href="${_escapeAttribute(link.$2)}" '
            'target="_blank" rel="noopener noreferrer">'
            '${_escapeText(link.$1)}</a>',
          );
        }
        output.write('</div>');
      }
      output.write('</div></article>');
    }
    output.write('</div></div></section>');
    return output.toString();
  }

  static String _writeSkills(List<PortfolioSkill> skills) {
    final grouped = <String, List<PortfolioSkill>>{};
    for (final skill in skills) {
      if (skill.name.trim().isEmpty) continue;
      final category = skill.category.trim().isEmpty
          ? 'Skills'
          : skill.category.trim();
      grouped.putIfAbsent(category, () => []).add(skill);
    }
    if (grouped.isEmpty) return '';
    final output = StringBuffer()
      ..write(
        '<section class="section" id="skills"><div class="wrap section-grid">'
        '<div class="section-aside"><h2 class="section-title">Skills</h2>'
        '<span class="label">What I bring to a team</span></div><div class="caps">',
      );
    for (final group in grouped.entries) {
      output
        ..write(
          '<div class="cap"><h3>${_escapeText(group.key)}</h3><ul>',
        )
        ..writeAll(
          group.value.map(
            (skill) =>
                '<li>${_escapeText(skill.name.trim())}'
                '${_element('small', skill.status)}</li>',
          ),
        )
        ..write('</ul></div>');
    }
    output.write('</div></div></section>');
    return output.toString();
  }

  static String _writeAbout({
    required List<PortfolioEducation> education,
    required List<PortfolioExperience> experience,
    required List<PortfolioRecordContent> certifications,
    required List<PortfolioRecordContent> achievements,
  }) {
    if (education.isEmpty &&
        experience.isEmpty &&
        certifications.isEmpty &&
        achievements.isEmpty) {
      return '';
    }
    final output = StringBuffer()
      ..write(
        '<section class="section" id="about"><div class="wrap section-grid">'
        '<div class="section-aside"><h2 class="section-title">Background</h2>'
        '</div><div class="editorial-records">',
      );
    for (final record in experience) {
      output.write(
        _writeEditorialRecord(
          'Experience',
          record.title,
          [
            record.organization,
            record.type,
            _dateText(record.startDate, record.isCurrent ? null : record.endDate),
            record.isCurrent ? 'Present' : '',
            record.description,
          ],
        ),
      );
    }
    for (final record in education) {
      output.write(
        _writeEditorialRecord(
          'Education',
          record.title,
          [
            record.institution,
            record.level,
            record.status,
            _dateText(record.startDate, record.endDate),
            record.description,
          ],
        ),
      );
    }
    for (final record in certifications) {
      output.write(
        _writeEditorialRecord(
          'Certification',
          record.title,
          [
            record.source,
            record.description,
            _dateText(record.achievedOn, record.expiresOn),
          ],
        ),
      );
    }
    for (final record in achievements) {
      output.write(
        _writeEditorialRecord(
          'Achievement',
          record.title,
          [
            record.source,
            record.description,
            _dateText(record.achievedOn, record.expiresOn),
          ],
        ),
      );
    }
    output.write('</div></div></section>');
    return output.toString();
  }

  static String _writeEditorialRecord(
    String category,
    String title,
    List<String> details,
  ) {
    final output = StringBuffer()
      ..write(
        '<article class="editorial-record"><span class="label">'
        '${_escapeText(category)}</span><div>',
      );
    if (title.trim().isNotEmpty) {
      output.write('<h3>${_escapeText(title.trim())}</h3>');
    }
    for (final detail in details) {
      if (detail.trim().isNotEmpty) {
        output.write('<p>${_escapeText(detail.trim())}</p>');
      }
    }
    output.write('</div></article>');
    return output.toString();
  }

  static String _writeContacts(List<(String, String, String?)> contacts) {
    if (contacts.isEmpty) return '';
    final output = StringBuffer()
      ..write(
        '<section class="section" id="contact"><div class="wrap section-grid">'
        '<div class="section-aside"><h2 class="section-title">Contact</h2></div>'
        '<div><p class="contact-big">Let’s talk.</p>'
        '<p class="contact-sub">Contact details selected for sharing.</p>'
        '<div class="c-list">',
      );
    for (final (label, value, url) in contacts) {
      final safeValue = _escapeText(value);
      final valueElement = url == null
          ? '<span class="val">$safeValue</span>'
          : '<a class="val" href="${_escapeAttribute(url)}" '
                'target="_blank" rel="noopener noreferrer">$safeValue</a>';
      output.write(
        '<div class="contact-row"><span class="label">${_escapeText(label)}</span>'
        '$valueElement<button class="copy-btn" type="button" '
        'data-copy="${_escapeAttribute(value)}">Copy</button></div>',
      );
    }
    output.write('</div></div></div></section>');
    return output.toString();
  }

  static List<(String, String, String?)> _selectedContacts(
    PortfolioProfile profile,
    PortfolioSelection selection,
  ) {
    final contacts = <(String, String, String?)>[];
    void addText(bool selected, String label, String value) {
      if (selected && value.trim().isNotEmpty) {
        contacts.add((label, value.trim(), null));
      }
    }

    void addLink(bool selected, String label, String value) {
      if (!selected || value.trim().isEmpty) return;
      final url = _safeHttpUrl(value);
      if (url != null) contacts.add((label, value.trim(), url));
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
    return contacts;
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

  static String _element(String tag, String text) =>
      text.trim().isEmpty ? '' : '<$tag>${_escapeText(text.trim())}</$tag>';

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
}

class _EditorialTemplate {
  const _EditorialTemplate({
    required this.html,
    required this.styles,
    required this.script,
  });

  final String html;
  final String styles;
  final String script;
}

class _PhotoAsset {
  const _PhotoAsset(this.name, this.bytes);

  final String name;
  final Uint8List bytes;
}
