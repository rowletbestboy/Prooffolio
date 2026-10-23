import 'dart:typed_data';

import '../../evidence/data/evidence_repository.dart';
import '../../evidence/domain/evidence.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/profile.dart';
import '../../projects/data/project_repository.dart';
import '../../projects/domain/project.dart';
import '../../skills/data/skill_repository.dart';
import '../../skills/domain/skill.dart';
import '../domain/portfolio_content.dart';
import '../domain/portfolio_record.dart';
import 'portfolio_record_repository.dart';

class PortfolioContentRepository {
  const PortfolioContentRepository({
    required this._profileRepository,
    required this._projectRepository,
    required this._skillRepository,
    required this._portfolioRecordRepository,
    required this._evidenceRepository,
  });

  final ProfileBackgroundRepository _profileRepository;
  final ProjectRepository _projectRepository;
  final SkillRepository _skillRepository;
  final PortfolioRecordRepository _portfolioRecordRepository;
  final EvidenceRepository _evidenceRepository;

  Future<PortfolioContent> loadPrivateContent(String userId) async {
    final profileFuture = _loadSource<ProfileBackground?, PortfolioProfile?>(
      () => _profileRepository.loadProfile(userId),
      (profile) => profile == null
          ? null
          : PortfolioProfile.fromProfileBackground(profile),
    );
    final projectsFuture = _loadSource<List<Project>, List<PortfolioProject>>(
      _projectRepository.listProjects,
      (projects) => projects.map(PortfolioProject.fromProject).toList(),
    );
    final skillsFuture = _loadSource<List<Skill>, List<PortfolioSkill>>(
      _skillRepository.listSkills,
      (skills) => skills.map(PortfolioSkill.fromSkill).toList(),
    );
    final educationFuture =
        _loadSource<List<EducationRecord>, List<PortfolioEducation>>(
          () => _profileRepository.listEducation(userId),
          (records) => records.map(PortfolioEducation.fromRecord).toList(),
        );
    final experienceFuture =
        _loadSource<List<ExperienceRecord>, List<PortfolioExperience>>(
          () => _profileRepository.listExperience(userId),
          (records) => records.map(PortfolioExperience.fromRecord).toList(),
        );
    final certificationsFuture =
        _loadSource<List<PortfolioRecord>, List<PortfolioRecordContent>>(
          () => _portfolioRecordRepository.listRecords(
            PortfolioRecordType.certification,
          ),
          (records) => records.map(PortfolioRecordContent.fromRecord).toList(),
        );
    final achievementsFuture =
        _loadSource<List<PortfolioRecord>, List<PortfolioRecordContent>>(
          () => _portfolioRecordRepository.listRecords(
            PortfolioRecordType.achievement,
          ),
          (records) => records.map(PortfolioRecordContent.fromRecord).toList(),
        );
    final evidenceFuture =
        _loadSource<List<EvidenceRecord>, List<PortfolioEvidence>>(
          _evidenceRepository.listEvidence,
          (records) => records.map(PortfolioEvidence.fromEvidence).toList(),
        );

    final profile = await profileFuture;
    final photoUrlFuture = _loadSource<String?, String?>(() async {
      final photoPath = profile.value?.photoPath;
      if (photoPath == null || photoPath.isEmpty) return null;
      return _profileRepository.createProfilePhotoSignedUrl(photoPath);
    }, (url) => url);
    final photoBytesFuture = _loadSource<Uint8List?, Uint8List?>(() async {
      final photoPath = profile.value?.photoPath;
      if (photoPath == null || photoPath.isEmpty) return null;
      return _profileRepository.downloadProfilePhoto(userId, photoPath);
    }, (bytes) => bytes);

    return PortfolioContent(
      profile: profile,
      photoUrl: await photoUrlFuture,
      photoBytes: await photoBytesFuture,
      projects: await projectsFuture,
      skills: await skillsFuture,
      education: await educationFuture,
      experience: await experienceFuture,
      certifications: await certificationsFuture,
      achievements: await achievementsFuture,
      evidence: await evidenceFuture,
    );
  }

  Future<PortfolioSource<R>> _loadSource<T, R>(
    Future<T> Function() load,
    R Function(T value) map,
  ) async {
    try {
      return PortfolioSource<R>.available(map(await load()));
    } catch (error) {
      return PortfolioSource<R>.unavailable(error);
    }
  }
}
