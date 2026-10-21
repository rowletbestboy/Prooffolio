# Prooffolio Portfolio, Publishing, and Resume Design

## Intent

Prooffolio already collects profile background, projects, skills, education,
experience, credentials, achievements, and evidence. The Portfolio destination
is currently a placeholder, so users cannot see those inputs assembled into a
portfolio or export them for applications. This feature makes Portfolio a
useful private workspace first, then lets a user deliberately publish a web
portfolio and generate a resume from the same saved records.

## User-approved delivery order

1. Add profile photo and contact links.
2. Create the private portfolio preview and an advisory meter with explanations.
3. Add light and dark web templates, live preview, and downloadable files. This
   phase also includes an explicit publish/unpublish flow with a shareable URL,
   as requested in the follow-up discussion.
4. Add an ATS-friendly resume layout and PDF/DOCX export.

Each phase should leave the existing app usable. Later phases consume the data
and interfaces from earlier phases.

## Goals

- Replace the Portfolio placeholder with a private preview of the user's saved
  profile and work records.
- Add an advisory readiness meter that explains its criteria and gives specific
  next steps. It must not present an objective judgment of the user's worth,
  employability, or career quality.
- Allow users to choose what appears in a public version, preview it, publish it
  at a Prooffolio-hosted shareable URL, and unpublish it later.
- Provide two web portfolio themes (light and dark), rendered as real HTML, CSS,
  and JavaScript files that can be previewed and downloaded.
- Generate a clean, selectable-text resume with PDF and DOCX download options.
- Add an optional profile photo and contact channels needed by the private and
  public portfolio.
- Preserve owner-only access to private profile and work records. Public
  visitors may access only content the user has explicitly selected for an
  active publication.

## Non-goals

- No claim that a resume is universally “ATS approved.” Use common ATS-friendly
  practices and describe the format honestly.
- No AI-written or fabricated content, scores, rankings, qualifications, or
  metrics.
- No forced publication, public-by-default profile, or public exposure of all
  saved data.
- No user-owned custom domains in the first release. Portfolios use a
  Prooffolio domain and username-based path.
- No paid subscriptions, analytics dashboard, visitor tracking, comments,
  contact form, or marketplace in this feature.
- No change to unrelated auth or existing record creation flows.

## Existing app and constraints

- Flutter / Dart app with Supabase Auth, Postgres, Storage, and RLS.
- Current `profiles` table is owner-only and contains identity/background fields.
- Projects, skills, portfolio records, education, experience, and Evidence are
  currently private. Evidence files are in a private Storage bucket.
- Existing profile repository supports profile background and education and
  experience records. The profile form currently captures display name and
  username; background details are handled separately.
- The user already ran the Evidence migration. New schema work must be supplied
  as new ordered migrations and must not ask the user to re-run that migration.
- Keep all prior uncommitted workspace changes intact.
- Follow the user's four-step order. Do not start later phases before the
  earlier phase is implemented and usable.

## Product behavior

### Phase 1: Photo and contact links

- Extend the profile with an optional photo and optional contact channels:
  email, phone, GitHub, LinkedIn, JobStreet, WhatsApp, and an extensible set of
  additional labeled links.
- Email should default from the signed-in account when available, while still
  allowing a user to choose a different public contact email.
- Phone and WhatsApp must be separate fields because they have different
  display/link behavior. Social URLs must be validated and normalized before
  being shown as links.
- Store the photo in a private Storage bucket while unpublished. Show it in the
  profile editor and private portfolio preview. The editor must explain that
  the chosen photo will appear on the web portfolio and recommend a
  professionally taken photo. Publication must make the selected photo
  retrievable by public visitors without making other private files public.
- All newly added contact information is optional and stays private until the
  user includes it in a published portfolio.

### Phase 2: Private portfolio preview and readiness meter

- The Portfolio destination shows a composed preview using only existing,
  saved user information. Empty sections are omitted; the interface gives
  direct links to add missing information.
- The advisory meter is descriptive and non-judgmental. It explains the
  coverage it checks (for example, profile basics, project detail, skills,
  evidence, and contact options) and shows actionable suggestions.
- Avoid “good/bad,” “pass/fail,” employability prediction, universal score
  thresholds, or comparative claims. Make clear that the meter measures
  content coverage in Prooffolio only.
- Users can preview and choose which supported records/contact fields to
  include before any public page exists.

### Phase 3: Templates, live preview, downloads, and publishing

- Provide two distinct templates with the same selected content: light and
  dark. Template selection and preview work without publishing.
