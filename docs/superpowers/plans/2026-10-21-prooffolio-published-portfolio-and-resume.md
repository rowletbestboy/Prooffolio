# Prooffolio Portfolio, Publishing, and Resume Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Replace the Portfolio placeholder with a private portfolio builder, optional public website publishing, and ATS-friendly PDF/DOCX resume exports.

**Architecture:** Extend the existing profile repository and private profile schema first. Build a portfolio view model from existing repositories, then use a deterministic HTML generator for both local downloads and published static files in a dedicated public Storage bucket. Keep publication selection private in an owner-only table; public visitors can only fetch the generated website files. Produce PDF and DOCX files from one resume view model.

**Tech Stack:** Flutter/Dart, Supabase Postgres/Storage, HTML/CSS/JavaScript, `pdf` for PDF output, `docx_dart` for DOCX output, existing `file_picker` for image selection.

**Spec:** `docs/superpowers/specs/2026-10-21-prooffolio-published-portfolio-and-resume-design.md`

## Global Constraints

- Follow the user-approved order: profile photo/contact links; private preview/advisory meter; light/dark site preview/download/publish; resume preview and PDF/DOCX.
- No public-by-default fields, fabricated profile content, employability claims, or universal ATS approval claim.
- Keep private profile, records, and evidence owner-only. Anonymous reads may return only a user's explicitly approved published snapshot and publication assets.
- Treat live publications as explicit snapshots; private edits do not publish until the user reviews and updates the site.
- Never include tokens, service keys, internal record IDs, unselected data, or private Evidence files in generated sites.
- Preserve prior uncommitted changes; do not reset or clean the shared checkout.
- Do not change the existing Evidence migration or ask the user to run it again. Add later migrations in sequence.

## Review Focus

- Image selection on web and mobile: bad MIME type, oversized file, cancel, and failed upload leave the existing photo intact.
- Empty and partial profiles: preview and readiness suggestions omit missing content and remain useful.
- HTML content: hostile markup and unsafe link protocols render as inert text or are rejected.
- Publication privacy: anonymous access cannot retrieve unselected or private rows/files; unpublish removes access to the current snapshot.
- Long resumes: descriptions wrap and flow across pages without truncating content or making text non-selectable.

## Phase 1 — Profile photo and contact links

### Task 1: Extend profile schema and repository contract

**Files:**
- Create: `app_name/supabase/migrations/20261026100000_expand_profile_portfolio_contacts.sql`
- Modify: `app_name/lib/features/profile/domain/profile.dart`
- Modify: `app_name/lib/features/profile/data/profile_repository.dart`
- Modify: `docs/supabase-setup.md`

**Interfaces:**
- Add optional `photoPath`, `contactEmail`, `phone`, `githubUrl`, `linkedInUrl`, `jobstreetUrl`, `whatsAppNumber`, and `additionalLinks` to `ProfileBackground`.
- `additionalLinks` is `List<ProfileContactLink>`, where `ProfileContactLink` has `label` and `url` strings.
- `ProfileBackground.toDatabaseFields()` and `fromJson()` round-trip all new values.
- Extend `ProfileBackgroundRepository` with `uploadProfilePhoto(String userId, Uint8List bytes, String fileName, String contentType) -> Future<String>` and `deleteProfilePhoto(String userId, String path) -> Future<void>`.

- [ ] Add nullable profile columns for contact values and JSONB labeled links; keep existing RLS unchanged and add a private `profile-photos` bucket with per-user object policies and MIME/size restrictions.
- [ ] Implement repository read/write and private bucket upload/removal, using owner-scoped paths and preserving the current image if a replacement fails.
- [ ] Document migration order after Evidence and explain that profile photos remain private until a published copy is created.
- [ ] Run `dart analyze` from `app_name`; expected: no issues.

### Task 2: Add photo and contact editing UI

**Files:**
- Modify: `app_name/lib/features/profile/presentation/profile_background_screen.dart`
- Modify: `app_name/lib/features/profile/presentation/profile_setup_screen.dart` only if profile entry point needs a link
- Modify: `app_name/lib/features/profile/data/profile_repository.dart` if adapter methods are needed

