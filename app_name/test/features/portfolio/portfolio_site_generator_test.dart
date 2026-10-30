import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:app_name/features/portfolio/data/portfolio_site_generator.dart';
import 'package:app_name/features/portfolio/domain/portfolio_content.dart';
import 'package:app_name/features/portfolio/domain/portfolio_template.dart';
import 'package:app_name/features/profile/domain/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const photoBytes = <int>[0xff, 0xd8, 0xff, 0xd9];
  final content = PortfolioContent(
    profile: const PortfolioSource.available(
      PortfolioProfile(
        displayName: 'Alex <script>alert(1)</script>',
        username: 'private-username',
        headline: 'Community educator',
        bio: 'I build <strong>inclusive</strong> programs.',
        occupationTitle: '',
        photoPath: 'private-user-id/private-photo.jpg',
        contactEmail: 'alex@example.test',
        phone: '555-0100',
        githubUrl: 'javascript:alert(1)',
        linkedInUrl: 'https://example.test/alex',
        upworkUrl: 'https://www.upwork.com/freelancers/~alex',
        jobstreetUrl: '',
        whatsAppNumber: '',
        additionalLinks: [
          ProfileContactLink(
            label: 'Personal site',
            url: 'https://example.test/?q=" onmouseover="alert(1)',
          ),
        ],
      ),
    ),
    photoUrl: const PortfolioSource.available('signed-private-photo-url'),
    photoBytes: PortfolioSource.available(Uint8List.fromList(photoBytes)),
    projects: const PortfolioSource.available([
      PortfolioProject(
        id: 'selected-project-id',
        title: 'Selected project',
        summary: 'A <script> tag stays text.',
        description: '',
        contribution: 'Organized the work.',
        technologies: ['Dart'],
        statusLabel: 'Completed',
        startDate: null,
        endDate: null,
      ),
      PortfolioProject(
        id: 'unselected-project-id',
        title: 'Private project',
        summary: 'Not selected.',
        description: '',
        contribution: '',
        technologies: [],
        statusLabel: 'Completed',
        startDate: null,
        endDate: null,
      ),
    ]),
    skills: const PortfolioSource.available([
      PortfolioSkill(
        id: 'selected-skill-id',
        name: 'Facilitation',
        category: 'Professional',
        status: 'Practicing',
        projectTitles: [],
      ),
      PortfolioSkill(
        id: 'unselected-skill-id',
        name: 'Private skill',
        category: 'Technical',
        status: 'Practicing',
        projectTitles: [],
      ),
    ]),
    education: const PortfolioSource.available([
      PortfolioEducation(
        id: 'selected-education-id',
        title: 'Community education',
        institution: 'Example College',
        level: 'Certificate',
        status: 'Completed',
        startDate: null,
        endDate: null,
        description: '',
      ),
    ]),
    experience: const PortfolioSource.available([
      PortfolioExperience(
        id: 'selected-experience-id',
        title: 'Program coordinator',
        organization: 'Community Center',
        type: 'Employment',
        startDate: null,
        endDate: null,
        isCurrent: false,
        description: 'Coordinated weekly activities.',
      ),
    ]),
    certifications: const PortfolioSource.available([
      PortfolioRecordContent(
        id: 'selected-certification-id',
        title: 'First Aid',
        source: 'Example Org',
        description: '',
        achievedOn: null,
        expiresOn: null,
      ),
    ]),
    achievements: const PortfolioSource.available([
      PortfolioRecordContent(
        id: 'selected-achievement-id',
        title: 'Volunteer recognition',
        source: '',
        description: '',
        achievedOn: null,
        expiresOn: null,
      ),
    ]),
    evidence: const PortfolioSource.available([
      PortfolioEvidence(
        id: 'private-evidence-id',
        title: 'Private evidence title',
        description: 'Confidential attachment notes.',
        kind: 'File',
        targetTitles: ['Selected project'],
      ),
    ]),
  );

  const selection = PortfolioSelection(
    includeDisplayName: true,
    includeHeadline: true,
    includeOccupationTitle: false,
    includeBio: true,
    includePhoto: true,
    includeEmail: true,
    includePhone: false,
    includeGithub: true,
    includeLinkedIn: true,
    includeJobstreet: false,
    includeWhatsApp: false,
    includeAdditionalLinks: true,
    projectIds: {'selected-project-id'},
    skillIds: {'selected-skill-id'},
    educationIds: {'selected-education-id'},
    experienceIds: {'selected-experience-id'},
    certificationIds: {'selected-certification-id'},
    achievementIds: {'selected-achievement-id'},
  );

  test('generated site contains only selected public information', () {
    final bundle = PortfolioSiteGenerator.generate(
      content,
      selection,
      PortfolioTemplate.light,
    );
    final html = utf8.decode(bundle.files['index.html']!);

    expect(html, contains('Alex &lt;script&gt;alert(1)&lt;/script&gt;'));
    expect(html, contains('Selected project'));
    expect(html, contains('Facilitation'));
    expect(html, contains('Community education'));
    expect(html, contains('Program coordinator'));
    expect(html, contains('First Aid'));
    expect(html, contains('Volunteer recognition'));
    expect(html, contains('alex@example.test'));
    expect(html, isNot(contains('Private project')));
    expect(html, isNot(contains('Private skill')));
    expect(html, isNot(contains('Private evidence title')));
    expect(html, isNot(contains('Confidential attachment notes')));
    expect(html, isNot(contains('private-user-id')));
    expect(html, isNot(contains('selected-project-id')));
    expect(html, isNot(contains('private-evidence-id')));
    expect(html, isNot(contains('signed-private-photo-url')));
    expect(html, isNot(contains('private-username')));
    expect(bundle.files.keys, contains('portfolio-photo.jpg'));
    expect(bundle.files['portfolio-photo.jpg'], photoBytes);
  });

  test('Upwork link is included only after explicit selection', () {
    final hidden = PortfolioSiteGenerator.generate(
      content,
      selection,
      PortfolioTemplate.light,
    );
    final shown = PortfolioSiteGenerator.generate(
      content,
      selection.copyWith(includeUpwork: true),
      PortfolioTemplate.light,
    );

    expect(utf8.decode(hidden.files['index.html']!), isNot(contains('upwork')));
    expect(utf8.decode(shown.files['index.html']!), contains('Upwork'));
    expect(
      utf8.decode(shown.files['index.html']!),
      contains('https://www.upwork.com/freelancers/~alex'),
    );
    expect(
      PortfolioSelection.fromJson(
        selection.copyWith(includeUpwork: true).toJson(),
      ).includeUpwork,
      isTrue,
    );
  });

  test('user text remains inert and unsafe URLs never become links', () {
    final bundle = PortfolioSiteGenerator.generate(
      content,
      selection,
      PortfolioTemplate.light,
    );
    final html = utf8.decode(bundle.files['index.html']!);

    expect(html, contains('&lt;script&gt;alert(1)&lt;/script&gt;'));
    expect(html, contains('&lt;strong&gt;inclusive&lt;/strong&gt;'));
    expect(html, contains('&lt;script&gt; tag stays text.'));
    expect(html, isNot(contains('href="javascript:')));
    expect(html, contains('href="https://example.test/alex"'));
    expect(html, isNot(contains('Personal site')));
    expect(html, isNot(contains(' onerror=')));
    expect(html, isNot(contains(' onmouseover=')));
  });

  test('photo alt text does not disclose an unselected display name', () {
    final bundle = PortfolioSiteGenerator.generate(
      content,
      selection.copyWith(includeDisplayName: false),
      PortfolioTemplate.light,
    );
    final html = utf8.decode(bundle.files['index.html']!);

    expect(html, contains('alt="Profile photo"'));
    expect(html, isNot(contains('alt="Alex')));
  });

  test('generated site uses the responsive one-page theme-toggle template', () {
    final light = PortfolioSiteGenerator.generate(
      content,
      selection,
      PortfolioTemplate.light,
    );
    final dark = PortfolioSiteGenerator.generate(
      content,
      selection,
      PortfolioTemplate.dark,
    );

    expect(
      utf8.decode(light.files['index.html']!),
      utf8.decode(dark.files['index.html']!),
    );
    expect(
      utf8.decode(light.files['styles.css']!),
      utf8.decode(dark.files['styles.css']!),
    );
    final html = utf8.decode(light.files['index.html']!);
    final styles = utf8.decode(light.files['styles.css']!);
    final script = utf8.decode(light.files['app.js']!);
    expect(html, contains('class="site-head"'));
    expect(html, contains('class="wrap hero-grid'));
    expect(html, contains('class="profile"'));
    expect(html, contains('class="case"'));
    expect(html, contains('id="theme-btn"'));
    expect(html, contains('aria-label="Switch theme"'));
    expect(styles, contains('--bg: #EEF1F5'));
    expect(styles, contains(':root[data-theme="dark"]'));
    expect(styles, contains('@media (prefers-color-scheme: dark)'));
    expect(styles, contains('@media (max-width: 780px)'));
    expect(styles, contains('@media (max-width: 560px)'));
    expect(styles, contains('@media (prefers-reduced-motion: reduce)'));
    expect(script, contains("'portfolio-theme:' + window.location.pathname"));
    expect(script, contains('localStorage.getItem(themeKey)'));
    expect(script, contains('localStorage.setItem(themeKey, next)'));
    expect(script, contains("setAttribute('data-theme', next)"));
    expect(html, isNot(contains('fonts.googleapis.com')));
    expect(html, isNot(contains('Fresh graduate')));
    expect(html, isNot(contains('your.name@example.com')));
    expect(
      light.files.keys,
      containsAll(['index.html', 'styles.css', 'app.js']),
    );
  });

  test('ZIP archive can be opened and preserves generated file bytes', () {
    final bundle = PortfolioSiteGenerator.generate(
      content,
      selection,
      PortfolioTemplate.dark,
    );

    final archive = ZipDecoder().decodeBytes(bundle.toZipBytes());
    final html = archive.singleWhere((file) => file.name == 'index.html');

    expect(html.content, orderedEquals(bundle.files['index.html']!));
  });
}
