import 'dart:typed_data';

import 'package:app_name/features/dashboard/presentation/home_shell.dart';
import 'package:app_name/features/evidence/data/evidence_repository.dart';
import 'package:app_name/features/evidence/domain/evidence.dart';
import 'package:app_name/features/portfolio/data/portfolio_content_repository.dart';
import 'package:app_name/features/portfolio/data/portfolio_record_repository.dart';
import 'package:app_name/features/portfolio/domain/resume_content.dart';
import 'package:app_name/features/portfolio/domain/portfolio_record.dart';
import 'package:app_name/features/portfolio/presentation/portfolio_preview_screen.dart';
import 'package:app_name/features/profile/data/profile_repository.dart';
import 'package:app_name/features/profile/domain/profile.dart';
import 'package:app_name/features/projects/data/project_repository.dart';
import 'package:app_name/features/projects/domain/project.dart';
import 'package:app_name/features/skills/data/skill_repository.dart';
import 'package:app_name/features/skills/domain/skill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'one unavailable record source does not hide other private content',
    () async {
      final repository = PortfolioContentRepository(
        profileRepository: _ProfileRepository(),
        projectRepository: _ProjectRepository(),
        skillRepository: _SkillRepository(),
        portfolioRecordRepository: _PortfolioRecordRepository(),
        evidenceRepository: _EvidenceRepository(),
      );

      final content = await repository.loadPrivateContent('owner-id');

      expect(content.profile.isAvailable, isTrue);
      expect(content.projects.isAvailable, isFalse);
      expect(content.projects.error, isNotNull);
      expect(content.skills.isAvailable, isTrue);
      expect(content.skills.value, isEmpty);
      expect(content.certifications.isAvailable, isTrue);
    },
  );

  testWidgets('private preview shows saved profile and contact fields', (
    tester,
  ) async {
    final repository = PortfolioContentRepository(
      profileRepository: _ProfileRepository(),
      projectRepository: _ProjectRepository(),
      skillRepository: _SkillRepository(),
      portfolioRecordRepository: _PortfolioRecordRepository(),
      evidenceRepository: _EvidenceRepository(),
    );
    var profileOpened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PortfolioPreviewScreen(
            repository: repository,
            userId: 'owner-id',
            onEditProfile: () => profileOpened = true,
            onOpenProjects: () {},
            onOpenSkills: () {},
            onOpenRecord: (_) {},
            onOpenEvidence: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alex Doe'), findsOneWidget);
    expect(find.text('Community educator'), findsOneWidget);
    expect(find.text('Email: alex@example.test'), findsOneWidget);
    expect(find.textContaining('not a rating of your career'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Open profile basics'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open profile basics'));
    expect(profileOpened, isTrue);
  });

  testWidgets('private preview shows contact even without an introduction', (
    tester,
  ) async {
    final repository = PortfolioContentRepository(
      profileRepository: _ProfileRepository(
        profile: const ProfileBackground(
          displayName: 'Alex Doe',
          username: 'alex',
          contactEmail: 'alex@example.test',
          upworkUrl: 'https://www.upwork.com/freelancers/~alex',
        ),
      ),
      projectRepository: _ProjectRepository(),
      skillRepository: _SkillRepository(),
      portfolioRecordRepository: _PortfolioRecordRepository(),
      evidenceRepository: _EvidenceRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PortfolioPreviewScreen(
            repository: repository,
            userId: 'owner-id',
            onEditProfile: () {},
            onOpenProjects: () {},
            onOpenSkills: () {},
            onOpenRecord: (_) {},
            onOpenEvidence: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Email: alex@example.test'), findsOneWidget);
    expect(
      find.text('Upwork: https://www.upwork.com/freelancers/~alex'),
      findsOneWidget,
    );
  });

  testWidgets('private preview offers a resume built from saved profile data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(850, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = PortfolioContentRepository(
      profileRepository: _ProfileRepository(),
      projectRepository: _ProjectRepository(),
      skillRepository: _SkillRepository(),
      portfolioRecordRepository: _PortfolioRecordRepository(),
      evidenceRepository: _EvidenceRepository(),
    );
    ResumeContent? resume;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PortfolioPreviewScreen(
            repository: repository,
            userId: 'owner-id',
            onEditProfile: () {},
            onOpenProjects: () {},
            onOpenSkills: () {},
            onOpenRecord: (_) {},
            onOpenEvidence: () {},
            onBuildResume: (content) {
              resume = ResumeContent.fromPortfolioContent(content);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generate Resume'));

    expect(resume?.displayName, 'Alex Doe');
    expect(resume?.contactDetails.single.value, 'alex@example.test');
  });

  testWidgets('portfolio preview presents saved work in the reference layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = PortfolioContentRepository(
      profileRepository: _ProfileRepository(
        profile: const ProfileBackground(
          displayName: 'Alex Doe',
          username: 'alex',
          headline: 'Computer Engineering Student',
          bio: 'Building practical solutions with code.',
          contactEmail: 'alex@example.test',
          githubUrl: 'https://github.com/alex',
        ),
      ),
      projectRepository: _ProjectRepository(projects: [_featuredProject]),
      skillRepository: _SkillRepository(skills: [_featuredSkill]),
      portfolioRecordRepository: _PortfolioRecordRepository(),
      evidenceRepository: _EvidenceRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PortfolioPreviewScreen(
            repository: repository,
            userId: 'owner-id',
            onEditProfile: () {},
            onOpenProjects: () {},
            onOpenSkills: () {},
            onOpenRecord: (_) {},
            onOpenEvidence: () {},
            onBuildResume: (_) {},
            onBuildSite: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Portfolio Preview'), findsOneWidget);
    expect(find.text('Featured Projects'), findsOneWidget);
    expect(find.text('Community Exchange'), findsOneWidget);
    expect(find.text('Flutter'), findsWidgets);
    expect(find.text('Repository'), findsOneWidget);
    expect(find.text('Live Demo'), findsOneWidget);
    expect(find.text('Skills'), findsWidgets);
    expect(find.text('About Me'), findsOneWidget);
    expect(find.text('Generate Resume'), findsOneWidget);
    expect(find.text('Generate Portfolio'), findsOneWidget);
  });

  testWidgets('about preview card opens profile editing', (tester) async {
    final repository = PortfolioContentRepository(
      profileRepository: _ProfileRepository(
        profile: const ProfileBackground(
          displayName: 'Alex Doe',
          username: 'alex',
          bio: 'A practical introduction.',
        ),
      ),
      projectRepository: _ProjectRepository(projects: [_featuredProject]),
      skillRepository: _SkillRepository(skills: [_featuredSkill]),
      portfolioRecordRepository: _PortfolioRecordRepository(),
      evidenceRepository: _EvidenceRepository(),
    );
    var profileOpened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PortfolioPreviewScreen(
            repository: repository,
            userId: 'owner-id',
            onEditProfile: () => profileOpened = true,
            onOpenProjects: () {},
            onOpenSkills: () {},
            onOpenRecord: (_) {},
            onOpenEvidence: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('About Me'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About Me'));

    expect(profileOpened, isTrue);
  });

  testWidgets(
    'preview includes project contribution when it is the only detail',
    (tester) async {
      final repository = PortfolioContentRepository(
        profileRepository: _ProfileRepository(),
        projectRepository: _ProjectRepository(
          projects: [
            Project(
              id: 'project-id',
              userId: 'owner-id',
              title: 'Community garden',
              summary: '',
              problemStatement: '',
              description: '',
              keyFeatures: const [],
              technologies: const [],
              contribution: 'I organized volunteer planting days.',
              challenges: '',
              lessonsLearned: '',
              repositoryUrl: '',
              demoUrl: '',
              startDate: null,
              endDate: null,
              status: ProjectStatus.completed,
              publicationStatus: ProjectPublicationStatus.draft,
              createdAt: DateTime.utc(2026),
              updatedAt: DateTime.utc(2026),
            ),
          ],
        ),
        skillRepository: _SkillRepository(),
        portfolioRecordRepository: _PortfolioRecordRepository(),
        evidenceRepository: _EvidenceRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PortfolioPreviewScreen(
              repository: repository,
              userId: 'owner-id',
              onEditProfile: () {},
              onOpenProjects: () {},
              onOpenSkills: () {},
              onOpenRecord: (_) {},
              onOpenEvidence: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('I organized volunteer planting days.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('achievement action opens the manager on Achievements', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(850, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final recordRepository = _PortfolioRecordRepository(
      records: [_achievementRecord],
    );
    final repository = PortfolioContentRepository(
      profileRepository: _ProfileRepository(),
      projectRepository: _ProjectRepository(),
      skillRepository: _SkillRepository(),
      portfolioRecordRepository: recordRepository,
      evidenceRepository: _EvidenceRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          portfolioContentRepository: repository,
          portfolioRecordRepository: recordRepository,
          profileUserId: 'owner-id',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.public_outlined),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Manage achievements'));
    await tester.tap(find.text('Manage achievements'));
    await tester.pumpAndSettle();

    final tabs = tester.widget<SegmentedButton<PortfolioRecordType>>(
      find.byType(SegmentedButton<PortfolioRecordType>),
    );
    expect(tabs.selected, contains(PortfolioRecordType.achievement));
  });
}

final _featuredProject = Project(
  id: 'featured-project',
  userId: 'owner-id',
  title: 'Community Exchange',
  summary: 'A neighborhood resource exchange.',
  problemStatement: '',
  description: 'Built a searchable catalog.',
  keyFeatures: const [],
  technologies: const ['Flutter', 'Supabase'],
  contribution: '',
  challenges: '',
  lessonsLearned: '',
  repositoryUrl: 'https://github.com/alex/community-exchange',
  demoUrl: 'https://example.test/community-exchange',
  startDate: null,
  endDate: null,
  status: ProjectStatus.completed,
  publicationStatus: ProjectPublicationStatus.draft,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _featuredSkill = Skill(
  id: 'featured-skill',
  userId: 'owner-id',
  name: 'Programming',
  category: SkillCategory.technologyDigital,
  status: SkillStatus.applied,
  projectIds: const ['featured-project'],
  projectTitles: const ['Community Exchange'],
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _achievementRecord = PortfolioRecord(
  id: 'achievement-id',
  userId: 'owner-id',
  recordType: PortfolioRecordType.achievement,
  title: 'Community award',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

class _ProfileRepository implements ProfileBackgroundRepository {
  _ProfileRepository({
    this.profile = const ProfileBackground(
      displayName: 'Alex Doe',
      username: 'alex',
      headline: 'Community educator',
      contactEmail: 'alex@example.test',
    ),
  });

  final ProfileBackground profile;

  @override
  Future<ProfileBackground?> loadProfile(String userId) async => profile;

  @override
  Future<void> saveBackground(
    String userId,
    ProfileBackground background,
  ) async {}

  @override
  Future<List<EducationRecord>> listEducation(String userId) async => [];

  @override
  Future<EducationRecord> saveEducation(
    String userId,
    EducationDraft draft, {
    String? id,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteEducation(String userId, String id) async {}

  @override
  Future<List<ExperienceRecord>> listExperience(String userId) async => [];

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
  Future<String> createProfilePhotoSignedUrl(String path) async =>
      'signed-photo';

  @override
  Future<Uint8List> downloadProfilePhoto(String userId, String path) async =>
      Uint8List(0);
}

class _ProjectRepository implements ProjectRepository {
  _ProjectRepository({this.projects = const []});

  final List<Project> projects;

  @override
  Future<List<Project>> listProjects() async =>
      projects.isEmpty ? throw Exception('offline') : projects;

  @override
  Future<Project> createProject(ProjectDraft draft) =>
      throw UnimplementedError();

  @override
  Future<Project> updateProject(String id, ProjectDraft draft) =>
      throw UnimplementedError();

  @override
  Future<void> deleteProject(String id) async {}
}

class _SkillRepository implements SkillRepository {
  _SkillRepository({this.skills = const []});

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
  Future<void> deleteSkill(String id) async {}
}

class _PortfolioRecordRepository implements PortfolioRecordRepository {
  _PortfolioRecordRepository({this.records = const []});

  final List<PortfolioRecord> records;

  @override
  Future<List<PortfolioRecord>> listRecords(PortfolioRecordType type) async =>
      records.where((record) => record.recordType == type).toList();

  @override
  Future<PortfolioRecord> createRecord(PortfolioRecordDraft draft) =>
      throw UnimplementedError();

  @override
  Future<PortfolioRecord> updateRecord(String id, PortfolioRecordDraft draft) =>
      throw UnimplementedError();

  @override
  Future<void> deleteRecord(String id) async {}
}

class _EvidenceRepository implements EvidenceRepository {
  @override
  Future<List<EvidenceRecord>> listEvidence() async => [];

  @override
  Future<List<EvidenceTarget>> listTargets() async => [];

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
  Future<void> deleteEvidence(EvidenceRecord record) async {}
}
