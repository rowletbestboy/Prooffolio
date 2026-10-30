import 'dart:typed_data';

import 'package:app_name/features/dashboard/presentation/home_shell.dart';
import 'package:app_name/features/profile/data/profile_repository.dart';
import 'package:app_name/features/profile/domain/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home keeps a long saved name readable on narrow phone widths', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          profileRepository: _ResponsiveProfileRepository(),
          profileUserId: 'user-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final metricCard = find.byType(Card).first;
    expect(tester.getSize(metricCard).width, greaterThan(220));
    expect(
      find.text('Avery With A Name That Is Much Longer Than The Header'),
      findsOneWidget,
    );
    expect(
      tester
          .getRect(
            find.text('Avery With A Name That Is Much Longer Than The Header'),
          )
          .right,
      lessThanOrEqualTo(
        tester
            .getRect(
              find.text('Real projects.\nReal skills.\nReal opportunities.'),
            )
            .left,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide Home uses side navigation instead of bottom navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(home: HomeShell()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _ResponsiveProfileRepository implements ProfileBackgroundRepository {
  @override
  Future<ProfileBackground?> loadProfile(String userId) async =>
      const ProfileBackground(
        displayName: 'Avery With A Name That Is Much Longer Than The Header',
        username: 'avery',
      );

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
  Future<String> createProfilePhotoSignedUrl(String path) =>
      throw UnimplementedError();

  @override
  Future<Uint8List> downloadProfilePhoto(String userId, String path) =>
      throw UnimplementedError();
}
