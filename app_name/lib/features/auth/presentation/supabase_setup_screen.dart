import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_brand_mark.dart';
import '../../../core/widgets/app_icon_tile.dart';

class SupabaseSetupScreen extends StatelessWidget {
  const SupabaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pageGutter = AppTheme.pageGutterFor(MediaQuery.sizeOf(context).width);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTheme.contentMaxWidth,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(pageGutter, 24, pageGutter, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppBrandMark(),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      border: Border.all(color: AppColors.lightSlate),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppIconTile(
                          icon: Icons.cloud_done_outlined,
                          color: AppColors.teal,
                          backgroundColor: AppColors.tealContainer,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Connect your Supabase project',
                          style: textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Create a project and add its URL and publishable key to your local Flutter run configuration. Your app will show sign-in here once it is connected.',
                          style: textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 22),
                        SelectableText(
                          'flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_YOUR_KEY',
                          style: textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Use only the publishable key in this Android app. Never put a secret or service-role key here.',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.indigoContainer,
                      borderRadius: BorderRadius.circular(
                        AppTheme.controlRadius,
                      ),
                    ),
                    child: Text(
                      'Full dashboard instructions: docs/supabase-setup.md',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.deepNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
