# Prooffolio Professional UI Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the approved professional blue-violet visual direction across sign-in, Home, and existing app screens without changing current workflows or privacy behavior.

**Architecture:** Keep Material 3 and centralize palette, typography, component shapes, and spacing in `AppColors`/`AppTheme`. Add small shared presentation widgets where they reduce repetition. Make Home progress counts an isolated view that consumes the existing repositories and degrades to neutral values when one source cannot load.

**Tech Stack:** Flutter, Dart, Material 3, existing Supabase repositories and models.

**Spec:** `docs/superpowers/specs/2026-10-21-prooffolio-professional-ui-design.md`

## Global Constraints

- Keep all existing routes, validation, repository calls, and form actions working.
- Use a very light cool gray canvas, white surfaces, the existing Indigo brand, a consistent radius scale, system sans-serif, and outlined Material icons.
- No new authentication providers, OTP screens, avatar upload, social login, publication, sharing, or public portfolio access.
- No new backend tables or changes to Supabase access policies.
- No decorative charts, scores, ranks, or unsupported completion claims.
- Use existing repositories and models for Home counts; unavailable sources render a neutral state without fabricated data.
- Keep 48 dp touch targets, safe areas, readable contrast, loading/error/disabled/pressed states, and adaptive layouts.
- Do not add or run tests unless the user asks to test or verify the implementation.

## Review Focus

- Small phone with the keyboard open: auth actions and inline errors remain reachable by scrolling without clipping.
- Large text scale: record titles, helper copy, and navigation labels remain legible and do not overflow horizontally.
- Partial Home data failure: one unavailable repository does not hide valid counts from other repositories or fabricate a value.
- Empty collections: empty-state actions remain visible above the bottom navigation and safe-area insets.
- Wider tablet layout: content remains centered at a readable maximum width instead of stretching edge-to-edge.

---

### Task 1: Shared visual foundation

**Files:**
- Modify `app_name/lib/core/theme/app_colors.dart`
- Modify `app_name/lib/core/theme/app_theme.dart`
- Create `app_name/lib/core/widgets/app_brand_mark.dart` (only if the shared mark is used by multiple flows)
- Create `app_name/lib/core/widgets/app_icon_tile.dart` (only if repeated feature icon treatments use the same interface)

**Interfaces:**
- `AppColors` remains the source for semantic canvas, surface, brand, text, border, and status colors.
- Shared widgets accept explicit labels/icons/colors and preserve accessibility semantics.

- [x] Define the approved semantic palette and reusable shape/spacing values in the shared theme.
- [x] Update theme defaults for cards, app bars, inputs, dialogs, chips, buttons, navigation, and focus/disabled states to a consistent light Material 3 system.
- [x] Add shared brand/icon widgets only where at least two screens use the same structure.
- [x] Run `dart analyze`; expected: no issues.

### Task 2: Sign-in, recovery, and first-run screens

**Files:**
- Modify `app_name/lib/features/auth/presentation/auth_screen.dart`
- Modify `app_name/lib/features/auth/presentation/new_password_screen.dart`
- Modify `app_name/lib/features/auth/presentation/supabase_setup_screen.dart`
- Modify `app_name/lib/features/profile/presentation/profile_setup_screen.dart`

**Interfaces:**
- Preserve `AuthScreen({required AuthService authService})` and all existing auth service calls.
- Preserve the current profile setup callbacks and input fields.

- [x] Build the blue-violet header and raised white form panel using the shared theme, with scroll/keyboard-safe layout.
- [x] Apply the same heading, field, button, inline message, and icon language to password recovery and setup flows.
- [x] Preserve autofill hints, password-manager/paste behavior, validation, and all existing state messages.
- [x] Run `dart analyze`; expected: no issues.

### Task 3: Home progress overview and navigation

**Files:**
- Modify `app_name/lib/features/dashboard/presentation/home_shell.dart`
- Modify `app_name/lib/features/auth/presentation/auth_gate.dart` only if a repository injection change is needed.

**Interfaces:**
- `HomeShell` continues to accept optional repositories and callbacks as it does now.
- Home shows project, skill, credential, achievement, and evidence counts sourced from `ProjectRepository.listProjects()`, `SkillRepository.listSkills()`, `PortfolioRecordRepository.listRecords(type)`, and `EvidenceRepository.listEvidence()`.
- Each metric independently displays a neutral placeholder when its source fails or is unavailable.

