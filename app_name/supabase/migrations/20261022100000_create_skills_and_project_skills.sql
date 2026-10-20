create table if not exists public.skills (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 80),
  category text not null check (category in (
    'programming_languages', 'mobile_development', 'web_development',
    'backend_development', 'databases', 'embedded_systems_iot',
    'networking_systems', 'software_engineering', 'testing_debugging',
    'technical_documentation', 'other'
  )),
  status text not null default 'learning'
    check (status in ('learning', 'practicing', 'applied')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint skills_user_id_id_unique unique (user_id, id)
);

create unique index if not exists skills_user_name_unique
  on public.skills (user_id, lower(trim(name)));
create index if not exists skills_user_name_idx
  on public.skills (user_id, name);

create table if not exists public.project_skills (
  user_id uuid not null references auth.users (id) on delete cascade,
  project_id uuid not null,
  skill_id uuid not null,
  created_at timestamptz not null default now(),
  primary key (user_id, project_id, skill_id),
  constraint project_skills_project_owner_fk
    foreign key (user_id, project_id)
    references public.projects (user_id, id) on delete cascade,
  constraint project_skills_skill_owner_fk
    foreign key (user_id, skill_id)
    references public.skills (user_id, id) on delete cascade
);

create index if not exists project_skills_skill_idx
  on public.project_skills (user_id, skill_id);

alter table public.skills enable row level security;
alter table public.project_skills enable row level security;
grant select, insert, update, delete on public.skills to authenticated;
grant select, insert, delete on public.project_skills to authenticated;

drop policy if exists "Users can read their own skills" on public.skills;
drop policy if exists "Users can create their own skills" on public.skills;
drop policy if exists "Users can update their own skills" on public.skills;
drop policy if exists "Users can delete their own skills" on public.skills;

create policy "Users can read their own skills"
  on public.skills for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users can create their own skills"
  on public.skills for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users can update their own skills"
  on public.skills for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "Users can delete their own skills"
  on public.skills for delete to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can read their own project skill links" on public.project_skills;
drop policy if exists "Users can create their own project skill links" on public.project_skills;
drop policy if exists "Users can delete their own project skill links" on public.project_skills;

create policy "Users can read their own project skill links"
  on public.project_skills for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users can create their own project skill links"
  on public.project_skills for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users can delete their own project skill links"
  on public.project_skills for delete to authenticated
  using ((select auth.uid()) = user_id);

create or replace function public.save_skill_with_projects(
  p_skill_id uuid,
  p_name text,
  p_category text,
  p_status text,
  p_project_ids uuid[]
) returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  saved_skill_id uuid;
  project_id uuid;
begin
  if current_user_id is null then
    raise exception 'Sign in is required to save a skill.' using errcode = '42501';
  end if;

  if p_skill_id is null then
    insert into public.skills (user_id, name, category, status)
    values (current_user_id, trim(p_name), p_category, p_status)
    returning id into saved_skill_id;
  else
    update public.skills
    set name = trim(p_name), category = p_category, status = p_status,
        updated_at = now()
    where id = p_skill_id and user_id = current_user_id
    returning id into saved_skill_id;
    if saved_skill_id is null then
      raise exception 'Skill was not found.' using errcode = 'P0002';
    end if;
  end if;

  delete from public.project_skills
  where user_id = current_user_id and skill_id = saved_skill_id;

  foreach project_id in array coalesce(p_project_ids, '{}'::uuid[]) loop
    insert into public.project_skills (user_id, project_id, skill_id)
    values (current_user_id, project_id, saved_skill_id)
    on conflict do nothing;
  end loop;

  return saved_skill_id;
end;
$$;

revoke all on function public.save_skill_with_projects(uuid, text, text, text, uuid[]) from public;
grant execute on function public.save_skill_with_projects(uuid, text, text, text, uuid[]) to authenticated;
