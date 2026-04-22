import AVKit
import SwiftUI

struct PlayerView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var playbackCoordinator: PlaybackCoordinator
    @State private var showsControls = true
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()

                VideoPlayer(player: playbackCoordinator.engine.player)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showsControls.toggle()
                        }
                    }

                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            playbackCoordinator.skip(by: -15)
                            showsControls = true
                        }
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            playbackCoordinator.skip(by: 15)
                            showsControls = true
                        }
                }
                .ignoresSafeArea()

                if showsControls, let context = playbackCoordinator.currentContext {
                    overlayGradients

                    VStack(spacing: 0) {
                        topBar(context: context, topInset: proxy.safeAreaInsets.top)
                        Spacer()
                        bottomControls(context: context, safeBottomInset: proxy.safeAreaInsets.bottom)
                    }
                    .transition(.opacity)
                }
            }
            .offset(y: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        guard value.translation.height > 0 else { return }
                        dragOffset = min(value.translation.height, 180)
                    }
                    .onEnded { value in
                        if value.translation.height > 120 {
                            playbackCoordinator.dismissPlayer()
                        }
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            dragOffset = 0
                        }
                    }
            )
        }
        .statusBarHidden(true)
        .task(id: showsControls) {
            guard showsControls else { return }
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                showsControls = false
            }
        }
        .onDisappear {
            playbackCoordinator.saveProgressSnapshot()
        }
    }

    private var overlayGradients: some View {
        VStack {
            LinearGradient(
                colors: [Color.black.opacity(0.62), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 170)

            Spacer()

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.84)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 280)
        }
        .ignoresSafeArea()
    }

    private func topBar(context: PlayerContext, topInset: CGFloat) -> some View {
        HStack(spacing: 12) {
            glassCircleButton(systemImage: "chevron.down") {
                playbackCoordinator.dismissPlayer()
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(context.anime.title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(L10n.episodeWithTitle(context.episode.number, context.episode.title))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.74))
                    .lineLimit(1)
            }

            Spacer()

            glassCircleButton(systemImage: "pip.enter") {
                playbackCoordinator.dismissPlayer()
            }
            .accessibilityLabel(Text(L10n.tr("Mini Player")))

            glassCircleButton(systemImage: "xmark") {
                playbackCoordinator.closePlayback()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, max(topInset, 8))
    }

    private func bottomControls(context: PlayerContext, safeBottomInset: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.episode.title)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Text(L10n.episodeRuntime(context.episode.number, timeString(playbackCoordinator.engine.duration)))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                    }

                    Spacer()

                    if playbackCoordinator.nextEpisode() != nil {
                        Menu {
                            if let nextEpisode = playbackCoordinator.nextEpisode() {
                                Button(L10n.nextUpEpisode(nextEpisode.number)) {
                                    playbackCoordinator.playNextEpisode()
                                }
                            }
                        } label: {
                            controlChipLabel(title: "Up Next", systemImage: "forward.end.fill")
                        }
                    }
                }

                Slider(
                    value: Binding(
                        get: { playbackCoordinator.engine.currentTime },
                        set: { playbackCoordinator.engine.seek(to: $0) }
                    ),
                    in: 0...max(playbackCoordinator.engine.duration, 1)
                )
                .tint(theme.palette.accent)

                HStack {
                    Text(timeString(playbackCoordinator.engine.currentTime))
                    Spacer()
                    Text("-\(timeString(max(playbackCoordinator.engine.duration - playbackCoordinator.engine.currentTime, 0)))")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
            }

            HStack(spacing: 18) {
                transportButton(systemImage: "gobackward.15", size: 46) {
                    playbackCoordinator.skip(by: -15)
                }

                Button {
                    playbackCoordinator.togglePlayback()
                } label: {
                    Image(systemName: playbackCoordinator.engine.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 64, height: 64)
                        .background(theme.palette.accent, in: Circle())
                        .shadow(color: theme.palette.accent.opacity(0.25), radius: 16, x: 0, y: 10)
                }

                transportButton(systemImage: "goforward.15", size: 46) {
                    playbackCoordinator.skip(by: 15)
                }

                transportButton(systemImage: "forward.end.fill", size: 42) {
                    playbackCoordinator.playNextEpisode()
                }
                .disabled(playbackCoordinator.nextEpisode() == nil)
                .opacity(playbackCoordinator.nextEpisode() == nil ? 0.45 : 1)
            }
            .frame(maxWidth: .infinity)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    menuControl(title: "Episodes", systemImage: "list.bullet.rectangle") {
                        ForEach(context.anime.seasons.flatMap(\.episodes)) { episode in
                            Button(L10n.episodeWithTitle(episode.number, episode.title)) {
                                playbackCoordinator.startPlayback(anime: context.anime, episode: episode)
                            }
                        }
                    }
                    menuControl(title: "Audio/Subs", systemImage: "captions.bubble") {
                        ForEach(playbackCoordinator.trackOptions.audioOptions, id: \.self) { option in
                            Button { } label: {
                                Text(option.localized)
                            }
                        }
                        Divider()
                        ForEach(playbackCoordinator.trackOptions.subtitleOptions, id: \.self) { option in
                            Button { } label: {
                                Text(option.localized)
                            }
                        }
                    }

                    menuControl(title: "Quality", systemImage: "dot.radiowaves.left.and.right") {
                        ForEach(playbackCoordinator.trackOptions.qualityOptions, id: \.self) { option in
                            Button { } label: {
                                Text(option.localized)
                            }
                        }
                    }

                    menuControl(title: "Speed", systemImage: "speedometer") {
                        ForEach(PlaybackSpeedPreset.allCases) { speed in
                            Button(speed.rawValue) {
                                playbackCoordinator.selectRate(speed.value)
                            }
                        }
                    }

                    Button {
                        playbackCoordinator.dismissPlayer()
                    } label: {
                        controlChipLabel(title: "Mini", systemImage: "pip.enter")
                    }
                }
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, max(safeBottomInset, 12))
    }

    private func transportButton(systemImage: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(.white.opacity(0.12), in: Circle())
        }
    }

    private func menuControl<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Menu {
            content()
        } label: {
            controlChipLabel(title: title, systemImage: systemImage)
        }
    }

    private func glassCircleButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.14), in: Circle())
        }
    }

    private func controlChipLabel(title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(title.localized)
        }
        .font(.system(size: 13, weight: .semibold, design: .rounded))
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.white.opacity(0.12), in: Capsule())
    }

    private func timeString(_ seconds: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = seconds >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: seconds) ?? "00:00"
    }
}

#Preview {
    PlayerView()
        .environmentObject(AppContainer.live.playbackCoordinator)
        .environment(\.appTheme, ThemeManager.makeTheme(preset: .classicDark, accent: .violet, posterRadius: 26, density: .balanced))
}
