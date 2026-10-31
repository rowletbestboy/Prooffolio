# Supabase setup for Prooffolio

This guide creates a development Supabase project and connects the Flutter app using its public client values. You do not need to share a password, secret key, or service-role key with me.

## 1. Create a project

1. Sign in to the Supabase dashboard and create a new project named `Prooffolio`.
2. Choose a database password and save it in your password manager. The Flutter app does not need this password.
3. Choose a region close to your expected users and wait until the project is ready.
4. Open **Project Settings ? API Keys** (or **Connect**, depending on the dashboard view). Copy the **Project URL** and the **Publishable key** (`sb_publishable_...`).

The publishable key is designed for mobile clients and is safe to ship with a properly secured database. Never copy a `secret` or legacy `service_role` key into Flutter; those bypass Row Level Security.

## 2. Configure email sign-in

1. Open **Authentication ? Sign In / Providers ? Email**.
2. Enable email/password sign-in.
3. Keep email confirmation enabled for production. For development, either confirm each test account or temporarily disable confirmation in the project dashboard. When confirmation is enabled, account creation can succeed without immediately creating an active session.
4. In **Authentication ? URL Configuration**, set the Site URL to a real web URL you control when available. For local development, use the project's default URL if the dashboard requires a value.
5. Add the mobile callback URL to **Redirect URLs**: `com.prooffolio.app://login-callback/`. This matches the current Android application ID. Keep that ID stable after publishing.

Supabase email confirmation and password recovery links need a configured redirect destination. The Android app has a matching deep-link intent filter; confirmation and recovery callbacks use the URI above.

## 3. Run the Flutter app with client configuration

Before running the connected app, open **SQL Editor → New query** in Supabase, paste the contents of `app_name/supabase/migrations/20261020170000_create_profiles.sql`, and run it. This creates the initial profile table and owner-only Row Level Security policies required by the session gate. The migration can be run again safely if it has already created the table and policies.

To use the Projects tab, run the next migration too: paste `app_name/supabase/migrations/20261021100000_create_projects.sql` into a new SQL Editor query and run it. It creates the owner-only project table and policies. Projects stay private drafts; public access is not enabled by this migration.

To use the Skills tab and connect skills to projects, run `app_name/supabase/migrations/20261022100000_create_skills_and_project_skills.sql` the same way. It creates private skill records, project links that require both records to belong to the signed-in user, and the `save_skill_with_projects` function used to save each skill and its links together.

To add inclusive profile details and broad occupation categories, run `app_name/supabase/migrations/20261023100000_expand_profile_and_skills.sql` after the first three migrations. It adds optional profile background fields and private education and experience records, then maps existing technology-specific skill categories to Technology and digital work while preserving skill names, proficiency labels, and project links. Apply the migrations in this order: profiles, projects, skills, then inclusive profile and skills expansion. Existing profile identity fields remain unchanged. All background questions are optional, and experience supports volunteer, community, caregiving, freelance, and independent work.

To add certifications and achievements, run `app_name/supabase/migrations/20261024100000_create_portfolio_records.sql` after the previous migration. It creates one private, owner-only record table for certifications and achievements. Both can be added without a project; certification expiration dates are optional. A user may explicitly select these records for a generated public portfolio; attached Evidence files remain private and are never included.

To add the shared Evidence library, run `app_name/supabase/migrations/20261025100000_create_evidence.sql` after the portfolio-record migration. It creates private evidence metadata and owner-checked links to projects, skills, experience, certifications, and achievements. It also creates the private `evidence` Storage bucket and per-user object policies. Apply migrations in order: profiles, projects, skills, inclusive profile and skills expansion, portfolio records, then evidence. See [the Evidence schema](evidence-schema.md) for the relationship diagram and ownership behavior.

To add private portfolio profile contacts and photos, run `app_name/supabase/migrations/20261026100000_expand_profile_portfolio_contacts.sql` after Evidence and before the portfolio-publication migration. It adds optional contact/social fields and a private `profile-photos` bucket. The profile photo remains private until a user explicitly selects it for a portfolio or photo resume.

