abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const portfolioPublicBaseUrl = String.fromEnvironment(
    'PORTFOLIO_PUBLIC_BASE_URL',
  );

  static bool get isConfigured =>
      url.startsWith('https://') &&
      publishableKey.startsWith('sb_publishable_');
}
