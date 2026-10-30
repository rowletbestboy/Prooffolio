import 'package:app_name/features/portfolio/domain/portfolio_content.dart';
import 'package:app_name/features/portfolio/data/portfolio_site_generator.dart';
import 'package:app_name/features/portfolio/domain/portfolio_template.dart';
import 'package:app_name/features/portfolio/presentation/portfolio_site_preview.dart';
import 'package:app_name/core/widgets/app_brand_mark.dart';
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
    'shows the portfolio preview dashboard and keeps content choices editable',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(
        () => PortfolioSiteGenerator.generate(
          content,
          PortfolioSelection.allFrom(content),
          PortfolioTemplate.light,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: PortfolioSitePreview(
            content: content,
            previewBuilder: (context, html) =>
                const SizedBox(key: ValueKey('portfolio-site-preview-surface')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _pumpPortfolioGeneration(tester);

      expect(find.text('Your Portfolio'), findsOneWidget);
      expect(find.text('Live preview'), findsOneWidget);
      expect(find.text('Portfolio readiness'), findsOneWidget);
      expect(find.text('Website'), findsOneWidget);
      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Edit Portfolio'), findsOneWidget);
      expect(find.text('Download Website'), findsOneWidget);
      expect(find.widgetWithText(CheckboxListTile, 'Email'), findsNothing);

      await tester.tap(find.text('Edit Portfolio'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(CheckboxListTile, 'Email'), findsOneWidget);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Email'),
            )
            .value,
        isTrue,
      );
    },
  );

  testWidgets(
    'selection starts private and generated page provides its own theme toggle',
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
      await _pumpPortfolioGeneration(tester);

      expect(
        tester
            .widget<SelectableText>(
              find.byKey(const ValueKey('generated-preview')),
            )
            .data,
        contains('Alex &amp; Co'),
      );
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(AppBrandMark),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Edit Portfolio'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile).first)
            .value,
        isTrue,
      );

      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();
      await _pumpPortfolioGeneration(tester);
      var generatedHtml = tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('generated-preview')),
          )
          .data!;
      expect(generatedHtml, isNot(contains('Alex &amp; Co')));

      generatedHtml = tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('generated-preview')),
          )
          .data!;
      expect(generatedHtml, contains('id="theme-btn"'));
      expect(generatedHtml, contains(':root[data-theme="dark"]'));
      expect(find.byType(SegmentedButton), findsNothing);
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
    await _pumpPortfolioGeneration(tester);

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
    await tester.tap(find.text('Edit Portfolio'));
    await tester.pumpAndSettle();
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
    await _pumpPortfolioGeneration(tester);
    generatedHtml = tester
        .widget<SelectableText>(find.byKey(const ValueKey('generated-preview')))
        .data!;
    expect(generatedHtml, isNot(contains('A neighborhood resource exchange.')));
  });
}

Future<void> _pumpPortfolioGeneration(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}
