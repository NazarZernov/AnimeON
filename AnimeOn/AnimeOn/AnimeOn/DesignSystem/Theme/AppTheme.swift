import SwiftUI

struct ThemeSpacing {
    let tiny: CGFloat
    let xSmall: CGFloat
    let small: CGFloat
    let medium: CGFloat
    let large: CGFloat
    let xLarge: CGFloat
    let xxLarge: CGFloat
    let heroInset: CGFloat
    let screenPadding: CGFloat
}

struct ThemeRadii {
    let xSmall: CGFloat
    let small: CGFloat
    let medium: CGFloat
    let large: CGFloat
    let xLarge: CGFloat
    let hero: CGFloat
    let control: CGFloat
    let sheet: CGFloat
    let poster: CGFloat
}

struct ThemeTypography {
    let display: Font
    let hero: Font
    let title: Font
    let headline: Font
    let section: Font
    let body: Font
    let subheadline: Font
    let caption: Font
    let pill: Font
    let eyebrow: Font
    let control: Font
    let metric: Font
}

struct ThemePalette {
    let background: Color
    let elevatedBackground: Color
    let card: Color
    let secondaryCard: Color
    let accent: Color
    let accentSoft: Color
    let accentGlow: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let outline: Color
    let divider: Color
    let surfaceHighlight: Color
    let shadow: Color
    let positive: Color
    let warning: Color
}

struct AppTheme {
    let palette: ThemePalette
    let spacing: ThemeSpacing
    let radii: ThemeRadii
    let typography: ThemeTypography
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = ThemeManager.makeTheme(
        preset: .classicDark,
        accent: .violet,
        posterRadius: 26,
        density: .balanced
    )
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}
