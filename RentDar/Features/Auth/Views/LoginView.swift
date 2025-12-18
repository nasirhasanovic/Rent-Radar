import SwiftUI

struct LoginView: View {
    private let settings = AppSettings.shared
    @State private var viewModel = LoginViewModel()
    @State private var hasAppeared = false
    @State private var showForgotPassword = false
    var onBack: () -> Void
    var onSignIn: () -> Void
    var onSignUp: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Back button
            Button {
                onBack()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            }
            .padding(.bottom, 24)
            .offset(y: hasAppeared ? 0 : -20)
            .opacity(hasAppeared ? 1 : 0)

            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome back")
                    .font(AppTypography.heading1)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Sign in to manage your properties")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(.bottom, 32)
            .offset(y: hasAppeared ? 0 : 20)
            .opacity(hasAppeared ? 1 : 0)

            // Form fields
            VStack(spacing: 20) {
                AppTextField(
                    label: "Email",
                    placeholder: "john@example.com",
                    text: $viewModel.email
                )
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

                VStack(alignment: .trailing, spacing: 8) {
                    AppTextField(
                        label: "Password",
                        placeholder: "••••••••",
                        text: $viewModel.password,
                        isSecure: true
                    )
                    .textContentType(.password)

                    Button {
                        showForgotPassword = true
                    } label: {
                        Text("Forgot password?")
                            .font(AppTypography.bodySmall)
                            .foregroundStyle(AppColors.primary)
                    }
                }
            }
            .offset(y: hasAppeared ? 0 : 30)
            .opacity(hasAppeared ? 1 : 0)

            Spacer().frame(height: 28)

            // Sign In button
            PrimaryButton(
                title: viewModel.isLoading ? "Signing In..." : "Sign In",
                isDisabled: !viewModel.isFormValid || viewModel.isLoading
            ) {
                viewModel.signIn(onSuccess: onSignIn)
            }
            .offset(y: hasAppeared ? 0 : 30)
            .opacity(hasAppeared ? 1 : 0)

            Spacer().frame(height: 24)

            // Divider
            HStack {
                Rectangle()
                    .fill(AppColors.border)
                    .frame(height: 1)
                Text("or continue with")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .layoutPriority(1)
                Rectangle()
                    .fill(AppColors.border)
                    .frame(height: 1)
            }
            .offset(y: hasAppeared ? 0 : 20)
            .opacity(hasAppeared ? 1 : 0)

            Spacer().frame(height: 24)

            // Social login buttons
            HStack(spacing: 12) {
                SocialLoginButton(
                    title: "Google",
                    icon: "g.circle.fill",
                    iconColor: AppColors.error
                ) {
                    viewModel.signInWithGoogle()
                }

                SocialLoginButton(
                    title: "Apple",
                    icon: "apple.logo",
                    iconColor: AppColors.textPrimary
                ) {
                    viewModel.signInWithApple()
                }
            }
            .offset(y: hasAppeared ? 0 : 20)
            .opacity(hasAppeared ? 1 : 0)

            Spacer()

            // Sign up link
            HStack {
                Spacer()
                Text("Don't have an account?")
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.textTertiary)
                Button {
                    onSignUp()
                } label: {
                    Text("Sign up")
                        .font(AppTypography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.primary)
                }
                Spacer()
            }
            .padding(.bottom, 16)
            .opacity(hasAppeared ? 1 : 0)
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.top, 16)
        .background(AppColors.surface)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                hasAppeared = true
            }
        }
        .fullScreenCover(isPresented: $showForgotPassword) {
            ForgotPasswordView(
                onDismiss: { showForgotPassword = false },
                onSuccess: {
                    showForgotPassword = false
                }
            )
            .preferredColorScheme(settings.colorScheme)
            .environment(\.locale, settings.locale)
        }
    }
}

// MARK: - Social Login Button

private struct SocialLoginButton: View {
    let title: String
    let icon: String
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(AppTypography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppSpacing.buttonHeight)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                    .stroke(AppColors.border, lineWidth: 1.5)
            )
        }
    }
}

#Preview {
    LoginView(
        onBack: {},
        onSignIn: {},
        onSignUp: {}
    )
}
