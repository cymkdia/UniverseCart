import SwiftUI
import Supabase

struct SharedFundingDetailLoader: View {
    @Environment(AuthSession.self) private var auth

    let itemId: UUID
    let onDismiss: () -> Void

    @State private var item: Item?
    @State private var ownerUserId: UUID?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if let item, let ownerUserId {
                    ItemDetailView(
                        item: item,
                        ownerUserId: ownerUserId,
                        onToggleListType: {},
                        onTapPrice: {}
                    )
                    .environment(auth)
                } else if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .padding()
                } else {
                    ProgressView("불러오는 중…")
                }
            }
            .navigationTitle("같이 선물하기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기", action: onDismiss)
                }
            }
        }
        .task(id: itemId) {
            await load()
        }
    }

    @MainActor
    private func load() async {
        guard let client = SupabaseService.shared.client else {
            errorMessage = "Supabase 연결을 확인해 주세요."
            return
        }

        do {
            let records: [ItemRecord] = try await client
                .from("items")
                .select()
                .eq("id", value: itemId.uuidString)
                .limit(1)
                .execute()
                .value

            guard let record = records.first, let loaded = record.toItem() else {
                errorMessage = "상품을 찾을 수 없어요."
                return
            }

            item = loaded
            ownerUserId = record.userId
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
