import 'package:app_name/features/portfolio/domain/portfolio_content.dart';
import 'package:app_name/features/portfolio/presentation/portfolio_site_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'resume_test_fixtures.dart';

void main() {
  const content = PortfolioContent(
    profile: PortfolioSource.available(
      PortfolioProfile(
        displayName: 'Alex & Co',
        username: 'alex',
        headline: 'Community educator',
        bio: 'A short introduction.',
        occupationTitle: 'Educator',
        photoPath: null,
        contactEmail: 'alex@example.test',
        phone: '',
        githubUrl: '',
        linkedInUrl: '',
        jobstreetUrl: '',
        whatsAppNumber: '',
        additionalLinks: [],
      ),
    ),
    photoUrl: PortfolioSource.available(null),
    projects: PortfolioSource.available([]),
    skills: PortfolioSource.available([]),
    education: PortfolioSource.available([]),
    experience: PortfolioSource.available([]),
    certifications: PortfolioSource.available([]),
    achievements: PortfolioSource.available([]),
    evidence: PortfolioSource.available([]),
  );

  testWidgets(
    'selection starts private and template changes regenerate the live page',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 5000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: PortfolioSitePreview(
            content: content,
            previewBuilder: (context, html) =>
                SelectableText(html, key: const ValueKey('generated-preview')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<SelectableText>(
              find.byKey(const ValueKey('generated-preview')),
            )
            .data,
        contains('Alex &amp; Co'),
      );
      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile).first)
            .value,
        isTrue,
      );

      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();
      var generatedHtml = tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('generated-preview')),
          )
          .data!;
      expect(generatedHtml, isNot(contains('Alex &amp; Co')));

      await tester.ensureVisible(find.text('Dark'));
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      generatedHtml = tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('generated-preview')),
          )
          .data!;
      expect(generatedHtml, contains('--page-background: #111827'));
    },
  );

  testWidgets('preselects saved work without exposing private Evidence', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: PortfolioSitePreview(
          content: portfolioContentWithResumeData(),
          previewBuilder: (context, html) =>
              SelectableText(html, key: const ValueKey('generated-preview')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    var generatedHtml = tester
        .widget<SelectableText>(find.byKey(const ValueKey('generated-preview')))
        .data!;
    expect(generatedHtml, contains('Alex Rivera'));
    expect(generatedHtml, contains('alex@example.com'));
    expect(generatedHtml, contains('Community Exchange'));
    expect(generatedHtml, contains('Product design'));
    expect(generatedHtml, contains('Bachelor of Design'));
    expect(generatedHtml, contains('Studio One'));
    expect(generatedHtml, contains('Accessibility Foundations'));
    expect(generatedHtml, contains('Community Design Award'));
    expect(generatedHtml, isNot(contains('Private proof file')));
    expect(generatedHtml, isNot(contains('private-project-id')));
    expect(generatedHtml, isNot(contains('private-evidence-id')));
    expect(
      tester
          .widget<CheckboxListTile>(
            find.widgetWithText(CheckboxListTile, 'Community Exchange'),
          )
          .value,
      isTrue,
    );

    await tester.tap(
      find.widgetWithText(CheckboxListTile, 'Community Exchange'),
    );
    await tester.pumpAndSettle();
    generatedHtml = tester
        .widget<SelectableText>(find.byKey(const ValueKey('generated-preview')))
        .data!;
    expect(generatedHtml, isNot(contains('A neighborhood resource exchange.')));
  });
}
