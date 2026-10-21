import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_name/features/profile/data/profile_repository.dart';
import 'package:app_name/features/profile/domain/profile.dart';
import 'package:app_name/features/profile/presentation/profile_background_screen.dart';
import 'package:app_name/features/dashboard/presentation/home_shell.dart';

void main() {
  test('an unsupported MIME type is not inferred from a trusted extension', () {
    final mimeType = ProfilePhotoPolicy.normaliseMimeType(
      'application/pdf',
      'renamed.jpg',
    );

    expect(mimeType, 'application/pdf');
    expect(
      ProfilePhotoPolicy.validate(
        PickedProfilePhoto(
          fileName: 'renamed.jpg',
          mimeType: mimeType,
          bytes: _tinyPng,
        ),
      ),
      isNotNull,
    );
  });

  test('MIME inference is used only when the platform omits the MIME type', () {
    expect(
      ProfilePhotoPolicy.normaliseMimeType(null, 'portrait.png'),
      'image/png',
    );
    expect(
      ProfilePhotoPolicy.validate(
        PickedProfilePhoto(
          fileName: 'portrait.png',
          mimeType: 'image/png',
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
      ),
      isNotNull,
    );
  });

  testWidgets('profile save is disabled while a photo upload is in progress', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProfileBackgroundRepository()
      ..photoUpload = Completer<String>();
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileBackgroundScreen(
          repository: repository,
          userId: 'user-1',
          photoPicker: _FakeProfilePhotoPicker(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chooseProfilePhotoButton')));
    await tester.pump();

    final saveButton = tester.widget<FilledButton>(
      find.byKey(const Key('saveProfileButton')),
    );
    try {
      expect(saveButton.onPressed, isNull);
    } finally {
      repository.photoUpload!.complete('user-1/profile.png');
      await tester.pump();
    }
  });

  testWidgets('photo actions are disabled while profile save is in progress', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProfileBackgroundRepository()
      ..backgroundSave = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileBackgroundScreen(
          repository: repository,
          userId: 'user-1',
          photoPicker: _FakeProfilePhotoPicker(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save profile'));
    await tester.pump();

    final chooseButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('chooseProfilePhotoButton')),
    );
    try {
      expect(chooseButton.onPressed, isNull);
    } finally {
      repository.backgroundSave!.complete();
      await tester.pump();
    }
  });

  testWidgets('private profile photo URL is refreshed before it expires', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProfileBackgroundRepository()
      ..background = const ProfileBackground(
        displayName: 'Avery Student',
        username: 'avery_student',
        photoPath: 'user-1/profile.png',
      );
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileBackgroundScreen(repository: repository, userId: 'user-1'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 90));
    await tester.pump();

    expect(repository.signedUrlRequests, greaterThanOrEqualTo(2));
  });

  testWidgets('saved contact email takes precedence over account email', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProfileBackgroundRepository()
      ..background = const ProfileBackground(
        displayName: 'Avery Student',
        username: 'avery_student',
        contactEmail: 'portfolio@example.com',
      );
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileBackgroundScreen(
          repository: repository,
          userId: 'user-1',
          accountEmail: 'account@example.com',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('profileContactEmailField')),
      240,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('profileContactEmailField')),
          )
          .controller!
          .text,
      'portfolio@example.com',
    );
  });

  testWidgets('profile action opens the background editor from Home', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProfileBackgroundRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          profileRepository: repository,
          profileUserId: 'user-1',
          profileAccountEmail: 'avery@example.com',
        ),
      ),
    );

    await tester.tap(find.byTooltip('Profile and background'));
    await tester.pumpAndSettle();

    expect(find.text('Profile and background'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('About you'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('About you'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('profileContactEmailField')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(repository.background.contactEmail, isNull);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('profileContactEmailField')),
          )
          .controller!
          .text,
      'avery@example.com',
    );
  });

  testWidgets('profile can be saved without a degree or work history', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProfileBackgroundRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileBackgroundScreen(repository: repository, userId: 'user-1'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('profileHeadlineField')),
      240,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.enterText(
      find.byKey(const Key('profileHeadlineField')),
      'Growing community gardens',
    );
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(repository.background.headline, 'Growing community gardens');
    expect(repository.education, isEmpty);
    expect(repository.experience, isEmpty);
    expect(find.text('Profile saved'), findsOneWidget);
  });

  testWidgets('education entry requires a title before it can be saved', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProfileBackgroundRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileBackgroundScreen(repository: repository, userId: 'user-1'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Add education'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Add education'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save education'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a course or qualification'), findsOneWidget);
    expect(repository.education, isEmpty);

    await tester.enterText(
      find.byKey(const Key('educationTitleField')),
      'Community horticulture course',
    );
    await tester.tap(find.text('Save education'));
    await tester.pumpAndSettle();

    expect(repository.education.single.title, 'Community horticulture course');
  });

  testWidgets('profile save failure is visible to the user', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProfileBackgroundRepository()
      ..failBackgroundSave = true;
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileBackgroundScreen(repository: repository, userId: 'user-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(find.text('Profile could not be saved. Try again.'), findsOneWidget);
  });

  testWidgets(
    'user can select a broad occupation and add education and volunteer work',
    (WidgetTester tester) async {
      final repository = _FakeProfileBackgroundRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileBackgroundScreen(
            repository: repository,
            userId: 'user-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final occupationField = find.byKey(const Key('occupationCategoryField'));
      await tester.scrollUntilVisible(
        occupationField,
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(occupationField);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('occupationSearchField')),
        'Education',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Education and training').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('occupationTitleField')),
        'Primary teacher',
      );

      await tester.scrollUntilVisible(
        find.text('Add education'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Add education'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('educationTitleField')),
        'Bachelor of Education',
      );
      await tester.enterText(
        find.byKey(const Key('educationInstitutionField')),
        'State University',
      );
      await tester.tap(find.text('Save education'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Add experience'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Add experience'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('experienceTitleField')),
        'Community reading tutor',
      );
      await tester.tap(find.byKey(const Key('experienceTypeField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Volunteering').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('experienceCurrentField')));
      await tester.tap(find.text('Save experience'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save profile'));
      await tester.pumpAndSettle();

      expect(
        repository.background.occupationCategory,
        OccupationCategory.education,
      );
      expect(repository.background.occupationTitle, 'Primary teacher');
      expect(repository.education.single.title, 'Bachelor of Education');
      expect(repository.experience.single.title, 'Community reading tutor');
      expect(repository.experience.single.organization, isNull);
      expect(repository.experience.single.type, ExperienceType.volunteering);
      expect(repository.experience.single.isCurrent, isTrue);
    },
  );
}

class _FakeProfileBackgroundRepository implements ProfileBackgroundRepository {
  ProfileBackground background = const ProfileBackground(
    displayName: 'Avery Student',
    username: 'avery_student',
  );
  final List<EducationRecord> education = [];
  final List<ExperienceRecord> experience = [];
  bool failBackgroundSave = false;
  Completer<void>? backgroundSave;
  Completer<String>? photoUpload;
  int signedUrlRequests = 0;
  int _nextId = 0;

  @override
  Future<ProfileBackground?> loadProfile(String userId) async => background;

  @override
  Future<void> saveBackground(String userId, ProfileBackground value) async {
    await backgroundSave?.future;
    if (failBackgroundSave) throw StateError('Save failed');
    background = value;
  }

  @override
  Future<String> uploadProfilePhoto(
    String userId,
    Uint8List bytes,
    String fileName,
    String contentType,
  ) async => await (photoUpload?.future ?? Future.value('$userId/$fileName'));

  @override
  Future<void> deleteProfilePhoto(String userId, String path) async {}

  @override
  Future<String> createProfilePhotoSignedUrl(String path) async {
    signedUrlRequests++;
    return 'https://example.com/$path?request=$signedUrlRequests';
  }

  @override
  Future<List<EducationRecord>> listEducation(String userId) async =>
      List.of(education);

  @override
  Future<EducationRecord> saveEducation(
    String userId,
    EducationDraft draft, {
    String? id,
  }) async {
    final now = DateTime.utc(2026, 10, 20);
    final record = EducationRecord(
      id: id ?? 'education-${++_nextId}',
      userId: userId,
      title: draft.title,
      institution: draft.institution,
      level: draft.level,
      status: draft.status,
      startDate: draft.startDate,
      endDate: draft.endDate,
      description: draft.description,
      createdAt: now,
      updatedAt: now,
    );
    education.removeWhere((item) => item.id == record.id);
    education.add(record);
    return record;
  }

  @override
  Future<void> deleteEducation(String userId, String id) async {
    education.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<ExperienceRecord>> listExperience(String userId) async =>
      List.of(experience);

  @override
  Future<ExperienceRecord> saveExperience(
    String userId,
    ExperienceDraft draft, {
    String? id,
  }) async {
    final now = DateTime.utc(2026, 10, 20);
    final record = ExperienceRecord(
      id: id ?? 'experience-${++_nextId}',
      userId: userId,
      title: draft.title,
      organization: draft.organization,
      type: draft.type,
      startDate: draft.startDate,
      endDate: draft.endDate,
      isCurrent: draft.isCurrent,
      description: draft.description,
      createdAt: now,
      updatedAt: now,
    );
    experience.removeWhere((item) => item.id == record.id);
    experience.add(record);
    return record;
  }

  @override
  Future<void> deleteExperience(String userId, String id) async {
    experience.removeWhere((item) => item.id == id);
  }
}

class _FakeProfilePhotoPicker implements ProfilePhotoPicker {
  @override
  Future<PickedProfilePhoto?> pickPhoto() async => PickedProfilePhoto(
    fileName: 'profile.png',
    mimeType: 'image/png',
    bytes: _tinyPng,
  );
}

final Uint8List _tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+j5QAAAABJRU5ErkJggg==',
);
