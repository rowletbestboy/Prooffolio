# Prooffolio Professional UI Refresh

## Intent

Make Prooffolio feel like a polished career portfolio product from the first
sign-in through everyday record keeping. The supplied references show a light,
quietly confident interface: a saturated blue-violet identity, generous white
surfaces, rounded panels, concise headings, and small illustrated or outlined
icons that make progress and evidence feel approachable.

The current app already has working sign-in, profile, project, skill,
certification, achievement, and Evidence flows. The refresh should make those
flows feel like one product while keeping their behavior familiar.

## Goals

- Give the sign-in and account creation screen the visual character of the
  supplied login reference.
- Give Home a clear progress overview inspired by the supplied dashboard
  reference, using counts from records that already exist.
- Carry the same visual system through Projects, Skills, Profile, Credentials,
  Evidence, password recovery, and first-run setup screens.
- Use small, consistent Material line icons tied to work, learning, credentials,
  and proof; keep labels beside meaningful icons.
- Improve spacing, typography, contrast, touch areas, loading and empty states,
  and adaptive layouts without changing the app's information or privacy model.
- Keep all existing routes, validation, repository calls, and form actions
  working.

## Non-goals

- No new authentication providers, OTP screens, avatar upload, social login,
  publication, sharing, or public portfolio access.
- No new backend tables or changes to Supabase access policies.
- No decorative charts or invented scores. Home indicators must describe
  saved record counts or clearly stated profile completion inputs.
- No third-party font or icon dependency. Use the platform text styles and
  Flutter Material icons already available.

## Visual direction

- **Canvas:** very light cool gray (`#F2F3F7` range) with clean white content
  surfaces. Use the current Indigo brand as the main blue-violet accent, with a
  slightly brighter periwinkle treatment for selected states and icon tiles.
- **Supporting accents:** use Teal for skills and evidence, and a warm Amber
  for credentials and achievements. Keep these as semantic icon, badge, and
  lightly tinted surface accents; Indigo remains the primary action and brand
  color. Maintain text contrast and never communicate status with color alone.
- **Structure:** mobile-first, centered content with responsive gutters and a
  comfortable maximum width. Use a few distinct surfaces to group related
  actions rather than placing every row in a separate card.
- **Responsive behavior:** use narrow-screen gutters and layouts below 400 dp,
  allow multi-column summaries when cards have enough width, and cap reading
  surfaces on wide web/tablet viewports. Forms and dialogs must fit the
  available viewport without horizontal overflow, including when Chrome DevTools
  device emulation is used.
- **Shape:** rounded panels and fields, with a consistent radius scale. Keep
  borders subtle and use elevation only for the raised auth panel and modal
  surfaces.
- **Type:** retain the system sans-serif for reliable native rendering. Use
  stronger heading weights and clear size/spacing steps; keep helper copy
  readable and never rely on low-contrast gray.
- **Icons:** use a consistent outlined Material icon style for navigation,
  file evidence, projects, skills, education, achievements, and privacy.
  Decorative icons sit beside descriptive text; icon-only controls retain
  tooltips and semantic labels.
- **Interaction:** preserve visible loading, error, disabled, focus, and pressed
  states. Meet 48 dp touch targets and maintain safe-area padding. Avoid
  nonessential motion.

## Screen behavior and layout

### Authentication

Use a full-width blue-violet upper field with rounded lower corners and a
compact Prooffolio mark. Place a white rounded form panel into the lower part of
that field, then continue it naturally on the cool gray canvas on taller
screens. Keep the screen title and one-line purpose visible before the fields.
Email and password remain labeled fields with autofill support. The primary
button uses the brand color; password reset and sign-up mode are clear but
secondary. Errors and email-confirmation guidance remain next to the form.
The layout scrolls with the keyboard and small screens.

### Home

Replace the current introductory-only home with a compact welcome header and a
single progress summary. Show live counts for projects, skills, credentials and
achievements, and evidence. Keep the cards visually varied by role (one
featured progress area plus smaller count tiles) instead of repeating a grid of
identical cards. Add direct actions to continue building a project or open the
Evidence and credentials areas. Include a brief private-by-default reminder.
Do not show a score, rank, or unsupported completion claim.

### Record screens

Use shared page headers, introductory copy, section spacing, and one clear
primary add action. Improve list rows with consistent icon tiles, clear titles,
short metadata, and visible private/status labels. Empty and load-error states
use one relevant icon, concise guidance, and a direct action. Preserve edit,
delete confirmation, and relationship-selection behavior.

### Profile and recovery/setup screens

Bring Profile Setup, Profile Background, new-password, and Supabase setup into
the same field, card, heading, and button system. Preserve the current field
order, validation, optionality, and recovery flow. Do not introduce new
personal-data questions.

### Navigation

Retain the existing four destinations and route behavior. Refresh selected and
unselected icon treatment and ensure labels remain visible. Keep secondary
screens reachable from Home without hiding the main destinations.

## Constraints and implementation calls

- Flutter and Material 3 remain the UI stack; the existing `AppTheme` and
  `AppColors` remain the design-token source.
- Reuse existing repositories and models for Home counts. If a repository is
  unavailable in a test or setup context, render a graceful loading/error or
  neutral state without fabricated data.
- Existing pending Supabase migrations remain a setup requirement. The visual
  refresh must not claim that a remote migration was applied.
- The current run environment has no open browser session or installed
  Supabase CLI. Applying the Evidence migration is therefore a separate
  dashboard action, not an app-code change.
- Use existing test patterns and preserve stable keys/accessibility labels.

## Acceptance criteria

- Sign-in and registration visually match the described blue-violet and white
  card direction while retaining all current auth behavior.
- Home presents real saved-record counts, helpful next actions, and no invented
  score.
- Every existing screen uses the shared theme and readable responsive spacing.
- Existing functional widget tests continue to pass; add/update focused tests
  for live Home counts, auth layout semantics, and screen navigation as needed.
- `dart analyze` is clean and the Flutter suite passes.
- Inspect small-phone and large-phone layouts, keyboard-open auth, and tablet
  width behavior; confirm no clipped forms, hidden actions, or horizontal
  overflow.

## Remaining decisions for the builder

Select exact spacing, radii, and per-screen accent assignments from the
existing palette. Keep choices consistent across screens and use color
contrast appropriate for the foreground/background role.
