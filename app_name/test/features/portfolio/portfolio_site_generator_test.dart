import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:app_name/features/portfolio/data/portfolio_site_generator.dart';
import 'package:app_name/features/portfolio/domain/portfolio_content.dart';
import 'package:app_name/features/portfolio/domain/portfolio_template.dart';
import 'package:app_name/features/profile/domain/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test(
    'uses the editorial template and shows the selected photo in its hero',
    () async {
      final bundle = await PortfolioSiteGenerator.generate(
        content,
        selection,
        PortfolioTemplate.light,
      );
      final html = utf8.decode(bundle.files['index.html']!);

      expect(html, contains('class="masthead"'));
      expect(
        html,
        contains('<img class="hero-photo" src="portfolio-photo.jpg"'),
      );
      expect(html, contains('Community educator'));
      expect(html, isNot(contains('Smart Geriatric Healthcare Assistant')));

      final previewHtml = PortfolioSiteGenerator.previewHtml(bundle);
      expect(
        previewHtml,
        contains('src="data:image/jpeg;base64,${base64Encode(photoBytes)}"'),
      );
    },
  );

  test('generated site contains only selected public information', () async {
    final bundle = await PortfolioSiteGenerator.generate(
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

  test('Upwork link is included only after explicit selection', () async {
    final hidden = await PortfolioSiteGenerator.generate(
      content,
      selection,
      PortfolioTemplate.light,
    );
    final shown = await PortfolioSiteGenerator.generate(
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

  test('user text remains inert and unsafe URLs never become links', () async {
    final bundle = await PortfolioSiteGenerator.generate(
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

  test('photo alt text does not disclose an unselected display name', () async {
    final bundle = await PortfolioSiteGenerator.generate(
      content,
      selection.copyWith(includeDisplayName: false),
      PortfolioTemplate.light,
    );
    final html = utf8.decode(bundle.files['index.html']!);

    expect(html, contains('alt="Profile photo"'));
    expect(html, isNot(contains('alt="Alex')));
  });

  test(
    'generated site uses the editorial responsive theme-toggle template',
    () async {
      final light = await PortfolioSiteGenerator.generate(
        content,
        selection,
        PortfolioTemplate.light,
      );
      final dark = await PortfolioSiteGenerator.generate(
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
      expect(html, contains('class="masthead"'));
      expect(html, contains('class="hero-aside"'));
      expect(html, contains('class="hero-photo-frame"'));
      expect(html, contains('class="entry"'));
      expect(html, contains('id="theme-btn"'));
      expect(html, contains('aria-label="Switch theme"'));
      expect(styles, contains('--bg: #F6F7F8'));
      expect(styles, contains("font-family: var(--font-display)"));
      expect(styles, contains(':root[data-theme="dark"]'));
      expect(styles, contains('@media (prefers-color-scheme: dark)'));
      expect(styles, contains('@media (max-width: 900px)'));
      expect(styles, contains('@media (max-width: 600px)'));
      expect(styles, contains('@media (prefers-reduced-motion: reduce)'));
      expect(
        script,
        contains("localStorage.getItem('portfolio-editorial-theme')"),
      );
      expect(
        script,
        contains("localStorage.setItem('portfolio-editorial-theme', next)"),
      );
      expect(script, contains("setAttribute('data-theme', next)"));
      expect(html, contains('fonts.googleapis.com'));
      expect(html, isNot(contains('Fresh graduate')));
      expect(html, isNot(contains('your.name@example.com')));
      expect(
        light.files.keys,
        containsAll(['index.html', 'styles.css', 'app.js']),
      );
    },
  );

  test('profile portrait is compact, circular, and right aligned', () async {
    final bundle = await PortfolioSiteGenerator.generate(
      content,
      selection,
      PortfolioTemplate.light,
    );
    final styles = utf8.decode(bundle.files['styles.css']!);

    expect(styles, contains('width: min(100%, 300px)'));
    expect(styles, contains('aspect-ratio: 1'));
    expect(styles, contains('border-radius: 50%'));
    expect(styles, contains('justify-items: end'));
    expect(styles, contains('justify-self: end'));
    expect(styles, contains('object-fit: cover'));
  });

  test('masthead places the title and copy beside the profile image', () async {
    final bundle = await PortfolioSiteGenerator.generate(
      content,
      selection,
      PortfolioTemplate.light,
    );
    final html = utf8.decode(bundle.files['index.html']!);

    expect(
      html,
      contains(
        '<div class="mast-body"><div class="mast-copy">'
        '<h1 class="headline">Alex &lt;script&gt;alert(1)&lt;/script&gt;',
      ),
    );
  });

  test(
    'responsive hero and project actions stay centered on small screens',
    () async {
      final bundle = await PortfolioSiteGenerator.generate(
        content,
        selection,
        PortfolioTemplate.light,
      );
      final styles = utf8.decode(bundle.files['styles.css']!);

      expect(
        styles,
        matches(RegExp(r'\.mast-body\s*\{[^}]*align-items:\s*start;')),
      );
      expect(
        styles,
        matches(RegExp(r'\.hero-aside\s*\{[^}]*justify-items:\s*center;')),
      );
      expect(
        styles,
        matches(RegExp(r'\.hero-photo-frame\s*\{[^}]*justify-self:\s*center;')),
      );
      expect(
        styles,
        matches(
          RegExp(
            r'\.facts\s*\{[^}]*width:\s*min\(100%,\s*22rem\);[^}]*margin-inline:\s*auto;',
          ),
        ),
      );
      expect(
        styles,
        matches(
          RegExp(r'\.entry \.actions\s*\{[^}]*justify-content:\s*center;'),
        ),
      );
    },
  );

  test(
    'ZIP archive can be opened and preserves generated file bytes',
    () async {
      final bundle = await PortfolioSiteGenerator.generate(
        content,
        selection,
        PortfolioTemplate.dark,
      );

      final archive = ZipDecoder().decodeBytes(bundle.toZipBytes());
      final html = archive.singleWhere((file) => file.name == 'index.html');

      expect(html.content, orderedEquals(bundle.files['index.html']!));
    },
  );
}
