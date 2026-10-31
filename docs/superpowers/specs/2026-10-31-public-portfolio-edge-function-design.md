# Public portfolio delivery through an Edge Function

## Intent

Published portfolio links should open as rendered websites in a browser, matching the generated live preview. The current public Storage URL returns the uploaded HTML body as `text/plain`, so browsers display its source instead. Re-uploading changes the object but has not corrected the response type.

The user chose a Supabase Edge Function as the serving approach and has not deployed functions before. Prefer a Dashboard-based first deployment and provide clear steps; do not require the Supabase CLI for the initial rollout.

## Goals

- Serve published HTML as `text/html; charset=utf-8`.
- Serve the site's CSS, JavaScript, SVG, raster images, and font assets with their proper MIME types.
- Keep publication data and assets in the existing public `published-portfolios` Storage bucket.
- Use a public URL that works when pasted into a new browser tab, without authentication.
- Keep the deployment source in the repository and explain how to deploy and configure it through the Supabase Dashboard.
- Make the current public URL base configurable so the app can generate the new Edge Function URL.

## Non-goals

- Changing portfolio generation, selection, publication status, or Storage upload behavior.
- Moving assets or portfolio records out of Supabase.
- Adding a custom domain, a database migration, or a service-role key to the Flutter app.
- Automatically deploying to the user's Supabase project from this workspace.

## Design

Add a dependency-free function at `app_name/supabase/functions/portfolio-site/index.ts`. It accepts public `GET` and `HEAD` requests at `/functions/v1/portfolio-site/{username}/{file}`, fetches the corresponding object from the existing public Storage bucket, and returns it with a MIME type selected by an extension allowlist.

Accept only lowercase usernames matching `^[a-z0-9_]{3,24}$`. Permit only the exact generated document names (`index.html`, `styles.css`, and `app.js`) and safe, single-segment asset filenames matching `^[A-Za-z0-9][A-Za-z0-9._-]*\.(svg|png|jpe?g|webp|woff2?|ttf|otf)$`. Reject nested paths, traversal segments, and all other extensions. Ignore query parameters when building Storage object paths.

Map extensions to response types:

- `.html` → `text/html; charset=utf-8`
- `.css` → `text/css; charset=utf-8`
- `.js` → `application/javascript`
- `.svg` → `image/svg+xml`
- `.png` → `image/png`
- `.jpg` and `.jpeg` → `image/jpeg`
- `.webp` → `image/webp`
- `.woff` → `font/woff`
- `.woff2` → `font/woff2`
- `.ttf` → `font/ttf`
- `.otf` → `font/otf`

The current generator writes `index.html`, `styles.css`, `app.js`, and an optional JPEG, PNG, or WebP profile photo. Its font links currently reference Google Fonts; local fonts and SVGs are not currently generated. The function nevertheless maps SVG and local font files correctly if they are present in a published folder.

Do not make this a general-purpose URL proxy. Return a clear 404 for unknown paths or missing objects. Do not forward the Storage response's content type or its restrictive CSP header; set the response headers needed for correct rendering and use `Cache-Control: no-store` so updates are not hidden by cached HTML.

The function derives the project Storage URL from Supabase's built-in `SUPABASE_URL` environment variable and reads only from the public bucket. It needs no secret or service-role key and performs no database access.

Set `PORTFOLIO_PUBLIC_BASE_URL` to:

`https://<project-ref>.supabase.co/functions/v1/portfolio-site`

The existing URL builder will then produce `/{username}/index.html`. Relative requests for CSS, JavaScript, images, SVGs, and fonts remain beneath the same function path and are served by the allowlisted route.

Existing published files do not need to be deleted, regenerated, or republished merely to change the serving URL; the function streams files already in Storage. After the app restarts with the new base URL, the Publishing card generates the function URL for existing publications. Previously copied Storage URLs are not changed or removed; they remain legacy links and may still display source text because their Storage response metadata remains unchanged.

## Dashboard deployment and setup

1. Deploy the repository's function source from Supabase Dashboard → Edge Functions using the editor.
2. Name the function `portfolio-site` and disable **Verify JWT**, because anonymous visitors must be able to open public portfolios.
3. Configure the Flutter app's `PORTFOLIO_PUBLIC_BASE_URL` to the function URL above in `app_name/supabase-config.json` or the run command, then restart the app.
4. Copy the new URL from the Publishing card and open it in a new tab.
5. To update the function later, paste the tracked source into the Dashboard editor and deploy the updated function.

The function source remains the version-controlled source of truth. No credentials are added to source or shared with the client.

## Validation

- Function tests cover supported routes and MIME types, rejection of disallowed usernames/files, `GET`/`HEAD`, and missing Storage objects.
- Flutter tests verify that the configured function base produces the expected public link.
- Verify the deployed `index.html` response reports `Content-Type: text/html` and renders; verify CSS, JavaScript, SVG, supported raster image, and supported font responses use their mapped MIME types.
- Run the existing Flutter tests and web build.

## Open implementation choices

Use the platform-provided `SUPABASE_URL`, `Deno.serve`, and native `fetch`; keep the function self-contained. No CLI, package dependency, migration, or additional secret is needed for the initial Dashboard deployment.
