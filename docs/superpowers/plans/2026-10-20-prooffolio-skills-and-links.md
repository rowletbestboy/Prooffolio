# Prooffolio Skills Library Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Add an owner-private Skills library with self-reported learning states and links to owned projects.

**Architecture:** Model the skill catalog separately from project-skill associations. Supabase writes use one transaction-backed RPC so a skill and its project links save atomically; ownership remains enforced by RLS and composite foreign keys. The Flutter screen uses the current Material 3 system and an injected repository.

**Tech Stack:** Flutter/Dart, Material 3, Supabase Flutter, PostgreSQL RLS.

**Spec:** `docs/superpowers/specs/2026-10-20-prooffolio-feature-status-and-roadmap.md` and the user-provided Prooffolio master prompt.

## Global Constraints

- Keep the current Flutter and Supabase dependencies.
- Skill claims are self-reported and must not imply certification or assessed proficiency.
- All skill and project-link reads and writes are owner-only.
- Existing auth, profile, project flows, and the four shell destinations continue working.
- Public portfolio and evidence records remain later roadmap steps.

## Review Focus

- Cross-user project IDs cannot be associated with a skill: database composite foreign keys and RLS reject them.
- Saving a skill and its link changes is atomic: one RPC transaction owns both writes.
- Empty projects still allow recording a skill without a project association.
- Long skill lists and larger text remain scrollable without hiding add/save actions.
- Status wording stays explicitly self-reported and is not presented as a measured score.

---

### Task 1: Skills domain and repository

**Files:**
- Create `app_name/lib/features/skills/domain/skill.dart`
- Create `app_name/lib/features/skills/data/skill_repository.dart`
- Create `app_name/test/features/skills/skill_test.dart`

**Interfaces:** `SkillRepository` lists owned skills with linked project titles, saves a `SkillDraft` and project IDs atomically, and deletes a skill. `SupabaseSkillRepository` implements that contract.

- [x] Test serialization, status/category labels, and project associations.
- [x] Implement the model and repository.

### Task 2: Skills migration

**Files:**
- Create `app_name/supabase/migrations/20261022100000_create_skills_and_project_skills.sql`

- [x] Add private `skills` and `project_skills` tables, owner RLS, constraints, and atomic `save_skill_with_projects` RPC.

### Task 3: Skills UI and app wiring

**Files:**
- Create `app_name/lib/features/skills/presentation/skills_screen.dart`
- Create `app_name/test/features/skills/skills_screen_test.dart`
- Modify `app_name/lib/features/dashboard/presentation/home_shell.dart`
- Modify `app_name/lib/features/auth/presentation/auth_gate.dart`
- Modify `docs/supabase-setup.md`
- Modify `docs/superpowers/specs/2026-10-20-prooffolio-feature-status-and-roadmap.md`

- [x] Test skill creation, project linking, name validation, and the honest empty state.
- [x] Build screen and editor using the injected project and skill repositories; edit, unlink, and delete actions are implemented.
- [x] Wire authenticated Supabase repositories into the existing shell.
- [x] Document migration setup and update feature status.
- [x] Run formatter, Flutter tests, and analyzer.
