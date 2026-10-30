# Prooffolio Home and Shared UI Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refresh Home to the approved reference, integrate the real logo and saved profile photo, and apply the same visual theme across every existing app page without changing other pages' layouts or behavior.

**Architecture:** Keep Flutter Material 3, the existing theme and repositories. Add a small, testable seven-milestone progress calculator and a reusable Home avatar; derive progress and counts from current profile and record data. Home gets the new hierarchy, while all other screens retain their structures and receive shared token/component styling.

**Tech Stack:** Flutter, Dart, Material 3, `flutter_test`, existing `image` package.

**Spec:** `docs/superpowers/specs/2026-10-29-prooffolio-home-refresh-design.md`

## Global Constraints

- Use `AppTheme`, `AppColors`, Material 3, the existing system font, and current repositories; add no dependencies or backend changes.
- Restyle every existing application page, but only restructure Home; preserve other pages' content, field order, routes, validation, and actions.
- Display profile photos from existing private storage using the existing signed-URL method; initials remain the fallback.
- Calculate progress from the seven milestones in the spec; the bar and rounded percentage must use the same fraction.
- Show the five live category counts separately from progress; loading or failed data must not be presented as a successful zero.
- Clean a derivative of the supplied logo and leave `app_name/assets/PROOFFOLIO LOGO.png` unchanged.
- Do not add notification or AI functionality or change generated resume or portfolio output.
- Preserve the current navigation behavior: bottom bar on narrow layouts and rail at the existing wide breakpoint.

## Review Focus

1. **Missing, expired, or undecodable profile photo** must show initials and keep the profile action usable — test in Task 3.
2. **Whitespace-only profile fields and all existing contact methods** must produce correct milestone results — test in Task 2.
3. **Empty and populated category sources, including each of certification, achievement, or evidence as the proof milestone**, must produce the exact seven-step percentage — test in Task 2.
4. **Loading, missing repository, or failed count source** must not be shown as a successful zero or percentage — test in Tasks 2 and 3.
5. **320 dp phone width, long profile names, and 1024 dp wide layout** must not overflow or obscure primary actions — test in Tasks 3–6 and inspect in Task 7.

---

### Task 1: Add cleaned branding and shared theme tokens

**Files:**
- Create: `app_name/assets/prooffolio_logo_clean.png`
- Create: `app_name/assets/prooffolio_mark_clean.png`
- Modify: `app_name/pubspec.yaml`
- Modify: `app_name/lib/core/widgets/app_brand_mark.dart`
- Modify: `app_name/lib/core/theme/app_colors.dart`
- Modify: `app_name/lib/core/theme/app_theme.dart`
- Create: `app_name/test/core/widgets/app_brand_mark_test.dart`
- Create: `app_name/test/core/theme/app_theme_test.dart`

**Interfaces:**
- Consumes: the supplied `PROOFFOLIO LOGO.png` source and current `AppTheme`/`AppColors`.
- Produces: registered full-lockup and compact-mark assets; `AppBrandMark` renders the appropriate asset for its existing `compact` and `inverse` variants; updated shared color and component tokens for later tasks.

- [ ] **Step 1: Write failing brand and theme tests.** In `app_brand_mark_test.dart`, assert that compact and full variants render an asset image without a Flutter exception, and that inverse mode remains legible on its dark surface. In `app_theme_test.dart`, assert that the shared scaffold, primary, surface, and navigation styles resolve through the expected semantic tokens.
- [ ] **Step 2: Run the focused tests and verify they fail for the placeholder mark or missing asset registration.** Run from `app_name`: `flutter test test/core/widgets/app_brand_mark_test.dart test/core/theme/app_theme_test.dart`.
- [ ] **Step 3: Create transparent full-lockup and compact-mark derivatives from the supplied PNG.** Remove its baked checkerboard, preserve brand colors, leave the original unchanged, register both files in `pubspec.yaml`, and replace the placeholder icon in `AppBrandMark` with the correct asset variant.
- [ ] **Step 4: Update `AppColors` and `AppTheme` shared semantic tokens and component styles** to match the approved navy/blue, teal, cool-light-surface visual direction while retaining Material 3 and readable contrast.
- [ ] **Step 5: Run the focused tests and analyze.** Run `flutter test test/core/widgets/app_brand_mark_test.dart test/core/theme/app_theme_test.dart` and `flutter analyze`; expect both to pass without missing-asset or layout exceptions.

### Task 2: Implement reusable profile and portfolio progress logic

**Files:**
- Modify: `app_name/lib/features/profile/domain/profile.dart`
- Modify: `app_name/lib/features/dashboard/presentation/profile_completion_reminder.dart`
- Create: `app_name/lib/features/dashboard/domain/portfolio_progress.dart`
- Modify: `app_name/test/features/profile/profile_test.dart`
- Modify: `app_name/test/features/dashboard/profile_completion_reminder_test.dart`
- Create: `app_name/test/features/dashboard/portfolio_progress_test.dart`

