import SwiftUI

/// 29CM-style action buttons (e.g. 장바구니 담기 / 바로 구매하기 row).
enum UCButtonMetrics {
    static let cornerRadius: CGFloat = 4
    static let actionHeight: CGFloat = 48
    static let segmentHeight: CGFloat = 40
    static let segmentCornerRadius: CGFloat = 6
    static let inlineSpacing: CGFloat = 8
    static let labelFont: Font = .subheadline.weight(.medium)
    static let toolbarFont: Font = .subheadline
}

struct UCBorderedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(UCButtonMetrics.labelFont)
            .foregroundStyle(UCColor.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: UCButtonMetrics.actionHeight)
            .background(UCColor.bg)
            .clipShape(RoundedRectangle(cornerRadius: UCButtonMetrics.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: UCButtonMetrics.cornerRadius)
                    .stroke(UCColor.border, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct UCPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(UCButtonMetrics.labelFont)
            .foregroundStyle(UCColor.bg)
            .frame(maxWidth: .infinity)
            .frame(height: UCButtonMetrics.actionHeight)
            .background(UCColor.gray950)
            .clipShape(RoundedRectangle(cornerRadius: UCButtonMetrics.cornerRadius))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct UCFundingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(UCButtonMetrics.labelFont)
            .foregroundStyle(UCColor.bg)
            .frame(maxWidth: .infinity)
            .frame(height: UCButtonMetrics.actionHeight)
            .background(UCColor.funding)
            .clipShape(RoundedRectangle(cornerRadius: UCButtonMetrics.cornerRadius))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct UCToolbarButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(UCButtonMetrics.toolbarFont)
                .foregroundStyle(UCColor.textSecond)
        }
        .buttonStyle(.plain)
    }
}

struct UCPrimaryCTA: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.semibold))
                }
                Text(title)
            }
        }
        .buttonStyle(UCPrimaryButtonStyle())
    }
}

struct UCFundingCTA: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.semibold))
                }
                Text(title)
            }
        }
        .buttonStyle(UCFundingButtonStyle())
    }
}

struct UCSecondaryCTA: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(UCBorderedButtonStyle())
    }
}

// Legacy names (share sheet / profile)
typealias UCCompactBorderedButtonStyle = UCBorderedButtonStyle
typealias UCCompactPrimaryButtonStyle = UCPrimaryButtonStyle
typealias UCCompactToolbarButton = UCToolbarButton
typealias UCCompactPrimaryCTA = UCPrimaryCTA
