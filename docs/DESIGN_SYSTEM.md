# Universe Cart — UI Style System

> 이 문서는 UI의 단일 진실 공급원(Single Source of Truth)입니다.
> Cursor·Claude에게 새 화면을 시킬 때 항상 이 문서를 함께 첨부하세요.
> 코드 변경은 기존 `Design/Theme.swift`·`Design/UCButtonStyle.swift`를 **확장**하는 방향으로 합니다(덮어쓰기 X).

---

## 0. 설계 철학

레퍼런스: **Apple iOS 네이티브의 절제**와 **29CM의 에디토리얼 모노크롬**.

- **직관**: 사용자가 한 번 봐서 무엇을 누르면 무엇이 되는지 알 수 있어야 한다. 새로 배워야 할 패턴 최소화.
- **명확**: 위계는 색이 아니라 *굵기·크기·명도*로 만든다. 채도 있는 색은 결정적 순간에만.
- **여백 우선**: 상품 이미지가 콘텐츠의 색을 책임진다. UI는 비켜준다.
- **모바일 우선·시스템 우선**: 시스템 컴포넌트(.sheet, .navigationStack, NavigationLink, Alert)를 먼저 쓰고, 필요할 때만 커스텀한다.

---

## 1. 현재 상태 진단

이미 잘 잡혀 있는 것:
- `UCColor` — 29CM ruler scale + 액센트 + 시맨틱 매핑. ✅
- `UCButtonMetrics` — 코너 4 / 액션 높이 48 / 세그먼트 40+6. ✅
- 몰 컬러 매핑 (`UCColor.mallColor`). ✅
- 온보딩 메트릭 분리 (`OnboardingMetrics`). ✅

흩어져 있어 통일이 필요한 것:
- **타입 스케일**이 화면마다 인라인(`font: .system(size: 26, weight: .bold)` 식).
- **간격 값**이 일관되지 않음(12·16·20·24·28이 혼재).
- **반경 값**이 다섯 종(4·6·8·12) — 의미별 정리 필요.
- **그림자**가 정의되지 않음 — 카드/시트 깊이감의 기준 부재.
- **emoji·voice 규칙**이 합의되지 않아 화면마다 톤이 다름.
- **빈 상태·콜아웃·뱃지** 같은 반복 컴포넌트가 ad hoc.

---

## 2. 토큰 — Tokens

### 2.1 색 (Color)

`UCColor`를 그대로 사용. 추가하지 말 것. 새 색을 쓰고 싶으면 먼저 토큰에 추가하고 명명한 뒤 사용.

```text
배경        UCColor.bg           = gray0   #FFFFFF
서피스      UCColor.surface      = gray100 #F4F4F4   (카드 배경·콜아웃)
보더        UCColor.border       = gray200 #E4E4E4
보더(진함)  UCColor.gray300      = #C4C4C4 (비활성·진한 구분선)
플레이스    UCColor.textDisabled = gray400 #A0A0A0
보조 텍스트 UCColor.textSecond   = gray500 #5D5D5D
강조 보조   UCColor.gray700      = #303030 (캡션 강조)
기본 텍스트 UCColor.textPrimary  = gray900 #19191A
검정        UCColor.gray950      = #000000 (CTA 배경)

액센트      UCColor.accent       = #FF4800 (세일·핵심 CTA만)
액센트 연함 UCColor.accentSoft   = #FFEFEB (배경 강조·뱃지)
액센트 진함 UCColor.accentDeep   = #D53F00 (액센트 위 텍스트·hover)

펀딩 메인   UCColor.funding      = #3B9B9C (진행 바·핵심 강조)
펀딩 연함   UCColor.fundingSoft  = #E4F2F2 (배경·뱃지)
펀딩 텍스트 UCColor.fundingText  = #1F6E70 (연한 배경 위 텍스트)
```

**규칙**
- 본문 ≥ `textSecond`. 회색 위에 회색을 쌓지 말 것(가독성).
- 액센트는 한 화면에 최대 1곳. 보통 핵심 CTA 또는 가격 강조에만.
- 위계는 **색이 아니라 굵기·크기**. 색은 *상태*(액센트·펀딩·비활성) 표시용.

