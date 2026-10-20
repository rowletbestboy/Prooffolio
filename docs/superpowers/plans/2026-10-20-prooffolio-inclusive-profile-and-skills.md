# Inclusive Profile and Skills Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Let users describe varied occupations, education, and experience, and categorize skills across fields without requiring a project or formal degree.

**Architecture:** Keep identity fields on `profiles`, add normalized owner-scoped education and experience tables, and extend the existing Skills categories with an additive migration. Add a profile/background editor reachable from the authenticated Home header; preserve the current first-run identity setup and existing project/skill links.

**Tech Stack:** Existing Flutter/Dart and Supabase Flutter dependencies, Material 3, PostgreSQL RLS.

**Spec:** `docs/superpowers/specs/2026-10-20-prooffolio-inclusive-portfolio-design.md`

## Global Constraints

- “Do not require a degree, formal employment, project, certificate, or achievement before someone can create a useful portfolio.”
- “Work history is optional and must accept informal, unpaid, self-directed, and community experience.”
- “Every new table has `user_id`, owner-only RLS, and indexes/constraints appropriate to its relationships.”
- “Migrations are additive and must preserve existing user projects, skills, and project-skill links.”
- Keep existing `display_name` and `username` requirements unchanged for onboarding.
- Do not add a package or change existing auth, Projects, or Skills CRUD behavior.

## Review Focus

- Existing users with old skill category values still load and save their skills: migration maps the old category values while preserving names, statuses, and project links; model tests cover legacy values.
- A user may save the profile without a degree, current job, occupation choice, or interests: widget test leaves optional sections empty.
- Ongoing and unpaid experience can be represented: model/widget tests cover volunteer experience with no organization and a current role with no end date.
- Education and experience records remain attached to the authenticated owner: migration owner policies and composite key constraints cover every row.
- Long labels and expanded text do not clip on mobile: profile editor test uses a narrow viewport and verifies scroll access to save.

---

### Task 1: Profile and background domain models

**Files:**
- Create `app_name/lib/features/profile/domain/profile.dart`
- Create `app_name/test/features/profile/profile_test.dart`

**Interfaces:** `OccupationCategory`, `CareerStage`, `EducationStatus`, `ExperienceType`, `ProfileBackground`, `EducationRecord`, and `ExperienceRecord` expose stable database values, human labels, and `fromJson`/serialization helpers. Every optional field defaults safely for existing profiles.

- [x] Test category values/labels and parsing of missing optional fields.
- [x] Test current experience with no end date and optional organization.
- [x] Implement domain models and serialization.
- [x] Run `flutter test test/features/profile/profile_test.dart --no-pub`.

### Task 2: Additive Supabase migration and repository

**Files:**
- Create `app_name/supabase/migrations/20261023100000_expand_profile_and_skills.sql`
- Modify `app_name/lib/features/profile/data/profile_repository.dart`
- Modify `app_name/lib/features/skills/domain/skill.dart`

**Interfaces:** Preserve `hasProfile` and the existing `saveProfile({required displayName, required username})` call. Add `loadProfile(userId)`, `saveBackground(userId, background)`, `listEducation(userId)`, `saveEducation(userId, record)`, `deleteEducation(userId, id)`, `listExperience(userId)`, `saveExperience(userId, record)`, and `deleteExperience(userId, id)`. Extend `SkillCategory` with broad domain categories and display legacy categories compatibly.

- [x] Add failing model tests for the new broad skill categories and legacy category parsing.
- [x] Expand categories to agriculture/environment, arts/media/design, business/administration, construction/trades, education, engineering/manufacturing, healthcare/care, hospitality, technology/digital, law/public service, science/research, sales/customer service, transport/logistics, virtual assistance/remote operations, communication/languages, leadership/project management, and Other.
- [x] Add nullable profile fields and normalized education/experience tables with owner-only RLS and owner-scoped composite keys.
- [x] Reclassify existing technology-specific skill category values to `technology_digital`, preserving skill names, statuses, and links; replace the category constraint with the broad set.
- [x] Implement Supabase repository mappings and preserve the existing onboarding save behavior.
- [ ] Run `flutter test test/features/profile/profile_test.dart test/features/skills/skill_test.dart --no-pub` and `dart analyze`.

### Task 3: Profile and background editor

**Files:**
- Create `app_name/lib/features/profile/presentation/profile_background_screen.dart`
- Create `app_name/test/features/profile/profile_background_screen_test.dart`

**Interfaces:** `ProfileBackgroundScreen({required ProfileBackgroundRepository repository, required String userId})` loads/saves background details plus repeatable education and experience records. Occupation uses a searchable picker with broad choices and “Other”; all fields besides existing identity fields are optional.

- [x] Test searchable occupation choice and custom role/title.
- [x] Test a user can save only a short profile without education or experience.
- [x] Test adding an education entry and current volunteer/independent experience.
- [ ] Test inline validation and visible save completion/error states.
- [x] Implement the scrollable Material 3 editor with one primary profile save action and separate add/edit/delete controls for repeatable records.
- [ ] Run `flutter test test/features/profile/profile_background_screen_test.dart --no-pub`.

### Task 4: Authenticated navigation and documentation

**Files:**
- Modify `app_name/lib/features/dashboard/presentation/home_shell.dart`
- Modify `app_name/lib/features/auth/presentation/auth_gate.dart`
- Modify `app_name/test/widget_test.dart`
- Modify `docs/supabase-setup.md`
- Modify `docs/superpowers/specs/2026-10-20-prooffolio-feature-status-and-roadmap.md`

- [x] Add a labeled Profile action in the authenticated Home header and open the profile/background editor.
- [x] Update Home copy to welcome projects, learning, and work experience without implying a project is required.
- [x] Test profile navigation and keep all four existing bottom destinations reachable.
- [x] Document migration order and order credentials/achievements before evidence uploads.
- [x] Format touched Dart files and run `flutter test --no-pub` (26 tests passed) and `dart analyze` (no issues).