- Generate a self-contained site bundle with HTML, CSS, and JavaScript. A user
  can download the bundle and host it independently. The bundle must contain
  only selected public content and required assets, never private evidence
  objects, user tokens, secrets, or internal IDs.
- Provide an in-app live preview of the public version before publishing.
- Publishing is an explicit, user-initiated action after a public-content
  review. Show the exact public fields and records, the resulting URL, and how
  to unpublish. Default all include toggles to off for sensitive contact
  channels and private evidence. Preserve selected publication state when
  updating unrelated private profile data.
- Serve a public read-only portfolio page from a Prooffolio-controlled domain
  using a stable username path. Published content should be a deliberate
  snapshot/projection of approved fields, not permission to query the user's
  private rows anonymously. Public visitor access must not expose draft
  projects, unselected records, private Evidence metadata/files, or account
  identifiers.
- Treat publication as an explicit snapshot: edits to the private profile or
  records do not silently change the live site. The user previews changes and
  selects **Update published site** to replace the public snapshot. Make the
  last published version and update action clear in the editor.
- Unpublishing makes the public page unavailable and revokes access to its
  publication-specific assets. Explain that already downloaded/copied content
  cannot be recalled.
- Scope public slugs to usernames in the first release. Username changes must
  not silently redirect or expose an old page; define a safe collision and
  rename behavior in the implementation plan.
- Use a configurable Prooffolio public base URL and username path. The
  implementation plan must inspect the existing deployment setup and choose a
  static hosting or web-route approach that serves these pages and supports
  fallback/routing. The specific production domain/provider is deployment
  configuration, not a user-facing choice in this feature.

### Phase 4: Resume / CV generator

- Place the resume generator at the bottom of the Portfolio area, as requested.
- Generate a text-first, single-column document with standard headings,
  selectable text, conventional date ordering, and no layout tables, icons,
  charts, or text-as-image that commonly interfere with ATS parsing.
- Users can inspect the resume before downloading PDF or DOCX. Omit optional
  blank fields and empty sections. Do not invent impact, dates, skills, or
  responsibilities.
- If essential identity/contact data are missing, explain what can be added;
  do not block a useful export solely because optional data are absent.
- Label it “ATS-friendly format,” not “ATS approved.”

## Privacy and security requirements

- Profile, photo, and work data remain private by default.
- Private preview and exports use authenticated owner data.
- Public page reads only a narrowly scoped publication representation. Avoid
  loosening existing table RLS policies for all projects, skills, profile, or
  Evidence.
- Public photos require a publication-scoped delivery mechanism. Do not turn a
  whole user photo or evidence bucket public.
- Validate and safely escape user text in generated HTML; allow only safe
  protocols for external links. Avoid executing user-provided JavaScript or
  raw HTML.
- Publish/unpublish and content selection must be auditable through explicit
  database state and covered by focused security checks during implementation.

## Open implementation choices for the plan

The builder may choose libraries and service structure that work with the
current Flutter/Supabase stack, provided that generated HTML is safe, public
reads are isolated from private records, and PDF/DOCX output is real downloadable
files on supported targets. The implementation plan should identify any
provider/service configuration and migration steps before coding them.

## Acceptance criteria

- Portfolio opens to a meaningful private preview populated from saved records;
  an empty account sees clear next actions and no fake content.
- Photo/contact fields save and load, validate correctly, and are not public
  until explicitly selected for publishing.
- The meter explains each suggestion and contains no unsupported judgment.
- Light and dark templates preview with the same selected content; generated
  HTML/CSS/JS downloads open as a working static site.
- Users can inspect exactly what will become public, publish it to a stable
  shareable URL, and unpublish it. Anonymous reads return only selected public
  content and cease after unpublish.
- Resume preview and PDF/DOCX exports reflect saved user data, omit blanks,
  preserve selectable text, and do not claim universal ATS approval.
- Existing private owner access and current record flows continue to work.

## Decisions made from the conversation

- Delivery order is fixed as the user's four steps above.
- Publishing is included with step 3, after private preview and both themes are
  available.
- A published portfolio is a frozen, explicitly approved snapshot and changes
  only when the user reviews and updates it.
- The public URL uses a configurable Prooffolio base URL and the user's
  username; production domain and hosting provider are deployment settings to
  resolve in the implementation plan.
- Missing content is omitted rather than fabricated; suggestions remain
  actionable and non-judgmental.
- User chooses publication fields and records explicitly; unpublished data
  stays private.
- First-release hosting uses a Prooffolio URL; custom domains are deferred.
- Resume output follows ATS-friendly conventions without claiming certification
  or universal approval.
