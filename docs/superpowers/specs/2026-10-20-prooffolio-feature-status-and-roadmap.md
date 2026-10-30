# Prooffolio Feature Inventory and Build Roadmap

This roadmap tracks the requirements in the supplied `MASTER PROJECT PROMPT — PROOFFOLIO`. The app must grow incrementally; this is the full product scope, not a claim that every feature is already present.

## Current implementation status

| Master-prompt feature | Status | Remaining work |
|---|---|---|
| 1. Onboarding and authentication | Partial | Sign-in, registration, recovery, session routing and basic identity setup exist. Add welcome/introduction, richer profile setup, privacy notice, and verify live auth/deep links. |
| 2. Dashboard | Partial | Theme, navigation, live counts, a profile-completion reminder, and evidence-trail introduction exist. Recent activity and a broader dashboard summary remain. |
| 3. Profile builder | Partial; inclusive background and private photo/contact editor implemented | Display name, username, optional headline/bio, 17 occupation areas, custom occupation title, career stage, interests, target roles, repeatable education and experience, profile photo, and optional contact links are available. Apply `20261023100000_expand_profile_and_skills.sql`, `20261026100000_expand_profile_portfolio_contacts.sql`, and `20261028100000_add_upwork_profile_link.sql` if they are not already applied. Visibility controls remain limited to explicit generated-portfolio selection. |
| 4. Project management | Implemented; migration required | Project CRUD, project fields, list/details/edit, validation, private draft default and delete confirmation are in the app. Apply `20261021100000_create_projects.sql` to Supabase before live use. Search/filter remains a later refinement. |
| 5. Skill library | Implemented; migration required | Skill CRUD, broad cross-occupation categories and self-reported Learning/Practicing/Applied labels. Apply the skills migration and `20261023100000_expand_profile_and_skills.sql` to Supabase before live use. |
| 6. Certifications and achievements | Implemented; migration required | Add, edit, and delete private credentials and recognition records without a project. Apply `20261024100000_create_portfolio_records.sql`. Selected records can appear in the generated portfolio; linked Evidence files stay private and are never included. |
| 7. Skill-to-evidence mapping | Implemented; migration required | Private file and URL evidence can link to owned projects, skills, experience, certifications, and achievements. Apply `20261025100000_create_evidence.sql`; public evidence sharing is not enabled. |
| 8. Public portfolio website | Implemented in app; external setup and live verification remain | Private preview, content selection, one generated responsive website with an in-page light/dark toggle, ZIP download, and explicit publish/update/unpublish flows exist. Live publishing requires the ordered profile/publication migrations and `PORTFOLIO_PUBLIC_BASE_URL` pointing to the public `published-portfolios` bucket. Confirm the user's Supabase migration and bucket state before claiming deployment is ready. |
| 9. AI portfolio generator | Not implemented | Website generation is deterministic from user-saved content; AI role/project drafting, structured generation and editing remain. |
| 10. Resume/CV builder and exports | Implemented without AI | Factual resume previews, optional photo layout, and PDF/DOCX export exist. AI-assisted role/job-description drafting remains; ATS-friendly is a layout description, not a parser guarantee. |
| 11. AI career readiness assistant | Not implemented | Transparent actionable recommendations, no employability score or claim of assessed ability. |
| 12. Portfolio completeness checker | Partial | Deterministic portfolio readiness suggestions and a profile-completion reminder exist. A broader completeness/checklist experience remains. |
| 13. Settings and account management | Partial | Sign-out exists. Add privacy settings, visibility, account deletion and related-data handling. |
| Supabase/backend security | Partial | Client initialization, owner-scoped table RLS, and a private Evidence bucket with per-user object policies exist. Apply remaining migrations; account deletion and server-side AI Edge Functions remain. |
| Google Play release | Not implemented | Release ID decision, privacy/data review, signed bundle, store listing/assets, closed testing and current Play Console requirements. |

## Delivery order

1. Project CRUD and private-by-default project records. (Implemented; apply the Supabase migration.)
2. Skill library and project-skill relationships. (Implemented; apply the Supabase migrations.)
3. Inclusive profile background, education and experience. (Implemented; apply `20261023100000_expand_profile_and_skills.sql`.)
4. Certifications and achievements. (Implemented; apply `20261024100000_create_portfolio_records.sql`.)
5. Shared private Evidence library, file uploads, URL evidence, and links to portfolio records. (Implemented; apply `20261025100000_create_evidence.sql`.)
6. Full settings/privacy controls and account deletion.
7. Expand live dashboard activity and deterministic completeness/readiness guidance.
8. Configure and verify live portfolio publishing in the target Supabase project; complete browser/device acceptance.
9. Server-side AI Edge Functions and reviewed portfolio/resume drafts.
10. Accessibility/privacy refinement, Android release build, store materials and Play testing.

AI and public sharing come after the underlying records and access policies, as the master prompt requires. Every career statement remains grounded in user-supplied information and user review. The generated website publishes only content explicitly selected by the user; Evidence remains private.
