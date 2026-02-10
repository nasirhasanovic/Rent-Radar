import SwiftUI

struct ForgotPasswordView: View {
    @State private var viewModel = ForgotPasswordViewModel()
    @State private var owlSubtitle = "Your secret is safe with me \u{1F60E}"
    var onDismiss: () -> Void
    var onSuccess: () -> Void

    var body: some View {
        Group {
            switch viewModel.currentStep {
            case .enterEmail:
                enterEmailStep
            case .verifyCode:
                verifyCodeStep
            case .newPassword:
                newPasswordStep
            case .success:
                successStep
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
    }

    // MARK: - Step 1: Enter Email

    private var enterEmailStep: some View {
        VStack(spacing: 0) {
            ForgotPasswordHeader(
                onBack: onDismiss,
                currentStep: 1,
                stepLabel: "Email"
            )

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Illustration
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "99F6E4"), Color(hex: "5EEAD4")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Text("\u{1F4E7}")
                                .font(.system(size: 56))
                        )
                        .padding(.top, 32)
                        .padding(.bottom, 16)

                    // Title
                    Text("Forgot Password?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(.bottom, 8)

                    Text("No worries! Enter the email address associated with your account and we'll send you a reset code.")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.textTertiary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)

                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Address")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColors.textSecondary)

                        HStack(spacing: 10) {
                            Text("\u{2709}\u{FE0F}")
                                .font(.system(size: 16))

                            TextField("Enter your email", text: $viewModel.email)
                                .font(.system(size: 15))
                                .foregroundStyle(AppColors.textPrimary)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                        .padding(14)
                        .background(AppColors.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    viewModel.email.isEmpty ? AppColors.border : AppColors.teal500,
                                    lineWidth: 1.5
                                )
                        )
                    }
                    .padding(.horizontal, 24)
                }
            }

            Spacer()

            // Button
            VStack(spacing: 16) {
                Button {
                    viewModel.sendResetCode { }
                } label: {
                    HStack {
                        Text(viewModel.isLoading ? String(localized: "Sending...") : String(localized: "Send Reset Code"))
                            .font(.system(size: 16, weight: .semibold))
                        if !viewModel.isLoading {
                            Text("\u{2192}")
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppColors.teal500)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: AppColors.teal500.opacity(0.35), radius: 14, x: 0, y: 4)
                }
                .disabled(!viewModel.isEmailValid || viewModel.isLoading)
                .opacity(viewModel.isEmailValid ? 1 : 0.6)

                HStack(spacing: 4) {
                    Text("Remember your password?")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.textTertiary)
                    Button { onDismiss() } label: {
                        Text("Sign In")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.teal600)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .background(AppColors.elevated)
    }

    // MARK: - Step 2: Verify Code

    private var verifyCodeStep: some View {
        VStack(spacing: 0) {
            ForgotPasswordHeader(
                onBack: { viewModel.goBack() },
                currentStep: 2,
                stepLabel: "Verification"
            )

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Illustration with badge
                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "99F6E4"), Color(hex: "5EEAD4")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .overlay(
                                Text("\u{1F4E7}")
                                    .font(.system(size: 56))
                            )

                        Circle()
                            .fill(AppColors.teal500)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text("\u{2709}")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white)
                            )
                            .overlay(
                                Circle().stroke(.white, lineWidth: 3)
                            )
                            .offset(x: 4, y: -4)
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 16)

                    // Title
                    Text("Verify Your Email")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(.bottom, 8)

                    Text("We sent a code to")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.textTertiary)

                    Text(viewModel.email)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(.top, 4)

                    // OTP fields
                    OTPInputView(
                        code: Binding(
                            get: { viewModel.verificationCode },
                            set: { viewModel.verificationCode = $0 }
                        ),
                        digitCount: 4
                    )
                    .padding(.top, 32)

                    // Resend section
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Text("Didn't receive code?")
                                .font(.system(size: 14))
                                .foregroundStyle(AppColors.textTertiary)

                            Button { viewModel.resendCode() } label: {
                                Text("Resend")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(viewModel.resendTimer == 0 ? AppColors.teal600 : AppColors.textTertiary)
                            }
                            .disabled(viewModel.resendTimer > 0)
                        }

                        if viewModel.resendTimer > 0 {
                            Text("Resend available in \(viewModel.timerFormatted)")
                                .font(.system(size: 12))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                    .padding(.top, 20)
                }
            }

            Spacer()

            // Button
            Button {
                viewModel.verifyCode { }
            } label: {
                HStack {
                    Text(viewModel.isLoading ? String(localized: "Verifying...") : String(localized: "Verify"))
                    if !viewModel.isLoading {
                        Text("\u{2192}")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(AppColors.teal500)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: AppColors.teal500.opacity(0.35), radius: 14, x: 0, y: 4)
            }
            .disabled(!viewModel.isCodeComplete || viewModel.isLoading)
            .opacity(viewModel.isCodeComplete ? 1 : 0.6)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .background(AppColors.elevated)
    }

    // MARK: - Step 3: New Password

    private var isAnyPasswordVisible: Bool {
        viewModel.isPasswordVisible || viewModel.isConfirmPasswordVisible
    }

    private var newPasswordStep: some View {
        VStack(spacing: 0) {
            ForgotPasswordHeader(
                onBack: { viewModel.goBack() },
                currentStep: 3,
                stepLabel: "Security"
            )

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Owl character
                    OwlCharacter(isCool: !isAnyPasswordVisible)
                        .padding(.top, 20)
                        .padding(.bottom, 16)

                    // Title
                    Text("Create New Password")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(.bottom, 4)

                    // Dynamic subtitle
                    Text(owlSubtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(isAnyPasswordVisible ? AppColors.textTertiary : AppColors.teal600)
                        .padding(.bottom, 24)
                        .animation(.easeInOut(duration: 0.3), value: isAnyPasswordVisible)

                    // Password fields
                    VStack(spacing: 16) {
                        // New Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppColors.textSecondary)

                            AuthPasswordField(
                                placeholder: "Enter password",
                                text: $viewModel.newPassword,
                                isVisible: $viewModel.isPasswordVisible
                            )

                            // Strength indicator
                            if !viewModel.newPassword.isEmpty {
                                PasswordStrengthBar(
                                    strength: viewModel.passwordStrengthLevel,
                                    label: viewModel.passwordStrength,
                                    color: viewModel.passwordStrengthColor
                                )
                            }
                        }

                        // Confirm Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppColors.textSecondary)

                            AuthPasswordField(
                                placeholder: "Confirm password",
                                text: $viewModel.confirmPassword,
                                isVisible: $viewModel.isConfirmPasswordVisible
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    // Requirements
                    PasswordRequirementsBox(
                        hasMinLength: viewModel.hasMinLength,
                        hasUppercase: viewModel.hasUppercase,
                        hasNumber: viewModel.hasNumber,
                        hasSpecialChar: viewModel.hasSpecialChar
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }

            Spacer()

            // Button
            Button {
                viewModel.resetPassword { }
            } label: {
                HStack {
                    Text(viewModel.isLoading ? String(localized: "Resetting...") : String(localized: "Reset Password"))
                    if !viewModel.isLoading {
                        Text("\u{2192}")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(AppColors.teal500)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: AppColors.teal500.opacity(0.35), radius: 14, x: 0, y: 4)
            }
            .disabled(!viewModel.canResetPassword || viewModel.isLoading)
            .opacity(viewModel.canResetPassword ? 1 : 0.6)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .background(AppColors.elevated)
        .onChange(of: viewModel.isPasswordVisible) { _, _ in updateOwlSubtitle() }
        .onChange(of: viewModel.isConfirmPasswordVisible) { _, _ in updateOwlSubtitle() }
    }

    private func updateOwlSubtitle() {
        if isAnyPasswordVisible {
            let phrases = [
                "Oh! Let me see... \u{1F440}",
                "Okay okay, I'll look away! \u{1F633}",
                "Just a quick peek! \u{1F648}",
                "Oops, caught me looking! \u{1F441}\u{FE0F}",
            ]
            owlSubtitle = phrases.randomElement()!
        } else {
            let phrases = [
                "Your secret is safe with me \u{1F60E}",
                "Looking cool, staying secure \u{1F576}\u{FE0F}",
                "No peeking here! \u{1F60E}",
                "Classified information \u{1F92B}",
            ]
            owlSubtitle = phrases.randomElement()!
        }
    }

    // MARK: - Step 4: Success

    private var successStep: some View {
        VStack(spacing: 0) {
            Spacer()

            // Success circle
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(.white.opacity(0.3))
                    .frame(width: 80, height: 80)

                Text("\u{2713}")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 32)

            Text("Password Reset!")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .padding(.bottom, 8)

            Text("Your password has been successfully reset.\nYou can now sign in with your new password.")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            // Tip cards
            VStack(spacing: 12) {
                SuccessTipCard(icon: "\u{1F510}", title: String(localized: "Keep it Secure"), description: String(localized: "Don\u{2019}t share your password with anyone"))
                SuccessTipCard(icon: "\u{1F3E0}", title: String(localized: "Manage Properties"), description: String(localized: "Access all your rentals securely"))
            }
            .padding(.top, 40)
            .padding(.horizontal, 24)

            Spacer()

            // Button
            Button {
                onSuccess()
            } label: {
                HStack {
                    Text("Sign In")
                    Text("\u{2192}")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.teal600)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.15), radius: 14, x: 0, y: 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "0D9488"), Color(hex: "0F766E")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Header

private struct ForgotPasswordHeader: View {
    let onBack: () -> Void
    let currentStep: Int
    let stepLabel: String

    var body: some View {
        VStack(spacing: 0) {
            // Back button
            HStack {
                Button(action: onBack) {
                    Text("\u{2039}")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(AppColors.textTertiary)
                        .frame(width: 36, height: 36)
                        .background(AppColors.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // Progress bar
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(1...3, id: \.self) { step in
                        Capsule()
                            .fill(step <= currentStep ? AppColors.teal500 : AppColors.border)
                            .frame(height: 4)
                    }
                }

                HStack {
                    Text("Step \(currentStep) of 3")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textTertiary)
                    Spacer()
                    Text(stepLabel)
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }
}

// MARK: - Success Tip Card

private struct SuccessTipCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            Text(icon)
                .font(.system(size: 18))
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(16)
        .background(.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    ForgotPasswordView(onDismiss: {}, onSuccess: {})
}
