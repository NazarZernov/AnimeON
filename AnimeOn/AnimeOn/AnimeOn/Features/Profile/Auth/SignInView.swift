import SwiftUI

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var sessionStore: SessionStore
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Sign In")
                    .font(theme.typography.hero)
                    .foregroundStyle(theme.palette.textPrimary)
                Text("The auth layer is ready for future Apple, API, and cookie-backed web-session login. This screen already provides a polished native entry point.")
                    .font(theme.typography.body)
                    .foregroundStyle(theme.palette.textSecondary)

                SettingsSectionContainer(title: "Credentials", subtitle: "Mock account access") {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                    SecureField("Password", text: $password)
                    GradientButton("Sign In", systemImage: "person.crop.circle.badge.checkmark") {
                        sessionStore.signInMock()
                        dismiss()
                    }
                }

                SettingsSectionContainer(title: "Future Sign-In Options", subtitle: "Architecture placeholders") {
                    row("Sign in with Apple", icon: "apple.logo")
                    row("Web Session Login Bridge", icon: "safari")
                    row("JWT + Refresh Token Restore", icon: "key.fill")
                }
            }
            .padding(theme.spacing.large)
        }
        .themedBackground()
        .navigationTitle("Account")
    }

    private func row(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text(title.localized)
            Spacer()
            Text("Soon")
                .foregroundStyle(theme.palette.textSecondary)
        }
        .foregroundStyle(theme.palette.textPrimary)
        .font(.system(size: 15, weight: .semibold, design: .rounded))
    }
}

struct SignUpView: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Create Account")
                    .font(theme.typography.hero)
                    .foregroundStyle(theme.palette.textPrimary)
                SettingsSectionContainer(title: "Coming Online", subtitle: "Future API-backed registration") {
                    Text("Email/password registration, Sign in with Apple, and social auth can plug into the session layer without changing the surrounding app architecture.")
                        .font(theme.typography.body)
                        .foregroundStyle(theme.palette.textSecondary)
                }
            }
            .padding(theme.spacing.large)
        }
        .themedBackground()
        .navigationTitle("Sign Up")
    }
}
