-- Universe Cart M6: 공유 위시리스트 (profiles + 공개 읽기)
-- Supabase SQL Editor → New query → 붙여넣기 → Run

create table if not exists public.profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  share_slug text unique,
  share_enabled boolean not null default false,
  updated_at timestamptz not null default now()
);

create index if not exists profiles_share_slug_idx on public.profiles (share_slug);

alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own_or_public" on public.profiles;
drop policy if exists "profiles_insert_own" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;

create policy "profiles_select_own_or_public"
  on public.profiles for select
  using (auth.uid() = user_id or share_enabled = true);

create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = user_id);

create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = user_id);

-- 위시리스트 공개 시, 로그인 없이도 읽기 (웹 페이지용)
drop policy if exists "items_select_shared_wishlist" on public.items;

create policy "items_select_shared_wishlist"
  on public.items for select
  using (
    list_type = 'wishlist'
    and exists (
      select 1
      from public.profiles p
      where p.user_id = items.user_id
        and p.share_enabled = true
    )
  );
