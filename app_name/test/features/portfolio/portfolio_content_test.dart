import 'package:app_name/features/portfolio/domain/portfolio_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('readiness explains saved coverage without assigning a score', () {
    const content = PortfolioContent(
      profile: PortfolioSource.available(
        PortfolioProfile(
          displayName: 'Alex',
          username: 'alex',
          headline: 'Community educator',
          bio: '',
          occupationTitle: '',
          photoPath: null,
          contactEmail: '',
          phone: '',
          githubUrl: '',
          linkedInUrl: '',
          jobstreetUrl: '',
          whatsAppNumber: '',
          additionalLinks: [],
        ),
      ),
      photoUrl: PortfolioSource.available(null),
      projects: PortfolioSource.available([
        PortfolioProject(
          id: 'private-project-id',
          title: 'Garden',
          summary: 'A community garden',
          description: '',
          contribution: '',
          technologies: [],
          statusLabel: 'Completed',
          startDate: null,
          endDate: null,
        ),
      ]),
      skills: PortfolioSource.available([]),
      education: PortfolioSource.available([]),
      experience: PortfolioSource.available([]),
      certifications: PortfolioSource.available([]),
      achievements: PortfolioSource.available([]),
      evidence: PortfolioSource.available([]),
    );

    final suggestions = PortfolioReadiness.evaluate(content);

    expect(suggestions, hasLength(5));
    expect(
      suggestions
          .singleWhere((item) => item.label == 'Profile basics')
          .isCovered,
      isTrue,
    );
    expect(
      suggestions
          .singleWhere((item) => item.label == 'Project detail')
          .isCovered,
      isTrue,
    );
    expect(
      suggestions.singleWhere((item) => item.label == 'Skills').explanation,
      contains('self-reported'),
    );
    expect(suggestions.every((item) => item.explanation.isNotEmpty), isTrue);
    expect(
      suggestions.any((item) => item.label.toLowerCase().contains('score')),
      isFalse,
    );
  });

  test('unavailable source is described instead of treated as empty', () {
    final content = PortfolioContent(
      profile: const PortfolioSource.available(null),
      photoUrl: const PortfolioSource.available(null),
      projects: PortfolioSource.unavailable(Exception('offline')),
      skills: const PortfolioSource.available([]),
      education: const PortfolioSource.available([]),
      experience: const PortfolioSource.available([]),
      certifications: const PortfolioSource.available([]),
      achievements: const PortfolioSource.available([]),
      evidence: const PortfolioSource.available([]),
    );

    final projectSuggestion = PortfolioReadiness.evaluate(
      content,
    ).singleWhere((item) => item.label == 'Project detail');

    expect(projectSuggestion.isCovered, isFalse);
    expect(projectSuggestion.explanation, contains('could not be loaded'));
  });
}
