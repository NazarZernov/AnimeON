import SwiftUI

struct LoadingSkeletonView: View {
    @Environment(\.appTheme) private var theme

    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    init(width: CGFloat? = nil, height: CGFloat, cornerRadius: CGFloat = 18) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        theme.palette.secondaryCard.opacity(0.9),
                        theme.palette.secondaryCard.opacity(0.4),
                        theme.palette.secondaryCard.opacity(0.9)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(theme.palette.outline, lineWidth: 1)
            )
            .opacity(0.85)
    }
}

#Preview {
    LoadingSkeletonView(width: 240, height: 140)
        .padding()
        .background(Color.black)
}