**Interfaces:**
- Add optional `ProfilePhotoPicker` interface returning selected filename, MIME type, and bytes; production adapter uses the existing `file_picker` dependency.
- Profile form saves contact fields through the profile repository; all remain optional.

- [ ] Add photo picker, preview, remove/replace actions, and the specified professional-photo disclaimer explaining that the image will appear on the web portfolio.
- [ ] Add email, phone, GitHub, LinkedIn, JobStreet, WhatsApp, and repeatable labeled-link fields with validation/normalization and visible optional labels.
- [ ] Handle cancellation, invalid type/size, network failure, and success without discarding other unsaved form values.
- [ ] Run `dart analyze` from `app_name`; expected: no issues.

## Phase 2 — Private portfolio preview and advisory meter

### Task 3: Create a portfolio content view model and builder

**Files:**
- Create: `app_name/lib/features/portfolio/domain/portfolio_content.dart`
- Create: `app_name/lib/features/portfolio/data/portfolio_content_repository.dart`
- Modify: `app_name/lib/features/dashboard/presentation/home_shell.dart`

**Interfaces:**
- `PortfolioContent` contains profile identity/contact/photo, project, skill, education, experience, credential, achievement, and evidence view data without database IDs.
- `PortfolioContent` uses typed lists for projects, skills, education, experience, records, and evidence; Evidence contributes to private preview/readiness only.
- `PortfolioContentRepository.loadPrivateContent(String userId)` composes profile and existing repositories; sources that fail independently expose unavailable state instead of synthetic values.
- `PortfolioReadiness.evaluate(PortfolioContent)` returns `List<ReadinessSuggestion>`; each item has `label`, `explanation`, `isCovered`, and `destination`. It must not assign an employability grade.

- [ ] Compose content from existing repositories, omitting blank fields and isolating source failures.
- [ ] Implement deterministic advisory criteria and explanations for profile basics, project detail, skills, evidence, and contact options.
- [ ] Replace the Portfolio placeholder with a private, scrollable preview, readiness summary, and direct links to edit/add relevant inputs.
- [ ] Run `dart analyze` from `app_name`; expected: no issues.

## Phase 3 — Web templates, download, and publishing

### Task 4: Generate safe light/dark static websites

**Files:**
- Create: `app_name/lib/features/portfolio/domain/portfolio_template.dart`
- Create: `app_name/lib/features/portfolio/data/portfolio_site_generator.dart`
- Create: `app_name/lib/features/portfolio/presentation/portfolio_site_preview.dart`
- Modify: `app_name/pubspec.yaml` for archive/download support if required

**Interfaces:**
- `PortfolioTemplate.light` and `.dark` select the two named visual variants.
- `PortfolioSiteBundle` contains a map of relative file paths to bytes, including `index.html`, `styles.css`, `app.js`, and an optional selected photo asset.
- `PortfolioSiteGenerator.generate(PortfolioContent content, PortfolioSelection selection, PortfolioTemplate template) -> PortfolioSiteBundle`.
- `PortfolioSelection` contains `includePhoto`, per-channel contact booleans, and selected sets of project, skill, education, experience, certification, and achievement IDs. IDs are used only in the authenticated app and are stripped from generated output. Evidence remains private and is never bundled.

- [ ] Build two distinct responsive templates from the same selected content, with no external runtime dependencies.
- [ ] Escape all user text and allow only HTTP/HTTPS URLs in generated anchors; never inject user HTML/JavaScript.
- [ ] Add an in-app live preview that renders the selected generated page, and actions to switch light/dark variants.
- [ ] Package and download the generated files as one ZIP bundle using the app's supported file-download flow.
- [ ] Run `dart analyze` from `app_name`; expected: no issues.

### Task 5: Store publication snapshots and publish/unpublish

**Files:**
- Create: `app_name/supabase/migrations/20261027100000_create_portfolio_publications.sql`
- Create: `app_name/lib/features/portfolio/data/portfolio_publication_repository.dart`
- Modify: `app_name/lib/features/portfolio/presentation/portfolio_site_preview.dart`
- Modify: `docs/supabase-setup.md`