### 2.2 타이포 — Typography

폰트는 **Pretendard**(이미 적용). 시스템 폰트 위에 Pretendard로 매핑.

`Theme.swift`에 다음 스케일을 추가하세요(아래는 권장 코드):

```swift
extension UCTypography {
    // Display & Title
    static let display: Font = .system(size: 30, weight: .heavy)       // 온보딩/시작 강조
    static let title1:  Font = .system(size: 24, weight: .bold)        // 화면 제목 (메인)
    static let title2:  Font = .system(size: 20, weight: .bold)        // 섹션 제목
    static let title3:  Font = .system(size: 17, weight: .semibold)    // 카드 제목/시트 타이틀
    // Body
    static let body:    Font = .system(size: 15, weight: .regular)     // 본문 기본
    static let bodyEmph:Font = .system(size: 15, weight: .semibold)    // 본문 강조 (가격·이름)
    static let callout: Font = .system(size: 14, weight: .medium)      // 라벨·세그먼트
    // Small
    static let footnote:Font = .system(size: 13, weight: .regular)     // 보조 설명
    static let caption: Font = .system(size: 12, weight: .medium)      // 칩·뱃지·메타
    static let captionSmall: Font = .system(size: 11, weight: .semibold) // 가장 작은 라벨
    // Numeric
    static let priceLg: Font = .system(size: 20, weight: .heavy)       // 상품 상세 가격
    static let priceMd: Font = .system(size: 16, weight: .heavy)       // 메인 카드 가격
    static let priceSm: Font = .system(size: 13, weight: .semibold)    // 정산·소계
}
```

**규칙**
- 한 화면에 사용하는 사이즈는 **최대 4단계**. 그 이상이면 정보 위계를 재설계.
- 굵기는 **regular / medium / semibold / bold / heavy** 5단계만. `light`·`thin` 금지(가독성).
- **한국어는 sentence case**. ALL CAPS는 영문 단어/라벨에만 제한적 허용(예: `UNIVERSE CART` 로고).
- 라인 스페이싱은 본문 1.5~1.6, 제목 1.3~1.4. 코드에서 `.lineSpacing(3~4)` 권장.

### 2.3 간격 — Spacing

`Theme.swift`에 추가:

```swift
enum UCSpacing {
    static let xs: CGFloat = 4      // 칩 내부·아이콘-텍스트
    static let sm: CGFloat = 8      // 행 간 미세 간격
    static let md: CGFloat = 12     // 컴포넌트 내부 패딩
    static let lg: CGFloat = 16     // 화면 좌우 기본 패딩
    static let xl: CGFloat = 20     // 카드 내부 패딩(넓게)
    static let xxl: CGFloat = 28    // 섹션 사이
    static let section: CGFloat = 32 // 큰 섹션 분리
}
```

**규칙**
- 화면 좌우 기본 패딩은 **16**(`lg`). 온보딩만 24(이미 정의됨 → 그대로 유지).
- 카드 내부 패딩 **16~20**. 그 이상은 시각적으로 비어 보이고, 그 이하는 답답함.
- 섹션 사이 **28~32**. 한 화면에 두 종 이상 섞지 말 것.

### 2.4 반경 — Corner Radius

```swift
enum UCRadius {
    static let xs: CGFloat = 4   // 버튼·인풋·작은 칩 (기존 UCButtonMetrics.cornerRadius)
    static let sm: CGFloat = 6   // 세그먼트 (기존)
    static let md: CGFloat = 8   // 카드·콜아웃·시트 내부 박스
    static let lg: CGFloat = 12  // 큰 시트·이미지 컨테이너 (선택)
}
```

**규칙**
- 한 화면에 반경 종류는 **최대 2가지**.
- 둥근 정도가 다르면 위계가 모호해진다 — *기능*이 다른 요소만 다른 반경.
- 이미지·썸네일은 보통 `xs`(4) — 너무 둥글지 않게.

### 2.5 그림자·깊이감 — Elevation

29CM/iOS 결의 핵심 — **그림자는 거의 안 쓴다.** 깊이는 *배경 색 차이*(흰색 vs 서피스)로 표현.

예외 — 진짜 floating 요소(시트, 토스트, 모달 헤더)에만 아주 옅게:

