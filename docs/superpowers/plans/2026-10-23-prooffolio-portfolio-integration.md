# Prooffolio Portfolio Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate the approved profile, portfolio publishing, and resume experience into the Desktop Flutter checkout so users can prepare polished private previews and explicitly publish/share selected portfolio content.

**Architecture:** Treat `C:\Users\sergr\Desktop\Prooffolio` as the only runnable integration target. Selectively reconcile the temporary worktree's privacy-safe profile photo/contact work, portfolio composition/generation/publication, and tests with Desktop's independently edited profile/dashboard UI; do not wholesale-copy either checkout. Use additive Supabase migrations and existing owner-scoped repositories, one shared content model, a deterministic static-site generator, and one resume model for PDF/DOCX output.

**Tech Stack:** Flutter/Dart, Supabase Auth/Postgres/Storage with RLS, `file_picker`, `archive`, WebView/iframe preview, `pdf`, `docx_dart`, Flutter widget/unit tests.

**Spec:** `docs/superpowers/specs/2026-10-23-prooffolio-portfolio-integration-design.md`

## Global Constraints

- Desktop is the integration target; preserve all pre-existing tracked and untracked work in both checkouts, and preserve every SQL migration and project document.
- Do not reset, clean, overwrite whole worktrees, commit, apply SQL, connect to a real Supabase project, or publish account data.
- New profile and portfolio data remain private until explicit user review and selection for publication; the profile photo is not automatically public.
- Keep existing owner-only table policies and private Evidence bucket unchanged; public visitors may access only explicitly selected generated static files.
- Never fabricate content, IDs, private Evidence paths, credentials, metrics, or claims in output.
- Call the standard resume layout “ATS-friendly,” never “ATS approved”; state that no universal ATS parser result is guaranteed.
- Use the approved portfolio mockup as the visual direction: evergreen/teal, editorial serif display with legible system sans, asymmetric photo-led introduction, selected-work case studies, clear contact action, cohesive light/dark layouts, responsive and accessible.
- Profile photo: JPG/PNG/WEBP signature validation, maximum 5,000,000 bytes, private source storage; publish a bundled copy only when explicitly selected.
- Require `PORTFOLIO_PUBLIC_BASE_URL` (HTTPS public bucket base URL) for live publishing; do not put a service-role key in Flutter.
- Complete each task's red/green test cycle before proceeding. Leave changes uncommitted unless separately requested.

## Review Focus

- Existing Desktop profile fields and ongoing UI edits versus imported model/editor: test saving/reloading new contacts/photo while retaining background and education/experience fields in Task 1.
- Missing/null optional migration columns or an un-applied additive migration: test old profiles with absent optional values and document migration order in Task 1.
- Partial source failures could be mistaken for an empty portfolio: test unavailable source messaging and retry in Task 3.
- HTML injection, unsafe URL schemes, internal IDs, private Evidence, or unselected records leaking into public output: test malicious text, `javascript:` links, and deselected records in Task 4.
- Storage, state-save, stale-preview, and unpublish failures could leave a broken public snapshot: test rollback and restore behavior in Task 5.
- Long names/descriptions, missing sections, or empty profile data could break export: test omission, safe filenames, selectable text, and multi-page content in Tasks 6–7.

## File Structure

