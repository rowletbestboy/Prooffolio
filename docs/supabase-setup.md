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
5. Add the mobile callback URL to **Redirect URLs**: `com.prooffolio.app_name://login-callback/`. This matches the current Android application ID. Keep that ID stable after publishing.

Supabase email confirmation and password recovery links need a configured redirect destination. The Android app has a matching deep-link intent filter; confirmation and recovery callbacks use the URI above.

## 3. Run the Flutter app with client configuration

Before running the connected app, open **SQL Editor → New query** in Supabase, paste the contents of `app_name/supabase/migrations/20261020170000_create_profiles.sql`, and run it. This creates the initial profile table and owner-only Row Level Security policies required by the session gate. The migration can be run again safely if it has already created the table and policies.

To use the Projects tab, run the next migration too: paste `app_name/supabase/migrations/20261021100000_create_projects.sql` into a new SQL Editor query and run it. It creates the owner-only project table and policies. Projects stay private drafts; public access is not enabled by this migration.

To use the Skills tab and connect skills to projects, run `app_name/supabase/migrations/20261022100000_create_skills_and_project_skills.sql` the same way. It creates private skill records, project links that require both records to belong to the signed-in user, and the `save_skill_with_projects` function used to save each skill and its links together.

To add inclusive profile details and broad occupation categories, run `app_name/supabase/migrations/20261023100000_expand_profile_and_skills.sql` after the first three migrations. It adds optional profile background fields and private education and experience records, then maps existing technology-specific skill categories to Technology and digital work while preserving skill names, proficiency labels, and project links. Apply the migrations in this order: profiles, projects, skills, then inclusive profile and skills expansion. Existing profile identity fields remain unchanged. All background questions are optional, and experience supports volunteer, community, caregiving, freelance, and independent work.

To add certifications and achievements, run `app_name/supabase/migrations/20261024100000_create_portfolio_records.sql` after the previous migration. It creates one private, owner-only record table for certifications and achievements. Both can be added without a project; certification expiration dates are optional. Public portfolios and file attachments are not enabled yet, so these records remain private.

To add the shared Evidence library, run `app_name/supabase/migrations/20261025100000_create_evidence.sql` after the portfolio-record migration. It creates private evidence metadata and owner-checked links to projects, skills, experience, certifications, and achievements. It also creates the private `evidence` Storage bucket and per-user object policies. Apply migrations in order: profiles, projects, skills, inclusive profile and skills expansion, portfolio records, then evidence. See [the Evidence schema](evidence-schema.md) for the relationship diagram and ownership behavior.

The Evidence client and bucket default to a 50 MB maximum (50,000,000 bytes). Supabase's project-wide Storage limit must be at least that high. If the project's limit is lower, reduce `EvidenceFilePolicy.maxFileBytes` in `app_name/lib/features/evidence/domain/evidence.dart` and both `50000000` limits in the evidence migration to the same byte value before applying it; the app's size label updates from the Dart constant. The allowed file types are JPG/JPEG, PNG, WEBP, PDF, DOC/DOCX, XLS/XLSX, PPT/PPTX, TXT, RTF, CSV, MP4, MOV, WEBM, MP3, M4A, WAV, and OGG. The client checks extension, reported MIME type, and file size, and Storage enforces the bucket MIME and size restrictions as well.

Uploaded files remain in a private bucket and are opened through signed links that expire after two minutes. Deleting file evidence removes the Storage object through the Storage API before deleting its metadata; if Storage removal fails, the evidence row remains so deletion can be retried. Public evidence sharing is not enabled.

To add optional profile photo and contact fields, run `app_name/supabase/migrations/20261026100000_expand_profile_portfolio_contacts.sql` after the Evidence migration. It adds private contact columns and labeled links to `profiles`, plus the private `profile-photos` Storage bucket. Apply migrations in order: profiles, projects, skills, inclusive profile and skills expansion, portfolio records, Evidence, then profile portfolio contacts. The photo bucket accepts JPEG, PNG, and WEBP files up to 5 MB, and its object policies limit each signed-in user to their own folder. Profile photos remain private until a later publication flow creates a separately selected public copy.

To enable opt-in website publishing, apply `app_name/supabase/migrations/20261027100000_create_portfolio_publications.sql` after the profile photo/contact migration. This creates the owner-only publication status table, a public `published-portfolios` Storage bucket for generated website files, and owner-scoped Storage write policies. If this migration has already been applied, do not run it again. Review the SQL and its public-bucket behavior before applying it; published site files are accessible to anyone with the URL.

To add a dedicated Upwork freelancer link, run `app_name/supabase/migrations/20261028100000_add_upwork_profile_link.sql` after the profile photo and contact migration. This later additive migration adds an optional field to the existing owner-private profile row. It can be applied after the publication migration and is needed before saving an Upwork URL. It is not added to public portfolios unless the user selects it during website review.

Set `PORTFOLIO_PUBLIC_BASE_URL` to the public object base URL for that bucket when running the app, for example `https://YOUR_PROJECT_REF.supabase.co/storage/v1/object/public/published-portfolios`. Live publishing is disabled if this value is missing or is not an HTTPS URL. Add the define to the run command:

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_YOUR_KEY `
  --dart-define=PORTFOLIO_PUBLIC_BASE_URL=https://YOUR_PROJECT_REF.supabase.co/storage/v1/object/public/published-portfolios
```

The app uploads only the content explicitly selected in the preview and asks for confirmation before publishing, updating, or unpublishing. Unpublishing removes the website files and deactivates the publication record, but copies or cached content outside Prooffolio may remain. Storage uses a short cache lifetime; it does not guarantee that third-party caches are purged. Do not put service-role keys in the Flutter app.

To check whether the table exists, run `select to_regclass('public.profiles');` in SQL Editor. The result should be `profiles`. If you need to rerun the migration, open the file in the project and copy the whole file into a new query before pressing **Run**.

From PowerShell, in the `app_name` directory, run:

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_YOUR_KEY
```

Replace both placeholders with the values from the dashboard. These values are compiled into the app; use only the publishable key. Do not use `--dart-define` for a secret/service-role key.

For repeatable local runs, keep the values in a local ignored file or IDE run configuration and do not commit them. The publishable key is not a password, but avoiding unnecessary public config commits makes environment changes easier to manage.

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
- [Supabase Storage bucket restrictions](https://supabase.com/docs/guides/storage/buckets/creating-buckets)
- [Supabase Storage file size limits](https://supabase.com/docs/guides/storage/uploads/file-limits)
