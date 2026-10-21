# Prooffolio Evidence Library Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Add a private Evidence library for safe file uploads and external URLs, with owner-checked links to projects, skills, experience, certifications, and achievements.

**Architecture:** Store file metadata and URLs in an owner-scoped `evidence_records` table, objects in a private Supabase Storage bucket, and typed target references in an owner-scoped relation table whose trigger validates target ownership. Use a platform file picker, client and bucket size/MIME restrictions, short-lived signed URLs for private file opening, and a Home entry point.

**Tech Stack:** Existing Flutter/Dart and Supabase Flutter; `file_picker` for platform file selection and `url_launcher` for opening URLs and signed file links.

**Spec:** `docs/superpowers/specs/2026-10-20-prooffolio-inclusive-portfolio-design.md`

## Global Constraints

- â€œStore objects in a private Supabase Storage bucket with per-user path ownership and policies.â€
- â€œThe client should validate extension and reported MIME type for user feedback, give a clear error for unsupported formats or oversized files, and make limits configurable to match the active Supabase Storage plan.â€
- â€œEnforce bucket-level content-type and size restrictions too; client validation alone is not a security boundary.â€
- â€œDeleting an evidence row must also remove its Storage object through the Storage API; handle abandoned objects after failed metadata saves.â€
- â€œEvery new table has `user_id`, owner-only RLS, and indexes/constraints appropriate to its relationships.â€
- â€œComposite ownership constraints prevent a user's skill or evidence link from pointing at another user's project or record.â€
- â€œDraft attachments must not be publicly addressable.â€
- Do not accept arbitrary executable content; allow only the design spec's image, document, video, and audio extensions.

## Review Focus

- MIME/extension mismatch or missing MIME input: accept only a listed extension and a compatible reported MIME type; reject mismatches clearly.
- Oversized and empty files: reject them before upload and enforce the same maximum at bucket level.
- Cross-user links: a user cannot attach evidence to another user's project, skill, experience, or portfolio record.
- Storage upload followed by metadata failure: remove the uploaded object before reporting failure.
- Storage deletion failure: keep the metadata row so the item remains visible and deletion can be retried.
- URL input: allow only absolute HTTP(S) URLs and keep them private until explicit publication exists.

---

### Task 1: Evidence domain and file policy

**Files:**
- Create `app_name/lib/features/evidence/domain/evidence.dart`
- Create `app_name/test/features/evidence/evidence_test.dart`

**Interfaces:** `EvidenceKind` supports `file` and `url`; `EvidenceTargetType` supports `project`, `skill`, `experience`, and `portfolioRecord`; `EvidenceTarget`, `EvidenceDraft`, and `EvidenceRecord` have stable database mappings. `EvidenceFilePolicy.validate({required String fileName, required String? mimeType, required int sizeBytes})` returns a user-facing error or `null`. The default upload ceiling is 50,000,000 bytes (50 MB), below Supabase's documented Free-project maximum, and extension/MIME allow-lists match the design spec.

- [x] Test URL normalization and HTTP(S)-only validation.
- [x] Test accepted and rejected extensions, MIME mismatch, missing MIME, zero-byte files, and the configured size boundary.
- [x] Test database serialization and parsing for file, URL, and target types.
- [x] Implement domain models and validation.
- [x] Run `flutter test test/features/evidence/evidence_test.dart --no-pub`.

### Task 2: Private storage schema and repository

**Files:**
- Create `app_name/supabase/migrations/20261025100000_create_evidence.sql`
- Create `app_name/lib/features/evidence/data/evidence_repository.dart`
- Create `app_name/test/features/evidence/evidence_repository_test.dart`

**Interfaces:** `EvidenceRepository` provides `listEvidence()`, `listTargets()`, `addUrl(...)`, `uploadFile(...)`, `openUrl(EvidenceRecord)`, and `deleteEvidence(EvidenceRecord)`. `SupabaseEvidenceRepository` derives the owner from the authenticated session, stores uploads at `<user-id>/<generated-name>`, cleans up an object if metadata insertion fails, and removes storage objects before deleting metadata.

- [x] Test repository-facing success, cleanup-on-metadata-failure, and deletion behavior using an injected storage adapter and fake database adapter.
- [x] Create private `evidence_records` and owner-only `evidence_links`; enforce target ownership for all four supported target types and clean links when targets are deleted.
- [x] Create/update the private `evidence` bucket with the allowed MIME list and 50 MB limit; add authenticated per-user path policies for select, insert, and delete.
- [x] Implement owner-scoped list, target, URL, upload, signed URL, and delete operations.
- [x] Run `flutter test test/features/evidence/evidence_repository_test.dart --no-pub`.

### Task 3: Evidence library UI and authenticated navigation

**Files:**
- Modify `app_name/pubspec.yaml`
- Create `app_name/lib/features/evidence/presentation/evidence_library_screen.dart`
- Create `app_name/test/features/evidence/evidence_library_screen_test.dart`
- Modify `app_name/lib/features/dashboard/presentation/home_shell.dart`
- Modify `app_name/lib/features/auth/presentation/auth_gate.dart`

**Interfaces:** `EvidenceLibraryScreen({required EvidenceRepository repository, required EvidenceFilePicker filePicker})` lists private evidence, supports adding a URL or selected file with optional multi-record links, opens URL/signed file links, and deletes with confirmation. `EvidenceFilePicker.pickFile()` returns the selected name, reported MIME type, length, and bytes; the production implementation uses `file_picker`.

- [x] Test creating URL evidence linked to a portfolio record, file evidence linked to a project, required URL/title validation, unsupported file feedback, and delete confirmation.
- [x] Add `file_picker` and `url_launcher` dependencies.
- [x] Implement a scrollable, accessible Evidence library and add a labeled Home action; inject the Supabase repository through `AuthGate`.
- [x] Run `flutter test test/features/evidence/evidence_library_screen_test.dart --no-pub`.

### Task 4: Setup documentation and whole-app verification

**Files:**
- Modify `docs/supabase-setup.md`
- Modify `docs/superpowers/specs/2026-10-20-prooffolio-feature-status-and-roadmap.md`

- [x] Document migration order, allowed formats, the 50 MB app/bucket limit, and how to lower the app and bucket limit together to match the project's global Storage limit.
- [x] Mark the Evidence library implemented while keeping public attachment sharing deferred.
- [x] Format touched Dart files; run `flutter test --no-pub` and `dart analyze`.
