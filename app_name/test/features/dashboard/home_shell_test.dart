import 'dart:typed_data';

import 'package:app_name/features/dashboard/presentation/home_shell.dart';
import 'package:app_name/features/evidence/data/evidence_repository.dart';
import 'package:app_name/features/evidence/domain/evidence.dart';
import 'package:app_name/features/portfolio/data/portfolio_record_repository.dart';
import 'package:app_name/features/portfolio/domain/portfolio_record.dart';
import 'package:app_name/features/profile/data/profile_repository.dart';
import 'package:app_name/features/profile/domain/profile.dart';
import 'package:app_name/features/projects/data/project_repository.dart';
import 'package:app_name/features/projects/domain/project.dart';
import 'package:app_name/features/skills/data/skill_repository.dart';
import 'package:app_name/features/skills/domain/skill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home matches the reference composition on a phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          profileRepository: _ProfileRepository(
            profile: const ProfileBackground(
              displayName: 'Alex Rivera',
              username: 'alex',
              headline: 'Product designer',
              bio: 'I build accessible products.',
              contactEmail: 'alex@example.test',
            ),
          ),
          profileUserId: 'user-1',
          projectRepository: _ProjectRepository([]),
          skillRepository: _SkillRepository([]),
          portfolioRecordRepository: _PortfolioRecordRepository({
            PortfolioRecordType.certification: [],
            PortfolioRecordType.achievement: [],
          }),
          evidenceRepository: _EvidenceRepository([]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your skills. Your work. Your proof.'), findsOneWidget);
    expect(find.text('Alex Rivera'), findsOneWidget);
    expect(
      find.text('Build a portfolio that shows what you can do.'),
      findsOneWidget,
    );
    expect(find.text('PORTFOLIO COMPLETION'), findsOneWidget);
    expect(find.text("You're on the right track!"), findsOneWidget);

    final metricCenters = [
      for (final label in [
        'Projects: 0',
        'Skills: 0',
        'Certifications: 0',
        'Achievements: 0',
        'Evidence: 0',
      ])
        tester.getCenter(find.bySemanticsLabel(label)),
    ];
    expect(
      metricCenters.map((center) => center.dy).reduce((a, b) => a > b ? a : b) -
          metricCenters
              .map((center) => center.dy)
              .reduce((a, b) => a < b ? a : b),
      lessThan(1),
    );

    final shortcutCenters = [
      for (final label in [
        'Add Project',
        'Manage Skills',
        'Generate Resume',
        'Portfolio',
      ])
        tester.getCenter(
          find
              .ancestor(of: find.text(label).first, matching: find.byType(Card))
              .first,
        ),
    ];
    expect(
      shortcutCenters
              .map((center) => center.dy)
              .reduce((a, b) => a > b ? a : b) -
          shortcutCenters
              .map((center) => center.dy)
              .reduce((a, b) => a < b ? a : b),
      lessThan(1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile shows saved background and Settings can log out', (
    tester,
  ) async {
    var signOutCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          onSignOut: () async {
            signOutCalls++;
          },
          profileRepository: _ProfileRepository(
            profile: const ProfileBackground(
              displayName: 'Alex Rivera',
              username: 'alex',
              headline: 'Product designer',
              bio: 'I build accessible products.',
              contactEmail: 'alex@example.test',
              phone: '+63 912 345 6789',
            ),
            education: [
              EducationRecord(
                id: 'education-1',
                userId: 'user-1',
                title: 'BS Computer Science',
                institution: 'Mapúa University',
                level: EducationLevel.bachelor,
                status: EducationStatus.completed,
                startDate: DateTime(2021),
                endDate: DateTime(2025),
                createdAt: DateTime.utc(2025),
                updatedAt: DateTime.utc(2025),
              ),
            ],
            experience: [
              ExperienceRecord(
                id: 'experience-1',
                userId: 'user-1',
                title: 'UX Intern',
                organization: 'Accessible Labs',
                type: ExperienceType.internship,
                startDate: DateTime(2024),
                endDate: DateTime(2024),
                createdAt: DateTime.utc(2024),
                updatedAt: DateTime.utc(2024),
              ),
            ],
          ),
          profileUserId: 'user-1',
          profileAccountEmail: 'alex@example.test',
          projectRepository: _ProjectRepository([]),
          skillRepository: _SkillRepository([_skill('Flutter')]),
          portfolioRecordRepository: _PortfolioRecordRepository({
            PortfolioRecordType.certification: [],
            PortfolioRecordType.achievement: [],
          }),
          evidenceRepository: _EvidenceRepository([]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Profile and background'));
    await tester.pumpAndSettle();

    expect(find.text('Alex Rivera'), findsOneWidget);
    expect(find.text('About you'), findsOneWidget);
    expect(find.text('Education and training'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Mapúa University'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('BS Computer Science'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Contact details'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Contact details'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Experience'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Experience'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('UX Intern'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Accessible Labs'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Flutter'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Flutter'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1000));
    await tester.pumpAndSettle();
    expect(find.text('Generate Resume'), findsNothing);
    expect(find.text('View Portfolio'), findsNothing);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('alex@example.test'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Log out'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Log out'), findsOneWidget);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out of Prooffolio?'), findsOneWidget);
    final dialogRect = tester.getRect(find.byType(AlertDialog));
    expect(
      tester.getCenter(find.text('Cancel')).dx,
      closeTo(dialogRect.center.dx, 1),
    );
    await tester.tap(find.text('Log out').last);
    await tester.pumpAndSettle();
    expect(signOutCalls, 1);
  });

  testWidgets('Profile is available from the fifth bottom navigation tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          profileRepository: _ProfileRepository(
            profile: const ProfileBackground(
              displayName: 'Alex Rivera',
              username: 'alex',
            ),
          ),
          profileUserId: 'user-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final navigation = find.byType(NavigationBar);
    expect(
      find.descendant(of: navigation, matching: find.text('Profile')),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: navigation,
        matching: find.byIcon(Icons.person_outline),
      ),
    );
    await tester.pumpAndSettle();

    expect(_selectedNavigationIndex(tester), 4);
    expect(find.text('Alex Rivera'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
  });

  testWidgets('phone navigation is a full-width labeled bottom bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeShell()));
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.bottomNavigationBar, isA<NavigationBar>());

    final navigation = find.byType(NavigationBar);
    final navigationRect = tester.getRect(navigation);
    expect(navigationRect.left, closeTo(0, 1));
    expect(navigationRect.width, closeTo(390, 1));
    expect(
      tester.widget<NavigationBar>(navigation).labelBehavior,
      NavigationDestinationLabelBehavior.alwaysShow,
    );
    expect(
      find.byKey(const ValueKey('floating-bottom-navigation')),
      findsNothing,
    );
  });

  testWidgets(
    'shows the saved greeting, milestone progress, counts, and recent projects',
    (tester) async {
      final updatedAt = DateTime.utc(2026, 10, 28);
      await tester.pumpWidget(
        MaterialApp(
          home: HomeShell(
            profileRepository: _ProfileRepository(
              profile: const ProfileBackground(
                displayName: 'Alex Rivera',
                username: 'alex',
                headline: 'Product designer',
                bio: 'I build accessible products.',
                contactEmail: 'alex@example.test',
                photoPath: 'profile/alex.png',
              ),
            ),
            profileUserId: 'user-1',
            projectRepository: _ProjectRepository([
              _project('newest', 'Recent research tool', updatedAt),
              _project(
                'older',
                'Earlier portfolio project',
                DateTime.utc(2026, 10, 20),
              ),
            ]),
            skillRepository: _SkillRepository([
              _skill('design'),
              _skill('research'),
              _skill('prototyping'),
            ]),
            portfolioRecordRepository: _PortfolioRecordRepository({
              PortfolioRecordType.certification: [
                _record(PortfolioRecordType.certification, 'UX certificate'),
              ],
              PortfolioRecordType.achievement: [
                _record(PortfolioRecordType.achievement, 'Design award'),
              ],
            }),
            evidenceRepository: _EvidenceRepository([
              _evidence('Workshop case study'),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alex Rivera'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('7 of 7 foundational items complete'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator).first,
            )
            .value,
        1,
      );
      await tester.scrollUntilVisible(
        find.text('Certs'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      for (final category in [
        'Projects',
        'Skills',
        'Certs',
        'Awards',
        'Evidence',
      ]) {
        expect(find.text(category), findsWidgets);
      }
      expect(find.bySemanticsLabel('Projects: 2'), findsOneWidget);
      expect(find.bySemanticsLabel('Skills: 3'), findsOneWidget);
      expect(find.bySemanticsLabel('Certifications: 1'), findsOneWidget);
      expect(find.bySemanticsLabel('Achievements: 1'), findsOneWidget);
      expect(find.bySemanticsLabel('Evidence: 1'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Recent research tool'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Recent research tool'), findsOneWidget);
      expect(find.text('Earlier portfolio project'), findsOneWidget);
      expect(find.text('In progress'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows the exact rounded progress fraction and copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          profileRepository: _ProfileRepository(
            profile: const ProfileBackground(
              displayName: 'Avery',
              username: 'avery',
              headline: 'Community designer',
              bio: 'I make clear learning tools.',
            ),
          ),
          profileUserId: 'user-1',
          projectRepository: _ProjectRepository([]),
          skillRepository: _SkillRepository([]),
          portfolioRecordRepository: _PortfolioRecordRepository({
            PortfolioRecordType.certification: [],
            PortfolioRecordType.achievement: [],
          }),
          evidenceRepository: _EvidenceRepository([]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('43%'), findsOneWidget);
    expect(find.text('3 of 7 foundational items complete'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator).first,
          )
          .value,
      3 / 7,
    );
  });

  testWidgets('does not show a percentage when a required source is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          profileRepository: _ProfileRepository(
            profile: const ProfileBackground(
              displayName: 'Avery',
              username: 'avery',
            ),
          ),
          profileUserId: 'user-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Portfolio progress is unavailable'), findsOneWidget);
    expect(find.text('0%'), findsNothing);
    expect(find.text('0 of 7 foundational items complete'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Certs'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('—'), findsNWidgets(5));
  });

  testWidgets('shows an explicit retry state when a data source fails', (
    tester,
  ) async {
    final projects = _ProjectRepository([], failuresRemaining: 1);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          profileRepository: _ProfileRepository(
            profile: const ProfileBackground(
              displayName: 'Avery',
              username: 'avery',
            ),
          ),
          profileUserId: 'user-1',
          projectRepository: projects,
          skillRepository: _SkillRepository([]),
          portfolioRecordRepository: _PortfolioRecordRepository({
            PortfolioRecordType.certification: [],
            PortfolioRecordType.achievement: [],
          }),
          evidenceRepository: _EvidenceRepository([]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load portfolio data'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('0%'), findsNothing);

    final callsBeforeRetry = projects.listCalls;
    await _tapHomeAction(tester, 'Try again');

    expect(find.text('14%'), findsOneWidget);
    expect(find.text('1 of 7 foundational items complete'), findsOneWidget);
    expect(projects.listCalls, greaterThan(callsBeforeRetry));
  });

  testWidgets(
    'shortcuts reach the existing project, skill, and portfolio destinations',
    (tester) async {
      for (final (label, index, opensPortfolio) in [
        ('Add Project', 1, false),
        ('Manage Skills', 2, false),
        ('Generate Resume', 0, true),
        ('Portfolio', 0, true),
      ]) {
        await tester.pumpWidget(
          MaterialApp(home: HomeShell(key: ValueKey(label))),
        );
        await tester.pumpAndSettle();
        await _tapShortcut(tester, label);
        if (opensPortfolio) {
          expect(_selectedNavigationIndex(tester), 3);
          expect(find.text('Portfolio Preview'), findsOneWidget);
          await tester.tap(find.byTooltip('Back to Home'));
          await tester.pumpAndSettle();
          expect(_selectedNavigationIndex(tester), index);
        } else {
          expect(_selectedNavigationIndex(tester), index);
        }
      }
    },
  );

  testWidgets('requests a signed URL for the saved private profile photo', (
    tester,
  ) async {
    final repository = _ProfileRepository(
      profile: const ProfileBackground(
        displayName: 'Alex Rivera',
        username: 'alex',
        photoPath: 'private/alex.png',
      ),
      signedUrl: 'https://example.test/signed-alex.png',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(profileRepository: repository, profileUserId: 'user-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.signedPhotoPath, 'private/alex.png');
  });
}

Future<void> _tapShortcut(WidgetTester tester, String label) async {
  final shortcut = find.text(label);
  final listView = find.byType(ListView).first;
  final navigationBar = find.byType(NavigationBar);
  for (var attempt = 0; attempt < 10; attempt++) {
    if (shortcut.evaluate().isNotEmpty &&
        tester.getCenter(shortcut.first).dy <
            tester.getTopLeft(navigationBar).dy - 20) {
      break;
    }
    await tester.drag(listView, const Offset(0, -180));
    await tester.pumpAndSettle();
  }
  expect(shortcut, findsWidgets);
  expect(
    tester.getCenter(shortcut.first).dy,
    lessThan(tester.getTopLeft(navigationBar).dy),
  );
  await tester.tap(shortcut.first);
  await tester.pumpAndSettle();
}

Future<void> _tapHomeAction(WidgetTester tester, String label) async {
  final action = find.text(label);
  final listView = find.byType(ListView).first;
  final navigationBar = find.byType(NavigationBar);
  for (var attempt = 0; attempt < 5; attempt++) {
    if (action.evaluate().isNotEmpty &&
        tester.getCenter(action.first).dy <
            tester.getTopLeft(navigationBar).dy - 20) {
      break;
    }
    await tester.drag(listView, const Offset(0, -100));
    await tester.pumpAndSettle();
  }
  await tester.tap(action.first);
  await tester.pumpAndSettle();
}

int _selectedNavigationIndex(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

Project _project(String id, String title, DateTime updatedAt) => Project(
  id: id,
  userId: 'user-1',
  title: title,
  summary: '',
  problemStatement: '',
  description: '',
  keyFeatures: const [],
  technologies: const [],
  contribution: '',
  challenges: '',
  lessonsLearned: '',
  repositoryUrl: '',
  demoUrl: '',
  startDate: null,
  endDate: null,
  status: ProjectStatus.inProgress,
  publicationStatus: ProjectPublicationStatus.draft,
  createdAt: updatedAt,
  updatedAt: updatedAt,
);

Skill _skill(String name) => Skill(
  id: name,
  userId: 'user-1',
  name: name,
  category: SkillCategory.technologyDigital,
  status: SkillStatus.applied,
  projectIds: const [],
  projectTitles: const [],
  createdAt: DateTime.utc(2026, 10, 1),
  updatedAt: DateTime.utc(2026, 10, 1),
);

PortfolioRecord _record(PortfolioRecordType type, String title) =>
    PortfolioRecord(
      id: title,
      userId: 'user-1',
      recordType: type,
      title: title,
      createdAt: DateTime.utc(2026, 10, 1),
      updatedAt: DateTime.utc(2026, 10, 1),
    );

EvidenceRecord _evidence(String title) => EvidenceRecord(
  id: title,
  userId: 'user-1',
  kind: EvidenceKind.url,
  title: title,
  description: '',
  sourceUrl: 'https://example.test/evidence',
  createdAt: DateTime.utc(2026, 10, 1),
  updatedAt: DateTime.utc(2026, 10, 1),
);

class _ProfileRepository implements ProfileBackgroundRepository {
  _ProfileRepository({
    required this.profile,
    this.signedUrl,
    this.education = const [],
    this.experience = const [],
  });

  final ProfileBackground? profile;
  final String? signedUrl;
  final List<EducationRecord> education;
  final List<ExperienceRecord> experience;
  String? signedPhotoPath;

  @override
  Future<ProfileBackground?> loadProfile(String userId) async => profile;

  @override
  Future<String> createProfilePhotoSignedUrl(String path) async {
    signedPhotoPath = path;
    return signedUrl ?? 'unsupported://photo';
  }

  @override
  Future<void> saveBackground(
    String userId,
    ProfileBackground background,
  ) async {}

  @override
  Future<List<EducationRecord>> listEducation(String userId) async => education;

  @override
  Future<EducationRecord> saveEducation(
    String userId,
    EducationDraft draft, {
    String? id,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteEducation(String userId, String id) async {}

  @override
  Future<List<ExperienceRecord>> listExperience(String userId) async =>
      experience;

  @override
  Future<ExperienceRecord> saveExperience(
    String userId,
    ExperienceDraft draft, {
    String? id,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteExperience(String userId, String id) async {}

  @override
  Future<String> uploadProfilePhoto(
    String userId,
    Uint8List bytes,
    String fileName,
    String contentType,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteProfilePhoto(String userId, String path) async {}

  @override
  Future<Uint8List> downloadProfilePhoto(String userId, String path) =>
      throw UnimplementedError();
}

class _ProjectRepository implements ProjectRepository {
  _ProjectRepository(this.projects, {this.failuresRemaining = 0});

  final List<Project> projects;
  int failuresRemaining;
  int listCalls = 0;

  @override
  Future<List<Project>> listProjects() async {
    listCalls++;
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw StateError('Project source unavailable');
    }
    return projects;
  }

  @override
  Future<Project> createProject(ProjectDraft draft) =>
      throw UnimplementedError();

  @override
  Future<Project> updateProject(String id, ProjectDraft draft) =>
      throw UnimplementedError();

  @override
  Future<void> deleteProject(String id) => throw UnimplementedError();
}

class _SkillRepository implements SkillRepository {
  _SkillRepository(this.skills);

  final List<Skill> skills;

  @override
  Future<List<Skill>> listSkills() async => skills;

  @override
  Future<Skill> saveSkill({
    String? id,
    required SkillDraft draft,
    required List<String> projectIds,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteSkill(String id) => throw UnimplementedError();
}

class _PortfolioRecordRepository implements PortfolioRecordRepository {
  _PortfolioRecordRepository(this.recordsByType);

  final Map<PortfolioRecordType, List<PortfolioRecord>> recordsByType;

  @override
  Future<List<PortfolioRecord>> listRecords(PortfolioRecordType type) async =>
      recordsByType[type] ?? const [];

  @override
  Future<PortfolioRecord> createRecord(PortfolioRecordDraft draft) =>
      throw UnimplementedError();

  @override
  Future<PortfolioRecord> updateRecord(String id, PortfolioRecordDraft draft) =>
      throw UnimplementedError();

  @override
  Future<void> deleteRecord(String id) => throw UnimplementedError();
}

class _EvidenceRepository implements EvidenceRepository {
  _EvidenceRepository(this.records);

  final List<EvidenceRecord> records;

  @override
  Future<List<EvidenceRecord>> listEvidence() async => records;

  @override
  Future<List<EvidenceTarget>> listTargets() async => const [];

  @override
  Future<EvidenceRecord> addUrl({
    required String title,
    required String sourceUrl,
    String description = '',
    List<EvidenceTarget> targets = const [],
  }) => throw UnimplementedError();

  @override
  Future<EvidenceRecord> uploadFile({
    required String title,
    required String fileName,
    required String? mimeType,
    required Uint8List bytes,
    String description = '',
    List<EvidenceTarget> targets = const [],
  }) => throw UnimplementedError();

  @override
  Future<String> openUrl(EvidenceRecord record) => throw UnimplementedError();

  @override
  Future<void> deleteEvidence(EvidenceRecord record) =>
      throw UnimplementedError();
}
