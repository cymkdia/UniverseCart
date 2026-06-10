# M12 — 약속 펀딩

친구가 **공유 웹**에서 금액·메시지로 「같이 선물할게요」를 남깁니다.  
**UC는 돈을 받지 않습니다.** 실제 송금은 카톡·계좌 등 앱 밖에서 하세요.

---

## 1. Supabase SQL

1. 대시보드 → **SQL Editor** → **New query**
2. `docs/M12-pledge-funding-setup.sql` 전체 붙여넣기 → **Run**
3. **Table Editor**에 `funding_pledges` 테이블이 생겼는지 확인

---

## 2. GitHub Pages (웹 반영)

아래 **2개 파일**을 커밋 후 **main에 Push** 하면 Actions가 자동 배포합니다.

- `web/share/index.html`
- `web/share/share.js` ← 새 파일 (JS 분리)

로컬만 테스트:

```bash
cd web/share
python3 -m http.server 8080
```

Safari: `http://localhost:8080/index.html?slug=본인슬러그`

---

## 3. 확인 순서

### 친구(또는 다른 계정) — 웹

1. 공유 링크 열기
2. 상품 아래 **같이 선물하기**
3. **이메일 로그인** (Universe Cart와 같은 Supabase 계정)
4. 금액·메시지 입력 → **약속 남기기**
5. 진행 바·참여 목록에 반영되는지

### 나 — 앱

1. **위시** 상품 상세 열기
2. **약속 펀딩** 블록에 모인 금액·참여자 표시
3. 안내 문구: 실제 결제는 UC 밖에서

---

## 4. 웹이 「불러오는 중…」에서 멈출 때

1. Supabase SQL Editor에서 `docs/M12-pledge-funding-grants-fix.sql` **Run** (한 번만)
2. GitHub에 `web/share/index.html` **최신본 Push** (스크립트를 페이지 맨 아래로 옮긴 버전)
3. GitHub **Actions** 배포가 초록인지 확인
4. Safari **새로고침** (안 바뀌면 시크릿 탭으로 링크 다시 열기)

원인: Safari에서 CDN 스크립트가 늦게 로드되면 `main()`이 실행되지 않을 수 있어요. 최신 `index.html`은 이 문제를 고칩니다.

---

## 5. 참고

- 한 상품당 **계정 1개 = 약속 1개** (다시 남기면 금액·메시지 **업데이트**)
- 위시 **주인**은 자기 상품에 약속할 수 없음
- **로그인**한 친구만 참여 (익명은 2차)
