import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/auth/presentation/supabase_setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  }
  runApp(const ProoffolioApp());
}

class ProoffolioApp extends StatelessWidget {
  const ProoffolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prooffolio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: SupabaseConfig.isConfigured
          ? AuthGate(client: Supabase.instance.client)
          : const SupabaseSetupScreen(),
    );
  }
}
