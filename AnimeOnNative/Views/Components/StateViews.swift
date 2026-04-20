import SwiftUI

private struct ShimmerModifier: ViewModifier {
    @State private var offsetX: CGFloat = -220

    func body(content: Content) -> some View {
        content
            .overlay {
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.18),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .rotationEffect(.degrees(18))
                .offset(x: offsetX)
                .blendMode(.plusLighter)
                .onAppear {
                    withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) {
                        offsetX = 320
                    }
                }
            }
            .clipped()
    }
}

private struct SkeletonBlock: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    init(width: CGFloat? = nil, height: CGFloat, cornerRadius: CGFloat = 16) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(AppTheme.surfaceElevated)
            .frame(width: width, height: height)
            .modifier(ShimmerModifier())
    }
}

struct LoadingStateView: View {
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(message)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: 14) {
                SkeletonBlock(height: 178, cornerRadius: 24)
                    .frame(maxWidth: .infinity)
                SkeletonBlock(height: 178, cornerRadius: 24)
                    .frame(maxWidth: .infinity)
            }

            VStack(alignment: .leading, spacing: 10) {
                SkeletonBlock(width: 160, height: 14, cornerRadius: 8)
                SkeletonBlock(height: 12, cornerRadius: 8)
                SkeletonBlock(width: 220, height: 12, cornerRadius: 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.surface.opacity(0.96))
        )
    }
}

struct MessageStateView: View {
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: "sparkles.tv")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.surface.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppTheme.surfaceBorder, lineWidth: 1)
        )
    }
}
