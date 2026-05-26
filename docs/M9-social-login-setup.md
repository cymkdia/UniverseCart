# M9 — Apple · 카카오 로그인 (Supabase)

> **⏸ 현재 보류:** 카카오 **비즈니스(개인) 등록** 후 이어갑니다. 앱에서는 카카오 버튼을 숨기고 **이메일 로그인**을 사용하세요.

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
6. **앱 설정 → 비즈니스** → **「개인으로 등록」** (또는 사업자 정보 등록)  
   - Supabase가 카카오에 **이메일(account_email)** 을 항상 요청합니다. 개인 앱은 여기 등록 후에야 이메일 동의항목을 켤 수 있어요.
7. **제품 설정 → 카카오 로그인 → 동의항목** (KOE205 방지 — **세 가지 모두**):
   - `닉네임(profile_nickname)` — **ON** + 동의 목적 입력
   - `프로필 사진(profile_image)` — **ON** + 동의 목적 입력
   - `카카오계정(이메일)(account_email)` — **ON** + 동의 목적 입력 (6번 후에 가능)

**OpenID Connect** (일반 화면): **OFF** 로 두어도 됩니다 (Supabase 일반 로그인용).

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
| 카카오 화면은 뜨는데 로그인 안 됨 | 아래 **카카오 체크리스트** |
| 카카오 후 앱으로 안 돌아옴 | Supabase Redirect URLs + Kakao Redirect URI |
| `Provider not enabled` | Supabase에서 해당 Provider Enable |
| 시뮬레이터 카카오 실패 | 실기기에서 먼저 테스트 |

### KOE205 (설정하지 않은 동의 항목)

Supabase + 카카오 조합은 **이메일·닉네임·프로필 사진** 스코프를 기본으로 요청합니다. 카카오 콘솔에서 **세 동의항목이 모두 ON**이어야 합니다. 이메일은 **비즈니스 → 개인으로 등록** 후 켤 수 있어요.

에러에 `account_email`만 나와도 위 6·7번을 진행하세요.

### 카카오 로그인 체크리스트 (화면은 뜨는데 실패할 때)

**Supabase → Authentication → URL Configuration**

```text
cymk.UniverseCart://auth-callback
```

**Supabase → Authentication → Providers → Kakao**

- Enable ON
- REST API Key / Client Secret (카카오와 동일)
- **Allow users without an email** → ON (이메일 동의 안 쓸 때)

**Kakao → REST API 키 상세**

```text
https://pnoqhvoqedkjgelollug.supabase.co/auth/v1/callback
```

- Client Secret **활성화**
- **제품 설정 → 카카오 로그인 → 일반** → 상태 **ON**

**앱 프로필 하단**에 나오는 회색/빨간 안내 문구를 그대로 확인하세요.

---

## 이메일 로그인

기존 **이메일/비밀번호** 로그인·회원가입은 그대로 사용할 수 있어요.
