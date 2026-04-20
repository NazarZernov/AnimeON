import SwiftUI

struct HeroSearchView: View {
    let featured: Anime
    let searchResults: [Anime]
    let pipeline: ImagePipeline
    @Binding var searchText: String
    let onSubmitSearch: () -> Void
    let onSelectAnime: (Anime) -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImageView(url: featured.bannerURL, pipeline: pipeline)
                .frame(minHeight: 360, maxHeight: 460)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.15),
                            Color.black.opacity(0.75),
                            Color.black.opacity(0.98)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))

            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 10) {
                    heroTag("Популярное сейчас", color: AppTheme.accent)
                    heroTag(String(format: "%.1f", featured.rating), color: AppTheme.warning)
                    heroTag(featured.type.localizedTitle, color: AppTheme.info)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(featured.title)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(featured.featuredQuote)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.82))
                        .frame(maxWidth: 620, alignment: .leading)
                }

                HStack(spacing: 14) {
                    metaValue("\(featured.year)")
                    metaValue(featured.status.localizedTitle)
                    metaValue(featured.progressText)
                    metaValue("\(featured.watchHours)ч watch time")
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(AppTheme.textMuted)

                            TextField("Поиск аниме...", text: $searchText)
                                .textFieldStyle(.plain)
                                .foregroundStyle(AppTheme.textPrimary)
                                .onSubmit(onSubmitSearch)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppTheme.surface.opacity(0.88))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(AppTheme.surfaceBorder, lineWidth: 1)
                        )

                        Button("Искать", action: onSubmitSearch)
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.accent)
                    }

                    if !searchResults.isEmpty {
                        VStack(spacing: 10) {
                            ForEach(searchResults.prefix(4)) { anime in
                                Button {
                                    onSelectAnime(anime)
                                } label: {
                                    HStack(spacing: 12) {
                                        RemoteImageView(url: anime.posterURL, pipeline: pipeline)
                                            .frame(width: 52, height: 72)
                                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(anime.title)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(AppTheme.textPrimary)
                                                .lineLimit(1)

                                            Text("\(anime.year) • \(anime.type.localizedTitle)")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundStyle(AppTheme.textSecondary)
                                        }

                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(AppTheme.surface.opacity(0.92))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(26)
        }
    }

    private func heroTag(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule(style: .continuous).fill(color))
    }

    private func metaValue(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white.opacity(0.84))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
    }
}