**Interfaces:**
- Consumes: `ProfileBackground` and the existing profile/project/skill/record/evidence repositories.
- Produces: `bool profileHasContactMethod(ProfileBackground? profile)` shared by profile readiness and progress; `PortfolioProgress? calculatePortfolioProgress({required ProfileBackground? profile, required int? projectCount, required int? skillCount, required int? certificationCount, required int? achievementCount, required int? evidenceCount})`; the result exposes `completedMilestones`, `totalMilestones` (7), `fraction`, and rounded `percentage`.
- A null count means its source is unavailable and calculation returns `null`. A null profile represents a successfully loaded but absent profile and counts its profile milestones as incomplete.

- [ ] **Step 1: Add failing profile-contact tests** for contact email, phone, each supported contact URL/number, an additional link with a URL, blank values, and no contact.
- [ ] **Step 2: Add failing progress tests** for 0/7, 3/7 → 43%, 7/7 → 100%, whitespace-only fields, optional photo not counted, each of certification/achievement/evidence satisfying the single proof milestone, and any unavailable count returning `null`.
- [ ] **Step 3: Run the focused tests and verify the new helper/calculator are missing or produce incorrect results.** Run `flutter test test/features/profile/profile_test.dart test/features/dashboard/profile_completion_reminder_test.dart test/features/dashboard/portfolio_progress_test.dart`.
- [ ] **Step 4: Extract the contact predicate into `profileHasContactMethod`, update `ProfileCompletionReminder` to use it, and implement `calculatePortfolioProgress`** with the seven criteria and exact rounding from the spec.
- [ ] **Step 5: Run the focused tests again** and confirm all milestone, contact, and existing profile-reminder tests pass.

### Task 3: Build the Home experience and profile avatar

**Files:**
- Create: `app_name/lib/features/dashboard/presentation/home_profile_avatar.dart`
- Modify: `app_name/lib/features/dashboard/presentation/home_shell.dart`
- Modify: `app_name/test/features/dashboard/home_responsive_test.dart`
- Create: `app_name/test/features/dashboard/home_profile_avatar_test.dart`
- Create: `app_name/test/features/dashboard/home_shell_test.dart`

**Interfaces:**
- Consumes: Task 1 shared theme/branding and Task 2 progress calculation.
- Produces: `HomeProfileAvatar({required String displayName, required String? photoUrl, required VoidCallback? onTap})`; a missing or failed network image displays initials. Home obtains `photoUrl` from the saved profile's `photoPath` using `ProfileBackgroundRepository.createProfilePhotoSignedUrl`.

- [ ] **Step 1: Add failing avatar widget tests** for a supplied photo URL, absent URL, image-load failure, accessible profile action, initials derived from the display name, and a long name that must not overflow.
- [ ] **Step 2: Add failing Home widget tests** for the saved greeting name, exact progress fraction/copy, five live category counts, recent-project data, shortcut destinations, and profile-photo signed URL lookup.
- [ ] **Step 3: Run `flutter test test/features/dashboard/home_profile_avatar_test.dart test/features/dashboard/home_shell_test.dart test/features/dashboard/home_responsive_test.dart`** and verify the new Home elements or avatar behavior are absent.
- [ ] **Step 4: Implement `HomeProfileAvatar` and update `home_shell.dart`.** Replace the existing Home content with the approved greeting hero, progress card, compact count breakdown, four shortcuts, recent-project cards, resume call-to-action, and existing navigation. Use real profile/project data; retain loading, empty, retry, and initials fallback states. Route actions to existing features, label the portfolio shortcut `Portfolio`, and do not add a notification action.
- [ ] **Step 5: Run the focused Home tests** and confirm 320 dp and 1024 dp layouts remain exception-free, the bottom bar/rail breakpoint is preserved, and all shortcuts still reach existing destinations.

### Task 4: Apply the shared theme to auth and profile pages

**Files:**
- Modify: `app_name/lib/features/auth/presentation/auth_screen.dart`
- Modify: `app_name/lib/features/auth/presentation/new_password_screen.dart`
- Modify: `app_name/lib/features/auth/presentation/supabase_setup_screen.dart`
- Modify: `app_name/lib/features/profile/presentation/profile_setup_screen.dart`
- Modify: `app_name/lib/features/profile/presentation/profile_background_screen.dart`
- Create: `app_name/test/features/auth/auth_theme_test.dart`
- Create: `app_name/test/features/profile/profile_setup_screen_test.dart`
- Modify: `app_name/test/features/profile/profile_background_screen_test.dart`

**Interfaces:**
- Consumes: Task 1 shared brand asset and theme tokens.
- Produces: consistent branded styling for auth gating/sign-in/sign-up, password recovery, new-password and Supabase setup, profile setup, and profile/background editing; existing forms, field order, validation, and profile-photo upload behavior stay unchanged.

