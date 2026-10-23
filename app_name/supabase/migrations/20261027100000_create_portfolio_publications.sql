create table if not exists public.portfolio_publications (
  user_id uuid primary key references auth.users (id) on delete cascade,
  username text not null check (username ~ '^[a-z0-9_]{3,24}$'),
  is_published boolean not null default false,
  template text not null check (template in ('light', 'dark')),
  selection jsonb not null default '{}'::jsonb
    check (jsonb_typeof(selection) = 'object'),
  selected_snapshot jsonb not null default '{}'::jsonb
    check (jsonb_typeof(selected_snapshot) = 'object'),
  published_at timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.portfolio_publications enable row level security;
revoke all on table public.portfolio_publications from anon, public;
grant select, insert, update on table public.portfolio_publications
  to authenticated;

drop policy if exists "Owners can read their portfolio publication"
  on public.portfolio_publications;
create policy "Owners can read their portfolio publication"
  on public.portfolio_publications for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Owners can create their portfolio publication"
  on public.portfolio_publications;
create policy "Owners can create their portfolio publication"
  on public.portfolio_publications for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1
      from public.profiles as profile
      where profile.user_id = (select auth.uid())
        and lower(profile.username) = portfolio_publications.username
    )
  );

drop policy if exists "Owners can update their portfolio publication"
  on public.portfolio_publications;
create policy "Owners can update their portfolio publication"
  on public.portfolio_publications for update to authenticated
  using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1
      from public.profiles as profile
      where profile.user_id = (select auth.uid())
        and lower(profile.username) = portfolio_publications.username
    )
  );

create unique index if not exists portfolio_publications_active_username_unique
  on public.portfolio_publications (username)
  where is_published;

create or replace function public.prevent_published_portfolio_username_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if lower(new.username) is distinct from lower(old.username)
     and exists (
       select 1
       from public.portfolio_publications as publication
       where publication.user_id = old.user_id
         and publication.is_published
     ) then
    raise exception
      using errcode = 'P0001',
            message = 'Unpublish your portfolio before changing your username.';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_prevent_published_username_change
  on public.profiles;
create trigger profiles_prevent_published_username_change
  before update of username on public.profiles
  for each row
  execute function public.prevent_published_portfolio_username_change();

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
) values (
  'published-portfolios',
  'published-portfolios',
  true,
  10000000,
  array[
    'text/html',
    'text/css',
    'text/javascript',
    'application/javascript',
    'image/jpeg',
    'image/png',
    'image/webp'
  ]
)
on conflict (id) do update set
  name = excluded.name,
  public = true,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Owners can list their published portfolio files"
  on storage.objects;
create policy "Owners can list their published portfolio files"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'published-portfolios'
    and exists (
      select 1
      from public.profiles as profile
      where profile.user_id = (select auth.uid())
        and name in (
          lower(profile.username) || '/index.html',
          lower(profile.username) || '/styles.css',
          lower(profile.username) || '/app.js',
          lower(profile.username) || '/portfolio-photo.jpg',
          lower(profile.username) || '/portfolio-photo.png',
          lower(profile.username) || '/portfolio-photo.webp'
        )
    )
  );

drop policy if exists "Owners can upload their published portfolio files"
  on storage.objects;
create policy "Owners can upload their published portfolio files"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'published-portfolios'
    and exists (
      select 1
      from public.profiles as profile
      where profile.user_id = (select auth.uid())
        and name in (
          lower(profile.username) || '/index.html',
          lower(profile.username) || '/styles.css',
          lower(profile.username) || '/app.js',
          lower(profile.username) || '/portfolio-photo.jpg',
          lower(profile.username) || '/portfolio-photo.png',
          lower(profile.username) || '/portfolio-photo.webp'
        )
    )
  );

drop policy if exists "Owners can update their published portfolio files"
  on storage.objects;
create policy "Owners can update their published portfolio files"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'published-portfolios'
    and exists (
      select 1
      from public.profiles as profile
      where profile.user_id = (select auth.uid())
        and name in (
          lower(profile.username) || '/index.html',
          lower(profile.username) || '/styles.css',
          lower(profile.username) || '/app.js',
          lower(profile.username) || '/portfolio-photo.jpg',
          lower(profile.username) || '/portfolio-photo.png',
          lower(profile.username) || '/portfolio-photo.webp'
        )
    )
  )
  with check (
    bucket_id = 'published-portfolios'
    and exists (
      select 1
      from public.profiles as profile
      where profile.user_id = (select auth.uid())
        and name in (
          lower(profile.username) || '/index.html',
          lower(profile.username) || '/styles.css',
          lower(profile.username) || '/app.js',
          lower(profile.username) || '/portfolio-photo.jpg',
          lower(profile.username) || '/portfolio-photo.png',
          lower(profile.username) || '/portfolio-photo.webp'
        )
    )
  );

drop policy if exists "Owners can delete their published portfolio files"
  on storage.objects;
create policy "Owners can delete their published portfolio files"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'published-portfolios'
    and exists (
      select 1
      from public.profiles as profile
      where profile.user_id = (select auth.uid())
        and name in (
          lower(profile.username) || '/index.html',
          lower(profile.username) || '/styles.css',
          lower(profile.username) || '/app.js',
          lower(profile.username) || '/portfolio-photo.jpg',
          lower(profile.username) || '/portfolio-photo.png',
          lower(profile.username) || '/portfolio-photo.webp'
        )
    )
  );