Live portfolio publishing is implemented in the app. The user reports that `app_name/supabase/migrations/20261027100000_create_portfolio_publications.sql` has already been run in their Supabase project; verify migration history before taking any action and do not rerun it automatically. It creates the private publication table and the public `published-portfolios` Storage bucket, whose public objects contain only generated website files. Apply `app_name/supabase/migrations/20261028100000_add_upwork_profile_link.sql` after it if the Upwork profile URL is needed and the migration is not already applied. The order is: profile contacts/photos (`20261026100000`), portfolio publications (`20261027100000`), then Upwork (`20261028100000`). The app does not apply migrations.

Live portfolio websites are served through a Cloudflare Worker, which reads the existing public `published-portfolios` files from Supabase Storage. Supabase Edge Functions were tested with a standalone HTML response and transformed it into `text/plain` with a sandbox Content-Security-Policy, so they cannot reliably serve the portfolio as a browser-rendered site. The existing `portfolio-site` function is not deleted or changed by this migration; leave it deployed until the Worker is deployed and verified.

The Worker serves the homepage at `https://<worker-domain>/<username>/` and serves supported files such as CSS, JavaScript, images, SVG, and fonts from sibling paths. It sets response MIME types itself, does not forward the Storage sandbox policy, and uses no Supabase secret or service-role key. It reads existing public objects only: no bucket change, SQL migration, metadata update, or file re-upload is needed.

### Deploy the portfolio Worker through the Cloudflare Dashboard

