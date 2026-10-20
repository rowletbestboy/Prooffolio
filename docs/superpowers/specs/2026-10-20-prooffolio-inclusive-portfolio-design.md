# Prooffolio Inclusive Portfolio Design

## Intent

Broaden Prooffolio from a technology-led student portfolio into an evidence-based portfolio for people across occupations and career stages. A person should be able to describe their background and show credible work even when they have no software project, repository, or conventional employment history.

## Why

The current profile asks only for a display name and username, while the project and skill examples lean toward software. That makes agriculture, education, business, science, engineering, virtual assistance, trades, care work, volunteering, and other paths feel secondary. The supplied master prompt already calls for education, interests, work experience, certifications, achievements, and user-supplied evidence; this design makes those records a core part of the product.

## Goals

- Let users describe a profession, field, role, career stage, education, and relevant experience in their own terms.
- Offer broad occupational categories while keeping an optional free-text field for precise or emerging roles.
- Make projects one useful portfolio content type, without requiring every person to have projects.
- Add certifications and achievements as first-class records.
- Let users attach relevant images, documents, audio, and video as evidence for projects, credentials, achievements, experience, or skills.
- Keep drafts and uploaded files private by default; the user chooses what becomes public later.
- Preserve the existing authentication, Projects, Skills, and portfolio foundation while expanding the data model additively.
- Keep claims user-authored and self-reported; evidence supports a claim but does not certify ability.

## Non-goals for this expansion

- Do not build a public portfolio site, AI writer, resume generator, or readiness score in this milestone. They remain later roadmap items and must consume the broader user-owned records when built.
- Do not require a degree, formal employment, project, certificate, or achievement before someone can create a useful portfolio.
- Do not infer occupation, competence, employability, or qualification from uploaded files.
- Do not require phone number, home address, or unrelated sensitive details.

## Product shape

### 1. Professional profile and background

Add optional profile fields for a short professional headline, biography, broad occupation category, specific role/title, career stage, interests, and target roles. The occupation selector should be searchable and include “Other” plus a free-text title; category selection must never prevent saving the profile.

Use a broad initial category set:

- Agriculture, forestry, and fisheries
- Arts, media, and design
- Business, finance, and administration
- Construction and skilled trades
- Education and training
- Engineering and manufacturing
- Healthcare and care services
- Hospitality and tourism
- Information technology and digital work
- Legal and public service
- Science and research
- Sales and customer service
- Transportation and logistics
- Virtual assistance and remote operations
- Community and nonprofit work
- Student or early career
- Other

Education is a repeatable record with optional program/course/qualification, institution, level, progress state (in progress, completed, paused), dates, and a short description. This supports undergraduate study, completed courses, vocational training, and other learning without treating a degree as mandatory.

Experience is a repeatable record with role/title, optional organization, experience type (employment, freelance, internship, volunteering, community work, caregiving, independent practice, or other), dates, and a description of the person's contribution. Work history is optional and must accept informal, unpaid, self-directed, and community experience.

### 2. Inclusive Skills library

Keep skill names user-authored and free-form, and broaden the category picker beyond technology. Use broad categories matching the occupation taxonomy (including agriculture/environment, arts/media/design, business/administration, construction/trades, education, engineering/manufacturing, healthcare/care, hospitality, technology/digital, law/public service, science/research, sales/customer service, transport/logistics, virtual assistance/remote operations, communication/languages, leadership/project management, and Other). Preserve existing skill names, learning states, and project links. A forward migration may reclassify the existing tech-specific category values to the broad technology/digital category; do not edit or rerun an already applied migration.

### 3. Portfolio records beyond projects

Keep existing Projects CRUD and its data intact. Add first-class Certifications and Achievements records with title, issuer/source (optional), description, dates, optional expiration for certificates, private-by-default publication state, and linked evidence. Users can create these records without adding a project.

Professional experience remains available in the profile background and can later be selected for the public portfolio. Users may include evidence with those records. Custom or unlisted record types can be represented with an “Other work sample” option, with a user-provided title and description.

### 4. Evidence and file uploads

Introduce a shared Evidence library that can attach files or external URLs to projects, certifications, achievements, experience, and skills. Store relational ownership and associations in Postgres rather than embedding IDs in free-text fields.

Start with a documented allow-list of common formats:

- Images: JPG/JPEG, PNG, WEBP
- Documents: PDF, DOC/DOCX, XLS/XLSX, PPT/PPTX, TXT, RTF, CSV
- Video: MP4, MOV, WEBM
- Audio: MP3, M4A, WAV, OGG

The client should validate extension and reported MIME type for user feedback, give a clear error for unsupported formats or oversized files, and make limits configurable to match the active Supabase Storage plan. Enforce bucket-level content-type and size restrictions too; client validation alone is not a security boundary. Do not accept arbitrary executable content. Upload completion must show the file name and type; unsupported inline previews can open through the platform's file viewer or download flow.

Store objects in a private Supabase Storage bucket with per-user path ownership and policies. Do not place service-role credentials in Flutter. Draft attachments must not be publicly addressable. Public sharing is a later feature and must expose only records and files explicitly selected by the owner, using short-lived authorized access for private files. Deleting an evidence row must also remove its Storage object through the Storage API; handle abandoned objects after failed metadata saves.

### 5. Navigation and presentation

Keep Home, Projects, Skills, and Portfolio available. Add clear entry points to Profile/Background, Certifications & Achievements, and Evidence without overloading bottom navigation; use a small number of well-named hubs or profile subsections. Projects remain directly discoverable. The final screen layout is the implementer's call, provided all content types can be found with predictable back navigation and a user can add a non-project record without first visiting Projects.

Use the established navy/indigo Material 3 design and calm, professional information hierarchy. Do not represent the experience as a technology portfolio template. Ask for information progressively, use optional labels clearly, and keep long forms scrollable with one primary save action per screen.

## Security and data rules

- Every new table has `user_id`, owner-only RLS, and indexes/constraints appropriate to its relationships.
- Composite ownership constraints prevent a user's skill or evidence link from pointing at another user's project or record.
- Files stay private by default. Validate every upload and download request against the authenticated owner.
- Account deletion must remove associated rows and storage objects.
- Public endpoints, when implemented later, expose only explicitly published records and selected attachments.
- AI features remain optional and may only summarize selected user-provided content after human review.

## Delivery sequence

1. Expand Profile/Background and the Skills category system for occupation, role/career stage, education records, inclusive experience, and broad skill domains.
2. Add Certifications and Achievements as private first-class portfolio records.
3. Add the shared private Evidence library, file picker, uploads, URL evidence, and links to supported records.
4. Update the dashboard/completeness rules and public portfolio later to use the broad record types. Revisit AI prompts only after structured records and publication controls exist.

Each phase should keep the app runnable and testable. Migrations are additive and must preserve existing user projects, skills, and project-skill links.

## Open implementation choices for the builder

- Choose concise page names and a navigation arrangement that fits the existing four-destination shell.
- Confirm supported file limits against current Supabase plan configuration before enabling uploads; show the resulting limits in the app and setup guide.
- Add an ER diagram with the migrations before complex evidence association queries, as required by the master prompt.
- Prefer established project conventions; add a Flutter package only when necessary for file selection and platform opening.
