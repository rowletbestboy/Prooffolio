import 'package:app_name/features/portfolio/domain/resume_content.dart';
import 'package:app_name/features/portfolio/domain/resume_layout.dart';
import 'package:app_name/features/portfolio/presentation/resume_preview_screen.dart';
import 'package:app_name/core/theme/app_colors.dart';
import 'package:app_name/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'resume_test_fixtures.dart';

void main() {
  testWidgets('resume preview introduces the ATS option and PDF preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ResumePreviewScreen(
          content: ResumeContent.fromPortfolioContent(
            portfolioContentWithResumeData(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ATS-friendly'), findsOneWidget);
    expect(find.text('Review and refine your resume.'), findsOneWidget);
    expect(find.text('Your Resume'), findsOneWidget);
    expect(
      find.textContaining('Parsing varies by applicant tracking system'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('resumePdfPreview')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('readiness and primary actions reflect saved resume content', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ResumePreviewScreen(
          content: ResumeContent.fromPortfolioContent(
            portfolioContentWithResumeData(),
          ),
        ),
      ),
    );

    expect(find.text('Resume readiness'), findsOneWidget);
    expect(find.text('5 of 5 sections'), findsOneWidget);
    expect(find.text('Profile information complete'), findsOneWidget);
    expect(find.text('Skills and projects included'), findsOneWidget);
    expect(find.text('Education included'), findsOneWidget);
    expect(find.text('Experience included'), findsOneWidget);
    expect(find.text('Contact details added'), findsOneWidget);
    expect(find.text('Edit Resume'), findsOneWidget);
    expect(find.text('Export PDF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('zoom controls change the displayed PDF scale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ResumePreviewScreen(
          content: ResumeContent.fromPortfolioContent(
            portfolioContentWithResumeData(),
          ),
        ),
      ),
    );

    expect(find.text('100%'), findsOneWidget);
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();
    expect(find.text('110%'), findsOneWidget);
    await tester.tap(find.byTooltip('Zoom out'));
    await tester.pump();
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('Edit Resume returns to the previous portfolio screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => ResumePreviewScreen(
                    content: ResumeContent.fromPortfolioContent(
                      portfolioContentWithResumeData(),
                    ),
                  ),
                ),
              ),
              child: const Text('Portfolio preview'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Portfolio preview'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Resume'));
    await tester.pumpAndSettle();

    expect(find.text('Portfolio preview'), findsOneWidget);
    expect(find.byType(ResumePreviewScreen), findsNothing);
  });

  testWidgets('offers a visual resume and explicit photo selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(850, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ResumePreviewScreen(
          content: ResumeContent.fromPortfolioContent(
            portfolioContentWithResumeData(photoBytes: tinyPngBytes()),
          ),
        ),
      ),
    );

    expect(find.text('Photo resume'), findsOneWidget);
    expect(find.text('Export PDF'), findsOneWidget);
    expect(find.text('Include profile photo'), findsNothing);

    await tester.tap(find.text('Photo resume'));
    await tester.pumpAndSettle();
    expect(find.text('Include profile photo'), findsOneWidget);
    await tester.tap(find.text('Include profile photo'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('resumePdfPreview')), findsOneWidget);
    expect(ResumeLayout.visual.label, 'Photo resume');
    await tester.tap(find.byTooltip('Resume options'));
    await tester.pumpAndSettle();
    expect(find.text('Export DOCX'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resume unavailable notice uses shared error surface tokens', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ResumePreviewScreen(
          content: ResumeContent(
            displayName: '',
            headline: '',
            summary: '',
            contactDetails: [],
            sections: [],
            unavailableSections: ['Profile'],
            photoBytes: null,
          ),
        ),
      ),
    );

    final noticeText = find.textContaining(
      'Some saved information could not be loaded',
    );
    final notice = tester.widget<Material>(
      find.ancestor(of: noticeText, matching: find.byType(Material)).first,
    );

    expect(notice.color, AppColors.errorContainer);
    expect(notice.borderRadius, BorderRadius.circular(AppTheme.controlRadius));
    expect(find.text('0 of 5 sections'), findsOneWidget);
    expect(
      find.text('Profile information complete could not be loaded'),
      findsOneWidget,
    );
    expect(
      find.text('Contact details added could not be loaded'),
      findsOneWidget,
    );
    expect(find.text('Profile information missing'), findsNothing);
  });
}
