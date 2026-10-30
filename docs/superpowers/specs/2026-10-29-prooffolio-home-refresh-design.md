# Prooffolio Home and Shared UI Refresh

**Status: Pending user approval**

## Intent

Refresh Prooffolio's Home screen to follow the user's supplied mobile
reference and accepted browser mockup, integrate the real Prooffolio logo, and
give the rest of the app the same visual language. The Home screen should make
the user's work feel tangible and make their next useful action easy to find.
This is a visual and interaction refresh, not a rewrite of the app's features.

The browser mockup is a visual reference only. Its sample identity, project
names, counts, and profile initials are not production data.

## Goals

- Make Home closely follow the approved hierarchy: branded header, personal
  greeting hero, portfolio-progress card, compact saved-record counts, four
  shortcuts, recent projects, resume call-to-action, and the existing bottom
  navigation.
- Display the signed-in user's saved professional photo in the Home header
  whenever one is available.
- Show a truthful progress percentage and bar, alongside the existing live
  category counts.
- Integrate the supplied Prooffolio logo throughout the app.
- Apply the Home reference's colors, typography, surfaces, and component
  styling across the rest of the app without rearranging those screens.
- Preserve existing routes, record data, profile editing, export behavior, and
  responsive navigation.

## Non-goals

- No new photo-upload flow, profile field, backend table, storage bucket, or
  access-policy change. Profile-photo upload already exists.
- No new notifications system, AI feature, or other destination.
- No restructuring of Projects, Skills, Profile, Evidence, Portfolio, auth,
  or resume-generator screens.
- No changes to the generated resume or portfolio PDF/website output.
- No new fonts, icon packages, or other dependencies.
- No invented Home data, scores, ranks, or completion values.

## Home screen

### Header and greeting

- Replace the placeholder brand mark with the supplied Prooffolio branding.
  Keep the signed-in user's avatar at the top of Home; tapping it opens the
  existing profile editor when that route is available.
- Read the avatar image from the existing `ProfileBackground.photoPath` for
  the current user, using the existing profile repository's signed-photo URL
  mechanism. Do not add a separate image field or use a public URL.
- While the profile/photo is loading, or if no photo is saved or the image
  cannot be loaded, show the user's initials. This fallback is confirmed by
  the user. Refresh profile/photo data when returning from profile editing or
  refreshing Home.
- Use the user's saved display name in the greeting. Do not ship the
  mockup's “Alex Rivera” sample as fixed content.
- Preserve sign-out access. The mockup's notification bell is not included in
  the app because there is no notification behavior to connect it to.

### Progress and live counts

The progress percentage represents completion of seven foundational
portfolio milestones, not the number of records a user has accumulated:

1. A non-empty profile display name.
2. A non-empty professional headline.
3. A non-empty work-summary bio.
4. At least one saved contact method: contact email, phone, GitHub, LinkedIn,
   Upwork, Jobstreet, WhatsApp, or an additional contact link with a URL.
5. At least one project.
6. At least one skill.
7. At least one supporting proof record: a certification, achievement, or
   evidence item.

The profile photo is optional and is not a completion requirement. Calculate
the percentage as the completed milestones divided by seven, rounded to the
nearest whole percent. The progress bar and percentage must use the same
fraction; show the matching “X of 7 foundational items complete” text as
context.

Keep compact live counts for Projects, Skills, Certifications, Achievements,
and Evidence. These describe saved-record volume, which is different from the
milestone percentage, so both measures can be shown without duplicating the
same metric. Do not add another aggregate total on top of those five counts.
The mockup's `43%` and sample category counts are illustrative; production
values come from the user's saved records.

Show a loading state while required sources are being read. If a required
source is unavailable or fails, do not treat it as zero or publish a
success-shaped percentage; show an explicit unavailable/retry state consistent
with the app's existing patterns. An empty category is a real zero only when
its source loaded successfully.

### Shortcuts and content

- Keep the four quick-action tiles from the accepted visual direction:
  **Add Project**, **Manage Skills**, **Generate Resume**, and **Portfolio**.
- Wire them to existing project, skill, resume, and portfolio destinations;
  do not introduce new workflows. The mockup's “AI Portfolio” label is
  changed to **Portfolio** because the app has no AI portfolio action.
- Show recent projects from the signed-in user's saved project records, with
  their actual titles and status. Provide a clear route to the existing
  Projects screen. Use an honest empty/error state when records are absent or
  cannot be loaded.
