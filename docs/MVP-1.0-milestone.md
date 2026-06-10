# Universe Cart — MVP 1.0 마일스톤

1차 MVP(위시 · 공유 · 약속 펀딩 · 코디네이션) 완료 기준 정리입니다.

---

## 완료된 기능

| 마일스톤 | 내용 | 가이드 |
|----------|------|--------|
| M1~M5 | 담기, 리스트, Supabase 동기화 | `docs/M5-supabase-setup.sql` |
| M6 | 위시리스트 웹 공유 (GitHub Pages) | `docs/M6-web-guide.md` |
| M8~M9 | URL 담기, Apple·카카오·이메일 로그인 | `docs/M9-social-login-setup.md` |
| M10 | 온보딩, 공유 UI, TestFlight 준비 | `docs/M10-testflight-prep.md` |
| M11 | 상세 화면·썸네일 안정화 | — |
| M12 | 약속 펀딩 (웹 참여 + 앱 현황) | `docs/M12-pledge-funding-guide.md` |
| M13 | 100% 이후 코디네이션 전체 흐름 | `docs/M13-funding-coordination-guide.md` |

---

## Supabase SQL (순서대로 1회씩)

1. `docs/M5-supabase-setup.sql` — items
2. `docs/M6-supabase-setup.sql` — profiles, 공개 읽기
3. `docs/M12-pledge-funding-setup.sql` — funding_pledges
4. `docs/M12-pledge-funding-grants-fix.sql` — 웹 API 권한 (필요 시)
5. `docs/M13-funding-coordination-setup.sql` — coordinations, notifications, 트리거

---

## 배포 체크리스트

### GitHub Pages (웹)
- [ ] `web/share/index.html`, `web/share/share.js` Push
- [ ] Actions 배포 성공 (초록)
- [ ] 시크릿 탭에서 `?slug=본인슬러그` 확인

### iOS 앱
- [ ] Xcode **⌘R** 최신 빌드
- [ ] `SupabaseSecrets.plist` 로컬 설정 (커밋 제외)
- [ ] 실기기: 카카오페이·토스 송금 링크 (Info.plist `LSApplicationQueriesSchemes`)

---

## 펀딩 전체 흐름 (M12 + M13)

1. 친구 웹 **같이 선물하기** → 금액·메시지 약속
2. 100% 달성 → 인앱 알림
3. 참여자 **대표 구매자** 지정 + 계좌
4. **정산 안내** (카카오페이·토스·카톡 공유)
5. 대표 **구매 완료**
6. 위시 주인 **선물 받음** → **받은 선물** 아카이브

**원칙:** UC는 결제·송금을 처리하지 않음. 코디네이션만 제공.

---

## 커밋·Push 참고

- `config.js`, `SupabaseSecrets.plist` — **커밋하지 않음** (.gitignore)
- 웹 변경 시 `index.html`의 `share.js?v=N` 버전 bump 권장
- 최근 M13 커밋: 앱 코디네이션 + 웹 100% UI + SQL + 가이드

---

## 다음 단계 (선택)

- UI 폴리시 전반
- TestFlight 배포 (`docs/M10-testflight-prep.md`)
- 푸시 알림 (현재: 인앱 토스트·배지)
- 카카오 로그인 UX 정리
