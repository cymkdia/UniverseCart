import SwiftUI

struct MarkGiftReceivedSheet: View {
    @Environment(\.dismiss) private var dismiss

    let itemTitle: String
    let onSubmit: (String?) async throws -> Void

    @State private var thankYouMessage = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("「\(itemTitle)」 선물을 받으셨나요? 받은 선물 아카이브로 옮깁니다.")
                        .font(.footnote)
                        .foregroundStyle(UCColor.textSecond)
                }

                Section("감사 메시지 (선택)") {
                    TextField("함께해 주셔서 고마워요!", text: $thankYouMessage, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("선물 받음")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("확인") {
                        Task { await submit() }
                    }
                    .disabled(isSubmitting)
                }
            }
        }
    }

    @MainActor
    private func submit() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let trimmed = thankYouMessage.trimmingCharacters(in: .whitespacesAndNewlines)
            try await onSubmit(trimmed.isEmpty ? nil : trimmed)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
