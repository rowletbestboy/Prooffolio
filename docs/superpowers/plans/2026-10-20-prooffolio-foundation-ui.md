# Prooffolio Foundation UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the generated Flutter counter demo with Prooffolio's first-run Android shell, centralized Material 3 theme, and clear Home, Projects, Skills, and Portfolio navigation.

**Architecture:** Keep the first milestone local and dependency-free. Centralize supplied brand colors and Material 3 component styles, then build a small stateful shell with four destinations and honest empty states; do not connect Supabase or present fabricated user metrics.

**Tech Stack:** Existing Flutter/Dart scaffold in `app_name/`, Material 3, Flutter SDK widgets, existing `flutter_test` setup.

**Spec:** `docs/superpowers/specs/2026-10-20-prooffolio-project-blueprint.md`

## Global Constraints

- Preserve the existing generated platform scaffolding and installed dependency versions.
- Use the supplied colors: navy `#14213D`, indigo `#4F46E5`, teal `#0F766E`, cloud `#F8FAFC`, slate `#0F172A`/`#64748B`, border `#E2E8F0`, and white `#FFFFFF`.
- Keep the light theme, Android system sans-serif, Material 3, and a consistent 8 dp spacing rhythm.
- Keep interactive targets at least 48 dp and use text/icons in addition to color for status.
- Do not add backend calls, mock production statistics, AI features, or new packages in this milestone.
- Keep the current package name and Android application ID (`com.prooffolio.app_name`) until the user chooses a final release ID; do not silently rename it.

## Review Focus

- Small screens and larger text must remain scrollable without clipped primary actions.
- All four bottom destinations must remain reachable with visible selected state and accessible labels.
- Empty states must clearly explain what the student can do next without implying that sample data is real.
- The official color pairs must preserve readable contrast; positive status must not be conveyed by teal alone.
- The shell must render without Supabase configuration or network access.

---

### Task 1: Central Material 3 theme

**Files:**
- Create: `app_name/lib/core/theme/app_colors.dart`
- Create: `app_name/lib/core/theme/app_theme.dart`
- Modify: `app_name/lib/main.dart`
- Modify: `app_name/test/widget_test.dart`

**Interfaces:**
- `AppColors` exposes `static const Color` values for the approved palette.
- `AppTheme.light` exposes the `ThemeData` used by `MaterialApp`.
- `main.dart` starts `ProoffolioApp` and sets the application title to `Prooffolio`.

- [x] Add the palette constants with semantic names and no per-widget raw hex values.
- [x] Define a Material 3 light theme with readable text styles, scaffold/surface colors, input decoration, filled and outlined buttons, cards, and navigation-bar defaults.
- [x] Replace the generated counter app root with a `MaterialApp` using `AppTheme.light`; remove the counter state and demo copy.
- [x] Replace the generated counter widget test with a smoke test for the Prooffolio app title and supplied Material 3 brand theme.
- [x] Review source for leftover `Flutter Demo`, `MyHomePage`, counter, and deep-purple seed references (none remain in `lib/`).

### Task 2: First-run navigation shell and honest empty states

**Files:**
- Create: `app_name/lib/features/dashboard/presentation/home_shell.dart`
- Modify: `app_name/lib/main.dart`
- Modify: `app_name/test/widget_test.dart`

**Interfaces:**
- `HomeShell` is the root authenticated shell and owns the selected bottom-navigation destination.
- Destinations: Home, Projects, Skills, Portfolio. Each has a stable semantic label and a distinct empty state.

- [x] Implement a Material bottom navigation bar with the four destinations and correct selected state.
- [x] Build a calm, evidence-centered Home first-run view: concise welcome heading, a single primary “Add your first project” action, and a short explanation that projects can be linked to skills and evidence.
- [x] Add lightweight first-run empty states for Projects, Skills, and Portfolio; explain the next action and do not show invented counts or completed status.
- [x] Keep page content vertically scrollable and use theme spacing/surfaces instead of repeated identical dashboard cards.
- [x] Extend the Prooffolio widget test with initial Home state and switching among all four destinations.
- [x] Run `flutter analyze` and `flutter test` from `app_name/`; both passed.

## Out of scope for this milestone

Authentication, profile persistence, project CRUD, skills/evidence models, Supabase setup, routing packages, real statistics, portfolio publication, AI, and Play signing. They remain later milestones in the approved blueprint.

