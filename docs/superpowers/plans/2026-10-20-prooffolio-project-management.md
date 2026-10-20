# Prooffolio Project Management Implementation Plan

> **For agentic workers:** Execute task by task. Steps use checkbox syntax for tracking.

**Goal:** Replace the Projects placeholder with authenticated, owner-scoped create/read/update/delete project workflows.

**Architecture:** Store projects in a versioned Supabase migration with RLS. Use a project model and repository boundary, then connect a mobile list/detail/form flow to the existing Projects navigation destination. New records start as private drafts; public exposure is deferred until the portfolio publication feature defines its narrow public-read policy.

**Tech Stack:** Existing Flutter/Dart app, `supabase_flutter`, Material 3, PostgreSQL/RLS, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-10-20-prooffolio-project-blueprint.md`; detailed source requirements: the user-provided Prooffolio master prompt; status ledger: `docs/superpowers/specs/2026-10-20-prooffolio-feature-status-and-roadmap.md`.

## Global Constraints

- Preserve Material 3 palette, auth/session gate, bottom navigation, existing Android application ID, and working profile flow.
- Keep project data user-owned and private by default; RLS must enforce ownership independently of UI.
- Do not invent project accomplishments, metrics, technologies, or impact.
- Keep dependencies unchanged unless an actual implementation need is established.
- Validate inputs and confirm destructive deletion.
- Use the existing shell; do not overload bottom navigation with new sections.

## Review Focus

- Empty, loading, failed and populated project lists have distinct, useful UI.
- Invalid or oversized fields are blocked before saving and match database constraints.
- Repository/demo URLs reject malformed non-empty values.
- Project records are selected and mutated only for the signed-in owner; RLS remains authoritative.
- Delete is explicit and confirmed; unpublished records are never public.

---

### Task 1: Project schema, model and repository

**Files:** Create `app_name/supabase/migrations/20261021100000_create_projects.sql`, `app_name/lib/features/projects/domain/project.dart`, `app_name/lib/features/projects/data/project_repository.dart`; add repository/model tests.

**Interfaces:** `Project` has immutable fields for identity, title, summary, project narrative, lists of features/technologies, contribution, challenges, lessons, dates, status, repository/demo URLs, publication status and timestamps. `ProjectRepository` exposes `Future<List<Project>> listProjects()`, `Future<Project> createProject(ProjectDraft draft)`, `Future<Project> updateProject(String id, ProjectDraft draft)`, and `Future<void> deleteProject(String id)`.

- [x] Write failing tests for project serialization, draft defaults and validation.
- [x] Add owner-only RLS migration and constraints matching form validation.
- [x] Implement the model, draft object and Supabase repository.
- [x] Run focused tests, full Flutter tests and analyzer.

### Task 2: Project list, detail and editor

**Files:** Create `projects/presentation/projects_screen.dart`, `project_form_screen.dart`, `project_detail_screen.dart`; tests with a fake repository.

- [x] Test empty/list states, create/edit save, validation and confirmed delete.
- [x] Implement a clear project list with title/status, short summary and useful empty state.
- [x] Implement grouped project form fields, scrollable on phone and text-scalable.
- [x] Implement project detail view with edit and delete actions.
- [x] Verify that failed saves retain entered form data and show actionable errors.

### Task 3: Connect to navigation and backend

**Files:** Modify `features/dashboard/presentation/home_shell.dart`, `features/auth/presentation/auth_gate.dart`, and `test/widget_test.dart`; update roadmap status.

- [x] Inject the signed-in Supabase project repository through AuthGate.
- [x] Route Projects tab and Home primary action to the new project flow.
- [x] Keep Home, Skills and Portfolio behavior intact.
- [x] Format, run all Flutter tests and analyzer.
- [x] Document how to apply the new migration in Supabase SQL Editor.

**External step after code:** Run the new projects migration in the user's Supabase project before testing live project CRUD.
