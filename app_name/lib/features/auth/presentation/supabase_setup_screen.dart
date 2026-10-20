import 'package:flutter/material.dart';

class SupabaseSetupScreen extends StatelessWidget {
  const SupabaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prooffolio', style: textTheme.titleLarge),
                  const SizedBox(height: 40),
                  Text(
                    'Connect your Supabase project',
                    style: textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Create a project and add its URL and publishable key to your local Flutter run configuration. Your app will show sign-in here once it is connected.',
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: SelectableText(
                      'flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_YOUR_KEY',
                      style: textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Use only the publishable key in this Android app. Never put a secret or service-role key here.',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Full dashboard instructions: docs/supabase-setup.md',
                    style: textTheme.labelLarge,
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