- `app_name/lib/features/profile/domain/profile.dart`: profile/contact/photo/upwork value objects and serialization.
- `app_name/lib/features/profile/data/profile_repository.dart`: owner-scoped profile/education/experience and private photo storage contract/adapter.
- `app_name/lib/features/profile/presentation/profile_background_screen.dart`: reconciled profile editor for photo, about, contact, and social/work links.
- `app_name/supabase/migrations/20261026100000_expand_profile_portfolio_contacts.sql`: private contact fields and private photo bucket policies from the existing temporary worktree.
- `app_name/supabase/migrations/20261028100000_add_upwork_profile_link.sql`: additive owner profile Upwork link after existing publication migration.
- `app_name/lib/features/dashboard/presentation/home_shell.dart`: profile completion reminder and Portfolio destination wiring, preserving current Desktop navigation/dashboard work.
- `app_name/lib/features/portfolio/domain/portfolio_content.dart`: profile/project/skill/education/experience/credential/achievement/evidence view models and source states.
- `app_name/lib/features/portfolio/domain/portfolio_template.dart`: light/dark template and selection model.
- `app_name/lib/features/portfolio/data/portfolio_content_repository.dart`: compose existing repositories into private preview content.
- `app_name/lib/features/portfolio/data/portfolio_site_generator.dart`: safe, polished responsive static HTML/CSS/JS, photo asset, and ZIP bundle.
- `app_name/lib/features/portfolio/presentation/portfolio_preview_screen.dart`: private profile/work preview, objective checklist, template previews, and resume entry actions.
- `app_name/lib/features/portfolio/presentation/portfolio_site_preview.dart`: selected-content review, template switch, download, publication status, confirm/publish/update/unpublish, stable URL.
- `app_name/lib/features/portfolio/data/portfolio_publication_repository.dart`: owner-checked publication orchestration and Supabase Storage/table adapter.
- `app_name/supabase/migrations/20261027100000_create_portfolio_publications.sql`: retain the migration the user says has already been applied; do not modify or rerun it.
- `app_name/lib/features/portfolio/domain/resume_content.dart`: shared factual resume model.
- `app_name/lib/features/portfolio/presentation/resume_preview_screen.dart`: ATS-friendly/photo resume previews and export actions.
- `app_name/lib/features/portfolio/data/resume_exporter.dart`: selectable-text PDF and DOCX serializers from the same model.
- `app_name/lib/features/auth/presentation/auth_gate.dart`, `app_name/lib/core/config/supabase_config.dart`: inject repositories and public-base configuration.
- `app_name/test/features/profile/`: profile serialization, migration compatibility, editor/photo/contact/upwork tests.
- `app_name/test/features/dashboard/`: profile reminder completion and navigation tests.
- `app_name/test/features/portfolio/`: content composition/readiness, site generator/privacy, preview/publish, resume model/export tests.
- `docs/supabase-setup.md`, `docs/superpowers/specs/2026-10-20-prooffolio-feature-status-and-roadmap.md`, `.superpowers/sdd/2026-10-23-prooffolio-portfolio-integration/progress.md`: update setup, roadmap, and task progress.

---

### Task 1: Reconcile profile inputs, private photo, and social/contact links

**Files:**
- Modify: `app_name/lib/features/profile/domain/profile.dart`
- Modify: `app_name/lib/features/profile/data/profile_repository.dart`
- Modify: `app_name/lib/features/profile/presentation/profile_background_screen.dart`
- Create: `app_name/supabase/migrations/20261026100000_expand_profile_portfolio_contacts.sql` (bring forward unchanged from the temporary worktree; reconcile schema only if Desktop differs)
- Create: `app_name/supabase/migrations/20261028100000_add_upwork_profile_link.sql`
- Modify: `app_name/test/features/profile/profile_test.dart`
- Modify: `app_name/test/features/profile/profile_background_screen_test.dart`
- Create or modify focused `app_name/test/features/profile/profile_photo_policy_test.dart`
- Modify: `docs/supabase-setup.md`

**Interfaces:**
- Consumes: existing `ProfileBackground`, `ProfileBackgroundRepository`, profile/background editor, and Supabase `profiles` table.
- Produces: optional `photoPath`, `contactEmail`, `phone`, `githubUrl`, `linkedInUrl`, `upworkUrl`, `jobstreetUrl`, `whatsAppNumber`, and `List<ProfileContactLink> additionalLinks`; repository photo methods `uploadProfilePhoto(String userId, Uint8List bytes, String fileName, String contentType) -> Future<String>`, `deleteProfilePhoto(String userId, String path) -> Future<void>`, `createProfilePhotoSignedUrl(String path) -> Future<String>`, and `downloadProfilePhoto(String userId, String path) -> Future<Uint8List>`; existing profile fields and editing behavior remain intact.

- [ ] **Step 1: Write failing model/repository/editor tests.** Verify all optional fields round-trip, missing optional JSON fields load as empty/null, Upwork URL normalization/validation, photo signature/type/5MB checks, existing background fields survive contact saves, and the editor labels the photo “used in your portfolio and photo resume” and “private until selected.”
- [ ] **Step 2: Run the focused tests and confirm the new assertions fail.** Run `flutter test test/features/profile/profile_test.dart test/features/profile/profile_background_screen_test.dart test/features/profile/profile_photo_policy_test.dart --no-pub` from `app_name`.
- [ ] **Step 3: Add/reconcile domain, repository, and editor support.** Port private photo upload/signed preview/replace/remove behavior and contact inputs from the temporary worktree, integrate them with Desktop's current profile UI without replacing its unrelated edits, and add optional Upwork.
- [ ] **Step 4: Add ordered additive SQL.** Keep `20261026100000_expand_profile_portfolio_contacts.sql` private and owner-scoped; create `20261028100000_add_upwork_profile_link.sql` with only the nullable `upwork_url` column/constraint needed. Do not edit the already-applied publication migration.
- [ ] **Step 5: Document exact migration order and run tests.** Include that contact/photo migration must precede the publication migration; Upwork migration follows it. Confirm all focused tests pass.

