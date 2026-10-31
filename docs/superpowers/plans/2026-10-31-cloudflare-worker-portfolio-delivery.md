# Cloudflare Worker Portfolio Delivery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Serve existing published portfolios as rendered websites at `https://<worker-domain>/<username>/` through a Cloudflare Worker.

**Architecture:** A dependency-free Worker validates username and asset paths, fetches files from the existing public Supabase Storage bucket, and returns bytes with explicit MIME and no-store headers. Flutter generates the username-root URL from `PORTFOLIO_PUBLIC_BASE_URL`; Dashboard instructions configure the Worker without changing existing Storage objects or the deployed Supabase function.

**Tech Stack:** Cloudflare Workers module API, TypeScript/Web APIs, Deno tests, Flutter/Dart tests.

**Spec:** `docs/superpowers/specs/2026-10-31-cloudflare-worker-portfolio-delivery-design.md`

## Global Constraints

- Keep the existing public `published-portfolios` bucket and every existing object unchanged.
- Do not re-upload portfolio files or change object metadata.
- Do not use a Supabase secret or service-role key.
- Use the existing username validation and reject unsafe/nested file paths.
- Use `/<username>/` for public portfolio URLs and serve `index.html` at that path.
- Use `Cache-Control: no-store` for Worker responses.
- Do not forward Storage Content-Security-Policy or add a custom Content-Security-Policy.
- Keep the existing Supabase Edge Function deployed and unchanged.
- Make the Worker pasteable as one tracked source file in the Cloudflare Dashboard; do not require Wrangler.
- Leave all changes uncommitted.

## Review Focus

- A username URL without its trailing slash must not make relative assets resolve outside the portfolio; redirect it to `/<username>/`.
- Encoded traversal, repeated separators, nested paths, malformed usernames, and malformed filenames must return 404 without a Storage fetch.
- Unknown file extensions must not be fetched or returned as generic downloads.
- A missing Storage object must remain 404; upstream failures must return 502 without leaking upstream response bodies.
- Upstream `text/plain` and sandbox CSP headers must not override mapped MIME types or appear in Worker responses.

---

### Task 1: Add the Cloudflare Worker and routing tests

**Files:**
- Create: `app_name/cloudflare/portfolio-worker/index.ts`
- Create: `app_name/cloudflare/portfolio-worker/index_test.ts`

**Interfaces:**
- Produces `export type PortfolioWorkerEnv = { SUPABASE_URL: string }`.
- Produces `export function createPortfolioWorkerHandler(options?: { fetcher?: typeof fetch }): (request: Request, env: PortfolioWorkerEnv) => Promise<Response>`.
- Produces a default Cloudflare module export with a `fetch(request, env)` handler that uses the factory.
- Supports GET and HEAD for `/username/`, `/username/index.html`, and supported single-segment asset names.

- [x] **Step 1: Write failing tests** named `serves the username root as index.html`, `redirects a username path without a trailing slash`, `serves explicit index and sibling assets`, `maps supported asset extensions to MIME types`, `rejects invalid and nested paths before fetching`, `rejects unknown asset extensions before fetching`, `returns 404 for missing Storage objects`, `returns 502 for Storage failures`, `rejects unsupported methods`, `returns 500 for invalid Worker configuration`, `does not forward Storage MIME or CSP headers`, and `serves HEAD without a body`.
  Assert Storage URLs use `/storage/v1/object/public/published-portfolios/<username>/<filename>`, root requests map to `index.html`, CSS/JS and image/SVG/font fixtures receive the expected MIME types, invalid paths cause no fetch, and all successful/error Worker responses use `Cache-Control: no-store`. Use a fake fetcher returning bodies with deliberately incorrect `text/plain` and sandbox CSP headers.
- [x] **Step 2: Run tests to verify they fail**

  Run in PowerShell: `& "$env:LOCALAPPDATA\Microsoft\WinGet\Links\deno.exe" test app_name/cloudflare/portfolio-worker/index_test.ts`

  Expected: FAIL because the Worker module and factory do not exist.
- [x] **Step 3: Implement the Worker**

  In `index.ts`, validate the public `SUPABASE_URL` environment value as an HTTPS URL; accept usernames matching `^[a-z0-9_]{3,24}$`; allow only a single safe filename segment; map `/username/` and `/username/index.html` to `index.html`; and redirect `/username` to `/username/`. Set these exact MIME types: `index.html` to `text/html; charset=utf-8`, `styles.css` to `text/css; charset=utf-8`, `app.js` to `application/javascript`, `.svg` to `image/svg+xml`, `.png` to `image/png`, `.jpg`/`.jpeg` to `image/jpeg`, `.webp` to `image/webp`, `.woff` to `font/woff`, `.woff2` to `font/woff2`, `.ttf` to `font/ttf`, and `.otf` to `font/otf`. Asset filenames must match `^[A-Za-z0-9][A-Za-z0-9._-]*$`; `index.html` is the only supported HTML file. Reject unsupported names/extensions before fetching. Fetch from the public bucket with the incoming GET/HEAD method, return 404 for missing objects, 502 for other non-success responses, 405 with `Allow: GET, HEAD` for other methods, and 500 for invalid/missing Worker configuration. Return the upstream body with only explicit `Content-Type`, `Cache-Control: no-store`, and `X-Content-Type-Options: nosniff` headers. Do not forward upstream CSP or other headers.