- [x] Replace the introductory-only Home content with a welcome header, a visually prominent progress area, and smaller labeled record-count tiles.
- [x] Keep existing project, profile, credentials, evidence, and sign-out actions reachable with one clear primary action.
- [x] Preserve the four bottom navigation destinations, selected states, visible labels, and secondary screen routes.
- [x] Run `dart analyze`; expected: no issues.

### Task 4: Existing record and profile screens

**Files:**
- Modify `app_name/lib/features/projects/presentation/projects_screen.dart`
- Modify `app_name/lib/features/projects/presentation/project_detail_screen.dart`
- Modify `app_name/lib/features/projects/presentation/project_form_screen.dart`
- Modify `app_name/lib/features/skills/presentation/skills_screen.dart`
- Modify `app_name/lib/features/portfolio/presentation/portfolio_records_screen.dart`
- Modify `app_name/lib/features/evidence/presentation/evidence_library_screen.dart`
- Modify `app_name/lib/features/profile/presentation/profile_background_screen.dart`

**Interfaces:**
- Keep all repository and route APIs unchanged.
- Use shared theme tokens/widgets for page widths, headers, icon tiles, field spacing, status labels, and empty/error states.

- [x] Align page gutters, title hierarchy, content widths, card/list surfaces, and primary actions across these screens.
- [x] Apply consistent feature icons and visible private/status labels while retaining text alternatives and tooltips for icon-only controls.
- [x] Keep add/edit/delete/link flows and confirmations unchanged.
- [x] Run `dart analyze`; expected: no issues.

### Task 5: Final review and visual verification

**Files:**
- Review all files changed by Tasks 1–4.

- [x] Re-check the implementation against the spec and address code review findings; visual/device criteria remain unverified due environment limits below.
- [x] Run `dart analyze`; expected: no issues.
- [ ] Perform a manual visual pass at narrow phone, tall phone, and tablet widths, including auth with the keyboard open; record any environment limits where a device preview is unavailable.
- [x] Do not run or add tests unless the user requests verification.

Visual pass limitation: The CUA environment exposed no browser surface, and the Flutter web debug build did not return from its compile stage. Static analysis passed; device-size visual acceptance remains unverified in this session.

## Follow-up: Semantic color and responsive browser layouts (2026-10-21)

**Design decision:** Keep Indigo as the brand and primary action. Assign Teal to skills/evidence and warm Amber to credentials/achievements, using semantic icon colors and pale containers rather than painting entire screens. Keep contrast and visible labels. At narrow widths use 16 dp gutters and a single-column Home metric layout where two columns would leave insufficient text space; progressively use 2 and 3 columns at larger widths. Keep the 720 dp reading-width cap and make dialog content obey available viewport width.

**Root-cause findings:** Home always used two metric columns at 320 dp, leaving each tile 130 dp wide. The Evidence page's empty-state column overflowed when the intro card left a short list viewport (reproduced at 320x700: 76 dp). The Evidence and credentials dialogs also had hard-coded content widths. Browser preview is unavailable in this session; viewport widget tests cover narrow layouts and wide navigation.

**Files:** `app_name/lib/core/theme/app_colors.dart`, `app_theme.dart`, `app_name/lib/features/dashboard/presentation/home_shell.dart`, `app_name/lib/features/portfolio/presentation/portfolio_records_screen.dart`, `app_name/lib/features/evidence/presentation/evidence_library_screen.dart`; focused widget tests in existing portfolio, Evidence, and dashboard test locations.

- [x] Add narrow-viewport regression coverage for the Home metrics and credential/Evidence editors; add a wide-navigation check.
- [x] Add semantic Amber tokens and apply the Teal/Amber roles to Home metrics, skills, Evidence, credentials/achievements, and profile background sections.
- [x] Remove fixed dialog widths, make the Evidence empty state scrollable, and adapt page gutters/grid breakpoints at narrow sizes; add a side navigation rail at wide web widths.
- [x] Run the focused widget tests and `dart analyze`.

Verification: The 3 focused widget test files passed (14 tests total), including 320x700 screens/editors and 1024x768 wide Home navigation. `dart analyze` and `git diff --check` passed. Browser visual preview remains unavailable in this session.

