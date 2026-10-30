import 'package:app_name/features/dashboard/domain/portfolio_progress.dart';
import 'package:app_name/features/profile/domain/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an absent profile and empty categories produce zero of seven', () {
    final progress = calculatePortfolioProgress(
      profile: null,
      projectCount: 0,
      skillCount: 0,
      certificationCount: 0,
      achievementCount: 0,
      evidenceCount: 0,
    );

    expect(progress?.completedMilestones, 0);
    expect(progress?.totalMilestones, 7);
    expect(progress?.fraction, 0);
    expect(progress?.percentage, 0);
  });

  test('three profile milestones round to 43 percent', () {
    final progress = calculatePortfolioProgress(
      profile: const ProfileBackground(
        displayName: 'Avery',
        username: 'avery',
        headline: 'Community educator',
        bio: 'I create accessible learning programs.',
      ),
      projectCount: 0,
      skillCount: 0,
      certificationCount: 0,
      achievementCount: 0,
      evidenceCount: 0,
    );

    expect(progress?.completedMilestones, 3);
    expect(progress?.totalMilestones, 7);
    expect(progress?.fraction, 3 / 7);
    expect(progress?.percentage, 43);
  });

  test('all seven foundational milestones produce 100 percent', () {
    final progress = calculatePortfolioProgress(
      profile: _completeProfile(),
      projectCount: 1,
      skillCount: 1,
      certificationCount: 1,
      achievementCount: 0,
      evidenceCount: 0,
    );

    expect(progress?.completedMilestones, 7);
    expect(progress?.totalMilestones, 7);
    expect(progress?.fraction, 1);
    expect(progress?.percentage, 100);
  });

  test('whitespace-only profile values do not satisfy profile milestones', () {
    final progress = calculatePortfolioProgress(
      profile: const ProfileBackground(
        displayName: ' ',
        username: 'avery',
        headline: '  ',
        bio: '\t',
        contactEmail: ' ',
        phone: '',
      ),
      projectCount: 0,
      skillCount: 0,
      certificationCount: 0,
      achievementCount: 0,
      evidenceCount: 0,
    );

    expect(progress?.completedMilestones, 0);
    expect(progress?.percentage, 0);
  });

  test('a profile photo does not count as a milestone', () {
    final progress = calculatePortfolioProgress(
      profile: const ProfileBackground(
        displayName: '',
        username: 'avery',
        photoPath: 'user-1/portrait.webp',
      ),
      projectCount: 0,
      skillCount: 0,
      certificationCount: 0,
      achievementCount: 0,
      evidenceCount: 0,
    );

    expect(progress?.completedMilestones, 0);
    expect(progress?.percentage, 0);
  });

  test('each kind of proof record satisfies the single proof milestone', () {
    final certification = calculatePortfolioProgress(
      profile: _completeProfile(),
      projectCount: 1,
      skillCount: 1,
      certificationCount: 1,
      achievementCount: 0,
      evidenceCount: 0,
    );
    final achievement = calculatePortfolioProgress(
      profile: _completeProfile(),
      projectCount: 1,
      skillCount: 1,
      certificationCount: 0,
      achievementCount: 1,
      evidenceCount: 0,
    );
    final evidence = calculatePortfolioProgress(
      profile: _completeProfile(),
      projectCount: 1,
      skillCount: 1,
      certificationCount: 0,
      achievementCount: 0,
      evidenceCount: 1,
    );

    expect(certification?.completedMilestones, 7);
    expect(achievement?.completedMilestones, 7);
    expect(evidence?.completedMilestones, 7);
  });

  test('any unavailable category count makes progress unavailable', () {
    final progressResults = [
      calculatePortfolioProgress(
        profile: _completeProfile(),
        projectCount: null,
        skillCount: 1,
        certificationCount: 1,
        achievementCount: 1,
        evidenceCount: 1,
      ),
      calculatePortfolioProgress(
        profile: _completeProfile(),
        projectCount: 1,
        skillCount: null,
        certificationCount: 1,
        achievementCount: 1,
        evidenceCount: 1,
      ),
      calculatePortfolioProgress(
        profile: _completeProfile(),
        projectCount: 1,
        skillCount: 1,
        certificationCount: null,
        achievementCount: 1,
        evidenceCount: 1,
      ),
      calculatePortfolioProgress(
        profile: _completeProfile(),
        projectCount: 1,
        skillCount: 1,
        certificationCount: 1,
        achievementCount: null,
        evidenceCount: 1,
      ),
      calculatePortfolioProgress(
        profile: _completeProfile(),
        projectCount: 1,
        skillCount: 1,
        certificationCount: 1,
        achievementCount: 1,
        evidenceCount: null,
      ),
    ];

    expect(progressResults, everyElement(isNull));
  });
}

ProfileBackground _completeProfile() => const ProfileBackground(
  displayName: 'Avery',
  username: 'avery',
  headline: 'Community educator',
  bio: 'I create accessible learning programs.',
  contactEmail: 'avery@example.com',
);