**Interfaces:**
- `PortfolioPublicationRepository.loadStatus(String userId)`, `publish(PortfolioContent content, PortfolioSelection selection, PortfolioTemplate template)`, `updatePublished(...)`, and `unpublish(String userId)`.
- A private publication row stores owner ID, unique username slug, active state, selected content snapshot, template, and publish timestamps. It contains only selected fields/records and no private evidence object paths.
- `PORTFOLIO_PUBLIC_BASE_URL` points to a dedicated public `published-portfolios` Storage bucket; public URLs follow `<base>/<username>/index.html`.

- [ ] Add an owner-only publication table and a dedicated public Storage bucket containing only generated static website files. Keep existing private table and Evidence bucket policies unchanged. The bucket is intentionally public for reads; inserts/deletes must be limited by RLS to the signed-in owner's username folder.
- [ ] Implement publish/update as an authenticated repository flow: reload records as the owner, validate selection and link protocols, generate the approved snapshot with the shared safe generator, upload only that bundle to `<username>/`, then save the private publication state. Roll back partial uploads if the state save fails.
- [ ] Implement unpublish by deleting only the owner's website files and deactivating the private publication row. Never copy Evidence objects; copy the profile photo into the public site bundle only when selected.
- [ ] If a user attempts to change their username while a publication is active, explain that they must unpublish first; this prevents a stale public username URL.
- [ ] Set short cache lifetimes on generated objects and delete every object in the user's published folder on unpublish; explain that copies or cached versions outside Prooffolio may persist.
- [ ] Add explicit public-content review, off-by-default contact selections, stable URL display/copy, update snapshot action, and unpublish confirmation.
- [ ] Document the migration, public bucket behavior, and `PORTFOLIO_PUBLIC_BASE_URL` configuration; state that a configured public base URL is required before live publication can work. No service-role key is needed in Flutter.
- [ ] Run `dart analyze` from `app_name`; expected: no issues.

## Phase 4 — Resume/CV generator and exports

### Task 6: Build a shared resume view model and preview

**Files:**
- Create: `app_name/lib/features/portfolio/domain/resume_content.dart`
- Create: `app_name/lib/features/portfolio/presentation/resume_preview_screen.dart`
- Modify: `app_name/lib/features/dashboard/presentation/home_shell.dart`

**Interfaces:**
- `ResumeContent.fromPortfolioContent(PortfolioContent)` produces standard sections: contact, summary, experience, education, skills, projects, credentials, and achievements.
- Empty optional sections are omitted; no data is synthesized.

- [ ] Add a text-first, one-column resume preview at the bottom of Portfolio, with standard headings and chronological dates.
- [ ] Add copy explaining “ATS-friendly format” and why no universal ATS approval is claimed.
- [ ] Run `dart analyze` from `app_name`; expected: no issues.

### Task 7: Export PDF and DOCX files

**Files:**
- Create: `app_name/lib/features/portfolio/data/resume_exporter.dart`
- Modify: `app_name/pubspec.yaml` and `app_name/pubspec.lock`
- Modify: `app_name/lib/features/portfolio/presentation/resume_preview_screen.dart`

**Interfaces:**
- `ResumeExporter.toPdf(ResumeContent) -> Future<Uint8List>` and `toDocx(ResumeContent) -> Future<Uint8List>`.
- Use the `pdf` package for selectable-text PDF and `docx_dart` for standard DOCX paragraphs/headings; use a platform-appropriate save/download mechanism without changing resume content between formats.

- [ ] Implement multi-page PDF with text flow, standard fonts, and no image-rendered text or decorative tables.
- [ ] Implement DOCX with Word heading styles, paragraphs, and lists only; omit empty optional sections.
- [ ] Add PDF and DOCX export actions with filenames based on the display name, sanitized for filesystem use.
- [ ] Run `dart analyze` from `app_name`; expected: no issues.

## Final review

- [ ] Walk through the four phases in order using a real signed-in account and the configured Supabase project.
- [ ] Confirm anonymous publication access returns only the selected snapshot and is unavailable after unpublish.
- [ ] Inspect downloaded website ZIP, PDF, and DOCX outputs for missing sections, unsafe markup, exposed private data, and selectable text.
- [ ] Run `dart analyze` from `app_name` and `git diff --check` from the repository root; resolve all reported issues.