1. Sign in to the [Cloudflare Dashboard](https://dash.cloudflare.com/) and open **Workers & Pages**.
2. Select **Create application**, then choose the option to create a Worker from the dashboard (the starter may be labeled **Hello World**). Give it a name such as `prooffolio-portfolio` and deploy the starter Worker. Cloudflare assigns a `workers.dev` URL such as `https://prooffolio-portfolio.<your-subdomain>.workers.dev`.
3. Open the new Worker and select **Edit code** (sometimes shown as **Quick edit**). In VS Code, open `app_name/cloudflare/portfolio-worker/index.ts`, copy the entire file, replace the starter code in the editor, and deploy/save the change.
4. Open the Worker **Settings** tab. Under **Variables and Secrets**, select **Add**, choose the **Text** type, and set:
   - **Variable name:** `SUPABASE_URL`
   - **Value:** `https://YOUR_PROJECT_REF.supabase.co`

   This is the public project URL, not a credential. Do not add a publishable key, secret key, or service-role key to the Worker. Select **Deploy** to apply the variable.
5. In the Worker settings, confirm the `workers.dev` domain is enabled. Do not add a login gate; visitors need to open portfolio pages without signing in.
6. Test the deployed Worker URL before changing the app config. Replace `<worker-domain>` and `<username>` with the assigned Worker host and a username that already has a published portfolio:

   ```powershell
   curl.exe -sS -D - -o NUL "https://<worker-domain>/<username>/"
   curl.exe -sS -I "https://<worker-domain>/<username>/styles.css"
   ```

   The homepage should return `200 OK`, `Content-Type: text/html; charset=utf-8`, and `Cache-Control: no-store`; it should not include Supabase's sandbox Content-Security-Policy. The CSS response should return `Content-Type: text/css; charset=utf-8`. Open `https://<worker-domain>/<username>/` in a browser and confirm the page renders and its styles, script, and any published image/font assets load. If the homepage check fails, do not change the app URL yet.

### Configure Flutter to publish Worker URLs

1. After the Worker passes the live check, open `app_name/supabase-config.json` (the local, git-ignored config) and change only `PORTFOLIO_PUBLIC_BASE_URL` to the Worker origin, for example `https://prooffolio-portfolio.<your-subdomain>.workers.dev`. Keep the existing Supabase project URL and publishable key unchanged. Do not add a space after the equals sign if you use a `--dart-define` command.
2. Fully stop the current Flutter run. From PowerShell in `app_name`, restart with the config file:

   ```powershell
   flutter run -d chrome --dart-define-from-file=supabase-config.json
   ```

3. Open the Publishing card for an already-published portfolio and copy its displayed URL. The new link should end in `/<username>/`; paste it into a browser tab. The Worker serves `index.html` automatically, so visitors do not append `/index.html`.

The app constructs the new Worker URL from the existing username; the published Storage objects and publication records do not need to be changed or republished. Previously copied Supabase function or Storage links remain unchanged. If publishing is not configured, private previews and downloads remain available, but the live website link is unavailable.

### Switch to a custom domain later

After adding a custom domain to the Worker in Cloudflare, change only `PORTFOLIO_PUBLIC_BASE_URL` to the custom origin and restart Flutter. The Worker route and stored object paths remain `/<username>/` and `<username>/<asset>`; usernames and portfolio files do not need to change.

The Evidence client and bucket default to a 50 MB maximum (50,000,000 bytes). Supabase's project-wide Storage limit must be at least that high. If the project's limit is lower, reduce `EvidenceFilePolicy.maxFileBytes` in `app_name/lib/features/evidence/domain/evidence.dart` and both `50000000` limits in the evidence migration to the same byte value before applying it; the app's size label updates from the Dart constant. The allowed file types are JPG/JPEG, PNG, WEBP, PDF, DOC/DOCX, XLS/XLSX, PPT/PPTX, TXT, RTF, CSV, MP4, MOV, WEBM, MP3, M4A, WAV, and OGG. The client checks extension, reported MIME type, and file size, and Storage enforces the bucket MIME and size restrictions as well.

Uploaded files remain in a private bucket and are opened through signed links that expire after two minutes. Deleting file evidence removes the Storage object through the Storage API before deleting its metadata; if Storage removal fails, the evidence row remains so deletion can be retried. Public evidence sharing is not enabled.

To check whether the table exists, run `select to_regclass('public.profiles');` in SQL Editor. The result should be `profiles`. If you need to rerun the migration, open the file in the project and copy the whole file into a new query before pressing **Run**.

Create a local config file by copying `app_name/supabase-config.example.json` to
`app_name/supabase-config.json`, then replace the placeholders with your
Supabase Project URL and **publishable** key. The local file is git-ignored.
Never add a secret or service-role key to it: Dart defines are compiled into
the app and are not a place for server credentials.

Both Chrome development and Android builds need the configuration at compile
time. From PowerShell in `app_name`, run Chrome with:

```powershell
flutter run -d chrome --dart-define-from-file=supabase-config.json
```

To build a signed release APK with the same configuration, run
`.\tool\build-release.ps1` from `app_name`. The script validates that only
public client configuration is present, then invokes
`flutter build apk --release --dart-define-from-file=...`. The APK is written
to `build\app\outputs\flutter-apk\app-release.apk`. The portfolio public URL
is needed only for live portfolio publishing.

If invoking Flutter directly instead, pass the same
`--dart-define-from-file=supabase-config.json` option to the release build.

## 4. When you finish

Tell me once the project exists. You may then provide the **Project URL** and **Publishable key** if you want me to verify the connected flow. Do not send the database password, secret key, service-role key, email password, or any user's login credentials.

## Before release

- Confirm the production redirect URLs and email templates.
- Add and review the versioned database schema and Row Level Security policies before storing profile or portfolio data.
- Set up production secrets only in Supabase/server-side services. AI provider keys and database secret keys must never ship in the Android app.

## Official references

- [Supabase Flutter quickstart](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)
- [Supabase API keys and client key safety](https://supabase.com/docs/guides/getting-started/api-keys)
- [Supabase native mobile deep linking](https://supabase.com/docs/guides/auth/native-mobile-deep-linking?platform=flutter)
- [Supabase redirect URL configuration](https://supabase.com/docs/guides/auth/redirect-urls)
- [Supabase Dashboard Edge Function quickstart](https://supabase.com/docs/guides/functions/quickstart-dashboard)
- [Supabase Edge Function configuration](https://supabase.com/docs/guides/functions/function-configuration)
- [Supabase Storage bucket restrictions](https://supabase.com/docs/guides/storage/buckets/creating-buckets)
- [Supabase Storage file size limits](https://supabase.com/docs/guides/storage/uploads/file-limits)
- [Cloudflare Workers Dashboard deployment](https://developers.cloudflare.com/workers/get-started/dashboard/)
- [Cloudflare Worker environment variables](https://developers.cloudflare.com/workers/configuration/environment-variables/)
