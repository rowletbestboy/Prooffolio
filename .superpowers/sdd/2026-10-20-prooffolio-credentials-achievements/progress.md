# SDD ledger — Certifications and Achievements

Pre-flight: Existing Supabase repository, route wiring, Material 3 theme, and approved inclusive portfolio design inspected before implementation.
Ruling: Work in supplied workspace because `C:\Users\sergr\Desktop\Prooffolio` has no `.git` directory; isolated worktrees and commit tracking are unavailable. Cost if wrong: the changes are not isolated in version control.
Task 1: Domain model, repository, and additive owner-only migration implemented. Focused model tests passed.
Task 2: Home entry point and record CRUD screen implemented. Widget tests cover project-free achievements, optional issuers, certificate expiration, delete refresh, empty states, type switching, privacy, and Home navigation.
Task 3: Setup guide and roadmap updated. `flutter test --no-pub` → 33 passed; `dart analyze` → no issues.
External step: Apply `app_name/supabase/migrations/20261024100000_create_portfolio_records.sql` to the connected Supabase project before using the feature live.
