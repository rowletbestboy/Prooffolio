# Prooffolio Project Handoff

Updated: 2026-10-21

This note captures the current workspace state for the next Copilot session. Read this first, then check the linked design spec, implementation plans, and current `git status` before editing anything.

## Project and user goal

Prooffolio is a Flutter app backed by Supabase for building a career portfolio from projects, skills, credentials, achievements, and evidence. The user approved a professional, mobile-first UI inspired by the screenshots in the conversation: light cool-gray canvas, white rounded surfaces, blue-violet brand color, concise headings, and small work/learning themed icons.

Keep the existing account, data, and privacy behavior. The portfolio is private by default. Do not invent scores, ranks, or completion claims, and do not add public sharing or backend policy changes as part of the UI refresh.

## Completed features and work

- Supabase authentication is already present, including sign in/account creation, password recovery/new password, and setup guidance.
- Project, skill, profile, certification, and achievement flows already exist. The recent Profile and Skills work is still uncommitted in this shared checkout.
- The Evidence library feature has been added in the current workspace: Evidence model/repository/screen, storage and access setup docs, and the migration at `app_name/supabase/migrations/20261025100000_create_evidence.sql`.
- The user confirmed they already ran the Evidence migration in the Supabase SQL Editor. Do not ask them to run it again unless a later schema change requires a new migration.
- The approved professional UI refresh is implemented across shared theme, auth/recovery/setup, Home, projects, skills, profile, credentials/achievements, and Evidence screens.
- Home gets live counts from the existing project, skill, portfolio-record, and Evidence repositories. Each count can fail independently and renders an unavailable placeholder rather than made-up data. Tapping Achievements opens the records screen with Achievements selected.
- Shared `AppColors`/`AppTheme`, `AppBrandMark`, and `AppIconTile` provide the common visual language. A review finding also led to darkening the hero indigo for white text contrast and relabeling the Home navigation button “View projects” to match what it does.
- UI code review findings were addressed. The latest `dart analyze` passed with “No issues found!” and `git diff --check` was clean.
- A follow-up color and responsiveness pass adds semantic Teal accents for skills/Evidence and Amber for credentials/achievements/profile background, while preserving Indigo as the primary brand color. Page gutters now shrink on narrow viewports, Home metrics become a single column on narrow phones, and wide web layouts use a side NavigationRail instead of a bottom bar.
- Responsive fixes addressed a reproduced 320x700 Evidence empty-state overflow (76 dp) by making the empty state scrollable. Credentials and Evidence dialogs now use viewport-aware widths and scrollable content.
- Focused viewport/widget checks for Home, credentials, and Evidence passed: 14 test cases across three files, covering 320x700 phone layouts and 1024x768 wide Home navigation. The user explicitly approved running these focused tests.
- No tests were added or run. The approved UI plan says not to run/add tests unless the user asks to test or verify, and the developer instructions also prohibit running tests unless asked.

## Important implementation decisions

- Flutter and Material 3 remain the UI stack. No new font or icon package was introduced for the UI refresh.
- `AppColors` and `AppTheme` are the shared design token sources.
- Existing repository methods are used for Home metrics; no synthetic values are displayed.
- Existing routes, validators, repository APIs, and privacy model should remain intact.
- The Home primary action navigates to the Projects destination and is intentionally labeled “View projects”; it does not open the add form directly.
- Supabase URL/key are provided through `--dart-define` at runtime. Do not copy credentials into source code or this handoff. The user supplied a publishable key in the earlier conversation; avoid repeating it in logs or documentation.
- The Supabase Evidence schema setup is separate from code: the SQL migration was already applied by the user in the dashboard.

## Current verification and limitations

- Run static analysis from `app_name`: `dart analyze` — last run passed.
- `git diff --check` — last run passed.
- A Flutter Web debug build was attempted but remained at “Compiling lib/main.dart for the Web...” without returning; it was interrupted. This is inconclusive, not a confirmed build failure.
- A browser/device visual pass could not be completed because the CUA environment exposed no browser surface. Keyboard-open auth, large text, and tablet orientation remain to be checked when a preview environment is available.
- No claim should be made that the web build or visual acceptance has passed.

## Workspace state: preserve all existing work

The checkout is on `main` and has many modified and untracked files. It includes earlier Profile/Skills work, the Evidence feature, the UI refresh, dependency/lockfile changes, docs, and pre-existing tests. These changes are intentionally uncommitted. Do not reset, clean, revert, or overwrite the working tree to “start fresh.” Inspect `git status --short` and diffs before modifying files. Do not treat all dirty files as belonging only to the UI refresh.

Known relevant files:

- UI spec: `docs/superpowers/specs/2026-10-21-prooffolio-professional-ui-design.md`
- UI implementation plan and final checklist: `docs/superpowers/plans/2026-10-21-prooffolio-professional-ui-refresh.md`
- UI task ledger: `.superpowers/sdd/2026-10-21-prooffolio-professional-ui-refresh/progress.md`
- Evidence plan: `docs/superpowers/plans/2026-10-21-prooffolio-evidence-library.md`
- Evidence schema/setup docs: `docs/evidence-schema.md`, `docs/supabase-setup.md`
- Evidence migration: `app_name/supabase/migrations/20261025100000_create_evidence.sql`
- Shared theme: `app_name/lib/core/theme/app_colors.dart`, `app_name/lib/core/theme/app_theme.dart`
- Home: `app_name/lib/features/dashboard/presentation/home_shell.dart`
- Auth: `app_name/lib/features/auth/presentation/`
- Record/profile UI: `app_name/lib/features/projects/presentation/`, `app_name/lib/features/skills/presentation/`, `app_name/lib/features/portfolio/presentation/`, `app_name/lib/features/evidence/presentation/`, `app_name/lib/features/profile/presentation/`

## Recommended next steps

1. **Resume with a workspace review.** Read this handoff, the UI spec and plan, then inspect `git status --short` and relevant diffs. Preserve the uncommitted work described above.
2. **Finish visual acceptance.** When Flutter Web/device preview is available, launch the app from `app_name` with the user's actual Supabase dart-defines supplied privately. Check narrow and tall phone, keyboard-open auth, larger text, tablet portrait/landscape, Home counts, and empty/error states. Fix any clipping or contrast issues and rerun `dart analyze`.
3. **Resolve build uncertainty.** Reattempt `flutter build web --debug` (or the target the user intends to run) and capture the complete output. Run `flutter run` from `C:\Users\sergr\Desktop\Prooffolio\app_name`, the directory containing `pubspec.yaml`; invoking it from the parent `Prooffolio` folder caused “No pubspec.yaml file found.”
4. **Check the existing Supabase-backed flows.** Since the Evidence migration is already applied, verify sign-in and Evidence loading/upload in the intended Supabase project without re-running the same SQL. Confirm runtime defines point to the correct project and never commit secrets.
5. **Only run tests if the user asks for testing/verification.** There are existing Profile and Evidence tests in the tree; don't add/run tests without that authorization under the current task constraint.
6. **Report remaining issues and the exact verification performed.** Keep the UI plan's visual acceptance box open until an actual device/browser pass is completed. Do not commit or publish unless the user asks.

## Run command context

Open PowerShell in `C:\Users\sergr\Desktop\Prooffolio\app_name` (the Flutter project root) before running Flutter. Supply `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` with local/runtime `--dart-define` values. Never paste the actual key into this handoff or commit it.
