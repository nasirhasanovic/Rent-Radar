import SwiftUI

struct EmailVerificationView: View {
    let viewModel: SignUpViewModel
    var onBack: () -> Void

    @State private var bounceOffset: CGFloat = 0
    @State private var dotScale: CGFloat = 1

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button { onBack() } label: {
                    Text("\u{2039}")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(AppColors.textTertiary)
                        .frame(width: 44, height: 44)
                        .background(AppColors.background)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 40)

                    // Email icon with notification dot
                    ZStack(alignment: .topTrailing) {
                        Text("\u{1F4E7}")
                            .font(.system(size: 48))
                            .frame(width: 100, height: 100)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "0D9488"), Color(hex: "14B8A6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                            .offset(y: bounceOffset)

                        Text("1")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(AppColors.expense)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(.white, lineWidth: 4)
                            )
                            .offset(x: 4, y: -4 + bounceOffset)
                            .scaleEffect(dotScale)
                    }
                    .padding(.bottom, 32)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                            bounceOffset = -10
                        }
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            dotScale = 1.1
                        }
                    }

                    // Title
                    Text("Check your email")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(.bottom, 8)

                    Text("We\u{2019}ve sent a 6-digit verification code to")
                        .font(.system(size: 15))
                        .foregroundStyle(AppColors.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 8)

                    Text(viewModel.email)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColors.teal600)
                        .padding(.bottom, 40)

                    // Code input boxes
                    OTPInputView(
                        code: Binding(
                            get: { viewModel.verificationCode },
                            set: { viewModel.verificationCode = $0 }
                        ),
                        digitCount: 6
                    )
                    .padding(.bottom, 24)

                    // Timer
                    Text("Code expires in ")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.textTertiary)
                    +
                    Text(viewModel.timerFormatted)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.teal600)

                    Spacer().frame(height: 12)

                    // Resend
                    Button { viewModel.resendCode() } label: {
                        Text("Resend code")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.teal600)
                    }
                    .padding(.bottom, 40)

                    // Help section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Didn\u{2019}t receive the email?")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppColors.textTertiary)

                        HStack(spacing: 0) {
                            Text("Check your spam folder or ")
                                .font(.system(size: 12))
                                .foregroundStyle(AppColors.textTertiary)
                            Button { onBack() } label: {
                                Text("try a different email address")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppColors.teal600)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.bottom, 24)

                    // Verify button
                    SignUpContinueButton(
                        title: viewModel.isVerifying ? String(localized: "Verifying...") : String(localized: "Verify Email"),
                        isDisabled: !viewModel.isCodeComplete || viewModel.isVerifying
                    ) {
                        viewModel.verifyEmail { }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .background(AppColors.elevated)
    }
}

// MARK: - Code Digit Field
// OTPInputView is now used as a shared component from OTPInputView.swift
