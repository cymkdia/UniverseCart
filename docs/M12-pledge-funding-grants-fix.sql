-- M12 보완: funding_pledges API 권한 (웹이 멈출 때 한 번 더 Run)
-- SQL Editor → 붙여넣기 → Run

grant select on table public.funding_pledges to anon, authenticated;
grant insert, update, delete on table public.funding_pledges to authenticated;