### Task 2: Add an actionable Home profile-completion reminder

**Files:**
- Modify: `app_name/lib/features/dashboard/presentation/home_shell.dart`
- Create: `app_name/lib/features/dashboard/presentation/profile_completion_reminder.dart` if extracting the reminder keeps the existing large screen maintainable.
- Modify: `app_name/test/features/dashboard/home_responsive_test.dart`
- Create: `app_name/test/features/dashboard/profile_completion_reminder_test.dart`

**Interfaces:**
- Consumes: `ProfileBackgroundRepository.loadProfile(String userId)` and saved user ID already available from `AuthGate`.
- Produces: a non-blocking reminder showing whether key portfolio/resume inputs are missing, a Profile edit action, and a completion state derived only from saved fields.

- [ ] **Step 1: Write failing widget tests.** Verify incomplete profile shows a clear “Complete your profile” reminder and opens Profile; complete profile changes/hides reminder; profile load failure does not falsely report completion; narrow viewport has no overflow.
- [ ] **Step 2: Run the focused dashboard tests and confirm failure.** Run `flutter test test/features/dashboard/profile_completion_reminder_test.dart test/features/dashboard/home_responsive_test.dart --no-pub`.
- [ ] **Step 3: Implement reminder and pass repository/user identity.** Use a simple, explained checklist over saved display name/headline/about/contact/profile photo, no employability score. Refresh it after the profile editor returns.
- [ ] **Step 4: Run focused dashboard tests and confirm pass.**

### Task 3: Integrate private portfolio composition, checklist, and navigation

**Files:**
- Create: `app_name/lib/features/portfolio/domain/portfolio_content.dart`
- Create: `app_name/lib/features/portfolio/domain/portfolio_record.dart` only if Desktop's current `PortfolioRecord` is not already the same domain type; reuse rather than duplicate otherwise.
- Create: `app_name/lib/features/portfolio/data/portfolio_content_repository.dart`
- Create: `app_name/lib/features/portfolio/presentation/portfolio_preview_screen.dart`
- Modify: `app_name/lib/features/dashboard/presentation/home_shell.dart`
- Modify: `app_name/lib/features/auth/presentation/auth_gate.dart`
- Create: `app_name/test/features/portfolio/portfolio_content_test.dart`
- Create: `app_name/test/features/portfolio/portfolio_content_repository_test.dart`
- Create: `app_name/test/features/portfolio/portfolio_preview_navigation_test.dart`

**Interfaces:**
- Consumes: existing profile, projects, skills, portfolio records, and Evidence repositories.
- Produces: `PortfolioContentRepository.loadPrivateContent(String userId) -> Future<PortfolioContent>` with independently unavailable source states; `PortfolioReadiness.evaluate(PortfolioContent) -> List<ReadinessSuggestion>` with label/explanation/coverage/destination; `PortfolioPreviewScreen` replacing the Desktop Portfolio placeholder.

- [ ] **Step 1: Write failing tests for profile mapping, mixed source failures, readiness criteria, and Portfolio tab navigation.** Assert sources that fail appear unavailable (not empty), Evidence is private-only, and checklist is descriptive/actionable rather than a career grade.
- [ ] **Step 2: Run focused tests and confirm failure.** Run `flutter test test/features/portfolio/portfolio_content_test.dart test/features/portfolio/portfolio_content_repository_test.dart test/features/portfolio/portfolio_preview_navigation_test.dart --no-pub`.
- [ ] **Step 3: Compose the view model using existing repository APIs.** Map stable IDs only into authenticated selection data; include signed photo URL and bytes via private repository calls; do not expose IDs or Evidence paths in public data.
- [ ] **Step 4: Replace only the Portfolio placeholder and wire HomeShell/AuthGate.** Preserve Desktop dashboard state and navigation; add actionable links to Profile, Projects, Skills, credentials, achievements, and Evidence.
- [ ] **Step 5: Run focused portfolio tests and confirm pass.**

### Task 4: Build the polished public site templates and preview/download

**Files:**
- Create: `app_name/lib/features/portfolio/domain/portfolio_template.dart`
- Create: `app_name/lib/features/portfolio/data/portfolio_site_generator.dart`
- Create: `app_name/lib/features/portfolio/presentation/portfolio_site_preview.dart`
- Create/reconcile: platform preview surfaces for Web iframe and native WebView if required by the Desktop app.
- Modify: `app_name/pubspec.yaml` / lock only for dependencies not already present (`archive`, WebView, web interop).
- Create: `app_name/test/features/portfolio/portfolio_site_generator_test.dart`
- Create: `app_name/test/features/portfolio/portfolio_site_preview_test.dart`