- Retain the resume call-to-action and connect it to the existing resume
  generation flow.
- Keep the current four destinations and responsive behavior: bottom
  `NavigationBar` on narrow layouts and `NavigationRail` at the existing wide
  breakpoint.

## Shared visual language and logo

- Use the provided Home reference as the visual anchor: a light cool canvas,
  deep navy/blue hero, teal highlights, indigo primary actions, restrained
  pastel category surfaces, clear dark text, rounded white cards, and compact
  outlined icons.
- Centralize the shared palette and component treatment in the existing
  `AppColors` and `AppTheme`. Maintain Material 3, the current system font,
  accessible contrast, visible labels, safe-area spacing, and 48 dp minimum
  control targets.
- Apply those shared styles to existing auth, profile, project, skill,
  evidence, portfolio, resume-preview, form, dialog, and navigation surfaces.
  This is an app-wide requirement, not just a Home-and-Projects refresh.
- Page coverage includes sign-in/sign-up, password recovery and new-password
  setup, Supabase setup, profile setup and profile/background editing, Home,
  Projects and project forms, Skills and skill forms, portfolio preview and
  publication, credentials and achievements, evidence, resume preview, and
  their loading, empty, error, confirmation, and edit states.
- Inspect Skills, Profile, and Portfolio specifically during implementation
  and visual verification so the shared styling is visible on those pages as
  well as Home and Projects.
- Preserve each existing screen's information hierarchy, field order, content,
  validation, actions, and layout. The other screens are not to be rearranged
  to match Home.
- The supplied `PROOFFOLIO LOGO.png` has an opaque checkerboard background.
  Create a cleaned transparent derivative (and a compact mark variant if
  required for the existing compact brand slot), register it as a Flutter
  asset, and use it in the shared brand component. Leave the supplied original
  file untouched. Keep the colored logo legible on light surfaces; do not
  apply a filter that changes the brand colors.

## Constraints and implementation calls

- Flutter, Material 3, `AppTheme`, `AppColors`, and current repositories remain
  the implementation basis. No backend or dependency changes are expected.
- Use the user's existing private profile-photo storage and short-lived
  signed-URL support; never make profile images public as part of this work.
- The compact count breakdown and checklist percentage intentionally answer
  different questions: “how many records are saved?” and “which foundational
  portfolio steps are complete?”
- The mockup's “AI Portfolio” shortcut is labeled **Portfolio** in the app
  and opens the existing Portfolio destination; do not imply an AI workflow
  that is not implemented.
- Preserve the current Home refresh affordance, profile completion messaging,
  sign-out behavior, and all existing app routes.
- The previous professional-UI proposal remains relevant for its shared
  visual principles, but this design narrows its Home and cross-screen scope:
  Home follows the user-approved reference, while other screens keep their
  current structure.

## Acceptance criteria

- Home follows the approved reference hierarchy and remains usable at narrow
  phone widths and the existing wide-layout breakpoint.
- When a saved profile photo exists, it appears in the Home header. Missing,
  expired, or failed photo loads show initials without crashing or hiding the
  profile action.
- Each progress-card percentage exactly matches the seven-milestone fraction,
  rounded to a whole percent. The bar uses that same fraction, and its
  `X of 7` copy agrees with both.
- The five category counts show real saved data; loading or failed sources are
  not represented as successful zero counts.
- Shortcuts open existing functionality. No inert notification or AI action
  is introduced.
- The actual logo renders cleanly without a checkerboard, including its
  compact use, and the original supplied PNG remains unchanged.
- Projects, Skills, Profile, Evidence, Portfolio, auth, and resume screens
  retain their current content structures and behavior while adopting the
  shared styling.
- Every existing application page, including Skills, Profile, and Portfolio,
  visibly uses the shared theme; verification is not limited to Home and
  Projects.
- Existing navigation and profile editing continue to work. Focused widget
  tests cover photo-present and initials-fallback states, milestone math,
  count loading/error states, Home actions, and narrow/wide layouts.
- Flutter tests and analysis pass; inspect phone and wide layouts for clipping,
  overflow, touch targets, and contrast.

## Remaining decisions for the builder

Choose exact colors, sizing, spacing, and the compact count layout using the
existing theme system and the accepted browser mockup. Keep data calculations
and loading/error states faithful to the rules above.
