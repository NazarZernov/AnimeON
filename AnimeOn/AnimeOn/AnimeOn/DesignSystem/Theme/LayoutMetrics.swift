import SwiftUI

struct LayoutMetrics {
    let width: CGFloat
    let isNarrowPhone: Bool
    let horizontalPadding: CGFloat
    let sectionSpacing: CGFloat
    let cardSpacing: CGFloat
    let compactSectionSpacing: CGFloat
    let rowSpacing: CGFloat
    let heroHeight: CGFloat
    let heroInset: CGFloat
    let heroSynopsisLines: Int
    let posterWidth: CGFloat
    let widePosterWidth: CGFloat
    let continueCardWidth: CGFloat
    let continueCardHeight: CGFloat
    let detailsBackdropHeight: CGFloat
    let detailsPosterWidth: CGFloat
    let detailsPosterHeight: CGFloat
    let detailsPanelOverlap: CGFloat
    let metadataColumns: [GridItem]
    let episodeArtworkWidth: CGFloat
    let episodeArtworkHeight: CGFloat
    let gridColumns: [GridItem]
    let primaryControlHeight: CGFloat
    let compactControlHeight: CGFloat
    let miniPlayerBottomInset: CGFloat
    let miniPlayerHeight: CGFloat

    static func forWidth(_ width: CGFloat, theme: AppTheme) -> LayoutMetrics {
        let clampedWidth = min(max(width, 320), 430)
        let isNarrowPhone = clampedWidth <= 350
        let horizontalPadding = isNarrowPhone ? max(theme.spacing.screenPadding - 1, 14) : theme.spacing.screenPadding
        let cardSpacing = isNarrowPhone ? theme.spacing.small : theme.spacing.medium
        let posterWidth = min(max(clampedWidth * 0.33, 116), 138)
        let widePosterWidth = min(max(clampedWidth * 0.42, 148), 178)
        let continueCardWidth = min(max(clampedWidth * 0.72, 224), 274)

        return LayoutMetrics(
            width: clampedWidth,
            isNarrowPhone: isNarrowPhone,
            horizontalPadding: horizontalPadding,
            sectionSpacing: isNarrowPhone ? theme.spacing.large : 26,
            cardSpacing: cardSpacing,
            compactSectionSpacing: isNarrowPhone ? theme.spacing.medium : theme.spacing.large,
            rowSpacing: isNarrowPhone ? theme.spacing.small : theme.spacing.medium,
            heroHeight: min(max(clampedWidth * 0.66, 228), 284),
            heroInset: isNarrowPhone ? 14 : 18,
            heroSynopsisLines: isNarrowPhone ? 2 : 3,
            posterWidth: posterWidth,
            widePosterWidth: widePosterWidth,
            continueCardWidth: continueCardWidth,
            continueCardHeight: min(max(continueCardWidth * 0.5, 118), 144),
            detailsBackdropHeight: min(max(clampedWidth * 0.66, 232), 286),
            detailsPosterWidth: isNarrowPhone ? 96 : 108,
            detailsPosterHeight: isNarrowPhone ? 140 : 156,
            detailsPanelOverlap: isNarrowPhone ? 38 : 44,
            metadataColumns: [
                GridItem(.flexible(), spacing: cardSpacing),
                GridItem(.flexible(), spacing: cardSpacing)
            ],
            episodeArtworkWidth: isNarrowPhone ? 92 : 102,
            episodeArtworkHeight: isNarrowPhone ? 54 : 58,
            gridColumns: [
                GridItem(.flexible(), spacing: cardSpacing),
                GridItem(.flexible(), spacing: cardSpacing)
            ],
            primaryControlHeight: isNarrowPhone ? 46 : 50,
            compactControlHeight: isNarrowPhone ? 42 : 44,
            miniPlayerBottomInset: isNarrowPhone ? 74 : 78,
            miniPlayerHeight: isNarrowPhone ? 66 : 70
        )
    }
}
