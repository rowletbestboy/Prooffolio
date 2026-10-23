# Prooffolio Profile, Portfolio Publishing, and Resume Integration

## Intent

Integrate the user's ongoing Codex work in the Desktop checkout with the
portfolio-builder and publication work in the temporary worktree. The Desktop
checkout is the runnable project the user has been launching and becomes the
integration target. The result should help a user turn truthful, saved profile
and work records into a polished, employer-shareable portfolio website and
reviewable resume exports.

The accepted public portfolio concept is the visual direction: a composed
personal introduction, editorial typography, selected project case studies,
skills, and contact action, with a restrained green accent, responsive
layout, and light/dark variants. It must feel intentionally designed rather
than like a generic upload or quick static export.

## User-approved behavior

- Profile information is authored in the Profile section and is source material
  for portfolio and resume generation.
- The user wants a homepage reminder to complete their profile.
- Profile fields include an image, contact information, and relevant social or
  work links such as LinkedIn, Upwork, and JobStreet.
- The profile photo must be clearly identified as the photo that may be used in
  the portfolio and resume.
- The public portfolio should be a polished website which showcases selected
  profile information, skills, projects, certifications, achievements, and
  other suitable saved records.
- Users should be able to publish a live website and share its URL with
  employers.
- The Portfolio workspace should include an objective content-coverage meter,
  light and dark website previews, and a resume/CV builder with two styles:
  text-first ATS-friendly and a standard photo layout. Both styles can export
  to PDF and DOCX.
- The public portfolio concept shown in the brainstorming browser was approved
  as the visual direction.
- Profile and work data stay private until the user explicitly reviews and
  selects what to publish. Approval of a profile photo as source material does
  not automatically publish it.

## Goals

1. Integrate, rather than replace, work in both existing checkouts, preserving
   Desktop's unrelated in-progress edits, all SQL migrations, and project
   documentation.
2. Make `C:\Users\sergr\Desktop\Prooffolio\app_name` the coherent, runnable
   Flutter application with the completed Profile, Home, Portfolio, website
   publishing, and resume surfaces.
3. Reuse current profile, project, skill, education, experience, certification,
   achievement, and Evidence repositories instead of creating duplicate data
   stores.
4. Keep private content private by default and publish only a confirmed
   snapshot.
5. Validate with targeted tests, analyzer, relevant builds, and a final
   worktree review. Do not commit unless separately requested.

## Non-goals and safeguards

- Do not apply SQL migrations, connect to the user's Supabase project, publish
  real account data, or request credentials during implementation.
- Do not replace the Desktop checkout wholesale, reset changes, or discard
  either worktree's existing SQL/docs.
- Do not fabricate resume or portfolio content, metrics, outcomes, or
  qualifications.
- Do not claim that any resume is universally “ATS approved.” Call the
  text-first design “ATS-friendly” and explain that parsing varies by system.
- Do not publish profile fields or photos automatically. Do not expose private
  Evidence files/paths, internal record IDs, account IDs, tokens, or secrets
  in generated pages.
- Do not implement AI generation, custom domains, visitor analytics, or
  employer accounts as part of this integration.
- Do not copy Google Docs template designs or assets. Use common resume
  conventions (single column, conventional headings, readable hierarchy) as
  inspiration for an original, interoperable layout.

## Existing work and integration boundary

### Desktop checkout

The Desktop checkout contains the user's ongoing UI/auth/profile/project/skill
work and an Evidence library migration, but its current Portfolio tab is still
an empty-destination placeholder. It does not currently contain the profile
photo/contact migration or the newer portfolio/publishing source files.
Preserve all Desktop tracked and untracked edits while bringing in compatible
features.

### Temporary worktree

The temporary worktree contains profile photo/contact model, editor and private
Storage support, portfolio view models/readiness preview, static light/dark
website generation and ZIP preview/download, publication repository and UI,
the publication migration, focused tests, and setup documentation. It does not
yet contain the resume preview/export phase. Integrate these capabilities
selectively and reconcile differences rather than blindly copying files over
Desktop.

### Database state and migrations

The user reports that `20261027100000_create_portfolio_publications.sql` has
already been run on Supabase. Keep that migration and its documentation.
Preserve earlier migrations as files, do not reapply anything automatically,
and do not assume the rest of the schema is present until the user checks
their setup. The profile photo/contact migration
`20261026100000_expand_profile_portfolio_contacts.sql` is present in the
temporary worktree but not the Desktop checkout and must be retained in the
integrated project.

Upwork needs a clear dedicated Profile input. Prefer an additive, owner-private
`upwork_url` column migration after the profile photo/contact migration; do
not rewrite an already-applied migration. Update model, repository, form,
portfolio selection, generated website, resume contact/link data, tests, and
setup documentation together.

## Product behavior

### Profile source information

- Keep existing identity, background, education, and experience editing.
- Keep or integrate the private profile-photo picker with JPG/PNG/WEBP
  signature and size checks. Place clear copy next to it:
  “This is the photo used in your portfolio and photo resume. It stays private
  until you choose to include it.”
- Provide optional email, phone, GitHub, LinkedIn, Upwork, JobStreet,
  WhatsApp, and repeatable custom labeled social/work links. Preserve URL
  validation and do not force any contact field.
- Store profile contacts in the owner-only profile row; the image remains in a
  private bucket until it is included in an approved generated site bundle.
- A profile editor save should preserve fields it does not edit and surface
  validation/save/upload failures.
- Existing profile data remains usable when newly added optional fields are
  absent or null.

### Home profile-completion reminder

- On Home, show a concise, actionable reminder when key profile details are
  missing, with a direct action opening Profile.
