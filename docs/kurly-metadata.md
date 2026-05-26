# 마켓컬리 URL 메타데이터

## 지원 URL

- `https://www.kurly.com/...`
- `https://kurlink.kurly.com/products/{id}` (공유 링크)
- `marketkurly.com` 호스트

## 앱 동작

1. Safari형 User-Agent + `Referer: https://www.kurly.com/` 로 HTML 요청
2. 실패(403 등) 시 데스크톱 Chrome UA로 한 번 더 시도
3. `og:title` / `og:image`, `__NEXT_DATA__` JSON의 `discountedPrice`·`salePrice` 등에서 가격 추출
4. 쇼핑몰 표시: **마켓컬리**, 기본 카테고리: **식품**

## 테스트

Xcode에서 `KurlyMetadataTests` 실행 (네트워크 불필요).

실기기에서 `kurlink` 상품 링크를 붙여 넣어 확인하세요. 일부 네트워크·VPN 환경에서는 여전히 403이 날 수 있습니다.

## 수동 입력

자동 추출이 실패하면 제목·가격을 직접 입력해 담을 수 있습니다.
