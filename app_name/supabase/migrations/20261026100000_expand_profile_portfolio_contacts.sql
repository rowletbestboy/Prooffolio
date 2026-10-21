-- Private profile contact fields and photo storage for the portfolio editor.
alter table public.profiles
  add column if not exists photo_path text,
  add column if not exists contact_email text,
  add column if not exists phone text,
  add column if not exists github_url text,
  add column if not exists linkedin_url text,
  add column if not exists jobstreet_url text,
  add column if not exists whatsapp_number text,
  add column if not exists additional_links jsonb not null default '[]'::jsonb;

alter table public.profiles
  drop constraint if exists profiles_additional_links_is_array;

alter table public.profiles
  add constraint profiles_additional_links_is_array
    check (jsonb_typeof(additional_links) = 'array');

-- Photos remain private while the profile is unpublished. A later publication
-- migration copies only a deliberately selected photo into public assets.
insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
) values (
  'profile-photos',
  'profile-photos',
  false,
  5000000,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  name = excluded.name,
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Users can read their own profile photos" on storage.objects;
drop policy if exists "Users can upload their own profile photos" on storage.objects;
drop policy if exists "Users can delete their own profile photos" on storage.objects;

create policy "Users can read their own profile photos"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Users can upload their own profile photos"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Users can delete their own profile photos"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
