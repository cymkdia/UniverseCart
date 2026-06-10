-- Universe Cart M12: 약속 펀딩 (금액·메시지 기록, UC는 결제 없음)
-- Supabase SQL Editor → New query → 붙여넣기 → Run

create table if not exists public.funding_pledges (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items (id) on delete cascade,
  contributor_user_id uuid not null references auth.users (id) on delete cascade,
  amount integer not null check (amount > 0),
  message text,
  contributor_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (item_id, contributor_user_id)
);

create index if not exists funding_pledges_item_id_idx on public.funding_pledges (item_id);
create index if not exists funding_pledges_contributor_idx on public.funding_pledges (contributor_user_id);

alter table public.funding_pledges enable row level security;

drop policy if exists "pledges_select_shared_wishlist" on public.funding_pledges;
drop policy if exists "pledges_select_owner" on public.funding_pledges;
drop policy if exists "pledges_select_contributor" on public.funding_pledges;
drop policy if exists "pledges_insert_contributor" on public.funding_pledges;
drop policy if exists "pledges_update_contributor" on public.funding_pledges;
drop policy if exists "pledges_delete_contributor" on public.funding_pledges;

-- 공개 위시리스트 상품의 약속 (웹·비로그인 읽기)
create policy "pledges_select_shared_wishlist"
  on public.funding_pledges for select
  using (
    exists (
      select 1
      from public.items i
      join public.profiles p on p.user_id = i.user_id
      where i.id = funding_pledges.item_id
        and i.list_type = 'wishlist'
        and p.share_enabled = true
    )
  );

-- 위시 주인이 자기 상품 약속 보기
create policy "pledges_select_owner"
  on public.funding_pledges for select
  using (
    exists (
      select 1
      from public.items i
      where i.id = funding_pledges.item_id
        and i.user_id = auth.uid()
    )
  );

-- 참여자가 자기 약속 보기
create policy "pledges_select_contributor"
  on public.funding_pledges for select
  using (auth.uid() = contributor_user_id);

-- 로그인 친구가 약속 참여 (주인 본인은 불가)
create policy "pledges_insert_contributor"
  on public.funding_pledges for insert
  with check (
    auth.uid() = contributor_user_id
    and exists (
      select 1
      from public.items i
      join public.profiles p on p.user_id = i.user_id
      where i.id = item_id
        and i.list_type = 'wishlist'
        and p.share_enabled = true
        and i.user_id <> auth.uid()
    )
  );

create policy "pledges_update_contributor"
  on public.funding_pledges for update
  using (auth.uid() = contributor_user_id)
  with check (auth.uid() = contributor_user_id);

create policy "pledges_delete_contributor"
  on public.funding_pledges for delete
  using (auth.uid() = contributor_user_id);

-- API(anon/authenticated)에서 테이블 접근 허용
grant select on table public.funding_pledges to anon, authenticated;
grant insert, update, delete on table public.funding_pledges to authenticated;