- Determine completion from saved, factual fields; do not infer or score
  employability. The prompt should state why a photo/headline/contact or work
  summary can help prepare portfolio/resume materials.
- The reminder updates after profile edits and disappears or changes to a
  completed state when the configured profile checklist is satisfied.
- It must not block access to other dashboard features.

### Portfolio workspace and readiness

- Replace the Desktop Portfolio placeholder with the real authenticated
  portfolio workspace, using current saved profile and work records.
- Show a transparent content-coverage meter/checklist with its criteria and
  actionable routes to add missing profile, project, skill, education,
  experience, certification, and achievement information. It is not a
  comparative grade or claim about job readiness.
- Content-loading errors must remain visible and retryable; do not render
  misleading “empty” content when a data source failed.
- Make a private preview before publish available regardless of whether the
  user has a publication.

### Employer-facing website templates and live publishing

- Provide light and dark variants based on the approved mockup's composition
  and level of polish, not sample personal details or generic filler.
- Use the selected profile image, name, headline, about text, contact/social
  links, skills, projects, certifications, achievements, education, and
  experience when chosen and present. Omit empty sections. Projects should
  receive clear title, summary, role/contribution, detail, and dates when those
  fields exist. Avoid claiming outcomes that the user did not save.
- Support private preview with desktop and narrow/mobile layouts; respect
  keyboard focus, readable contrast, and reduced motion. Use no third-party
  scripts or externally hosted user content.
- All text is escaped, generated anchors accept only safe HTTP(S) URLs, and
  IDs are used only for authenticated selection state, never public HTML.
- Public photos are copied into the approved static bundle only when selected.
  Evidence remains private and is never copied into the public bucket.
- Publishing/update requires a review of the exact selected content and an
  explicit confirmation. Unpublish has separate confirmation and explains
  external copies/caches may remain.
- Show a stable public URL, provide copy/share action, and update the public
  snapshot only after explicit confirmation. Private edits do not silently
  alter live content.
- Use the existing dedicated `published-portfolios` bucket and owner-scoped
  migration policies. Keep the existing short cache and rollback behavior.
  Publishing is disabled with an explicit explanation until
  `PORTFOLIO_PUBLIC_BASE_URL` is configured.
- Username changes while published must explain unpublishing is required.

### Resume/CV preview and exports

- Place resume tools below website templates in Portfolio.
- Build one factual resume model from saved profile, experience, education,
  skills, selected projects, certifications, and achievements. Omit blank
  sections and never invent content.
- Offer two intentionally distinct layouts:
  1. Text-first, single-column “ATS-friendly” with conventional headings,
     semantic reading order, standard fonts, no tables/columns/icons that
     impair text extraction, no photo by default.
  2. A standard visual resume with the user's profile photo when present and
     selected.
- Provide a preview before export, and PDF and DOCX outputs from the same
  model, retaining selectable text and consistent content. PDF must flow
  across pages without truncation; DOCX uses normal paragraphs/headings/lists.
- Sanitize display-name-derived filenames. Provide platform-appropriate save
  or download behavior.
- Explain that ATS parsing varies and no universal approval is guaranteed.

## Design direction

### Palette

- Deep evergreen `#1D2927` for primary text.
- Muted slate-green `#64716D` for secondary copy.
- Page mist `#F4F6F3` and paper `#FFFFFF` for the light site.
- Botanical teal `#087E70` for primary actions and selected details.
- Warm brass `#E7AA48` only for restrained emphasis and focus.
- Dark mode equivalents use deep forest-charcoal surfaces and accessible
  softened teal, without reducing text contrast.

### Type

- Editorial serif display face for portfolio name/headline and major section
  headings; use an available system serif fallback to keep the site
  self-contained.
- Neutral, highly legible system sans-serif for body content, controls, and
  project details.
- No dependence on remote font services.

### Layout

- Public site: asymmetric two-part hero with a left-aligned introduction and
  optional portrait; a compact top navigation; selected work as spacious case
  study cards; skills and background in a secondary section; a clear contact
  invitation near the end.
- Portfolio workspace: vertically ordered readiness, website templates, then
  resume choices/preview/export, collapsing to a single column on mobile.
- Profile editor: retain the existing app form patterns, add explicit
  headings for photo, about, contact and social links, and keep a persistent
  save action consistent with current experience.
- Alignment is left-aligned for reading; center only the visual portrait
  within its hero frame. Do not justify body copy.

### Principles

- One memorable design gesture: editorial typography paired with a distinctive
  portrait silhouette/selected-work art treatment; keep content quiet and
  legible around it.
- Let user-supplied work be the visual proof. Use no fake companies, claims,
  metrics, or example content in the final generated site.
- Structural hierarchy should distinguish real project case studies from
  skills and personal background.
- Light/dark modes share one coherent composition, not two unrelated themes.

## Acceptance and validation

- The Desktop checkout remains the launch target and no existing Desktop edits,
  SQL, or docs are lost.
- Profile fields including Upwork save, reload, validate, and survive saves to
  other profile fields. Photo label is visible; upload remains private until
  explicit use in output.
- Home reminder appears when the profile is incomplete, opens Profile, and
  updates after completion.
- Portfolio shows the objective meter, actual user content, light/dark preview,
  explicit selection/review, publish/update/unpublish, and share URL/copy.
- Generated HTML never includes unselected fields, evidence file paths, tokens,
  secrets, or record IDs; unsafe links are not rendered as links.
- Each resume style previews; PDF and DOCX contain the same selected factual
  sections, with selectable text and correct multi-page flow.
- Run focused affected tests, `flutter analyze`, the Flutter Web build, and
  `git diff --check`. Report known unrelated legacy test failures separately.
- Do not connect to Supabase, run SQL, or publish user data as validation.
