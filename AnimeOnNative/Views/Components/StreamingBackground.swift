import SwiftUI

struct StreamingBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.background, AppTheme.backgroundSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(AppTheme.accent.opacity(0.22))
                .frame(width: 420, height: 420)
                .blur(radius: 120)
                .offset(x: -220, y: -260)

            Circle()
                .fill(AppTheme.accentGlow.opacity(0.16))
                .frame(width: 320, height: 320)
                .blur(radius: 110)
                .offset(x: 260, y: -220)

            Circle()
                .fill(AppTheme.info.opacity(0.08))
                .frame(width: 260, height: 260)
                .blur(radius: 90)
                .offset(x: 180, y: 260)
        }
    }
}
