import SwiftUI

struct GradientButton: View {
    enum Size {
        case compact
        case regular

        var height: CGFloat {
            switch self {
            case .compact: 44
            case .regular: 50
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .compact: 12
            case .regular: 14
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .compact: 13
            case .regular: 15
            }
        }

        var font: Font {
            switch self {
            case .compact: .system(size: 14, weight: .semibold, design: .rounded)
            case .regular: .system(size: 16, weight: .semibold, design: .rounded)
            }
        }
    }

    @Environment(\.appTheme) private var theme

    let title: String
    let systemImage: String
    let isProminent: Bool
    let size: Size
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String,
        isProminent: Bool = true,
        size: Size = .regular,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isProminent = isProminent
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: size.iconSize, weight: .semibold))
                Text(title.localized)
                    .font(size.font)
            }
            .foregroundStyle(isProminent ? Color.white : theme.palette.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.control, style: .continuous)
                    .stroke(isProminent ? Color.white.opacity(0.08) : theme.palette.outline, lineWidth: 1)
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: theme.radii.control, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.palette.surfaceHighlight.opacity(isProminent ? 0.72 : 0.4),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .padding(1)
                    .mask(
                        RoundedRectangle(cornerRadius: theme.radii.control, style: .continuous)
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.control, style: .continuous))
        }
        .buttonStyle(.plain)
        .shadow(color: isProminent ? theme.palette.accentGlow.opacity(0.34) : theme.palette.shadow.opacity(0.2), radius: isProminent ? 18 : 10, x: 0, y: isProminent ? 10 : 6)
    }

    private var background: some ShapeStyle {
        LinearGradient(
            colors: isProminent
                ? [theme.palette.accent.opacity(0.95), theme.palette.accent.opacity(0.74)]
                : [theme.palette.secondaryCard.opacity(0.95), theme.palette.card.opacity(0.94)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    GradientButton("Continue", systemImage: "play.fill") { }
        .padding()
        .background(Color.black)
}
