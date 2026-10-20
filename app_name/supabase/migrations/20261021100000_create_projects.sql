create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 120),
  summary text not null default '' check (char_length(summary) <= 280),
  problem_statement text not null default '' check (char_length(problem_statement) <= 5000),
  description text not null default '' check (char_length(description) <= 8000),
  key_features text[] not null default '{}',
  technologies text[] not null default '{}',
  contribution text not null default '' check (char_length(contribution) <= 3000),
  challenges text not null default '' check (char_length(challenges) <= 3000),
  lessons_learned text not null default '' check (char_length(lessons_learned) <= 3000),
  start_date date,
  end_date date,
  constraint projects_repository_url_format check (
    repository_url is null or
      (char_length(repository_url) <= 2048 and repository_url ~* '^https?://[^[:space:]]+$')
  ),
  constraint projects_demo_url_format check (
    demo_url is null or
      (char_length(demo_url) <= 2048 and demo_url ~* '^https?://[^[:space:]]+$')
  ),
  status text not null default 'in_progress'
    check (status in ('in_progress', 'completed', 'paused')),
  repository_url text,
  demo_url text,
  publication_status text not null default 'draft'
    check (publication_status in ('draft', 'published')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint projects_date_order check (
    start_date is null or end_date is null or end_date >= start_date
  ),
  constraint projects_user_id_id_unique unique (user_id, id)
);

create index if not exists projects_user_updated_idx
  on public.projects (user_id, updated_at desc);

alter table public.projects enable row level security;
grant select, insert, update, delete on table public.projects to authenticated;

drop policy if exists "Users can read their own projects" on public.projects;
drop policy if exists "Users can create their own projects" on public.projects;
drop policy if exists "Users can update their own projects" on public.projects;
drop policy if exists "Users can delete their own projects" on public.projects;

create policy "Users can read their own projects"
  on public.projects for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can create their own projects"
  on public.projects for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Users can update their own projects"
  on public.projects for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users can delete their own projects"
  on public.projects for delete to authenticated
  using ((select auth.uid()) = user_id);
