import SwiftUI

struct SettingsSectionContainer<Content: View>: View {
    @Environment(\.appTheme) private var theme

    let title: String
    let subtitle: String?
    @ViewBuilder let content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            VStack(alignment: .leading, spacing: theme.spacing.tiny) {
                Text(title.localized)
                    .font(theme.typography.title)
                    .foregroundStyle(theme.palette.textPrimary)
                if let subtitle {
                    Text(subtitle.localized)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.palette.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                content
            }
        }
        .padding(theme.spacing.large)
        .background(
            RoundedRectangle(cornerRadius: theme.radii.large, style: .continuous)
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
                    RoundedRectangle(cornerRadius: theme.radii.large, style: .continuous)
                        .fill(theme.palette.surfaceHighlight.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radii.large, style: .continuous)
                        .stroke(theme.palette.outline, lineWidth: 1)
                )
        )
        .shadow(color: theme.palette.shadow.opacity(0.65), radius: 18, x: 0, y: 12)
    }
}

#Preview {
    SettingsSectionContainer(title: "Appearance", subtitle: "Visual style and motion") {
        Toggle("Reduce Motion", isOn: .constant(false))
    }
    .padding()
    .background(Color.black)
}
