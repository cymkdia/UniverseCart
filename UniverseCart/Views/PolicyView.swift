import SwiftUI

struct PolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                section(
                    title: "서비스 안내",
                    body: """
                    Universe Cart는 여러 쇼핑몰에 담아 둔 위시·장바구니 상품을 한곳에서 모아 보는 앱입니다. \
                    결제는 각 쇼핑몰에서 직접 진행합니다.
                    """
                )

                section(
                    title: "개인정보",
                    body: """
                    로그인 시 이메일과 담은 상품 정보가 Supabase에 저장됩니다. \
                    위시리스트 공개를 켜면 선택한 항목이 웹 링크로 공유될 수 있습니다.
                    """
                )

                section(
                    title: "약속 펀딩",
                    body: """
                    친구가 공유 웹에서 금액·메시지로 선물 약속을 남길 수 있습니다. \
                    Universe Cart는 금전을 받거나 보관하지 않으며, 실제 송금·구매는 앱 밖에서 진행합니다.
                    """
                )

                section(
                    title: "외부 링크",
                    body: """
                    「쇼핑몰에서 보기」「결제하기」를 누르면 해당 쇼핑몰(Safari·앱)로 이동합니다. \
                    그곳의 이용약관과 개인정보 처리방침이 적용됩니다.
                    """
                )

                Text("문의: 앱 내 프로필 계정 이메일로 연락해 주세요.")
                    .font(.footnote)
                    .foregroundStyle(UCColor.textSecond)
            }
            .padding(20)
        }
        .background(UCColor.bg)
        .navigationTitle("이용 안내")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(UCColor.textPrimary)

            Text(body)
                .font(.subheadline)
                .foregroundStyle(UCColor.textSecond)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
