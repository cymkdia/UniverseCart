# M6 — 공유 위시리스트 웹

## 1. Supabase SQL

`docs/M6-supabase-setup.sql` 실행 (M5와 같은 SQL Editor)

## 2. 앱 (Xcode)

1. `SupabaseSecrets.plist`에 추가 (선택, 나중에 웹 URL 정해지면):

```xml
<key>SHARE_WEB_BASE_URL</key>
<string>https://사용자.github.io/UniverseCart/web/share/index.html</string>
```

2. **Cmd + R** → 프로필 → **위시리스트 공개** 켜기 → **링크 복사**

## 3. 웹 페이지 로컬 테스트

```bash
cd web/share
cp config.example.js config.js
# config.js 에 SUPABASE_URL, SUPABASE_ANON_KEY 입력 (앱 plist와 동일)
python3 -m http.server 8080
```

브라우저: `http://localhost:8080/index.html?slug=복사한슬러그`

## 4. GitHub Pages (친구에게 보낼 링크)

**단계별 안내:** `docs/github-pages-setup.md` 를 따르세요.

요약:

1. `.github/workflows/deploy-share-pages.yml` Push
2. GitHub **Secrets**: `SUPABASE_URL`, `SUPABASE_ANON_KEY`
3. **Pages** → Source: **GitHub Actions**
4. Actions 배포 성공 후 plist:

```xml
<key>SHARE_WEB_BASE_URL</key>
<string>https://cymkdia.github.io/UniverseCart/index.html</string>
```

`config.js`는 Git에 올리지 마세요. 배포 시 Actions가 생성합니다.
