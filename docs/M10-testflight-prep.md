# M10 — TestFlight · 출시 준비 (앱 내부 + Xcode)

카카오 로그인(M9)은 **비즈니스 등록 후** 이어갑니다. 지금은 **이메일 로그인**으로 앱을 쓸 수 있어요.

---

## 지금 상태

| 항목 | 상태 |
|------|------|
| M1~M8 (MVP + 데이터 안정화) | ✅ |
| M6 공유 웹 (GitHub Pages) | ✅ |
| M9 카카오 로그인 | ⏸ 보류 |
| M9 Apple 로그인 | ⏸ ($99 개발자 프로그램 후) |
| **M10 TestFlight** | **← 지금** |

---

## M10 — 할 일 목록

### 1) 앱에서 최종 확인 (본인 iPhone)

- [ ] Share로 상품 담기 → 메인 리스트에 보임
- [ ] 위시 ↔ 장바구니, 카테고리 필터
- [ ] 이메일 로그인 → 로그아웃
- [ ] 위시리스트 공개 → 링크 복사 → Safari에서 열림
- [ ] 상세 → 「쇼핑몰에서 보기」 Safari 이동
- [ ] 같은 URL 다시 공유 → 중복 없이 업데이트 (M8)

### 2) Xcode — 아카이브 전

1. 스킴 **UniverseCart** + **Any iOS Device** (또는 실기기)
2. **Product → Archive**
3. **Distribute App** → **TestFlight & App Store** (나중에 $99 계정 필요)

### 3) App Store Connect (유료 개발자 후)

- 앱 이름, 설명, 스크린샷
- 개인정보 처리방침 URL (GitHub Pages 정책 페이지 또는 Notion 링크)
- 「결제 없음, 외부 쇼핑몰 링크만」 명시

### 4) 심사용 한 줄 (참고)

> 사용자가 쇼핑 앱에서 공유한 URL만 저장·표시하며, 자동 크롤링·결제는 하지 않습니다.

---

## 나중에 (UI 일괄)

- 리스트/그리드 하트·장바구니 배치
- Pretendard 폰트

**완료:** Share Extension UI를 메인 앱 톤에 맞춤 (M10-B)

**완료:** 로그인 후 온보딩 2단계 (공유 가이드 → 링크 담기) (M10-C)

온보딩을 다시 보려면 (디버그): Xcode에서 `OnboardingPreferences.resetForTesting()` 호출 또는 앱 삭제 후 재설치.

---

## M9 다시 시작할 때

`docs/M9-social-login-setup.md` 참고 — 카카오 **개인/비즈니스 등록** → 동의항목 3종 ON.
