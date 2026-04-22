import SwiftUI

struct DownloadQualitySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    @State private var selectedAnimeID = MockCatalog.titles[0].id
    @State private var selectedEpisodeID = MockCatalog.titles[0].seasons[0].episodes[0].id
    @State private var selectedQuality: DownloadQualityPreference = .p1080

    let onQueue: (Anime, Episode, DownloadQualityPreference) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    SettingsSectionContainer(title: "Select Title", subtitle: "Queue a demo offline item") {
                        Picker("Anime", selection: $selectedAnimeID) {
                            ForEach(MockCatalog.titles) { anime in
                                Text(anime.title).tag(anime.id)
                            }
                        }
                        .onChange(of: selectedAnimeID) { _, _ in
                            selectedEpisodeID = selectedAnime.seasons.first?.episodes.first?.id ?? ""
                        }

                        Picker("Episode", selection: $selectedEpisodeID) {
                            ForEach(selectedAnime.seasons.flatMap(\.episodes)) { episode in
                                Text(L10n.episode(episode.number)).tag(episode.id)
                            }
                        }

                        Picker("Quality", selection: $selectedQuality) {
                            ForEach(DownloadQualityPreference.allCases) { quality in
                                Text(quality.title).tag(quality)
                            }
                        }
                    }
                }
                .padding(theme.spacing.large)
            }
            .themedBackground()
            .navigationTitle("Queue Download")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Queue") {
                        if let episode = selectedAnime.seasons.flatMap(\.episodes).first(where: { $0.id == selectedEpisodeID }) {
                            onQueue(selectedAnime, episode, selectedQuality)
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private var selectedAnime: Anime {
        MockCatalog.anime(with: selectedAnimeID)
    }
}
