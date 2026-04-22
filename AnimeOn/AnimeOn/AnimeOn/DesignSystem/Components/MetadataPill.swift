import SwiftUI

struct MetadataPill: View {
    @Environment(\.appTheme) private var theme

    let title: String
    let icon: String?
    let highlighted: Bool

    init(_ title: String, icon: String? = nil, highlighted: Bool = false) {
        self.title = title
        self.icon = icon
        self.highlighted = highlighted
    }

    var body: some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .semibold))
            }
            Text(title.localized)
        }
        .font(theme.typography.pill)
        .foregroundStyle(highlighted ? theme.palette.textPrimary : theme.palette.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(highlighted ? theme.palette.accentSoft.opacity(0.92) : theme.palette.secondaryCard.opacity(0.76))
                .overlay(
                    Capsule(style: .continuous)
                        .fill(theme.palette.surfaceHighlight.opacity(highlighted ? 0.18 : 0.08))
                )
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(theme.palette.outline.opacity(highlighted ? 0.4 : 1), lineWidth: 0.8)
        )
        .clipShape(Capsule(style: .continuous))
    }
}

#Preview {
    HStack {
        MetadataPill("1080p", icon: "sparkles", highlighted: true)
        MetadataPill("Sci-Fi")
    }
    .padding()
    .background(Color.black)
}
