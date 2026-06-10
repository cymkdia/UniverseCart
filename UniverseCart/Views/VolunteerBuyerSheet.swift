import SwiftUI

struct VolunteerBuyerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let itemTitle: String
    let onSubmit: (SettlementBankOption, String) async throws -> Void

    @State private var selectedBank = SettlementBankOption.common[0]
    @State private var accountNumber = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("대표 구매자가 실제로 상품을 구매하고, 참여자들이 이 계좌로 약속 금액을 송금합니다.")
                        .font(.footnote)
                        .foregroundStyle(UCColor.textSecond)
                }

                Section("송금받을 계좌") {
                    Picker("은행", selection: $selectedBank) {
                        ForEach(SettlementBankOption.common) { bank in
                            Text(bank.displayName).tag(bank)
                        }
                    }

                    TextField("계좌번호 (- 없이)", text: $accountNumber)
                        .keyboardType(.numberPad)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("대표로 구매하기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("확인") {
                        Task { await submit() }
                    }
                    .disabled(isSubmitting || accountNumber.filter(\.isNumber).count < 10)
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
            try await onSubmit(selectedBank, accountNumber)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
