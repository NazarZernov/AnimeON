import SwiftUI

enum AppTheme {
    static let background = Color(hex: "#090B10")
    static let backgroundSecondary = Color(hex: "#05070B")
    static let surface = Color(hex: "#12161D")
    static let surfaceElevated = Color(hex: "#191F28")
    static let surfaceBorder = Color.white.opacity(0.08)
    static let accent = Color(hex: "#FF5A36")
    static let accentSecondary = Color(hex: "#FF8447")
    static let accentGlow = Color(hex: "#FFC36A")
    static let danger = Color(hex: "#FF5B66")
    static let success = Color(hex: "#2CCB97")
    static let warning = Color(hex: "#FFB342")
    static let info = Color(hex: "#53A8FF")
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.74)
    static let textMuted = Color.white.opacity(0.48)

    static let heroGradient = LinearGradient(
        colors: [
            Color(hex: "#491116"),
            Color(hex: "#11161F"),
            Color(hex: "#090B10")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [
            Color(hex: "#1A202A"),
            Color(hex: "#0F131A")
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}
