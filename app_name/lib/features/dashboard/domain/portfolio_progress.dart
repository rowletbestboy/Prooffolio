import '../../profile/domain/profile.dart';

class PortfolioProgress {
  const PortfolioProgress({required this.completedMilestones});

  static const _totalMilestones = 7;

  final int completedMilestones;

  int get totalMilestones => _totalMilestones;

  double get fraction => completedMilestones / totalMilestones;

  int get percentage => (fraction * 100).round();
}

PortfolioProgress? calculatePortfolioProgress({
  required ProfileBackground? profile,
  required int? projectCount,
  required int? skillCount,
  required int? certificationCount,
  required int? achievementCount,
  required int? evidenceCount,
}) {
  if (projectCount == null ||
      skillCount == null ||
      certificationCount == null ||
      achievementCount == null ||
      evidenceCount == null) {
    return null;
  }

  var completedMilestones = 0;
  if (profile?.displayName.trim().isNotEmpty == true) {
    completedMilestones++;
  }
  if (profile?.headline.trim().isNotEmpty == true) {
    completedMilestones++;
  }
  if (profile?.bio.trim().isNotEmpty == true) {
    completedMilestones++;
  }
  if (profileHasContactMethod(profile)) {
    completedMilestones++;
  }
  if (projectCount > 0) completedMilestones++;
  if (skillCount > 0) completedMilestones++;
  if (certificationCount > 0 || achievementCount > 0 || evidenceCount > 0) {
    completedMilestones++;
  }

  return PortfolioProgress(completedMilestones: completedMilestones);
}
