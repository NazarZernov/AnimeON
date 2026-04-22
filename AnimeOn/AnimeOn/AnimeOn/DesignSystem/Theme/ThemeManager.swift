import Combine
import SwiftUI

@MainActor
final class ThemeManager: ObservableObject {
    @Published private(set) var theme: AppTheme

    private let settingsStore: SettingsStore
    private var cancellables = Set<AnyCancellable>()

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        self.theme = ThemeManager.makeTheme(
            preset: settingsStore.settings.appearance.preset,
            accent: settingsStore.settings.appearance.accentColor,
            posterRadius: settingsStore.settings.appearance.posterCornerRadius,
            density: settingsStore.settings.appearance.cardDensity
        )

        settingsStore.$settings
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
    }

    var colorScheme: ColorScheme? {
        switch settingsStore.settings.appearance.themeMode {
        case .system: nil
        case .dark: .dark
        case .light: .light
        }
    }

    func refresh() {
        theme = ThemeManager.makeTheme(
            preset: settingsStore.settings.appearance.preset,
            accent: settingsStore.settings.appearance.accentColor,
            posterRadius: settingsStore.settings.appearance.posterCornerRadius,
            density: settingsStore.settings.appearance.cardDensity
        )
    }

    nonisolated static func makeTheme(
        preset: ThemePreset,
        accent: AccentColorOption,
        posterRadius: Double,
        density: CardDensity
    ) -> AppTheme {
        let accentColor = accent.color

        let spacing: ThemeSpacing = switch density {
        case .compact:
            ThemeSpacing(tiny: 4, xSmall: 6, small: 10, medium: 14, large: 18, xLarge: 24, xxLarge: 32, heroInset: 16, screenPadding: 16)
        case .balanced:
            ThemeSpacing(tiny: 4, xSmall: 8, small: 12, medium: 16, large: 20, xLarge: 28, xxLarge: 36, heroInset: 18, screenPadding: 18)
        case .spacious:
            ThemeSpacing(tiny: 6, xSmall: 10, small: 14, medium: 18, large: 24, xLarge: 32, xxLarge: 40, heroInset: 22, screenPadding: 20)
        }

        let palette: ThemePalette = {
            switch preset {
            case .classicDark:
                return ThemePalette(
                    background: Color(hex: 0x050609),
                    elevatedBackground: Color(hex: 0x0F1117),
                    card: Color(hex: 0x151924),
                    secondaryCard: Color(hex: 0x1C2230),
                    accent: accentColor,
                    accentSoft: accentColor.opacity(0.14),
                    accentGlow: accentColor.opacity(0.36),
                    textPrimary: .white,
                    textSecondary: Color.white.opacity(0.72),
                    textTertiary: Color.white.opacity(0.46),
                    outline: Color.white.opacity(0.08),
                    divider: Color.white.opacity(0.06),
                    surfaceHighlight: Color.white.opacity(0.12),
                    shadow: .black.opacity(0.52),
                    positive: Color(hex: 0x34D399),
                    warning: Color(hex: 0xF59E0B)
                )
            case .midnightOLED:
                return ThemePalette(
                    background: Color.black,
                    elevatedBackground: Color(hex: 0x08090C),
                    card: Color(hex: 0x0D1017),
                    secondaryCard: Color(hex: 0x131823),
                    accent: accentColor,
                    accentSoft: accentColor.opacity(0.18),
                    accentGlow: accentColor.opacity(0.32),
                    textPrimary: .white,
                    textSecondary: Color.white.opacity(0.74),
                    textTertiary: Color.white.opacity(0.5),
                    outline: Color.white.opacity(0.09),
                    divider: Color.white.opacity(0.06),
                    surfaceHighlight: Color.white.opacity(0.14),
                    shadow: .black.opacity(0.66),
                    positive: Color(hex: 0x4ADE80),
                    warning: Color(hex: 0xFBBF24)
                )
            case .softGraphite:
                return ThemePalette(
                    background: Color(hex: 0x0D1016),
                    elevatedBackground: Color(hex: 0x141823),
                    card: Color(hex: 0x191F2A),
                    secondaryCard: Color(hex: 0x212938),
                    accent: accentColor,
                    accentSoft: accentColor.opacity(0.13),
                    accentGlow: accentColor.opacity(0.28),
                    textPrimary: .white,
                    textSecondary: Color.white.opacity(0.7),
                    textTertiary: Color.white.opacity(0.48),
                    outline: Color.white.opacity(0.07),
                    divider: Color.white.opacity(0.05),
                    surfaceHighlight: Color.white.opacity(0.1),
                    shadow: .black.opacity(0.38),
                    positive: Color(hex: 0x6EE7B7),
                    warning: Color(hex: 0xFDE68A)
                )
            case .neonViolet:
                return ThemePalette(
                    background: Color(hex: 0x07050D),
                    elevatedBackground: Color(hex: 0x0D0917),
                    card: Color(hex: 0x151024),
                    secondaryCard: Color(hex: 0x211735),
                    accent: Color(hex: 0xA855F7),
                    accentSoft: Color(hex: 0xA855F7).opacity(0.18),
                    accentGlow: Color(hex: 0xA855F7).opacity(0.4),
                    textPrimary: .white,
                    textSecondary: Color.white.opacity(0.74),
                    textTertiary: Color.white.opacity(0.5),
                    outline: Color.white.opacity(0.08),
                    divider: Color.white.opacity(0.06),
                    surfaceHighlight: Color.white.opacity(0.12),
                    shadow: Color(hex: 0x180027).opacity(0.45),
                    positive: Color(hex: 0x2DD4BF),
                    warning: Color(hex: 0xFB7185)
                )
            case .warmCinema:
                let cinemaAccent = accent == .violet ? Color(hex: 0xF59E0B) : accentColor
                return ThemePalette(
                    background: Color(hex: 0x0A0808),
                    elevatedBackground: Color(hex: 0x12100F),
                    card: Color(hex: 0x1A1715),
                    secondaryCard: Color(hex: 0x24201D),
                    accent: cinemaAccent,
                    accentSoft: cinemaAccent.opacity(0.15),
                    accentGlow: cinemaAccent.opacity(0.3),
                    textPrimary: .white,
                    textSecondary: Color.white.opacity(0.72),
                    textTertiary: Color.white.opacity(0.5),
                    outline: Color.white.opacity(0.08),
                    divider: Color.white.opacity(0.06),
                    surfaceHighlight: Color.white.opacity(0.11),
                    shadow: .black.opacity(0.42),
                    positive: Color(hex: 0x86EFAC),
                    warning: Color(hex: 0xF59E0B)
                )
            }
        }()

        return AppTheme(
            palette: palette,
            spacing: spacing,
            radii: ThemeRadii(
                xSmall: 10,
                small: 14,
                medium: 18,
                large: 22,
                xLarge: 28,
                hero: 32,
                control: 16,
                sheet: 30,
                poster: posterRadius
            ),
            typography: ThemeTypography(
                display: .system(size: 31, weight: .bold, design: .rounded),
                hero: .system(size: 24, weight: .bold, design: .rounded),
                title: .system(size: 20, weight: .semibold, design: .rounded),
                headline: .system(size: 16, weight: .semibold, design: .rounded),
                section: .system(size: 18, weight: .bold, design: .rounded),
                body: .system(size: 15, weight: .regular, design: .default),
                subheadline: .system(size: 13, weight: .medium, design: .default),
                caption: .system(size: 11, weight: .medium, design: .default),
                pill: .system(size: 10, weight: .semibold, design: .rounded),
                eyebrow: .system(size: 12, weight: .semibold, design: .rounded),
                control: .system(size: 15, weight: .semibold, design: .rounded),
                metric: .system(size: 28, weight: .bold, design: .rounded)
            )
        )
    }
}
