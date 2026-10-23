import 'dart:typed_data';

import 'package:app_name/features/portfolio/domain/portfolio_content.dart';
import 'package:image/image.dart' as image;

Uint8List tinyPngBytes() {
  final pixel = image.Image(width: 1, height: 1);
  return Uint8List.fromList(image.encodePng(pixel));
}

PortfolioContent portfolioContentWithResumeData({
  Uint8List? photoBytes,
  String? photoPath,
}) => PortfolioContent(
  profile: PortfolioSource.available(
    PortfolioProfile(
      displayName: 'Alex Rivera',
      username: 'alex',
      headline: 'Product designer',
      bio: 'Designs accessible tools for local communities.',
      occupationTitle: 'Product designer',
      photoPath: photoPath,
      contactEmail: 'alex@example.com',
      phone: '+1 555 0100',
      githubUrl: 'https://github.com/alex',
      linkedInUrl: 'https://linkedin.com/in/alex',
      upworkUrl: 'https://www.upwork.com/freelancers/~alex',
      jobstreetUrl: '',
      whatsAppNumber: '',
      additionalLinks: [],
    ),
  ),
  photoUrl: const PortfolioSource.available(null),
  photoBytes: PortfolioSource.available(photoBytes),
  projects: PortfolioSource.available([
    PortfolioProject(
      id: 'private-project-id',
      title: 'Community Exchange',
      summary: 'A neighborhood resource exchange.',
      description: 'Built a searchable catalog.',
      contribution: 'Designed the interaction model.',
      technologies: const ['Flutter'],
      statusLabel: 'Completed',
      startDate: DateTime(2023, 1),
      endDate: DateTime(2023, 8),
    ),
  ]),
  skills: const PortfolioSource.available([
    PortfolioSkill(
      id: 'private-skill-id',
      name: 'Product design',
      category: 'Design',
      status: 'Practiced',
      projectTitles: ['Community Exchange'],
    ),
  ]),
  education: PortfolioSource.available([
    PortfolioEducation(
      id: 'private-education-id',
      title: 'Bachelor of Design',
      institution: 'North College',
      level: 'Undergraduate',
      status: 'Completed',
      startDate: DateTime(2015),
      endDate: DateTime(2019),
      description: '',
    ),
  ]),
  experience: PortfolioSource.available([
    PortfolioExperience(
      id: 'older-role',
      title: 'Visual designer',
      organization: 'Studio One',
      type: 'Employment',
      startDate: DateTime(2019),
      endDate: DateTime(2022),
      isCurrent: false,
      description: 'Created product illustrations.',
    ),
    PortfolioExperience(
      id: 'newer-role',
      title: 'Product designer',
      organization: 'Studio Two',
      type: 'Employment',
      startDate: DateTime(2023),
      endDate: null,
      isCurrent: true,
      description: 'Led design for a community platform.',
    ),
  ]),
  certifications: PortfolioSource.available([
    PortfolioRecordContent(
      id: 'private-certification-id',
      title: 'Accessibility Foundations',
      source: 'Design Institute',
      description: 'Practical accessibility',
      achievedOn: DateTime(2024),
      expiresOn: null,
    ),
  ]),
  achievements: PortfolioSource.available([
    PortfolioRecordContent(
      id: 'private-achievement-id',
      title: 'Community Design Award',
      source: 'Local Design Week',
      description: 'Recognized for community work.',
      achievedOn: DateTime(2022),
      expiresOn: null,
    ),
  ]),
  evidence: const PortfolioSource.available([
    PortfolioEvidence(
      id: 'private-evidence-id',
      title: 'Private proof file',
      description: 'private/bucket/object.png',
      kind: 'File',
      targetTitles: [],
    ),
  ]),
);

PortfolioContent emptyPortfolioContent() => PortfolioContent(
  profile: const PortfolioSource.available(
    PortfolioProfile(
      displayName: '',
      username: '',
      headline: '',
      bio: '',
      occupationTitle: '',
      photoPath: null,
      contactEmail: '',
      phone: '',
      githubUrl: '',
      linkedInUrl: '',
      upworkUrl: '',
      jobstreetUrl: '',
      whatsAppNumber: '',
      additionalLinks: [],
    ),
  ),
  photoUrl: const PortfolioSource.available(null),
  projects: const PortfolioSource.available([]),
  skills: const PortfolioSource.available([]),
  education: const PortfolioSource.available([]),
  experience: const PortfolioSource.available([]),
  certifications: const PortfolioSource.available([]),
  achievements: const PortfolioSource.available([]),
  evidence: const PortfolioSource.available([]),
);
