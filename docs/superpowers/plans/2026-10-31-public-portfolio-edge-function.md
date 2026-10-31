# Public Portfolio Edge Function Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make published portfolio URLs render existing Storage files as a website by serving them through a public Supabase Edge Function with explicit MIME types.

**Architecture:** Keep `published-portfolios` as the source for every existing portfolio file. Add a public, allowlisted `portfolio-site` function that proxies only a portfolio owner's requested file and supplies the correct response MIME type; point Flutter's configured public URL base to that function.

**Tech Stack:** Supabase Edge Functions (Deno, native `fetch`), Flutter/Dart, Supabase Storage.

**Spec:** [2026-10-31-public-portfolio-edge-function-design.md](../specs/2026-10-31-public-portfolio-edge-function-design.md)

## Global Constraints

- Keep the existing `published-portfolios` bucket and existing files; do not delete, regenerate, or republish files merely to switch the serving URL.
- Accept only lowercase usernames matching `^[a-z0-9_]{3,24}$`.
- `GET` and `HEAD` may serve only `index.html`, `styles.css`, `app.js`, and safe single-segment asset filenames matching `^[A-Za-z0-9][A-Za-z0-9._-]*\.(svg|png|jpe?g|webp|woff2?|ttf|otf)$`.
- Map `.html` to `text/html; charset=utf-8`, `.css` to `text/css; charset=utf-8`, `.js` to `application/javascript`, `.svg` to `image/svg+xml`, `.png` to `image/png`, `.jpg`/`.jpeg` to `image/jpeg`, `.webp` to `image/webp`, `.woff` to `font/woff`, `.woff2` to `font/woff2`, `.ttf` to `font/ttf`, and `.otf` to `font/otf`.
- Never put a Supabase secret or service-role key in the Flutter app or function source; the function reads only the existing public Storage bucket.
- The new base URL is `https://<project-ref>.supabase.co/functions/v1/portfolio-site`; the public URL remains `/{username}/index.html` below that base.
- Do not delete or redirect previously copied Storage URLs; explain they remain legacy links and may retain their current `text/plain` behavior.
- Do not change Flutter app authentication, package ID, Android signing, or unrelated app behavior. This public read-only delivery function intentionally has no visitor authentication.
- The initial function deployment must use the Supabase Dashboard editor; do not assume Supabase CLI is installed.

## Review Focus

- Encoded or traversal paths must not escape the validated username/file pair; the handler must reject the path without requesting Storage.
- Unsupported methods, usernames, filenames, and extensions must not be proxied.
- Missing Storage objects must produce a not-found response and must not be reported as a successful HTML page.
- `HEAD` must return the correct mapped MIME type and no response body.
- Responses must not inherit Storage's `text/plain` or restrictive CSP headers, and must use `Cache-Control: no-store`; tests belong with the function handler.

---

### Task 1: Add the Edge Function file server

**Files:**
- Create: `app_name/supabase/functions/portfolio-site/index.ts`
- Create: `app_name/supabase/functions/portfolio-site/index_test.ts`

**Interfaces:**
- Produces: `createPortfolioSiteHandler(options: { supabaseUrl: string; fetcher?: typeof fetch }): (request: Request) => Promise<Response>`, exported for tests and used by `Deno.serve` in the same file.
- The handler strips the fixed `/functions/v1/portfolio-site` route prefix, then maps exactly `/{username}/{filename}` to the public object URL `{supabaseUrl}/storage/v1/object/public/published-portfolios/{username}/{filename}`.
- Only `GET` and `HEAD` are supported. Query parameters are ignored when forming the object key.

- [ ] **Step 1: Write the failing Deno tests**

Add tests named:

1. `serves index html with an explicit html content type`
2. `maps all supported asset extensions to their response content types`
3. `returns storage 404 for a missing published file`
4. `rejects invalid usernames and unsupported filenames before fetching`
5. `rejects encoded traversal and nested paths before fetching`
6. `serves head responses without a body`
7. `rejects methods other than get and head`
8. `sets safe cache and MIME headers instead of forwarding Storage headers`

Use an injected `fetcher` to assert the exact Storage URL, provide controlled object responses, and verify MIME type, status, body, and that rejected paths make no Storage request. Cover `application/javascript`, SVG, PNG, JPG, JPEG, WebP, WOFF, WOFF2, TTF, and OTF. Use realistic function request URLs that include `/functions/v1/portfolio-site`.

- [ ] **Step 2: Run the tests and verify the expected failures**

Run: `deno test app_name/supabase/functions/portfolio-site/index_test.ts`

Expected: FAIL because the handler does not yet exist. If Deno is unavailable, install only the Deno runtime needed to execute this test; Supabase CLI is not required.

- [ ] **Step 3: Implement the self-contained function**

