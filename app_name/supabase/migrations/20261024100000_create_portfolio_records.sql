-- Private, owner-managed credentials and recognition records.
create table if not exists public.portfolio_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  record_type text not null check (record_type in ('certification', 'achievement')),
  title text not null check (char_length(trim(title)) between 1 and 160),
  source text check (source is null or char_length(source) <= 160),
  description text not null default '' check (char_length(description) <= 3000),
  achieved_on date,
  expires_on date,
  is_public boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint portfolio_records_certificate_expiration check (
    expires_on is null or record_type = 'certification'
  ),
  constraint portfolio_records_date_order check (
    achieved_on is null or expires_on is null or expires_on >= achieved_on
  ),
  constraint portfolio_records_user_id_id_unique unique (user_id, id)
);

create index if not exists portfolio_records_user_type_updated_idx
  on public.portfolio_records (user_id, record_type, updated_at desc);

alter table public.portfolio_records enable row level security;
grant select, insert, update, delete on public.portfolio_records to authenticated;

drop policy if exists "Users can read their own portfolio records" on public.portfolio_records;
drop policy if exists "Users can create their own portfolio records" on public.portfolio_records;
drop policy if exists "Users can update their own portfolio records" on public.portfolio_records;
drop policy if exists "Users can delete their own portfolio records" on public.portfolio_records;

create policy "Users can read their own portfolio records"
  on public.portfolio_records for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users can create their own portfolio records"
  on public.portfolio_records for insert to authenticated
  with check ((select auth.uid()) = user_id and is_public = false);
create policy "Users can update their own portfolio records"
  on public.portfolio_records for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id and is_public = false);
create policy "Users can delete their own portfolio records"
  on public.portfolio_records for delete to authenticated
  using ((select auth.uid()) = user_id);
