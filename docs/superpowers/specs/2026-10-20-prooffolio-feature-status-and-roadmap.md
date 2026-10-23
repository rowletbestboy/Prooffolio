# Prooffolio Feature Inventory and Build Roadmap

This roadmap tracks the requirements in the supplied `MASTER PROJECT PROMPT — PROOFFOLIO`. The app must grow incrementally; this is the full product scope, not a claim that every feature is already present.

## Current implementation status

| Master-prompt feature | Status | Remaining work |
|---|---|---|
| 1. Onboarding and authentication | Partial | Sign-in, registration, recovery, session routing and basic identity setup exist. Add welcome/introduction, richer profile setup, privacy notice, and verify live auth/deep links. |
| 2. Dashboard | Partial | Theme, navigation and evidence-trail introduction exist. Replace placeholder with live counts, recent activity, publication state, completeness checklist and next actions. |
| 3. Profile builder | Partial; inclusive background and private photo/contact editor implemented | Display name, username, optional headline/bio, 17 occupation areas, custom occupation title, career stage, interests, target roles, repeatable education and experience, profile photo, and optional contact links are available. Apply `20261023100000_expand_profile_and_skills.sql` and `20261026100000_expand_profile_portfolio_contacts.sql`. Visibility controls remain for the publishing phase. |
| 4. Project management | Implemented; migration required | Project CRUD, project fields, list/details/edit, validation, private draft default and delete confirmation are in the app. Apply `20261021100000_create_projects.sql` to Supabase before live use. Search/filter remains a later refinement. |
| 5. Skill library | Implemented; migration required | Skill CRUD, broad cross-occupation categories and self-reported Learning/Practicing/Applied labels. Apply the skills migration and `20261023100000_expand_profile_and_skills.sql` to Supabase before live use. |
| 6. Certifications and achievements | Implemented; migration required | Add, edit, and delete private credentials and recognition records without a project. Apply `20261024100000_create_portfolio_records.sql`. They can link to private Evidence records; public portfolios remain later work. |
| 7. Skill-to-evidence mapping | Implemented; migration required | Private file and URL evidence can link to owned projects, skills, experience, certifications, and achievements. Apply `20261025100000_create_evidence.sql`; public evidence sharing remains later work. |
| 8. Portfolio preview and public website | Private preview, downloadable site, and opt-in publishing implemented; migration required | The authenticated Portfolio destination composes saved profile, project, skill, education, experience, credentials, achievements, and private evidence. The site builder uses explicit selection, light/dark templates, and a ZIP download. Publishing requires confirmation and the `20261027100000_create_portfolio_publications.sql` migration plus `PORTFOLIO_PUBLIC_BASE_URL`; public files contain only the generated selection, never private Evidence. |
| 9. AI portfolio generator | Not implemented | Role/project selection, templates, structured drafts, editing, preview and explicit publish approval. |
| 10. AI resume/CV builder | Not implemented | Role/job description selection, factual structured draft, editable review, ATS-friendly preview and PDF export. |
| 11. AI career readiness assistant | Not implemented | Transparent actionable recommendations, no employability score or claim of assessed ability. |
| 12. Portfolio completeness checker | Not implemented | Deterministic completeness rules from saved records, separate from AI. |
| 13. Settings and account management | Partial | Sign-out exists. Add privacy settings, visibility, account deletion and related-data handling. |
| Supabase/backend security | Partial | Client initialization, owner-scoped table RLS, and a private Evidence bucket with per-user object policies exist. Apply remaining migrations; account deletion and server-side AI Edge Functions remain. |
| Google Play release | Not implemented | Release ID decision, privacy/data review, signed bundle, store listing/assets, closed testing and current Play Console requirements. |

## Delivery order

1. Project CRUD and private-by-default project records. (Implemented; apply the Supabase migration.)
2. Skill library and project-skill relationships. (Implemented; apply the Supabase migrations.)
3. Inclusive profile background, education and experience. (Implemented; apply `20261023100000_expand_profile_and_skills.sql`.)
4. Certifications and achievements. (Implemented; apply `20261024100000_create_portfolio_records.sql`.)
5. Shared private Evidence library, file uploads, URL evidence, and links to portfolio records. (Implemented; apply `20261025100000_create_evidence.sql`.)
6. Profile photo/contact fields and private portfolio preview with descriptive content coverage. (Implemented; apply `20261026100000_expand_profile_portfolio_contacts.sql`.)
7. Light/dark portfolio templates, selected-content review, download, and explicit publication. (Implemented; apply `20261027100000_create_portfolio_publications.sql` and configure `PORTFOLIO_PUBLIC_BASE_URL` before live publishing.)
8. Resume preview and PDF/DOCX export from saved records.
9. Full profile/settings/privacy and account deletion.
10. Live dashboard refinement and deterministic completeness/readiness checklists.
11. Server-side AI Edge Function and reviewed portfolio/resume drafts.
12. Accessibility/privacy refinement, Android release build, store materials and Play testing.

AI and public sharing come after the underlying records and access policies, as the master prompt requires. Every career statement remains grounded in user-supplied information and user review.
