# Auto-Populated Portfolio Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preselect all available saved content in generated portfolio websites while keeping the user's full Portfolio workspace private to their signed-in account.

**Architecture:** Add a `PortfolioSelection` factory that selects non-empty, available profile fields and every saved portfolio record. Initialize new website previews with that selection; continue restoring an existing publication's saved selection. The authenticated Portfolio tab remains private and continues to display the user's saved content without exposing that account page to employers.

**Tech Stack:** Flutter, Dart, existing portfolio domain, website generator, and Flutter tests.

**Spec:** `docs/superpowers/specs/2026-10-23-prooffolio-portfolio-integration-design.md`, amended by the user's approval in this conversation: all available saved content is selected by default in generated websites, but users can deselect it before downloading or explicitly publishing.

## Global Constraints

- The Portfolio tab and profile/work records remain private to the signed-in account.
- A generated website is public only after explicit publishing; a downloaded website bundle is under the user's control to share.
- All available saved profile details and work records are selected by default; users can deselect any content before download or publication.
- Empty profile fields and unavailable data sources do not create fabricated content.
- Never include Evidence files, paths, internal record IDs, account IDs, tokens, or secrets in generated websites.
- Preserve the saved selection and template when loading an existing active publication.
- Do not change database schema or apply migrations.

## Review Focus

- Empty optional profile fields must remain unselected, while all non-empty profile/contact fields are preselected.
- Every saved project, skill, education, experience, certification, and achievement must be selected by its internal ID without exposing that ID in generated HTML.
- An unavailable content source must not fail website preview generation or be mistaken for available records.
- A valid profile photo is preselected only when its saved profile path and downloadable photo bytes are available; Evidence remains excluded.
- Existing active publications restore the owner's saved selections rather than replacing them with new defaults.

---

### Task 1: Derive a selection from saved portfolio content

**Files:**
- Modify: `app_name/lib/features/portfolio/domain/portfolio_template.dart`
- Create: `app_name/test/features/portfolio/portfolio_selection_test.dart`

**Interfaces:**
- Consumes: `PortfolioContent` and its `PortfolioSource<T>` values.
- Produces: `PortfolioSelection.allFrom(PortfolioContent content) -> PortfolioSelection`.

- [x] **Step 1: Write failing tests for `PortfolioSelection.allFrom`**

Test that non-empty profile text and contact values are selected; a photo is selected only when available photo bytes exist; all records in each available collection contribute their IDs; empty and unavailable sources contribute no selections; and Evidence is never selected.

- [x] **Step 2: Run the focused test and verify it fails**

Run from `app_name`: `flutter test test\features\portfolio\portfolio_selection_test.dart`

Expected: compilation fails because `PortfolioSelection.allFrom` is not defined.

- [x] **Step 3: Implement `PortfolioSelection.allFrom`**

Set each profile/contact boolean only when its corresponding value is non-empty. Derive record ID sets from available collections, treat unavailable collections as empty, and select the photo only when its saved profile path and downloaded bytes are available.

- [x] **Step 4: Run the focused test and verify it passes**

Run from `app_name`: `flutter test test\features\portfolio\portfolio_selection_test.dart`

Expected: all selection tests pass.

### Task 2: Start new website previews with all saved content selected

**Files:**
- Modify: `app_name/lib/features/portfolio/presentation/portfolio_site_preview.dart`
- Modify: `app_name/test/features/portfolio/portfolio_site_preview_test.dart`
- Modify: `app_name/test/features/portfolio/portfolio_site_publishing_test.dart`
- Verify: `app_name/test/features/portfolio/portfolio_preview_navigation_test.dart`

**Interfaces:**
- Consumes: `PortfolioSelection.allFrom(PortfolioContent content)` from Task 1.
- Produces: New website previews and downloads that include all available saved content initially, with existing checkbox controls and publication confirmation preserved.

- [x] **Step 1: Update preview and publishing tests**

Assert that a new preview starts with all available profile and contact choices and all saved record IDs selected; its generated HTML contains every saved item but no Evidence or internal IDs; unchecking an item removes it from generated HTML; publishing still requires confirmation; and loading an active publication restores its saved selection.

- [x] **Step 2: Run the focused tests and verify expected failures**

Run from `app_name`: `flutter test test\features\portfolio\portfolio_site_preview_test.dart test\features\portfolio\portfolio_site_publishing_test.dart`

Expected: default-selection assertions fail before the integration change.

- [x] **Step 3: Initialize new preview selection from saved content**

In `PortfolioSitePreview.initState`, initialize `_selection` with `PortfolioSelection.allFrom(widget.content)`. Keep `_loadPublicationStatus` restoring `_publication.selection` for an active publication. Replace the “nothing is selected” copy with a clear note that saved details are preselected, can be removed from the preview, and downloaded files can be shared by the user; live publishing requires explicit confirmation.

- [x] **Step 4: Run the focused portfolio tests**

Run from `app_name`: `flutter test test\features\portfolio\portfolio_selection_test.dart test\features\portfolio\portfolio_site_preview_test.dart test\features\portfolio\portfolio_site_publishing_test.dart test\features\portfolio\portfolio_preview_navigation_test.dart`

Expected: all tests pass, including the existing check that the signed-in user's Portfolio destination is a private preview rather than a public-site status page.

### Task 3: Validate the integrated change

**Files:**
- Verify: `app_name` Flutter sources and tests.

**Interfaces:**
- Consumes: Tasks 1 and 2.
- Produces: Verified behavior without schema changes.

- [x] **Step 1: Run portfolio tests**

Run from `app_name`: `flutter test test\features\portfolio`

Expected: all portfolio tests pass.

- [x] **Step 2: Run static analysis**

Run from `app_name`: `flutter analyze`

Expected: `No issues found!`

- [x] **Step 3: Check patch formatting**

Run from the repository root: `git diff --check`

Expected: exit code 0.