```swift
extension View {
    func ucFloatingShadow() -> some View {
        self.shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}
```

**규칙**
- 카드·리스트 행에는 그림자 **금지**. 보더(`UCColor.border`)만 사용.
- 위에서 떨어지는 시트/토스트만 위 함수 사용.

### 2.6 아이콘

**SF Symbols 사용**. 이미 `MainListView`·온보딩에서 적용 중. 커스텀 SVG는 몰 로고·핵심 브랜드 마크에만 한정.

**규칙**
- 인라인 아이콘 사이즈: `.caption`(=12pt) ~ `.body`(=17pt). 화면 강조 아이콘은 22~28pt.
- 색은 텍스트와 같게(`UCColor.textPrimary` / `textSecond`). 액센트 아이콘 금지.
- weight는 보통 `.regular` 또는 `.semibold`. `.bold`는 강조용으로만.

---

## 3. 컴포넌트 — Components

### 3.1 Buttons

**Primary CTA** — 검정 배경, 흰 텍스트. 화면당 1개 원칙.
- `UCPrimaryCTA(_:systemImage:action:)` 사용. 절대 인라인으로 새 버튼 만들지 말 것.
- 위치: 화면 하단 sticky footer 또는 시트 마지막.

**Secondary (Bordered)** — 흰 배경 + 보더, 검정 텍스트.
- `UCSecondaryCTA(_:action:)` 사용.
- 위치: Primary 옆 또는 보조 액션(예: "쇼핑몰에서 보기").

**Tertiary (Text)** — 텍스트만, 보더·배경 없음. `UCToolbarButton` 사용 (현재 "건너뛰기"용).

**Destructive** — 정의되지 않음. 필요해지면 `UCColor.accent`로 텍스트 색만 다르게(배경은 흰색). 빨강 배경 버튼은 금지.

**규칙**
- 한 화면에 Primary는 1개. 두 개 필요하면 우선순위 재검토.
- 버튼 라벨은 **동사로 시작**: "위시리스트에 담기", "공유하기", "결제하러 가기". 명사형("결제") 지양.
- 버튼 텍스트는 최대 12자(한국어). 길면 줄임표 대신 액션 재정의.

### 3.2 Inputs

