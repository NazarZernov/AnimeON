import SwiftUI

struct GlassCard<Content: View>: View {
    @Environment(\.appTheme) private var theme

    let padding: CGFloat
    let cornerRadius: CGFloat?
    @ViewBuilder let content: Content

    init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius ?? theme.radii.large, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.palette.card.opacity(0.98),
                                theme.palette.secondaryCard.opacity(0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius ?? theme.radii.large, style: .continuous)
                            .fill(theme.palette.surfaceHighlight.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius ?? theme.radii.large, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        theme.palette.surfaceHighlight,
                                        theme.palette.outline,
                                        theme.palette.outline.opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: theme.palette.shadow.opacity(0.75), radius: 24, x: 0, y: 14)
    }
}

#Preview {
    GlassCard {
        Text("Premium surface")
            .foregroundStyle(.white)
    }
    .padding()
    .background(Color.black)
}
