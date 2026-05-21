import SwiftUI

struct MallBadge: View {
    let mall: Mall

    var body: some View {
        if let assetName = mall.logoAssetName {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 19, height: 19)
                .accessibilityLabel(mall.displayName)
        } else {
            Text(mall.displayName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(UCColor.textPrimary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(UCColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(UCColor.border, lineWidth: 1)
                )
        }
    }
}