**Field** — 코너 `xs`(4), 패딩 13×14, 폰트 `.body`.
- **기본 상태**: 보더 **1pt** `UCColor.border`(#E4E4E4) — 평상시엔 시선을 끌지 않게 가볍게.
- **포커스 상태(편집 중)**: 보더 **1.5pt** `UCColor.textPrimary`(#19191A) — 사용자가 ‘지금 편집 중’임을 분명히.

```swift
struct UCInputField: View {
    let placeholder: String
    @Binding var text: String
    @FocusState private var focused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .focused($focused)
            .padding(.horizontal, 14).padding(.vertical, 13)
            .background(UCColor.bg)
            .overlay(
                RoundedRectangle(cornerRadius: UCRadius.xs)
                    .stroke(focused ? UCColor.textPrimary : UCColor.border,
                            lineWidth: focused ? 1.5 : 1)
            )
            .animation(.easeInOut(duration: 0.15), value: focused)
    }
}
```

**규칙**
- 평상시 1pt 가볍게, 포커스 시 1.5pt 검정으로 상태 분명히. 인풋이 카드 위에 있을 때도 시각 무게가 과하지 않게.
- 라벨은 인풋 위에. 안에 들어가는 placeholder는 *예시*에만(라벨 대체 X).
- 에러 메시지는 인풋 아래 12pt `UCColor.accentDeep`.

### 3.3 Cards

**Item Card (리스트 행)** — 흰 배경, 보더 없음. 행 구분은 `UCColor.line`(필요시 신규 추가) 또는 행 사이 12pt 여백.

**Info Card / Nudge** — 서피스 배경, 코너 `md`(8), 패딩 `xl`(20).

**Callout (중요·경고)** — 흰 배경 + 1.5pt 보더(`textPrimary`), 코너 `md`(8). 상단 라벨 칩(`UCColor.accentSoft` 배경, `accentDeep` 텍스트) "중요" 등.

이미 `OnboardingImportantBox`로 구현돼 있음 — 다른 곳에서도 같은 패턴 재사용할 것.

### 3.4 Chips / Tags

```text
일반 칩 (필터)   — 보더 1pt(border), 코너 sm(6), 폰트 caption, 패딩 6×12
선택된 칩        — 배경 textPrimary, 텍스트 흰색
액센트 칩(뱃지)  — 배경 accentSoft, 텍스트 accentDeep, 폰트 captionSmall, 코너 xs(4)
몰 칩            — 보더 1pt, 좌측 `Circle().fill(UCColor.mallColor(...))` 7×7
```

**규칙**
- 한 행에 칩 개수는 **4~5개** 이내. 넘으면 가로 스크롤 또는 카테고리 재설계.
- 칩 내 아이콘은 12pt까지.

### 3.5 Sheets / Modals

- 항상 시스템 `.sheet` 또는 `.fullScreenCover`. 커스텀 backdrop+overlay 금지.
- 시트 타이틀은 `ucSheetNavigationTitle("제목")` (이미 정의됨, inline 17pt semibold). Large title 금지.
- 시트 상단 좌측: 닫기(또는 뒤로), 우측: 완료/저장. iOS 패턴 준수.

### 3.6 Lists & Sections

- 메인 리스트: 행 사이 12~14pt 여백. 보더 없는 흰 배경.
- 섹션 헤더: `title3` (17pt semibold), 상단 패딩 `xxl`(28), 하단 패딩 `sm`(8).
- 한 섹션 안에 행이 7개를 넘으면 분할 또는 "더보기" 검토.

### 3.7 Empty State

빈 상태는 **방어 화면이 아니라 행동 유도 화면**이다.
- 큰 이모지 1개(32pt) 또는 시스템 아이콘
- title2(20pt bold) 한 줄
- footnote(13pt) 보조 설명 1~2줄
- 가장 가까운 다음 액션 버튼(Primary 또는 Secondary)

이미 메인 빈 상태 넛지로 구현된 패턴을 표준으로.

### 3.8 Toast / In-app Banner

- `InAppNotificationBanner` 사용(이미 있음).
- 위치: 상단(아래로 슬라이드). 자동 4초 dismiss + 사용자 탭 시 즉시 닫힘.
- 색: 기본은 `gray900` 배경 + 흰 텍스트. 성공은 `funding`, 경고는 `accent`.

### 3.9 Progress (Funding Bar)

- 트랙: `surface`(F4F4F4)
- 채움: `UCColor.funding`(#3B9B9C)
- 높이 6pt, 코너 3pt
- 라벨: "62% · 3명 참여 중" 식으로 비율 + 참여자 함께.

---

## 4. 레이아웃 패턴 — Layout

### 4.1 화면 구조

```
[Status bar (system)]
[Navigation/Header — brand title 또는 sheet inline title]
[Top toolbar — 세그먼트 / 토글 / 필터 칩]
[Content — Scroll]
[Sticky footer — Primary CTA 또는 합계 정보] (있을 때만)
[Tab bar (system)] (메인 탭에서만)
```

### 4.2 GNB / Tab Bar

- GNB(상단) 높이 50pt (`UCLayout.gnbHeight`).
- Tab bar 52pt (`UCLayout.tabBarHeight`) — 단, 시스템 TabView 사용 시 자동.
- 1차 탭: **내 리스트 / 프로필** (현재 코드 기준). 알림/친구는 2차.

### 4.3 Safe Area

- 하단 sticky CTA는 `.safeAreaPadding(.bottom, 4)` 권장(노치 기기 자연스럽게).
- 시트 상단도 시스템 핸들과 충돌 안 나게 첫 컨텐츠는 16pt 이상 띄움.

### 4.4 이미지 비율

- 상품 썸네일: 4:5 또는 5:6 (세로형). 정사각 지양 — 의류 중심 큐레이션엔 세로가 맞음.
- 큰 상세 이미지: 1:1 또는 4:5.

---

## 5. Voice — 문구·톤

### 5.1 톤

- **담백하고 분명하게.** 과장 형용사 금지("어마어마한 할인", "역대급").
- **명사+동사 짧게.** "위시리스트에 담기" ✓ / "지금 바로 위시리스트에 담아보세요" ✗
- **사용자의 행동을 기준으로 쓴다.** "구매가 완료됐어요" → "구매 완료" 또는 "구매 완료 표시".

### 5.2 사람 부르기

- 친구·주인 같은 관계어는 그대로. ("지은님이 약속했어요")
- 가능한 한 한국어. 영어 단어는 브랜드 용어에만(Universe Cart, 펀딩 등 정착된 단어).

### 5.3 숫자·통화

- 통화 표기: **₩129,000** (₩ + 천단위 콤마 + 공백 없음).
- 퍼센트: **19% 할인** (숫자+%+공백+단어).
- 날짜: **6.10 (수)** 또는 **2026.6.10** 일관성 있게 한 가지로.

---

## 6. Emoji 규칙

**원칙**: 일반 UI(버튼·필드·리스트 행)에서는 emoji 사용 금지. *정서적 모먼트*에만 한정 사용.

**허용 모먼트**
- 온보딩·서비스 설명 가치 페이지 (🛒 🎁 ✨ 💝 🛍️ 등)
- 빈 상태 (🛍️ 다른 몰에서도 담아보세요)
- 축하 모먼트 (🎯 100% 달성, 🎁 첫 선물 받음)
- 가이드 팁 (💡 한 줄 팁 정도)

**금지**
- 버튼 라벨·필드 라벨·CTA 안
- 가격·상품명·계정 정보
- 에러·경고 메시지(이모지로 톤 흐리지 말 것)

**화이트리스트 (가능한 한 이것만 재사용)**
🛒 🛍️ 🎁 ✨ 💝 🎯 💡 ⚠️ ✅ 🔁 — 새 이모지 추가 전엔 토론.

---

## 7. Don'ts — 자주 일어나는 실수 막기

1. **인라인 색·폰트 값 쓰지 않기.** `Color(hex:"...")`·`font: .system(size: 17)`을 직접 쓰지 말고 `UCColor.*`·`UCTypography.*` 사용.
2. **새 반경 만들지 않기.** `UCRadius`에 없으면 안 쓰는 게 맞다.
3. **그림자로 깊이 만들지 않기.** 배경 색 차이로 표현. 시트·토스트만 예외.
4. **액센트 컬러로 본문 강조 X.** 강조는 굵기로.
5. **버튼을 새로 만들지 않기.** `UCPrimaryCTA`/`UCSecondaryCTA` 외에는 추가 ButtonStyle 만들지 말 것.
6. **emoji를 UI 메인 라벨에 X.** 정서 모먼트에만.
7. **칩 5개 넘기지 않기.** 필터가 늘어나면 그룹화·재카테고리.
8. **시트 안에 또 시트 X.** 두 단계 깊이까지만(시트 내 NavigationStack push는 OK).

---

## 8. 새 화면 만들 때 체크리스트

새 화면이나 컴포넌트를 추가할 때 다음 순서로 확인:

1. **시스템 컴포넌트로 해결되는가?** → 그렇다면 그걸 사용.
2. **기존 컴포넌트로 해결되는가?** → 그렇다면 그걸 재사용.
3. **새로 만들어야 한다면, 어떤 토큰을 쓰는가?** → 색·폰트·간격·반경을 토큰으로만.
4. **한 화면 안 위계가 명확한가?** → Primary 1개, 강조는 굵기로.
5. **Voice 톤이 담백한가?** → 형용사 빼고 다시 읽어보기.
6. **emoji가 필요한 자리인가?** → 정서 모먼트가 아니면 빼기.

---

## 9. Cursor에게 줄 짧은 안내

새 작업을 요청할 때 프롬프트 끝에 다음 한 줄을 항상 붙이세요:

> "코드 변경 시 `docs/DESIGN_SYSTEM.md`의 토큰·컴포넌트만 사용해줘. `UCColor`·`UCTypography`·`UCSpacing`·`UCRadius`·`UCPrimaryCTA`·`UCSecondaryCTA`·`ucSheetNavigationTitle`. 인라인 색/폰트/반경 값은 만들지 마."

이 한 줄이 화면 일관성을 가장 크게 잡아줍니다.
