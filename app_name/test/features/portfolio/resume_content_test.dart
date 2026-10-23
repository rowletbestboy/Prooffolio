import 'package:app_name/features/portfolio/domain/resume_content.dart';
import 'package:flutter_test/flutter_test.dart';

import 'resume_test_fixtures.dart';

void main() {
  test('maps saved sections and sorts dated experience newest first', () {
    final resume = ResumeContent.fromPortfolioContent(
      portfolioContentWithResumeData(),
    );

    expect(resume.displayName, 'Alex Rivera');
    expect(
      resume.contactDetails.map((detail) => detail.value),
      containsAll([
        'alex@example.com',
        '+1 555 0100',
        'https://github.com/alex',
        'https://linkedin.com/in/alex',
        'https://www.upwork.com/freelancers/~alex',
      ]),
    );
    expect(resume.summary, 'Designs accessible tools for local communities.');
    expect(resume.sections.map((section) => section.heading), [
      'Experience',
      'Education',
      'Skills',
      'Projects',
      'Certifications',
      'Achievements',
    ]);
    expect(resume.sections.first.entries.map((entry) => entry.title), [
      'Product designer',
      'Visual designer',
    ]);
    expect(resume.sections.first.entries.first.dateRange, contains('Present'));
    expect(
      resume.sections
          .expand((section) => section.entries)
          .map((entry) => '${entry.title} ${entry.description}')
          .join(' '),
      isNot(contains('Private proof file')),
    );
    expect(
      resume.sections
          .expand((section) => section.entries)
          .map((entry) => '${entry.title} ${entry.description}')
          .join(' '),
      isNot(contains('private/bucket/object.png')),
    );
  });

  test('omits blank optional sections and does not invent content', () {
    final resume = ResumeContent.fromPortfolioContent(emptyPortfolioContent());

    expect(resume.displayName, isEmpty);
    expect(resume.summary, isEmpty);
    expect(resume.contactDetails, isEmpty);
    expect(resume.sections, isEmpty);
  });
}
