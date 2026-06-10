import SwiftUI

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

struct UCSecureInputField: View {
    let placeholder: String
    @Binding var text: String
    @FocusState private var focused: Bool

    var body: some View {
        SecureField(placeholder, text: $text)
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