Export the handler factory, validate method and full function route before fetching, restrict usernames to `^[a-z0-9_]{3,24}$`, allow the exact document names plus safe single-segment assets with the supported extensions, and map each extension to the MIME types in the Global Constraints. Forward Storage not-found status as 404, return 502 for other upstream failures, do not forward its content-type or CSP headers, set `X-Content-Type-Options: nosniff` and `Cache-Control: no-store`, and omit the body for `HEAD`. Start `Deno.serve` with the built-in `SUPABASE_URL` only when `import.meta.main`; return a clear server error if that environment value is missing. Do not use any key or database.

- [ ] **Step 4: Run the tests and verify they pass**

Run: `deno test app_name/supabase/functions/portfolio-site/index_test.ts`

Expected: all eight tests pass without network access.

### Task 2: Point Flutter's public links at the function

**Files:**
- Modify: `app_name/test/features/portfolio/portfolio_publication_repository_test.dart`
- Modify: `app_name/supabase-config.example.json`

**Interfaces:**
- Consumes: the deployed function URL base supplied through `PORTFOLIO_PUBLIC_BASE_URL`.
- Produces: `publicUrl('alex_doe')` equal to `https://portfolio.example.test/functions/v1/portfolio-site/alex_doe/index.html` in the repository test fixture.

- [ ] **Step 1: Update the URL expectation**

Change the repository test fixture base to `https://portfolio.example.test/functions/v1/portfolio-site` and assert the resulting URL ends in `/alex_doe/index.html`.

- [ ] **Step 2: Run the focused repository test**

Run: `cd app_name; flutter test test/features/portfolio/portfolio_publication_repository_test.dart`

Expected: PASS, confirming the existing URL builder appends the username and `index.html` to the new function base. This task changes only the base URL configuration; no Dart URL-builder behavior is changed.

- [ ] **Step 3: Update the config example**

Set only `PORTFOLIO_PUBLIC_BASE_URL` in `app_name/supabase-config.example.json` to `https://YOUR_PROJECT_REF.supabase.co/functions/v1/portfolio-site`. Do not change URL-builder behavior or any other app configuration.

- [ ] **Step 4: Run the focused repository test and verify it passes**

Run: `cd app_name; flutter test test/features/portfolio/portfolio_publication_repository_test.dart`

Expected: all tests in that file pass, including the function URL assertion.

### Task 3: Document beginner-friendly Dashboard deployment and legacy URL behavior

**Files:**
- Modify: `docs/supabase-setup.md`

**Interfaces:**
- Consumes: the tracked function source at `app_name/supabase/functions/portfolio-site/index.ts`.
- Produces: steps a Dashboard-only user can follow to deploy the function, configure the local Flutter base URL, and open the new public link.

- [ ] **Step 1: Document the Dashboard deployment**

Provide ordered beginner steps: open the correct Supabase project; navigate to Edge Functions; create `portfolio-site` using the editor; paste the repository's `index.ts`; disable **Verify JWT** because public sites must open anonymously; deploy; change only `PORTFOLIO_PUBLIC_BASE_URL` in the local ignored `app_name/supabase-config.json` or run command; restart Flutter from `app_name`; copy the new URL from the Publishing card and open it in a new tab. State that no CLI, secret key, SQL migration, or file re-upload is needed.

- [ ] **Step 2: Explain existing publication and legacy link behavior**

State that existing published Storage files remain in place and the function serves those same bytes under the new URL. The app produces the new function URL for existing published portfolios after restart. Previously copied Storage URLs are not changed or removed and may continue to show source text.

### Task 4: Verify the integrated change

**Files:**
- No additional files.

**Interfaces:**
- Consumes: the function handler, updated public URL base, and deployment documentation from Tasks 1–3.
- Produces: verified local code and an explicit manual post-deployment check for the user's Supabase project.

- [ ] **Step 1: Run the full Flutter test suite**

Run: `cd app_name; flutter test`

Expected: all tests pass.

- [ ] **Step 2: Analyze changed Dart code**

Run: `cd app_name; dart analyze lib/features/portfolio/data/portfolio_publication_repository.dart test/features/portfolio/portfolio_publication_repository_test.dart`

Expected: no issues.

- [ ] **Step 3: Build the Flutter web application**

Run: `cd app_name; flutter build web`

Expected: build succeeds.

- [ ] **Step 4: Verify deployment manually after the user deploys**

Open `https://<project-ref>.supabase.co/functions/v1/portfolio-site/<username>/index.html`. Confirm it renders, then inspect response headers and asset requests: HTML is `text/html`, CSS is `text/css`, JavaScript is `application/javascript`, and any SVG/image/font files use their mapped MIME types. This final live check requires the user to deploy through the Dashboard and cannot be claimed from local tests.
