# Cloudflare Worker Portfolio Delivery Design

## Intent

Serve published Prooffolio websites as rendered browser pages through a
predictable username URL. Supabase Edge Functions are not suitable for this
delivery path: a live diagnostic confirmed that Supabase rewrites even a
standalone HTML response to `text/plain` and adds a sandbox Content-Security-
Policy.

## Goals

- Open a published homepage directly at `https://<worker-domain>/<username>/`.
- Serve `index.html` for the username root, plus its CSS, JavaScript, photos,
  fonts, and other supported published assets from sibling paths.
- Read the existing public `published-portfolios` bucket without changing,
  removing, or re-uploading any objects.
- Set browser-appropriate MIME and cache headers at the Worker boundary rather
  than forwarding Storage response headers.
- Use `Cache-Control: no-store` for all Worker responses so portfolio updates
  become visible without waiting for cached files to expire.
- Do not add a custom Content-Security-Policy during this migration; continue to
  set `X-Content-Type-Options: nosniff`.
- Keep the base URL configurable so a future custom domain only changes
  `PORTFOLIO_PUBLIC_BASE_URL`.
- Include routing and response tests, plus Cloudflare Dashboard deployment and
  Flutter configuration instructions.

## Non-goals

- Deploying or deleting the existing Supabase Edge Function.
- Changing Supabase schema, bucket visibility, RLS, or stored object metadata.
- Re-uploading portfolio files or adding a service-role/secret key.
- Changing portfolio generation, user identity, or username storage structure.
- Automatically deploying new portfolios to a separate static hosting bucket.

## User-approved behavior

- The visitor opens the portfolio homepage, not an app screen, Storage page,
  raw HTML source, or file download.
- The public path is `/<username>/`; the visitor need not append
  `/index.html`.
- CSS, JavaScript, images, SVG, fonts, and other supported assets load from
  sibling paths under the same username.
- Existing username validation and safe path validation remain in force.
- A `workers.dev` host is the initial default. A future custom domain must not
  require changing portfolio object paths or usernames.
- The existing Supabase function remains deployed and is not deleted as part
  of this change.

## Proposed design

Add a standalone, dependency-free Cloudflare Worker source file under
`app_name/cloudflare/portfolio-worker/`. The Worker accepts public `GET` and
`HEAD` requests, validates a single username segment and a single supported
asset filename, maps `/username/` to the stored `username/index.html`, and
fetches that object from the existing public Supabase Storage URL. It returns
the upstream bytes with an explicit MIME type and safe cache/security headers;
it does not forward upstream Content-Type or Content-Security-Policy headers.
Missing objects return 404, unsupported paths return 404 without a Storage
request, and other upstream failures return 502.

The Worker receives the public Supabase project URL through a Cloudflare
Dashboard environment variable named `SUPABASE_URL`. This is a public project
URL, not a credential. It uses no publishable, secret, or service-role key.
Asset routing uses a constrained single-segment path and a documented
extension-to-MIME map. The initial supported set must include the publisher's
current files (`index.html`, `styles.css`, `app.js`, and `portfolio-photo`
JPEG/PNG/WebP variants) as well as safe SVG, common raster image, and font
extensions. Unknown extensions are rejected rather than guessed or downloaded.

Change app URL generation to produce
`<PORTFOLIO_PUBLIC_BASE_URL>/<username>/`. The example configuration uses a
placeholder `workers.dev` origin; the actual domain is configured locally by
the user. The user can later change only this origin to a custom domain.

Update the Supabase setup documentation to explain why its Edge Function is
not the HTML website host, how to create/deploy the Worker in Cloudflare's
browser Dashboard, configure `SUPABASE_URL`, copy the `workers.dev` base URL
into the Flutter config, restart Flutter, and open the new URL. Preserve the
existing Edge Function and explain that previously copied Supabase URLs do not
change; the app displays the new Worker URL after restart without republishing.

## Validation

- Worker tests cover username-root-to-index routing, explicit index routing,
  supported asset routing and MIME types, malformed/traversal paths, missing
  files, upstream errors, and replacement of Storage response headers.
- Flutter repository tests assert that the generated public URL ends in
  `/<username>/`, with publishing UI expectations updated to match.
- Run the focused Deno tests/type-check for the Worker and focused Flutter
  tests/analyzer for changed Dart code.
- The Dashboard deployment guide includes an explicit live check for response
  status, `Content-Type: text/html`, absence of the Supabase sandbox CSP, and
  browser loading of CSS/JS/assets before any old function is retired.

## Constraints and implementation calls

- Do not edit the user's ignored `app_name/supabase-config.json`; update only
  the tracked example and document how to set the user's Worker URL locally.
- Keep the Worker deployable by pasting a single tracked source file into the
  Cloudflare Dashboard, without requiring Wrangler or a package installation.
- The Worker is an unauthenticated public file reader, constrained to the
  public bucket, validated username paths, and supported asset names.
- Do not forward the Storage Content-Security-Policy or add a new restrictive
  policy; portfolio pages must be able to load their local scripts, styles,
  images, and externally hosted fonts.
- Do not delete, redeploy, or otherwise alter the Supabase Edge Function
  during this migration. Keep the existing deployment available as a fallback
  until the Worker is deployed and verified.
