import SwiftUI

enum InAppNotificationBannerStyle {
    case surface
    case funding
}

struct InAppNotificationBanner: View {
    let title: String
    let subtitle: String?
    var style: InAppNotificationBannerStyle = .surface
    let onDismiss: () -> Void

    private var usesDarkBackground: Bool {
        style == .funding
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: subtitle == nil ? 0 : 5) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(titleColor)

                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(subtitleColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 8)

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(closeColor)
                }
            }
            .padding(12)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: UCRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: UCRadius.md)
                    .stroke(borderColor, lineWidth: usesDarkBackground ? 0 : 1)
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var iconName: String {
        switch style {
        case .surface: return "bell.fill"
        case .funding: return "gift.fill"
        }
    }

    private var backgroundColor: Color {
        usesDarkBackground ? UCColor.funding : UCColor.surface
    }

    private var borderColor: Color {
        UCColor.border
    }

    private var titleColor: Color {
        usesDarkBackground ? UCColor.bg : UCColor.textPrimary
    }

    private var subtitleColor: Color {
        usesDarkBackground ? UCColor.bg.opacity(0.8) : UCColor.textSecond
    }

    private var iconColor: Color {
        usesDarkBackground ? UCColor.bg : UCColor.fundingText
    }

    private var closeColor: Color {
        usesDarkBackground ? UCColor.bg.opacity(0.8) : UCColor.textSecond
    }
}
