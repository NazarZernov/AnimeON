import AVFoundation
import SwiftUI

struct PlayerSurfaceView: View {
    @ObservedObject var manager: PlayerManager
    @State private var seekFeedback: String?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                PlayerRenderView(player: manager.player) { layer in
                    #if os(iOS)
                    manager.configurePictureInPicture(with: layer)
                    #endif
                }
                .background(Color.black)

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.42),
                        .clear,
                        Color.black.opacity(0.65)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    if let seekFeedback {
                        Text(seekFeedback)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(.black.opacity(0.6), in: Capsule())
                            .padding(.bottom, 18)
                    }
                    bottomBar
                }
                .padding(20)
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .contentShape(Rectangle())
            .gesture(playerGesture(in: geometry.size))
            .onTapGesture {
                manager.togglePlayPause()
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            if manager.isBuffering {
                Label("Buffering", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.45), in: Capsule())
            }

            Spacer()

            sourceMenu
            qualityMenu
            audioMenu

            #if os(iOS)
            if manager.isPictureInPictureAvailable {
                Button {
                    manager.startPictureInPicture()
                } label: {
                    Image(systemName: "pip.enter")
                }
                .buttonStyle(.bordered)
            }
            #endif
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 14) {
            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: {
                            guard manager.duration > 0 else { return 0 }
                            return manager.currentTime / manager.duration
                        },
                        set: { manager.seek(to: $0) }
                    ),
                    in: 0...1
                )
                .tint(AppTheme.accent)

                HStack {
                    Text(timeLabel(manager.currentTime))
                    Spacer()
                    Text(timeLabel(manager.duration))
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
            }

            HStack(spacing: 18) {
                Button {
                    manager.seek(by: -10)
                } label: {
                    Image(systemName: "gobackward.10")
                }
                .buttonStyle(.bordered)

                Button {
                    manager.togglePlayPause()
                } label: {
                    Image(systemName: manager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 52, height: 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)

                Button {
                    manager.seek(by: 10)
                } label: {
                    Image(systemName: "goforward.10")
                }
                .buttonStyle(.bordered)

                Menu {
                    ForEach([0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
                        Button("\(speed.formatted())x") {
                            manager.updatePlaybackRate(Float(speed))
                        }
                    }
                } label: {
                    Label("\(manager.playbackRate.formatted())x", systemImage: "speedometer")
                }
                .buttonStyle(.bordered)

                Toggle("Autoplay", isOn: $manager.shouldAutoplayNext)
                    .toggleStyle(.switch)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background(.black.opacity(0.44), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var sourceMenu: some View {
        Menu {
            ForEach(manager.availableSources) { source in
                Button(source.title) {
                    manager.selectSource(source)
                }
            }
        } label: {
            Label(manager.selectedSource?.title ?? "Source", systemImage: "play.tv")
        }
        .buttonStyle(.bordered)
    }

    private var qualityMenu: some View {
        Menu {
            ForEach(manager.availableQualities) { quality in
                Button(quality.label) {
                    manager.selectQuality(quality)
                }
            }
        } label: {
            Label(
                manager.availableQualities.first(where: { $0.id == manager.selectedQualityID })?.label ?? "Quality",
                systemImage: "bolt.horizontal.circle"
            )
        }
        .buttonStyle(.bordered)
    }

    private var audioMenu: some View {
        Menu {
            ForEach(manager.availableAudioTracks) { track in
                Button(track.title) {
                    manager.selectAudioTrack(track)
                }
            }
        } label: {
            Label(
                manager.availableAudioTracks.first(where: { $0.id == manager.selectedAudioTrackID })?.title ?? "Audio",
                systemImage: "waveform"
            )
        }
        .buttonStyle(.bordered)
    }

    private func playerGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 18)
            .onChanged { value in
                guard abs(value.translation.width) <= abs(value.translation.height) else { return }
                if value.startLocation.x < size.width / 2 {
                    manager.adjustBrightness(by: -value.translation.height / 2200)
                } else {
                    manager.adjustVolume(by: Float(-value.translation.height / 900))
                }
            }
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                let offset = Double(value.translation.width / 8)
                manager.seek(by: offset)
                seekFeedback = offset >= 0 ? "+\(Int(offset)) сек" : "\(Int(offset)) сек"
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 900_000_000)
                    seekFeedback = nil
                }
            }
    }

    private func timeLabel(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds > 0 else { return "00:00" }
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

#if os(iOS)
import UIKit

private struct PlayerRenderView: UIViewRepresentable {
    let player: AVPlayer
    let onLayerReady: (AVPlayerLayer) -> Void

    func makeUIView(context: Context) -> PlayerLayerUIView {
        let view = PlayerLayerUIView()
        view.playerLayer.videoGravity = .resizeAspect
        view.playerLayer.player = player
        onLayerReady(view.playerLayer)
        return view
    }

    func updateUIView(_ uiView: PlayerLayerUIView, context: Context) {
        uiView.playerLayer.player = player
        onLayerReady(uiView.playerLayer)
    }
}

private final class PlayerLayerUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
}
#else
import AppKit

private struct PlayerRenderView: NSViewRepresentable {
    let player: AVPlayer
    let onLayerReady: (AVPlayerLayer) -> Void

    func makeNSView(context: Context) -> PlayerLayerNSView {
        let view = PlayerLayerNSView()
        view.playerLayer.videoGravity = .resizeAspect
        view.playerLayer.player = player
        onLayerReady(view.playerLayer)
        return view
    }

    func updateNSView(_ nsView: PlayerLayerNSView, context: Context) {
        nsView.playerLayer.player = player
        onLayerReady(nsView.playerLayer)
    }
}

private final class PlayerLayerNSView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = AVPlayerLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer = AVPlayerLayer()
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
}
#endif
