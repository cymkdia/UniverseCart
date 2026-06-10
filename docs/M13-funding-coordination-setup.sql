-- Universe Cart M13: 펀딩 코디네이션 (100% 이후 흐름)
-- Supabase SQL Editor → New query → Run

-- ---------------------------------------------------------------------------
-- 1. funding_coordinations — 상품별 코디네이션 상태
-- ---------------------------------------------------------------------------
create table if not exists public.funding_coordinations (
  item_id uuid primary key references public.items (id) on delete cascade,
  owner_user_id uuid not null references auth.users (id) on delete cascade,
  state text not null default 'collecting'
    check (state in ('collecting', 'goal_reached', 'buyer_assigned', 'purchased', 'received')),
  buyer_user_id uuid references auth.users (id),
  goal_reached_at timestamptz,
  purchased_at timestamptz,
  received_at timestamptz,
  thank_you_message text,
  settlement_bank_name text,
  settlement_bank_code text,
  settlement_account_number text,
  updated_at timestamptz not null default now()
);

create index if not exists funding_coordinations_owner_idx
  on public.funding_coordinations (owner_user_id);
create index if not exists funding_coordinations_state_idx
  on public.funding_coordinations (state);

alter table public.funding_coordinations enable row level security;

drop policy if exists "coord_select_involved" on public.funding_coordinations;
drop policy if exists "coord_select_shared" on public.funding_coordinations;
drop policy if exists "coord_insert_system" on public.funding_coordinations;
drop policy if exists "coord_update_owner" on public.funding_coordinations;
drop policy if exists "coord_update_buyer" on public.funding_coordinations;
drop policy if exists "coord_update_volunteer" on public.funding_coordinations;

-- 주인 · 참여자 · 대표 구매자
create policy "coord_select_involved"
  on public.funding_coordinations for select
  using (
    auth.uid() = owner_user_id
    or auth.uid() = buyer_user_id
    or exists (
      select 1 from public.funding_pledges p
      where p.item_id = funding_coordinations.item_id
        and p.contributor_user_id = auth.uid()
    )
  );

-- 공개 위시 (웹)
create policy "coord_select_shared"
  on public.funding_coordinations for select
  using (
    exists (
      select 1
      from public.items i
      join public.profiles pr on pr.user_id = i.user_id
      where i.id = funding_coordinations.item_id
        and i.list_type = 'wishlist'
        and pr.share_enabled = true
    )
  );

create policy "coord_insert_system"
  on public.funding_coordinations for insert
  with check (auth.uid() = owner_user_id or auth.uid() is not null);

create policy "coord_update_owner"
  on public.funding_coordinations for update
  using (auth.uid() = owner_user_id);

create policy "coord_update_buyer"
  on public.funding_coordinations for update
  using (auth.uid() = buyer_user_id);

-- goal_reached 상태에서 참여자가 대표 volunteer
create policy "coord_update_volunteer"
  on public.funding_coordinations for update
  using (
    state = 'goal_reached'
    and exists (
      select 1 from public.funding_pledges p
      where p.item_id = funding_coordinations.item_id
        and p.contributor_user_id = auth.uid()
    )
  );

grant select on table public.funding_coordinations to anon, authenticated;
grant insert, update on table public.funding_coordinations to authenticated;

-- ---------------------------------------------------------------------------
-- 2. funding_notifications — 인앱 알림
-- ---------------------------------------------------------------------------
create table if not exists public.funding_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  item_id uuid not null references public.items (id) on delete cascade,
  kind text not null
    check (kind in ('goal_reached', 'buyer_assigned', 'purchased', 'received')),
  title text not null,
  body text not null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists funding_notifications_user_idx
  on public.funding_notifications (user_id, created_at desc);

alter table public.funding_notifications enable row level security;

drop policy if exists "funding_notif_select_own" on public.funding_notifications;
drop policy if exists "funding_notif_update_own" on public.funding_notifications;
drop policy if exists "funding_notif_insert_auth" on public.funding_notifications;

create policy "funding_notif_select_own"
  on public.funding_notifications for select
  using (auth.uid() = user_id);

create policy "funding_notif_update_own"
  on public.funding_notifications for update
  using (auth.uid() = user_id);

create policy "funding_notif_insert_auth"
  on public.funding_notifications for insert
  with check (auth.uid() is not null);

grant select, insert, update on table public.funding_notifications to authenticated;

-- ---------------------------------------------------------------------------
-- 3. 100% 달성 시 coordination + 알림 (pledge 저장 트리거)
-- ---------------------------------------------------------------------------
create or replace function public.sync_funding_goal_reached(p_item_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_price integer;
  v_owner uuid;
  v_title text;
  v_total integer;
  v_contributor uuid;
begin
  select i.price, i.user_id, i.title
    into v_price, v_owner, v_title
  from public.items i
  where i.id = p_item_id;

  if v_price is null or v_price <= 0 then
    return;
  end if;

  select coalesce(sum(amount), 0)
    into v_total
  from public.funding_pledges
  where item_id = p_item_id;

  if v_total < v_price then
    return;
  end if;

  insert into public.funding_coordinations (
    item_id, owner_user_id, state, goal_reached_at, updated_at
  )
  values (p_item_id, v_owner, 'goal_reached', now(), now())
  on conflict (item_id) do update
  set
    state = case
      when funding_coordinations.state = 'collecting' then 'goal_reached'
      else funding_coordinations.state
    end,
    goal_reached_at = coalesce(funding_coordinations.goal_reached_at, now()),
    updated_at = now()
  where funding_coordinations.state in ('collecting', 'goal_reached');

  -- 주인 알림 (중복 방지: kind+item 조합 최근 1시간)
  if not exists (
    select 1 from public.funding_notifications n
    where n.user_id = v_owner
      and n.item_id = p_item_id
      and n.kind = 'goal_reached'
      and n.created_at > now() - interval '1 hour'
  ) then
    insert into public.funding_notifications (user_id, item_id, kind, title, body)
    values (
      v_owner,
      p_item_id,
      'goal_reached',
      '100% 달성!',
      '이제 누가 대표로 살지 정해주세요'
    );
  end if;

  for v_contributor in
    select distinct contributor_user_id
    from public.funding_pledges
    where item_id = p_item_id
      and contributor_user_id <> v_owner
  loop
    if not exists (
      select 1 from public.funding_notifications n
      where n.user_id = v_contributor
        and n.item_id = p_item_id
        and n.kind = 'goal_reached'
        and n.created_at > now() - interval '1 hour'
    ) then
      insert into public.funding_notifications (user_id, item_id, kind, title, body)
      values (
        v_contributor,
        p_item_id,
        'goal_reached',
        '100% 달성!',
        '이제 누가 대표로 살지 정해주세요'
      );
    end if;
  end loop;
end;
$$;

create or replace function public.trg_funding_pledges_goal_check()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.sync_funding_goal_reached(
    coalesce(NEW.item_id, OLD.item_id)
  );
  return coalesce(NEW, OLD);
end;
$$;

drop trigger if exists funding_pledges_goal_check on public.funding_pledges;
create trigger funding_pledges_goal_check
  after insert or update or delete on public.funding_pledges
  for each row
  execute function public.trg_funding_pledges_goal_check();

-- ---------------------------------------------------------------------------
-- 4. items — 받은 선물 list_type 허용 (앱에서 received_gift 사용)
-- ---------------------------------------------------------------------------
-- list_type 은 text 이므로 별도 migration 불필요.
-- 앱·웹에서 'received_gift' 값 사용.
