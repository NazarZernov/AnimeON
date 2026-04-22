import SwiftUI

struct EmptyStateView: View {
    @Environment(\.appTheme) private var theme

    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        title: String,
        message: String,
        systemImage: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        GlassCard(padding: 22, cornerRadius: theme.radii.large) {
            VStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(theme.palette.accent)

                Text(title.localized)
                    .font(theme.typography.title)
                    .foregroundStyle(theme.palette.textPrimary)

                Text(message.localized)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.palette.textSecondary)
                    .multilineTextAlignment(.center)

                if let actionTitle, let action {
                    GradientButton(actionTitle, systemImage: "arrow.clockwise", size: .compact, action: action)
                        .frame(maxWidth: 220)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    EmptyStateView(title: "No Results", message: "Try a broader title, genre, or filter set.", systemImage: "sparkle.magnifyingglass")
        .padding()
        .background(Color.black)
}
