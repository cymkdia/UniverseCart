# GitHub Pages — 친구에게 보낼 위시리스트 링크

로컬(`localhost`)이 아니라 **인터넷에서 열리는 주소**를 만드는 순서입니다.

최종 공유 주소 형태:

`https://cymkdia.github.io/UniverseCart/index.html?slug=본인슬러그`

---

## 1단계 — GitHub에 배포 설정 파일 올리기

1. **GitHub Desktop**에서 변경 파일 확인  
   - `.github/workflows/deploy-share-pages.yml`  
   - `docs/github-pages-setup.md` (이 파일)
2. 커밋 메시지 예: `M6: GitHub Pages 배포 workflow`
3. **Push origin** (`main` 브랜치)

`SupabaseSecrets.plist`, `web/share/config.js`는 **체크 해제** (키 유출 방지).

---

## 2단계 — GitHub Secrets 등록

1. 브라우저에서 저장소 열기: https://github.com/cymkdia/UniverseCart  
2. **Settings** → 왼쪽 **Secrets and variables** → **Actions**  
3. **New repository secret** 두 번 추가:

| Name | Value |
|------|--------|
| `SUPABASE_URL` | 앱 `SupabaseSecrets.plist`의 `SUPABASE_URL`과 동일 |
| `SUPABASE_ANON_KEY` | 앱 plist의 `SUPABASE_ANON_KEY`와 동일 |

(anon key는 클라이언트용 공개 키이지만, 저장소에 plist 파일로 올리지는 않습니다.)

---

## 3단계 — Pages를 Actions로 켜기

1. 같은 저장소 **Settings** → **Pages**  
2. **Build and deployment** → **Source**: **GitHub Actions** 선택  
3. 저장

---

## 4단계 — 배포 실행 확인

1. **Actions** 탭 → **Deploy share web (GitHub Pages)** 워크플로  
2. Push 후 자동 실행되거나, **Run workflow**로 수동 실행  
3. 초록색 체크가 뜨면 성공  

실패 시 빨간 로그에 `SUPABASE_URL` Secrets 안내가 나오면 2단계를 다시 확인하세요.

4. **Settings → Pages**에서 사이트 주소 확인  
   - 보통: `https://cymkdia.github.io/UniverseCart/`

브라우저에서 테스트:

`https://cymkdia.github.io/UniverseCart/index.html?slug=cymk86`

(본인 프로필에 설정한 slug로 바꾸기)

---

## 5단계 — iOS 앱에 공유 URL 넣기

1. Xcode에서 `UniverseCart/Config/SupabaseSecrets.plist` 열기  
2. `SHARE_WEB_BASE_URL` 값을 아래로 변경:

```xml
<key>SHARE_WEB_BASE_URL</key>
<string>https://cymkdia.github.io/UniverseCart/index.html</string>
```

3. **Cmd + R**로 앱 실행  
4. **프로필** → **위시리스트 공개** 켜기 → **링크 복사**  
5. 복사한 링크를 메모/카톡에 붙여 넣어 Safari에서 열리는지 확인  

---

## 자주 묻는 것

**Q. config.js는 Git에 안 올리는데 웹은 어떻게 동작하나요?**  
배포할 때 GitHub Actions가 Secrets로 `config.js`를 잠깐 만들어 Pages에 올립니다.

**Q. slug가 뭔가요?**  
프로필 공유용 짧은 이름(예: `cymk86`). 앱에서 링크 복사 시 자동으로 붙습니다.

**Q. 위시가 안 보여요**  
Supabase에서 `docs/M6-supabase-setup.sql` 실행 여부, 프로필 **위시리스트 공개** ON, 해당 계정에 위시 아이템이 있는지 확인하세요.
