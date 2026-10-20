-- Expand profile details without changing existing sign-up identity requirements.
alter table public.profiles
  add column if not exists headline text,
  add column if not exists bio text not null default '',
  add column if not exists occupation_category text,
  add column if not exists occupation_title text,
  add column if not exists career_stage text,
  add column if not exists interests text[] not null default '{}',
  add column if not exists target_roles text[] not null default '{}';

alter table public.profiles
  drop constraint if exists profiles_headline_length,
  drop constraint if exists profiles_bio_length,
  drop constraint if exists profiles_occupation_category_valid,
  drop constraint if exists profiles_occupation_title_length,
  drop constraint if exists profiles_career_stage_valid;

alter table public.profiles
  add constraint profiles_headline_length
    check (headline is null or char_length(headline) <= 120),
  add constraint profiles_bio_length
    check (char_length(bio) <= 2000),
  add constraint profiles_occupation_category_valid check (
    occupation_category is null or occupation_category in (
      'agriculture_forestry_fisheries', 'arts_media_design',
      'business_finance_administration', 'construction_skilled_trades',
      'education_training', 'engineering_manufacturing',
      'healthcare_care_services', 'hospitality_tourism', 'technology_digital',
      'legal_public_service', 'science_research', 'sales_customer_service',
      'transportation_logistics', 'virtual_assistance_remote_operations',
      'community_nonprofit', 'student_early_career', 'other'
    )
  ),
  add constraint profiles_occupation_title_length
    check (occupation_title is null or char_length(occupation_title) <= 120),
  add constraint profiles_career_stage_valid check (
    career_stage is null or career_stage in (
      'student', 'early_career', 'experienced', 'career_changer',
      'returning_to_work', 'self_employed', 'other'
    )
  );

create table if not exists public.education_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 160),
  institution text check (institution is null or char_length(institution) <= 160),
  level text check (level is null or level in (
    'secondary', 'vocational', 'certificate', 'diploma', 'associate',
    'bachelor', 'master', 'doctoral', 'other'
  )),
  status text not null default 'in_progress'
    check (status in ('in_progress', 'completed', 'paused')),
  start_date date,
  end_date date,
  description text not null default '' check (char_length(description) <= 3000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint education_records_date_order check (
    start_date is null or end_date is null or end_date >= start_date
  ),
  constraint education_records_user_id_id_unique unique (user_id, id)
);

create index if not exists education_records_user_updated_idx
  on public.education_records (user_id, updated_at desc);

create table if not exists public.experience_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 160),
  organization text check (organization is null or char_length(organization) <= 160),
  experience_type text not null check (experience_type in (
    'employment', 'freelance', 'internship', 'volunteering',
    'community_work', 'caregiving', 'independent_practice', 'other'
  )),
  start_date date,
  end_date date,
  is_current boolean not null default false,
  description text not null default '' check (char_length(description) <= 3000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint experience_records_current_end_date check (
    not is_current or end_date is null
  ),
  constraint experience_records_date_order check (
    start_date is null or end_date is null or end_date >= start_date
  ),
  constraint experience_records_user_id_id_unique unique (user_id, id)
);

create index if not exists experience_records_user_updated_idx
  on public.experience_records (user_id, updated_at desc);

alter table public.education_records enable row level security;
alter table public.experience_records enable row level security;
grant select, insert, update, delete on public.education_records to authenticated;
grant select, insert, update, delete on public.experience_records to authenticated;

drop policy if exists "Users can read their own education records" on public.education_records;
drop policy if exists "Users can create their own education records" on public.education_records;
drop policy if exists "Users can update their own education records" on public.education_records;
drop policy if exists "Users can delete their own education records" on public.education_records;

create policy "Users can read their own education records"
  on public.education_records for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users can create their own education records"
  on public.education_records for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users can update their own education records"
  on public.education_records for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "Users can delete their own education records"
  on public.education_records for delete to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can read their own experience records" on public.experience_records;
drop policy if exists "Users can create their own experience records" on public.experience_records;
drop policy if exists "Users can update their own experience records" on public.experience_records;
drop policy if exists "Users can delete their own experience records" on public.experience_records;

create policy "Users can read their own experience records"
  on public.experience_records for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users can create their own experience records"
  on public.experience_records for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users can update their own experience records"
  on public.experience_records for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "Users can delete their own experience records"
  on public.experience_records for delete to authenticated
  using ((select auth.uid()) = user_id);

-- Keep existing skill names, statuses, and links while replacing the narrow
-- technology-specific categories with a cross-occupation taxonomy.
alter table public.skills drop constraint if exists skills_category_check;

update public.skills
set category = 'technology_digital'
where category in (
  'programming_languages', 'mobile_development', 'web_development',
  'backend_development', 'databases', 'embedded_systems_iot',
  'networking_systems', 'software_engineering', 'testing_debugging',
  'technical_documentation'
);

alter table public.skills
  add constraint skills_category_check check (category in (
    'agriculture_environment', 'arts_media_design', 'business_administration',
    'construction_trades', 'education_training', 'engineering_manufacturing',
    'healthcare_care', 'hospitality_tourism', 'technology_digital',
    'law_public_service', 'science_research', 'sales_customer_service',
    'transport_logistics', 'virtual_assistance_remote_operations',
    'communication_languages', 'leadership_project_management', 'other'
  ));
