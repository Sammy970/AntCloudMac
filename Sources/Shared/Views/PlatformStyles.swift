import SwiftUI

extension Color {
    /// AntCloud brand blue, sampled from the official icon.
    static let antBlue = Color(red: 0.29, green: 0.53, blue: 0.91)
}

enum KeyboardKind { case email, phone, oneTimeCode, number }

extension View {
    /// Plain text-link button: `.link` on macOS, borderless on iOS.
    @ViewBuilder
    func textLinkStyle() -> some View {
        #if os(macOS)
        buttonStyle(.link)
        #else
        buttonStyle(.borderless)
        #endif
    }

    /// Picks a suitable software keyboard on iOS; no-op on macOS.
    @ViewBuilder
    func keyboard(_ kind: KeyboardKind) -> some View {
        #if os(iOS)
        switch kind {
        case .email:
            keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled()
        case .phone:
            keyboardType(.phonePad).textContentType(.telephoneNumber)
        case .oneTimeCode:
            keyboardType(.numberPad).textContentType(.oneTimeCode)
        case .number:
            keyboardType(.numberPad)
        }
        #else
        self
        #endif
    }
}

/// The app's own icon: the bundle icon on macOS, a cloud glyph on iOS.
struct AppIconImage: View {
    var body: some View {
        #if os(macOS)
        Image(nsImage: NSApp.applicationIconImage).resizable().interpolation(.high)
        #else
        Image(systemName: "cloud.fill").resizable().scaledToFit().foregroundStyle(Color.antBlue)
        #endif
    }
}

extension View {
    /// Lets the view run under a hidden, transparent window title bar (macOS 15+); no-op elsewhere.
    @ViewBuilder
    func transparentTitleBar() -> some View {
        #if os(macOS)
        if #available(macOS 15, *) {
            toolbar(removing: .title).toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        } else {
            self
        }
        #else
        self
        #endif
    }
}
