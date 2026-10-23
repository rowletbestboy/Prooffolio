import 'package:app_name/features/portfolio/domain/portfolio_content.dart';
import 'package:app_name/features/portfolio/domain/portfolio_template.dart';
import 'package:flutter_test/flutter_test.dart';

import 'resume_test_fixtures.dart';

void main() {
  test('selects every non-empty saved profile field and portfolio record', () {
    final selection = PortfolioSelection.allFrom(
      portfolioContentWithResumeData(
        photoBytes: tinyPngBytes(),
        photoPath: 'profile-id/photo.png',
      ),
    );

    expect(selection.includeDisplayName, isTrue);
    expect(selection.includeHeadline, isTrue);
    expect(selection.includeOccupationTitle, isTrue);
    expect(selection.includeBio, isTrue);
    expect(selection.includePhoto, isTrue);
    expect(selection.includeEmail, isTrue);
    expect(selection.includePhone, isTrue);
    expect(selection.includeGithub, isTrue);
    expect(selection.includeLinkedIn, isTrue);
    expect(selection.includeUpwork, isTrue);
    expect(selection.includeJobstreet, isFalse);
    expect(selection.includeWhatsApp, isFalse);
    expect(selection.includeAdditionalLinks, isFalse);
    expect(selection.projectIds, {'private-project-id'});
    expect(selection.skillIds, {'private-skill-id'});
    expect(selection.educationIds, {'private-education-id'});
    expect(selection.experienceIds, {'older-role', 'newer-role'});
    expect(selection.certificationIds, {'private-certification-id'});
    expect(selection.achievementIds, {'private-achievement-id'});
  });

  test('does not select empty fields or unavailable data sources', () {
    final emptySelection = PortfolioSelection.allFrom(emptyPortfolioContent());
    final unavailableSelection = PortfolioSelection.allFrom(
      _contentWithUnavailableProjects(),
    );

    for (final selection in [emptySelection, unavailableSelection]) {
      expect(selection.includeDisplayName, isFalse);
      expect(selection.includeHeadline, isFalse);
      expect(selection.includeOccupationTitle, isFalse);
      expect(selection.includeBio, isFalse);
      expect(selection.includePhoto, isFalse);
      expect(selection.includeEmail, isFalse);
      expect(selection.includePhone, isFalse);
      expect(selection.includeGithub, isFalse);
      expect(selection.includeLinkedIn, isFalse);
      expect(selection.includeUpwork, isFalse);
      expect(selection.includeJobstreet, isFalse);
      expect(selection.includeWhatsApp, isFalse);
      expect(selection.includeAdditionalLinks, isFalse);
      expect(selection.projectIds, isEmpty);
      expect(selection.skillIds, isEmpty);
      expect(selection.educationIds, isEmpty);
      expect(selection.experienceIds, isEmpty);
      expect(selection.certificationIds, isEmpty);
      expect(selection.achievementIds, isEmpty);
    }
  });

  test('does not select a photo when no downloadable photo bytes exist', () {
    final selection = PortfolioSelection.allFrom(
      portfolioContentWithResumeData(),
    );

    expect(selection.includePhoto, isFalse);
  });

  test(
    'does not select photo bytes when the profile has no saved photo path',
    () {
      final selection = PortfolioSelection.allFrom(
        portfolioContentWithResumeData(photoBytes: tinyPngBytes()),
      );

      expect(selection.includePhoto, isFalse);
    },
  );
}

PortfolioContent _contentWithUnavailableProjects() => PortfolioContent(
  profile: const PortfolioSource.unavailable('profile unavailable'),
  photoUrl: const PortfolioSource.available(null),
  projects: PortfolioSource.unavailable(Exception('projects unavailable')),
  skills: const PortfolioSource.available([]),
  education: const PortfolioSource.available([]),
  experience: const PortfolioSource.available([]),
  certifications: const PortfolioSource.available([]),
  achievements: const PortfolioSource.available([]),
  evidence: const PortfolioSource.available([]),
);
