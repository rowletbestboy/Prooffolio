-- Keep the optional Upwork URL in the existing owner-private profile row.
alter table public.profiles
  add column if not exists upwork_url text;
