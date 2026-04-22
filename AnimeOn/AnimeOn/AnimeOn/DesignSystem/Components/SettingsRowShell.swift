import SwiftUI

struct SettingsRowShell<Accessory: View>: View {
    @Environment(\.appTheme) private var theme

    let icon: String?
    let title: String
    let subtitle: String?
    let tint: Color?
    @ViewBuilder let accessory: Accessory

    init(
        icon: String? = nil,
        title: String,
        subtitle: String? = nil,
        tint: Color? = nil,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
        self.accessory = accessory()
    }

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint ?? theme.palette.accent)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill((tint ?? theme.palette.accent).opacity(0.16))
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title.localized)
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.palette.textPrimary)
                if let subtitle {
                    Text(subtitle.localized)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.palette.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 12)

            accessory
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: theme.radii.medium, style: .continuous)
                .fill(theme.palette.secondaryCard.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radii.medium, style: .continuous)
                        .fill(theme.palette.surfaceHighlight.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radii.medium, style: .continuous)
                        .stroke(theme.palette.outline.opacity(0.8), lineWidth: 1)
                )
        )
    }
}

#Preview {
    SettingsRowShell(icon: "wand.and.stars", title: "Appearance", subtitle: "Theme and accent") {
        Image(systemName: "chevron.right")
            .foregroundStyle(.white.opacity(0.4))
    }
    .padding()
    .background(Color.black)
}
