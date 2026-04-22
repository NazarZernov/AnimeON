import SwiftUI

struct ThemePickerRow: View {
    @Environment(\.appTheme) private var theme

    let preset: ThemePreset
    let selectedPreset: ThemePreset
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.9), Color.white.opacity(0.12), Color.black.opacity(0.72)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(theme.palette.outline, lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text(preset.title)
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.palette.textPrimary)
                    Text(preset.description)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.palette.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: selectedPreset == preset ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(selectedPreset == preset ? accent : theme.palette.textTertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: theme.radii.medium, style: .continuous)
                    .fill(theme.palette.secondaryCard.opacity(0.62))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radii.medium, style: .continuous)
                            .stroke(theme.palette.outline, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ThemePickerRow(preset: .classicDark, selectedPreset: .classicDark, accent: .purple, action: {})
        .padding()
        .background(Color.black)
}
