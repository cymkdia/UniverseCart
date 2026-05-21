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

1. GitHub 저장소 **Settings** → **Pages**
2. Source: **Deploy from branch** → `main` 또는 `feature/...` → `/web/share` 폴더 (또는 `docs` 배포 방식에 맞게)
3. 배포 URL + `?slug=xxx` 를 `SHARE_WEB_BASE_URL` 로 plist에 저장

`config.js`는 Git에 올리지 마세요 (키 노출). `config.example.js`만 커밋.
