-- Private evidence metadata, typed links, and Storage objects.
create table if not exists public.evidence_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  kind text not null check (kind in ('file', 'url')),
  title text not null check (char_length(trim(title)) between 1 and 160),
  description text not null default '' check (char_length(description) <= 3000),
  source_url text,
  file_name text,
  content_type text,
  size_bytes bigint,
  storage_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint evidence_records_kind_fields check (
    (kind = 'url'
      and source_url is not null
      and source_url ~* '^https?://[^[:space:]/?#]+([/?#][^[:space:]]*)?$'
      and file_name is null
      and content_type is null
      and size_bytes is null
      and storage_path is null)
    or
    (kind = 'file'
      and source_url is null
      and file_name is not null
      and content_type is not null
      and size_bytes between 1 and 50000000
      and storage_path is not null)
  ),
  constraint evidence_records_storage_path_unique unique (storage_path),
  constraint evidence_records_user_id_id_unique unique (user_id, id)
);

create index if not exists evidence_records_user_updated_idx
  on public.evidence_records (user_id, updated_at desc);

alter table public.evidence_records enable row level security;
grant select, insert, update, delete on public.evidence_records to authenticated;

drop policy if exists "Users can read their own evidence" on public.evidence_records;
drop policy if exists "Users can add their own evidence" on public.evidence_records;
drop policy if exists "Users can update their own evidence" on public.evidence_records;
drop policy if exists "Users can delete their own evidence" on public.evidence_records;

create policy "Users can read their own evidence"
  on public.evidence_records for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users can add their own evidence"
  on public.evidence_records for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users can update their own evidence"
  on public.evidence_records for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "Users can delete their own evidence"
  on public.evidence_records for delete to authenticated
  using ((select auth.uid()) = user_id);

-- Require the app to remove private file objects through Storage before
-- deleting their metadata, so ordinary row deletion cannot orphan objects.
create or replace function public.prevent_evidence_object_orphan()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.storage_path is not null and exists (
    select 1 from storage.objects
    where bucket_id = 'evidence' and name = old.storage_path
  ) then
    raise exception 'Remove the evidence Storage object before deleting its record.'
      using errcode = '23503';
  end if;
  return old;
end;
$$;

drop trigger if exists evidence_records_require_object_removal
  on public.evidence_records;
create trigger evidence_records_require_object_removal
  before delete on public.evidence_records
  for each row execute function public.prevent_evidence_object_orphan();

create table if not exists public.evidence_links (
  user_id uuid not null references auth.users (id) on delete cascade,
  evidence_id uuid not null,
  target_type text not null check (
    target_type in ('project', 'skill', 'experience', 'portfolio_record')
  ),
  target_id uuid not null,
  created_at timestamptz not null default now(),
  primary key (user_id, evidence_id, target_type, target_id),
  constraint evidence_links_evidence_owner_fk
    foreign key (user_id, evidence_id)
    references public.evidence_records (user_id, id) on delete cascade
);

create index if not exists evidence_links_user_target_idx
  on public.evidence_links (user_id, target_type, target_id);

alter table public.evidence_links enable row level security;
grant select, insert, delete on public.evidence_links to authenticated;

drop policy if exists "Users can read their own evidence links" on public.evidence_links;
drop policy if exists "Users can add their own evidence links" on public.evidence_links;
drop policy if exists "Users can delete their own evidence links" on public.evidence_links;

create policy "Users can read their own evidence links"
  on public.evidence_links for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users can add their own evidence links"
  on public.evidence_links for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users can delete their own evidence links"
  on public.evidence_links for delete to authenticated
  using ((select auth.uid()) = user_id);

create or replace function public.validate_evidence_link_target()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  target_exists boolean := false;
begin
  case new.target_type
    when 'project' then
      select exists (
        select 1 from public.projects
        where user_id = new.user_id and id = new.target_id
      ) into target_exists;
    when 'skill' then
      select exists (
        select 1 from public.skills
        where user_id = new.user_id and id = new.target_id
      ) into target_exists;
    when 'experience' then
      select exists (
        select 1 from public.experience_records
        where user_id = new.user_id and id = new.target_id
      ) into target_exists;
    when 'portfolio_record' then
      select exists (
        select 1 from public.portfolio_records
        where user_id = new.user_id and id = new.target_id
      ) into target_exists;
  end case;

  if not target_exists then
    raise exception 'Evidence links must target a record owned by the same user.'
      using errcode = '23503';
  end if;
  return new;
end;
$$;

drop trigger if exists evidence_links_validate_target on public.evidence_links;
create trigger evidence_links_validate_target
  before insert or update on public.evidence_links
  for each row execute function public.validate_evidence_link_target();

create or replace function public.remove_evidence_links_for_target()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  deleted_target_type text;
begin
  deleted_target_type := case tg_table_name
    when 'projects' then 'project'
    when 'skills' then 'skill'
    when 'experience_records' then 'experience'
    when 'portfolio_records' then 'portfolio_record'
  end;
  delete from public.evidence_links
    where user_id = old.user_id
      and target_type = deleted_target_type
      and target_id = old.id;
  return old;
end;
$$;

drop trigger if exists projects_remove_evidence_links on public.projects;
create trigger projects_remove_evidence_links
  after delete on public.projects for each row
  execute function public.remove_evidence_links_for_target();
drop trigger if exists skills_remove_evidence_links on public.skills;
create trigger skills_remove_evidence_links
  after delete on public.skills for each row
  execute function public.remove_evidence_links_for_target();
drop trigger if exists experience_remove_evidence_links on public.experience_records;
create trigger experience_remove_evidence_links
  after delete on public.experience_records for each row
  execute function public.remove_evidence_links_for_target();
drop trigger if exists portfolio_records_remove_evidence_links on public.portfolio_records;
create trigger portfolio_records_remove_evidence_links
  after delete on public.portfolio_records for each row
  execute function public.remove_evidence_links_for_target();

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
) values (
  'evidence',
  'evidence',
  false,
  50000000,
  array[
    'image/jpeg', 'image/png', 'image/webp',
    'application/pdf', 'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'text/plain', 'application/rtf', 'text/rtf', 'text/csv', 'application/csv',
    'video/mp4', 'video/quicktime', 'video/webm',
    'audio/mpeg', 'audio/mp3', 'audio/mp4', 'audio/x-m4a',
    'audio/wav', 'audio/x-wav', 'audio/wave', 'audio/ogg', 'application/ogg'
  ]
)
on conflict (id) do update set
  name = excluded.name,
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Users can read their own evidence objects" on storage.objects;
drop policy if exists "Users can upload their own evidence objects" on storage.objects;
drop policy if exists "Users can delete their own evidence objects" on storage.objects;

create policy "Users can read their own evidence objects"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'evidence'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy "Users can upload their own evidence objects"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'evidence'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy "Users can delete their own evidence objects"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'evidence'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
