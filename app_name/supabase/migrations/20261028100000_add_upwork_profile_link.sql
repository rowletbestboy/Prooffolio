alter table public.profiles
  add column if not exists upwork_url text;

alter table public.profiles
  drop constraint if exists profiles_upwork_url_valid;

alter table public.profiles
  add constraint profiles_upwork_url_valid
    check (
      upwork_url is null
      or upwork_url ~* '^https://(www\.)?upwork\.com/freelancers/[^[:space:]]+$'
    );
