import SwiftUI

struct PremiumView: View {
    @StateObject private var viewModel: PremiumViewModel
    @Binding private var selectedSection: AppSection

    init(service: any AnimeServicing, selectedSection: Binding<AppSection>) {
        _viewModel = StateObject(wrappedValue: PremiumViewModel(service: service))
        _selectedSection = selectedSection
    }

    var body: some View {
        ScreenContainer(
            selectedSection: $selectedSection,
            currentSection: .premium,
            title: "Раскрой полный потенциал",
            subtitle: AppSection.premium.subtitle
        ) {
            switch viewModel.state {
            case .idle, .loading:
                LoadingStateView(message: "Подтягиваем планы Premium...")

            case let .failed(message):
                MessageStateView(title: "Premium временно недоступен", message: message, actionTitle: "Повторить") {
                    Task { await viewModel.load() }
                }

            case let .empty(message):
                MessageStateView(title: "Нет тарифов", message: message, actionTitle: nil, action: nil)

            case let .loaded(plans):
                VStack(alignment: .leading, spacing: 20) {
                    Text("Поддержи любимый проект и получи 4K-режим, ускоренный прогресс, уникальные бейджи и более премиальное ощущение от просмотра.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 18)], spacing: 18) {
                        ForEach(plans) { plan in
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text(plan.title)
                                        .font(.system(size: 24, weight: .black, design: .rounded))
                                        .foregroundStyle(AppTheme.textPrimary)

                                    Spacer()

                                    if let badge = plan.badge {
                                        Text(badge)
                                            .font(.system(size: 11, weight: .black))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Capsule(style: .continuous).fill(AppTheme.accent))
                                    }
                                }

                                HStack(alignment: .bottom, spacing: 8) {
                                    Text(plan.price)
                                        .font(.system(size: 34, weight: .black, design: .rounded))
                                        .foregroundStyle(AppTheme.textPrimary)

                                    Text(plan.oldPrice)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(AppTheme.textMuted)
                                        .strikethrough()
                                }

                                Text(plan.monthlyEquivalent)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(AppTheme.accent)

                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(plan.features, id: \.self) { feature in
                                        Label(feature, systemImage: "checkmark.circle.fill")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                }

                                Button("Оформить") {}
                                    .buttonStyle(.borderedProminent)
                                    .tint(AppTheme.accent)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(22)
                            .background(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .fill(AppTheme.surface.opacity(0.96))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .stroke(plan.badge == nil ? AppTheme.surfaceBorder : AppTheme.accent.opacity(0.7), lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
        .task {
            if case .idle = viewModel.state {
                await viewModel.load()
            }
        }
    }
}
