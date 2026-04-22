import SwiftUI

struct SectionHeader: View {
    @Environment(\.appTheme) private var theme

    let title: String
    let subtitle: String?
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.localized)
                    .font(theme.typography.section)
                    .foregroundStyle(theme.palette.textPrimary)
                if let subtitle {
                    Text(subtitle.localized)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.palette.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if let actionTitle, let action {
                Button(actionTitle.localized, action: action)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.palette.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(theme.palette.secondaryCard.opacity(0.78), in: Capsule(style: .continuous))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(theme.palette.outline, lineWidth: 1)
                    )
            }
        }
    }
}

#Preview {
    SectionHeader(title: "Trending Now", subtitle: "Most replayed tonight.", actionTitle: "See All")
        .padding()
        .background(Color.black)
}
