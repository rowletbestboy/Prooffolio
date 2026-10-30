import 'package:app_name/features/portfolio/domain/resume_content.dart';
import 'package:app_name/features/portfolio/domain/resume_layout.dart';
import 'package:app_name/features/portfolio/presentation/resume_preview_screen.dart';
import 'package:app_name/core/theme/app_colors.dart';
import 'package:app_name/core/theme/app_theme.dart';
import 'package:app_name/core/widgets/app_brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'resume_test_fixtures.dart';

void main() {
  testWidgets('labels the text-first resume ATS-friendly without a guarantee', (
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

    expect(find.text('ATS-friendly format'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(AppBrandMark),
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Parsing varies by applicant tracking system'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('resumePdfPreview')), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    expect(find.text('Download PDF'), findsOneWidget);
    expect(find.text('Download DOCX'), findsOneWidget);
    expect(find.text('Include profile photo'), findsNothing);

    await tester.tap(find.text('Photo resume'));
    await tester.pumpAndSettle();
    expect(find.text('Include profile photo'), findsOneWidget);
    await tester.tap(find.text('Include profile photo'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('resumePdfPreview')), findsOneWidget);
    expect(ResumeLayout.visual.label, 'Photo resume');
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
  });
}
