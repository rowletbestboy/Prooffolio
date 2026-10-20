# Certifications and Achievements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Let users add and manage certifications and achievements as private portfolio records without requiring a project.

**Architecture:** Add one owner-scoped `portfolio_records` table with a constrained `record_type`, one domain model, repository, and CRUD screen. Expose the screen from Home and pass the authenticated Supabase repository through the existing AuthGate. Keep file evidence and public sharing for later phases.

**Tech Stack:** Existing Flutter/Dart and Supabase Flutter dependencies, Material 3, PostgreSQL RLS.

**Spec:** `docs/superpowers/specs/2026-10-20-prooffolio-inclusive-portfolio-design.md`

## Global Constraints

- “Make projects one useful portfolio content type, without requiring every person to have projects.”
- “Add first-class Certifications and Achievements records with title, issuer/source (optional), description, dates, optional expiration for certificates, private-by-default publication state, and linked evidence.”
- “Every new table has `user_id`, owner-only RLS, and indexes/constraints appropriate to its relationships.”
- Keep existing authentication, profile, Projects, Skills, and project-skill behavior intact.
- Do not add dependencies; evidence file attachments are explicitly deferred to the next phase.

## Review Focus

- A person with no project can create and manage either record type.
- Optional issuer, description, and dates remain nullable or safely empty.
- Achievement records cannot carry a certificate expiration date.
- New records remain owner-only and private by default.
- Long titles and descriptions remain scrollable on narrow screens.

---

### Task 1: Domain and persistence

**Files:**
- Create `app_name/lib/features/portfolio/domain/portfolio_record.dart`
- Create `app_name/test/features/portfolio/portfolio_record_test.dart`
- Create `app_name/supabase/migrations/20261024100000_create_portfolio_records.sql`
- Create `app_name/lib/features/portfolio/data/portfolio_record_repository.dart`

**Interfaces:** `PortfolioRecordType` has `certification` and `achievement`; `PortfolioRecordDraft` holds title, source, description, date earned, and optional expiration; `PortfolioRecord` adds id, owner, timestamps, and private/public state. `PortfolioRecordRepository` lists by type and creates, updates, and deletes by id. The Supabase implementation relies on authenticated RLS and derives `user_id` from the session.

- [x] Add tests for optional fields, dates, record type parsing, and private-by-default serialization.
- [x] Implement model, migration with owner-only RLS, repository mappings.
- [x] Run focused domain tests and analyzer.

### Task 2: CRUD screen and Home entry point

**Files:**
- Create `app_name/lib/features/portfolio/presentation/portfolio_records_screen.dart`
- Create `app_name/test/features/portfolio/portfolio_records_screen_test.dart`
- Modify `app_name/lib/features/dashboard/presentation/home_shell.dart`
- Modify `app_name/lib/features/auth/presentation/auth_gate.dart`

**Interfaces:** `PortfolioRecordsScreen({required PortfolioRecordRepository repository})` lets the user switch between Certifications and Achievements, add/edit/delete records, and browse the selected type. The Home screen provides a labeled entry point and the AuthGate injects `SupabasePortfolioRecordRepository`.

- [x] Test creating an achievement without a project or issuer.
- [x] Test creating a certification with an expiration date and deleting a record.
- [x] Test empty states, type switching, and Home navigation.
- [x] Implement responsive Material 3 forms with optional labels, clear privacy state, and one primary save action.
- [x] Run the focused screen tests.

### Task 3: Documentation and final checks

**Files:**
- Modify `docs/supabase-setup.md`
- Modify `docs/superpowers/specs/2026-10-20-prooffolio-feature-status-and-roadmap.md`

- [x] Document the new migration after `20261023100000_expand_profile_and_skills.sql`.
- [x] Mark Certifications and Achievements implemented while keeping evidence uploads as the next phase.
- [x] Format changed Dart files; run `flutter test --no-pub` (33 tests passed) and `dart analyze` (no issues).