- [ ] **Step 1: Add failing widget tests** asserting the auth and profile screens render the shared brand, preserve their primary form controls, and remain scrollable without overflow at 320 dp.
- [ ] **Step 2: Run `flutter test test/features/auth/auth_theme_test.dart test/features/profile/profile_setup_screen_test.dart test/features/profile/profile_background_screen_test.dart`** and confirm the new theme assertions fail.
- [ ] **Step 3: Replace page-local visual overrides in the listed screens with shared theme tokens** and update only the visual treatment; preserve existing labels, validation, error feedback, and submit behavior.
- [ ] **Step 4: Run the focused tests** and confirm profile-photo upload/edit tests and auth/profile behavior remain intact.

### Task 5: Apply the shared theme to Projects, Skills, and Evidence

**Files:**
- Modify: `app_name/lib/features/projects/presentation/projects_screen.dart`
- Modify: `app_name/lib/features/projects/presentation/project_detail_screen.dart`
- Modify: `app_name/lib/features/projects/presentation/project_form_screen.dart`
- Modify: `app_name/lib/features/skills/presentation/skills_screen.dart`
- Modify: `app_name/lib/features/evidence/presentation/evidence_library_screen.dart`
- Modify: `app_name/test/features/projects/projects_screen_test.dart`
- Modify: `app_name/test/features/skills/skills_screen_test.dart`
- Modify: `app_name/test/features/evidence/evidence_library_screen_test.dart`

**Interfaces:**
- Consumes: Task 1 shared tokens and existing repositories/forms.
- Produces: aligned page headers, cards, status labels, fields, action buttons, empty/error states, and confirmation dialogs without changing each page's information hierarchy or behavior.

- [ ] **Step 1: Add failing shared-theme assertions to the existing Projects, Skills, and Evidence widget tests.** Cover visible page headings/actions and verify representative card, field, dialog, and empty/error surfaces use the shared semantic colors.
- [ ] **Step 2: Run `flutter test test/features/projects/projects_screen_test.dart test/features/skills/skills_screen_test.dart test/features/evidence/evidence_library_screen_test.dart`** and verify the new theme assertions fail.
- [ ] **Step 3: Update the listed screens to use the shared styles** while keeping create/edit/delete, relationship selection, evidence file selection, status, and retry behavior unchanged.
- [ ] **Step 4: Run the focused feature tests** and verify existing repository and navigation behavior remains intact.

### Task 6: Apply the shared theme to Portfolio and resume app screens

**Files:**
- Modify: `app_name/lib/features/portfolio/presentation/portfolio_preview_screen.dart`
- Modify: `app_name/lib/features/portfolio/presentation/portfolio_records_screen.dart`
- Modify: `app_name/lib/features/portfolio/presentation/portfolio_site_preview.dart`
- Modify: `app_name/lib/features/portfolio/presentation/resume_preview_screen.dart`
- Modify: `app_name/test/features/portfolio/portfolio_preview_navigation_test.dart`
- Modify: `app_name/test/features/portfolio/portfolio_records_screen_test.dart`
- Modify: `app_name/test/features/portfolio/resume_preview_screen_test.dart`
- Do not modify: `app_name/lib/features/portfolio/data/resume_exporter.dart` or generated portfolio-site output/surface files.

**Interfaces:**
- Consumes: Task 1 shared tokens and existing portfolio/resume repositories.
- Produces: consistent styling for the in-app portfolio, record-management, site-preview controls, and resume-preview UI. Generated PDF and public-site output are unchanged.

- [ ] **Step 1: Add failing theme assertions** to portfolio navigation, record-management, and resume-preview tests; retain existing navigation and PDF-preview checks.
- [ ] **Step 2: Run `flutter test test/features/portfolio/portfolio_preview_navigation_test.dart test/features/portfolio/portfolio_records_screen_test.dart test/features/portfolio/resume_preview_screen_test.dart`** and verify the new assertions fail.
- [ ] **Step 3: Update the listed app-page surfaces to use shared colors, typography, cards, and controls** without changing portfolio content, publication behavior, resume templates, or PDF output.
- [ ] **Step 4: Run the focused portfolio tests** and confirm navigation, image/data display, and resume preview behavior remain intact.

### Task 7: Verify the complete app-wide refresh

**Files:**
- Verify: all files in Tasks 1–6
- No new implementation files unless a focused test exposes a specific missing requirement.

**Interfaces:**
- Consumes: the completed shared theme, logo, Home, and feature-screen updates.
- Produces: a verified, responsive app-wide refresh matching the approved spec.

- [ ] **Step 1: Run the full Flutter suite** from `app_name`: `flutter test`; expect zero failures.
- [ ] **Step 2: Run `flutter analyze`** from `app_name`; expect no new diagnostics.
- [ ] **Step 3: Run `git diff --check`** from the repository root; expect no whitespace errors.
- [ ] **Step 4: Inspect 320 dp phone and 1024 dp wide layouts** for auth entry/recovery/setup, profile setup/background, Home, Projects/list/detail/form, Skills, Evidence, Portfolio/record management/site-preview controls, and resume preview. Confirm the shared theme is visible on every page, only Home's structure changed, and there is no clipping, horizontal overflow, hidden primary action, unreadable logo, or broken profile-photo fallback.
- [ ] **Step 5: Confirm generated resume PDFs and portfolio-site output are unchanged** by the UI-only work.
