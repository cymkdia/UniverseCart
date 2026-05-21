-- Universe Cart M5: items 테이블 + RLS
-- Supabase 대시보드 → SQL Editor → New query → 붙여넣기 → Run

create table if not exists public.items (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  image_url text,
  price integer,
  product_url text not null,
  mall text not null,
  category text not null,
  list_type text not null,
  updated_at timestamptz not null default now()
);

create index if not exists items_user_id_idx on public.items (user_id);

alter table public.items enable row level security;

drop policy if exists "items_select_own" on public.items;
drop policy if exists "items_insert_own" on public.items;
drop policy if exists "items_update_own" on public.items;
drop policy if exists "items_delete_own" on public.items;

create policy "items_select_own"
  on public.items for select
  using (auth.uid() = user_id);

create policy "items_insert_own"
  on public.items for insert
  with check (auth.uid() = user_id);

create policy "items_update_own"
  on public.items for update
  using (auth.uid() = user_id);

create policy "items_delete_own"
  on public.items for delete
  using (auth.uid() = user_id);
