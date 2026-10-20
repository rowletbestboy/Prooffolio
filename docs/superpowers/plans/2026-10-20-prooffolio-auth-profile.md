# Prooffolio Authentication and Profile Setup Plan

> **For agentic workers:** Use this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Add a configured Supabase authentication entry flow and first profile setup screen, with clear setup instructions and safe client-key handling.

**Architecture:** Initialize Supabase only when both public client values are provided at build time. Route unauthenticated users to a sign-in/create-account flow, authenticated new users to profile setup, and returning users to the existing HomeShell. Keep account and profile persistence behind Supabase Auth and a `profiles` row; do not place secret keys in Flutter.

**Tech Stack:** Existing Flutter/Dart scaffold, `supabase_flutter`, `flutter_test`, Supabase Auth/Postgres.

**Spec:** `docs/superpowers/specs/2026-10-20-prooffolio-project-blueprint.md`

## Global Constraints

- Preserve existing Material 3 theme, navigation, package identity, and scaffold.
- Use the Supabase publishable key in the mobile client; never include a secret/service-role key.
- Keep user-generated career claims self-reported and editable; do not fabricate profile data.
- Do not add database access until RLS and schema are provided in versioned SQL.

## Review Focus

- Missing Supabase build values show actionable setup guidance and never crash startup.
- Invalid email, short password, and mismatched confirmation receive inline feedback.
- Sign-up with email confirmation enabled explains that the user must confirm their inbox.
- Profile setup requires a display name and username and handles username conflicts.
- Returning authenticated users reach HomeShell; sign-out clears the session.

---

### Task 1: Supabase project setup guide and safe configuration

**Files:** Create `docs/supabase-setup.md`; create `app_name/lib/core/config/supabase_config.dart`; modify `app_name/pubspec.yaml`, `app_name/lib/main.dart`; test configuration and missing-key screen.

- [x] Write a failing widget test for the missing-configuration setup screen.
- [x] Add the setup guide with dashboard steps, email auth settings, Android redirect URL, build command, and key safety rules.
- [x] Add Supabase Flutter and environment configuration; only initialize when URL and publishable key are non-empty.
- [x] Verify format, analyzer, and Flutter tests.

### Task 2: Sign-in and account creation

**Files:** Create `app_name/lib/features/auth/presentation/auth_screen.dart`; modify app routing/bootstrap and tests.

- [x] Add tests for form validation and sign-in/create-account mode switching.
- [x] Implement email/password sign-in and sign-up with useful Supabase error messages and confirmation guidance.
- [x] Route based on Supabase session state without changing HomeShell behavior.
- [x] Verify format, analyzer, and Flutter tests.

### Task 3: First profile setup and session controls

**Files:** Create profile model/repository and profile setup screen plus SQL migration under `app_name/supabase/migrations/`; add tests.

- [x] Define `profiles` schema and owner-only RLS policies in a migration.
- [x] Add tests for required profile fields and password recovery validation.
- [x] Persist display name/username and route to HomeShell after success; sign-out is available from the shell.
- [x] Verify format, analyzer, and Flutter tests.

**External setup still required:** Create a Supabase project, apply `app_name/supabase/migrations/20261020170000_create_profiles.sql`, add the URL and publishable key to a local run configuration, and register the documented mobile redirect. A live backend smoke test must wait until those project-specific values and dashboard settings exist.