**Interfaces:**
- Consumes: `PortfolioContent`, `PortfolioSelection`, `PortfolioReadiness`.
- Produces: `PortfolioSiteGenerator.generate(PortfolioContent, PortfolioSelection, PortfolioTemplate) -> PortfolioSiteBundle`, `PortfolioSiteGenerator.previewHtml(PortfolioSiteBundle) -> String`, and `PortfolioSiteBundle.toZipBytes() -> Uint8List`.

- [ ] **Step 1: Write failing generator/privacy/design tests.** Include selected photo/contact/upwork/socials, skills, richly detailed projects, certifications, achievements, empty sections, hostile HTML, unsafe URL schemes, internal IDs, private Evidence data, both theme variants, and mobile/focus/reduced-motion stylesheet expectations.
- [ ] **Step 2: Run the focused tests to confirm failure.**
- [ ] **Step 3: Implement original light/dark site generation based on the approved mockup.** Use user content only; feature a restrained asymmetric hero/photo, clear intro, meaningful project case studies, skills, credentials/achievements, and a contact action. Escape text, permit only safe HTTP(S) links, omit empty sections, exclude Evidence and IDs, and bundle only a selected validated photo. Keep runtime self-contained.
- [ ] **Step 4: Implement preview and ZIP download.** Provide clear template switching and selected-content review; use the app's supported file save flow and distinguish cancel from failure.
- [ ] **Step 5: Run generator and preview tests; inspect both generated templates at desktop and mobile widths.**

### Task 5: Integrate live publish/update/unpublish to Supabase

**Files:**
- Create: `app_name/lib/features/portfolio/data/portfolio_publication_repository.dart`
- Bring forward unchanged unless reconciliation required: `app_name/supabase/migrations/20261027100000_create_portfolio_publications.sql`
- Modify: `app_name/lib/core/config/supabase_config.dart`
- Modify: `app_name/lib/features/auth/presentation/auth_gate.dart`
- Modify: `app_name/lib/features/dashboard/presentation/home_shell.dart`
- Modify: `app_name/lib/features/profile/presentation/profile_setup_screen.dart`
- Modify: `app_name/lib/features/portfolio/presentation/portfolio_site_preview.dart`
- Modify: `docs/supabase-setup.md`
- Create: `app_name/test/features/portfolio/portfolio_publication_repository_test.dart`
- Create: `app_name/test/features/portfolio/portfolio_site_publishing_test.dart`

**Interfaces:**
- Consumes: shared generator/bundle and owner-authenticated Supabase client.
- Produces: `PORTFOLIO_PUBLIC_BASE_URL`; `PortfolioPublicationRepository.loadStatus(String userId)`, `publish(PortfolioContent, PortfolioSelection, PortfolioTemplate)`, `updatePublished(...)`, `unpublish(String userId)`, `publicUrl(String username)`; AuthGate injection into preview.

- [ ] **Step 1: Write failing repository/UI tests.** Cover fresh snapshot comparison, owner checks, missing HTTPS config, upload/state rollback, restore on unpublish failure, explicit review before publish/update/unpublish, URL display/copy, restored active selection, private Evidence exclusion, and username-change message.
- [ ] **Step 2: Run focused tests and confirm failure.**
- [ ] **Step 3: Port/reconcile the temporary worktree publication repository and Supabase Storage adapter.** Use only fixed generated paths/allowlisted files; stage `index.html` last; short cache; rollback previous files/status on failures. Keep the publication row private and snapshot limited to generated approved content.
- [ ] **Step 4: Wire config/repository/UI.** Disable live publish without a valid HTTPS base URL, explicitly state when setup is required, require confirmation after showing the exact selection/URL, display/copy stable public URL, and explain that external copies/caches may persist on unpublish.
- [ ] **Step 5: Map publication username SQLSTATE `P0001` to clear profile editor guidance.**
- [ ] **Step 6: Document existing migration status and order without telling the user to rerun an already applied migration.** State whether profile/contact and Upwork migrations remain to be applied based on their setup.
- [ ] **Step 7: Run focused tests.** Do not execute migrations, use production Supabase, or publish real user content.

### Task 6: Add shared resume model and two previews

