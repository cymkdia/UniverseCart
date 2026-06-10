import SwiftUI

struct InAppNotificationBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "bell.fill")
                    .foregroundStyle(UCColor.fundingText)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(UCColor.textPrimary)
                    .multilineTextAlignment(.leading)

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(UCColor.textSecond)
                }
            }
            .padding(12)
            .background(UCColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(UCColor.border, lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