- [x] **Step 4: Run Worker tests and type-check**

  Run in PowerShell: `& "$env:LOCALAPPDATA\Microsoft\WinGet\Links\deno.exe" check app_name/cloudflare/portfolio-worker/index.ts app_name/cloudflare/portfolio-worker/index_test.ts`

  Run in PowerShell: `& "$env:LOCALAPPDATA\Microsoft\WinGet\Links\deno.exe" test app_name/cloudflare/portfolio-worker/index_test.ts`

  Expected: type-check succeeds and all Worker tests pass.

### Task 2: Generate username-root portfolio URLs in Flutter

**Files:**
- Modify: `app_name/lib/features/portfolio/data/portfolio_publication_repository.dart`
- Modify: `app_name/test/features/portfolio/portfolio_publication_repository_test.dart`
- Modify: `app_name/test/features/portfolio/portfolio_site_publishing_test.dart`
- Modify: `app_name/supabase-config.example.json`

**Interfaces:**
- Consumes the existing `PORTFOLIO_PUBLIC_BASE_URL` setting as the Worker origin.
- Preserves `String publicUrl(String username)` and its current username validation.
- Produces `<base>/<lowercase-username>/`, with exactly one trailing slash and no `index.html`.

- [x] **Step 1: Update URL tests to expect a Worker username-root URL**

  Assert a base of `https://portfolio.example.test` produces
  `https://portfolio.example.test/alex_doe/`, including when the configured base
  has one trailing slash. Update the publishing UI tests to assert that the
  shared site URL ends in `/alex_doe/`.
- [x] **Step 2: Run focused Flutter tests to verify the URL expectation fails**

  Run from `app_name`: `flutter test test/features/portfolio/portfolio_publication_repository_test.dart test/features/portfolio/portfolio_site_publishing_test.dart`

  Expected: FAIL because the repository currently appends `/index.html`.
- [x] **Step 3: Update `publicUrl` and the tracked example configuration**

  Make `publicUrl` return `<base>/<slug>/` and change its configuration error
  text to refer to the public portfolio Worker base URL. Set the example
  `PORTFOLIO_PUBLIC_BASE_URL` to a clear Cloudflare `workers.dev` placeholder
  such as `https://prooffolio-portfolio.YOUR_SUBDOMAIN.workers.dev`; do not
  edit the ignored local `app_name/supabase-config.json`.
- [x] **Step 4: Run focused Flutter tests and analysis**

  Run from `app_name`: `flutter test test/features/portfolio/portfolio_publication_repository_test.dart test/features/portfolio/portfolio_site_publishing_test.dart`

  Run from `app_name`: `flutter analyze lib/features/portfolio/data/portfolio_publication_repository.dart test/features/portfolio/portfolio_publication_repository_test.dart test/features/portfolio/portfolio_site_publishing_test.dart`

  Expected: tests pass and analysis reports no issues.

### Task 3: Document Cloudflare Dashboard deployment and migration

**Files:**
- Modify: `docs/supabase-setup.md`
- Reference: `app_name/cloudflare/portfolio-worker/index.ts`
- Reference: `app_name/supabase-config.example.json`

**Interfaces:**
- Consumes the Worker module created in Task 1 and the URL behavior from Task 2.
- Documents the Worker variable `SUPABASE_URL` as a public project URL, not a secret.
- Preserves the existing Supabase function deployment; it must not be deleted or changed.

- [x] **Step 1: Replace the live-publishing instructions**

  Explain the observed Supabase Edge Function HTML rewrite and make Cloudflare
  Worker the recommended website delivery origin. Give exact browser Dashboard
  steps to create a Worker, paste the tracked single-file module, deploy it,
  add the non-secret `SUPABASE_URL` variable, enable its `workers.dev` URL, and
  verify the Worker remains publicly accessible without a Supabase key.
- [x] **Step 2: Document app configuration and end-to-end live verification**

  Give the exact PowerShell/config steps to set
  `PORTFOLIO_PUBLIC_BASE_URL` to the Worker origin and restart Flutter. Verify
  `/<username>/` returns HTML with `Content-Type: text/html`, no sandbox CSP,
  and that CSS, JavaScript, and image/font assets load. State that existing
  Storage objects need no republish; the app displays the new URL after
  restart, while previously copied Supabase URLs do not change. Explain that
  moving to a custom domain later requires only changing the base URL.
- [x] **Step 3: Review the final diff and test coverage**

  Confirm no edits were made to `app_name/supabase-config.json`, the Storage
  bucket/objects, or the Supabase Edge Function source/deployment. Run the
  commands from Tasks 1 and 2; report exact results and provide the deployment
  steps to the user before they deploy.