**Files:**
- Create: `app_name/lib/features/portfolio/domain/resume_content.dart`
- Create: `app_name/lib/features/portfolio/presentation/resume_preview_screen.dart`
- Modify: `app_name/lib/features/portfolio/presentation/portfolio_preview_screen.dart`
- Create: `app_name/test/features/portfolio/resume_content_test.dart`
- Create: `app_name/test/features/portfolio/resume_preview_screen_test.dart`

**Interfaces:**
- Consumes: `PortfolioContent`.
- Produces: `ResumeContent.fromPortfolioContent(PortfolioContent)` with profile/contact, summary, experience, education, skills, selected projects, certifications, and achievements; two preview modes `ResumeTemplate.atsFriendly` and `ResumeTemplate.standardPhoto`.

- [ ] **Step 1: Write failing tests.** Verify factual field mapping, chronological dates, omission of blank/empty sections, correct photo inclusion only in standard photo mode, accessible text-first structure, and truthful ATS caveat.
- [ ] **Step 2: Run focused tests and confirm failure.**
- [ ] **Step 3: Implement shared resume model and Portfolio resume section.** Put resume tools below website templates; permit preview before export; never invent missing content.
- [ ] **Step 4: Implement ATS-friendly one-column and standard photo previews.** Keep photo optional, conventional headings, readable hierarchy, and text extraction order.
- [ ] **Step 5: Run focused tests and confirm pass.**

### Task 7: Export selectable-text PDF and DOCX

**Files:**
- Create: `app_name/lib/features/portfolio/data/resume_exporter.dart`
- Modify: `app_name/lib/features/portfolio/presentation/resume_preview_screen.dart`
- Modify: `app_name/pubspec.yaml`, `app_name/pubspec.lock`
- Create: `app_name/test/features/portfolio/resume_exporter_test.dart`

**Interfaces:**
- Consumes: `ResumeContent` and selected `ResumeTemplate`.
- Produces: `ResumeExporter.toPdf(ResumeContent content, ResumeTemplate template) -> Future<Uint8List>` and `ResumeExporter.toDocx(ResumeContent content, ResumeTemplate template) -> Future<Uint8List>`.

- [ ] **Step 1: Write failing exporter tests.** Verify non-empty PDF/DOCX outputs, same factual sections in both formats, omission of empty sections, safe display-name filenames, photo only in standard template, PDF text extraction and multi-page flow.
- [ ] **Step 2: Run focused tests and confirm failure.**
- [ ] **Step 3: Add compatible `pdf` and `docx_dart` dependencies using the package manager after manifest changes.** Do not upgrade unrelated dependencies.
- [ ] **Step 4: Implement PDF with selectable text, standard fonts, and natural page flow; implement DOCX with normal headings, paragraphs and lists.** Use the same selected content model for both.
- [ ] **Step 5: Wire PDF and DOCX save/download actions using existing platform save support.** Sanitize filenames from display name and report save/cancel/errors accurately.
- [ ] **Step 6: Run focused export tests and confirm pass.**

### Task 8: Integrate project docs, run validation, and review

**Files:**
- Modify: `docs/supabase-setup.md`
- Modify: `docs/superpowers/specs/2026-10-20-prooffolio-feature-status-and-roadmap.md`
- Modify: `docs/superpowers/plans/2026-10-21-prooffolio-published-portfolio-and-resume.md`
- Create/update: `.superpowers/sdd/2026-10-23-prooffolio-portfolio-integration/progress.md`
- Preserve all SQL and docs from both checkouts; no other cleanup.

**Interfaces:**
- Consumes: completed Tasks 1–7.
- Produces: accurate migration/run guidance and a verified, uncommitted Desktop worktree.

- [ ] **Step 1: Update migration order, run commands, profile/publication behavior, and roadmap.** Make clear which migrations are additive and that migrations are never applied by the app.
- [ ] **Step 2: Run focused related tests and the full suite.** Record pre-existing legacy failures separately from regressions.
- [ ] **Step 3: Run `flutter analyze --no-pub`, `flutter build web --no-pub`, and `git diff --check` from the Desktop checkout.**
- [ ] **Step 4: Inspect `git status` and diff; verify no unrelated user changes were reverted, no secrets were added, all SQL/docs are present, and no generated cache/temp artifacts remain.**
- [ ] **Step 5: Request one final read-only code review of the integrated delta and address Critical/Important findings.**
- [ ] **Step 6: Report what was integrated, required migrations (never auto-run), the actual public URL setup requirement, validation evidence, and any remaining external deployment configuration. Do not claim live production hosting is ready unless the Supabase public bucket/config are actually verified by the user.**
