import SwiftUI

struct ScreenContainer<Content: View>: View {
    @Binding var selectedSection: AppSection
    let currentSection: AppSection
    let title: String
    let subtitle: String
    let onRefresh: (() async -> Void)?
    @ViewBuilder let content: Content

    init(
        selectedSection: Binding<AppSection>,
        currentSection: AppSection,
        title: String,
        subtitle: String,
        onRefresh: (() async -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        _selectedSection = selectedSection
        self.currentSection = currentSection
        self.title = title
        self.subtitle = subtitle
        self.onRefresh = onRefresh
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                TopNavigationBar(
                    selectedSection: $selectedSection,
                    currentSection: currentSection,
                    title: title,
                    subtitle: subtitle
                )
                content
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear)
        .refreshable {
            if let onRefresh {
                await onRefresh()
            }
        }
    }
}

struct TopNavigationBar: View {
    @Binding var selectedSection: AppSection
    let currentSection: AppSection
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppTheme.heroGradient)
                        .frame(width: 42, height: 42)
                        .overlay(
                            Image(systemName: "play.rectangle.fill")
                                .foregroundStyle(.white)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("AnimeOn Native")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text("Streaming-grade Apple client")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }

                Spacer(minLength: 12)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        searchHint
                        syncPill
                        premiumPill
                        profilePill
                    }

                    HStack(spacing: 10) {
                        syncPill
                        premiumPill
                        profilePill
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(AppSection.primarySections) { section in
                        Button {
                            withAnimation(.snappy) {
                                selectedSection = section
                            }
                        } label: {
                            Text(section.displayTitle)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(selectedSection == section ? AppTheme.textPrimary : AppTheme.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(selectedSection == section ? AppTheme.accent.opacity(0.24) : AppTheme.surface.opacity(0.92))
                                )
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(selectedSection == section ? AppTheme.accent : AppTheme.surfaceBorder, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: 820, alignment: .leading)
            }
        }
    }

    private var searchHint: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.textMuted)
            Text(currentSection == .search ? "Моментальный поиск" : "⌘F для поиска")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textMuted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.surface.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.surfaceBorder, lineWidth: 1)
        )
    }

    private var syncPill: some View {
        Label("Offline ready", systemImage: "arrow.triangle.2.circlepath.circle.fill")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(AppTheme.success)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(AppTheme.surface.opacity(0.94))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(AppTheme.surfaceBorder, lineWidth: 1)
            )
    }

    private var premiumPill: some View {
        Label("4K / Sync", systemImage: "sparkles")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accent, AppTheme.accentGlow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
    }

    private var profilePill: some View {
        Button {
            withAnimation(.snappy) {
                selectedSection = .profile
            }
        } label: {
            Label(currentSection == .profile ? "Профиль" : "Войти", systemImage: "person.crop.circle.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    Capsule(style: .continuous)
                        .fill(AppTheme.surface.opacity(0.94))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(AppTheme.surfaceBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
