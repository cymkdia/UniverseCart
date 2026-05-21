# M9 — Apple · 카카오 로그인 (Supabase)

앱 코드는 준비됐어요. **Supabase 대시보드 + Apple/Kakao 개발자 설정**을 해야 실제로 로그인됩니다.

리다이렉트 URL (앱과 동일해야 함):

```text
cymk.UniverseCart://auth-callback
```

---

## 1) Supabase — URL 설정

1. [Supabase Dashboard](https://supabase.com/dashboard) → 프로젝트
2. **Authentication** → **URL Configuration**
3. **Redirect URLs**에 추가:

```text
cymk.UniverseCart://auth-callback
```

4. **Save**

---

## 2) Apple 로그인

### A. Apple Developer

1. [developer.apple.com](https://developer.apple.com) → **Certificates, Identifiers & Profiles**
2. **Identifiers** → 앱 ID `cymk.UniverseCart` 선택
3. **Sign In with Apple** 체크 → **Save**
4. **Keys** (필요 시) — Supabase 문서에 따라 Services ID / Secret 생성

### B. Supabase

1. **Authentication** → **Providers** → **Apple**
2. **Enable** ON
3. Apple Developer에서 받은 **Services ID**, **Secret** 등 입력 (Supabase 안내 따르기)
4. Redirect URL이 위와 같은지 확인

### C. Xcode (로컬)

1. 타깃 **UniverseCart** → **Signing & Capabilities**
2. **+ Capability** → **Sign In with Apple** 추가  
   (entitlements 파일에도 들어가 있음)
3. **Cmd + R** → 프로필 → **Sign in with Apple** 버튼 테스트

---

## 3) 카카오 로그인

### A. Kakao Developers

1. [developers.kakao.com](https://developers.kakao.com) → 앱 선택/생성
2. **플랫폼** → **iOS** 번들 ID: `cymk.UniverseCart`
3. **카카오 로그인** 활성화
4. **Redirect URI** (Kakao 콘솔에 허용 URI):

```text
https://pnoqhvoqedkjgelollug.supabase.co/auth/v1/callback
```

(본인 Supabase 프로젝트 URL로 바꾸기 — `SUPABASE_URL` + `/auth/v1/callback`)

5. **REST API 키** 복사

### B. Supabase

1. **Authentication** → **Providers** → **Kakao**
2. **Enable** ON
3. Kakao **REST API Key** → Client ID
4. Kakao **Client Secret** (콘솔에서 발급) 입력
5. **Save**

### C. 앱에서 테스트

1. **Cmd + R** (실기기 또는 시뮬레이터)
2. **프로필** → **카카오로 계속하기**
3. 카카오 로그인 웹 화면 → 완료 후 앱으로 돌아오면 **로그인됨**

---

## 문제 해결

| 증상 | 확인 |
|------|------|
| Apple 버튼 눌러도 반응 없음 | Sign In with Apple capability, 실기기 Apple ID |
| 카카오 후 앱으로 안 돌아옴 | Supabase Redirect URLs + Kakao Redirect URI |
| `Provider not enabled` | Supabase에서 해당 Provider Enable |
| 시뮬레이터 카카오 실패 | 실기기에서 먼저 테스트 |

---

## 이메일 로그인

기존 **이메일/비밀번호** 로그인·회원가입은 그대로 사용할 수 있어요.
