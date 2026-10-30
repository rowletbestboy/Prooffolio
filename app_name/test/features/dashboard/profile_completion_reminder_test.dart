import 'dart:typed_data';

import 'package:app_name/features/dashboard/presentation/home_shell.dart';
import 'package:app_name/features/dashboard/presentation/profile_completion_reminder.dart';
import 'package:app_name/features/profile/data/profile_repository.dart';
import 'package:app_name/features/profile/domain/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('incomplete profile reminder opens the profile overview', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          profileRepository: _FakeProfileRepository(),
          profileUserId: 'user-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Complete your profile'), findsOneWidget);
    expect(find.textContaining('work summary'), findsOneWidget);

    await tester.tap(find.text('Open profile'));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('About you'), findsOneWidget);
  });

  testWidgets('complete saved details show a completed state', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProfileRepository()
      ..profile = const ProfileBackground(
        displayName: 'Avery Student',
        username: 'avery_student',
        headline: 'Community educator',
        bio: 'I create accessible learning programs.',
        contactEmail: 'avery@example.com',
      );
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(profileRepository: repository, profileUserId: 'user-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Profile details ready'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Profile details ready'), findsOneWidget);
    expect(find.text('Complete your profile'), findsNothing);
  });

  testWidgets('each supported contact method keeps the profile ready', (
    WidgetTester tester,
  ) async {
    const profiles = <ProfileBackground>[
      ProfileBackground(
        displayName: 'Avery',
        username: 'avery',
        headline: 'Community educator',
        bio: 'I create accessible learning programs.',
        contactEmail: 'avery@example.com',
      ),
      ProfileBackground(
        displayName: 'Avery',
        username: 'avery',
        headline: 'Community educator',
        bio: 'I create accessible learning programs.',
        phone: '+1 555 0100',
      ),
      ProfileBackground(
        displayName: 'Avery',
        username: 'avery',
        headline: 'Community educator',
        bio: 'I create accessible learning programs.',
        githubUrl: 'https://github.com/avery',
      ),
      ProfileBackground(
        displayName: 'Avery',
        username: 'avery',
        headline: 'Community educator',
        bio: 'I create accessible learning programs.',
        linkedInUrl: 'https://www.linkedin.com/in/avery',
      ),
      ProfileBackground(
        displayName: 'Avery',
        username: 'avery',
        headline: 'Community educator',
        bio: 'I create accessible learning programs.',
        upworkUrl: 'https://www.upwork.com/freelancers/~avery',
      ),
      ProfileBackground(
        displayName: 'Avery',
        username: 'avery',
        headline: 'Community educator',
        bio: 'I create accessible learning programs.',
        jobstreetUrl: 'https://www.jobstreet.com/profile/avery',
      ),
      ProfileBackground(
        displayName: 'Avery',
        username: 'avery',
        headline: 'Community educator',
        bio: 'I create accessible learning programs.',
        whatsAppNumber: '+15550100',
      ),
      ProfileBackground(
        displayName: 'Avery',
        username: 'avery',
        headline: 'Community educator',
        bio: 'I create accessible learning programs.',
        additionalLinks: [
          ProfileContactLink(label: 'Writing', url: 'https://example.com'),
        ],
      ),
    ];

    for (final profile in profiles) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileCompletionReminder(
              profile: profile,
              isLoading: false,
              hasError: false,
              onOpenProfile: () {},
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('Profile details ready'), findsOneWidget);
      expect(find.text('Complete your profile'), findsNothing);
    }
  });

  testWidgets('profile load failures are not shown as completed', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProfileRepository()..failProfileLoad = true;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(profileRepository: repository, profileUserId: 'user-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Profile details could not be checked'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Profile details could not be checked'), findsOneWidget);
    expect(find.text('Profile details ready'), findsNothing);
  });
}

class _FakeProfileRepository implements ProfileBackgroundRepository {
  ProfileBackground profile = const ProfileBackground(
    displayName: 'Avery Student',
    username: 'avery_student',
  );
  bool failProfileLoad = false;

  @override
  Future<ProfileBackground?> loadProfile(String userId) async {
    if (failProfileLoad) throw StateError('Profile request failed');
    return profile;
  }

  @override
  Future<void> saveBackground(
    String userId,
    ProfileBackground background,
  ) async {
    profile = background;
  }

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
  Future<String> createProfilePhotoSignedUrl(String path) =>
      throw UnimplementedError();

  @override
  Future<Uint8List> downloadProfilePhoto(String userId, String path) =>
      throw UnimplementedError();
}
