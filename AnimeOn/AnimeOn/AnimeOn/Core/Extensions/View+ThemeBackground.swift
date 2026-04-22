import SwiftUI

extension View {
    func themedBackground() -> some View {
        modifier(ThemedBackgroundModifier())
    }
}

private struct ThemedBackgroundModifier: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    theme.palette.background.ignoresSafeArea()

                    LinearGradient(
                        colors: [
                            theme.palette.background,
                            theme.palette.elevatedBackground,
                            theme.palette.background
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    RadialGradient(
                        colors: [
                            theme.palette.accentGlow.opacity(0.32),
                            .clear,
                            theme.palette.background
                        ],
                        center: .topLeading,
                        startRadius: 20,
                        endRadius: 420
                    )
                    .ignoresSafeArea()
                    .blur(radius: 56)

                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.07),
                            .clear
                        ],
                        center: .top,
                        startRadius: 12,
                        endRadius: 280
                    )
                    .blendMode(.softLight)
                    .ignoresSafeArea()
                    .blur(radius: 40)

                    LinearGradient(
                        colors: [
                            theme.palette.surfaceHighlight.opacity(0.42),
                            .clear,
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                    .ignoresSafeArea()
                }
            )
    }
}
