import SwiftUI

struct SignUpView: View {
    @State private var viewModel = SignUpViewModel()
    @State private var owlSubtitle = "Your secret is safe with me \u{1F60E}"
    var onBack: () -> Void
    var onLogin: () -> Void
    var onComplete: () -> Void

    var body: some View {
        Group {
            switch viewModel.phase {
            case .registration:
                registrationView
            case .verification:
                EmailVerificationView(viewModel: viewModel, onBack: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.phase = .registration
                    }
                })
            case .success:
                SignUpSuccessView(
                    firstName: viewModel.firstName,
                    onAddProperty: onComplete,
                    onExplore: onComplete
                )
            }
        }
        .animation(.easeInOut(duration: 0.35), value: viewModel.phase)
    }

    private var registrationView: some View {
        VStack(spacing: 0) {
            // Header — back button
            HStack {
                Button {
                    if viewModel.canGoBack {
                        withAnimation(.easeInOut(duration: 0.25)) { viewModel.goBack() }
                    } else {
                        onBack()
                    }
                } label: {
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

            // Progress bar
            SignUpProgressBar(
                progress: viewModel.progressPercent,
                step: viewModel.currentStep,
                totalSteps: viewModel.totalSteps,
                label: viewModel.stepLabel
            )
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)

            // Step content
            ScrollView(.vertical, showsIndicators: false) {
                Group {
                    switch viewModel.currentStep {
                    case 1:
                        step1AccountView
                    case 2:
                        step2PersonalInfoView
                    case 3:
                        step3SecurityView
                    case 4:
                        step4PropertyTypeView
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .background(AppColors.elevated)
        .animation(.easeInOut(duration: 0.25), value: viewModel.currentStep)
    }

    // MARK: - Step 1: Account

    private var step1AccountView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Create Account")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.bottom, 8)

            Text("Sign up to start managing your rental properties like a pro.")
                .font(.system(size: 15))
                .foregroundStyle(AppColors.textTertiary)
                .lineSpacing(4)
                .padding(.bottom, 32)

            // Social buttons
            VStack(spacing: 12) {
                Button {
                    viewModel.signUpWithGoogle()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(AppColors.expense)
                        Text("Continue with Google")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(AppColors.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppColors.border, lineWidth: 2)
                    )
                }

                Button {
                    viewModel.signUpWithApple()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                        Text("Continue with Apple")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(AppColors.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.bottom, 28)

            // Divider
            HStack(spacing: 16) {
                Rectangle().fill(AppColors.border).frame(height: 1)
                Text("or continue with email")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.textTertiary)
                    .layoutPriority(1)
                Rectangle().fill(AppColors.border).frame(height: 1)
            }
            .padding(.bottom, 28)

            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email Address")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)

                TextField("Enter your email", text: $viewModel.email)
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.textPrimary)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal, 16)
                    .frame(height: 54)
                    .background(AppColors.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppColors.border, lineWidth: 2)
                    )
            }

            // Continue
            SignUpContinueButton(title: String(localized: "Continue"), isDisabled: !viewModel.isEmailValid) {
                withAnimation(.easeInOut(duration: 0.25)) { viewModel.goNext() }
            }
            .padding(.top, 24)

            Spacer().frame(height: 40)

            // Footer
            HStack {
                Spacer()
                Text("Already have an account?")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.textTertiary)
                Button { onLogin() } label: {
                    Text("Log in")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.teal600)
                }
                Spacer()
            }
        }
    }

    // MARK: - Step 2: Personal Info

    private var step2PersonalInfoView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Tell us about you")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.bottom, 8)

            Text("We\u{2019}ll personalize your experience based on your details.")
                .font(.system(size: 15))
                .foregroundStyle(AppColors.textTertiary)
                .lineSpacing(4)
                .padding(.bottom, 32)

            // Avatar preview
            HStack(spacing: 16) {
                Text(viewModel.initials.isEmpty ? "?" : viewModel.initials)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "0D9488"), Color(hex: "14B8A6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.fullName.isEmpty ? "Your Name" : viewModel.fullName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Tap to add profile photo")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textTertiary)
                }

                Spacer()

                Text("\u{1F4F7}")
                    .font(.system(size: 14))
                    .frame(width: 36, height: 36)
                    .background(AppColors.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            }
            .padding(16)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.bottom, 24)

            // Name fields side by side
            HStack(spacing: 12) {
                SignUpFormField(label: "First Name", placeholder: "John", text: $viewModel.firstName)
                    .textContentType(.givenName)
                SignUpFormField(label: "Last Name", placeholder: "Doe", text: $viewModel.lastName)
                    .textContentType(.familyName)
            }
            .padding(.bottom, 20)

            // Phone
            VStack(alignment: .leading, spacing: 8) {
                Text("Phone Number")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)

                HStack(spacing: 10) {
                    Text(viewModel.countryCode)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: 70, height: 54)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppColors.border, lineWidth: 2)
                        )

                    TextField("(555) 123-4567", text: $viewModel.phoneNumber)
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.textPrimary)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .padding(.horizontal, 16)
                        .frame(height: 54)
                        .background(AppColors.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppColors.border, lineWidth: 2)
                        )
                }

                HStack(spacing: 6) {
                    Text("\u{1F512}")
                        .font(.system(size: 14))
                    Text("We\u{2019}ll only use this for account security")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textTertiary)
                }
                .padding(.top, 4)
            }

            SignUpContinueButton(title: String(localized: "Continue"), isDisabled: !viewModel.isStep2Valid) {
                withAnimation(.easeInOut(duration: 0.25)) { viewModel.goNext() }
            }
            .padding(.top, 24)
        }
    }

    // MARK: - Step 3: Security

    private var step3SecurityView: some View {
        VStack(spacing: 0) {
            // Owl character
            OwlCharacter(isCool: !viewModel.isAnyPasswordVisible)
                .padding(.bottom, 20)

            // Title
            Text("Create a password")
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 6)

            // Dynamic subtitle
            Text(owlSubtitle)
                .font(.system(size: 14))
                .foregroundStyle(viewModel.isAnyPasswordVisible ? AppColors.textTertiary : AppColors.teal600)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 24)
                .animation(.easeInOut(duration: 0.3), value: viewModel.isAnyPasswordVisible)

            // Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)

                AuthPasswordField(
                    placeholder: "Enter password",
                    text: $viewModel.password,
                    isVisible: $viewModel.isPasswordVisible
                )

                // Strength indicator
                if !viewModel.password.isEmpty {
                    PasswordStrengthBar(
                        strength: viewModel.passwordStrength,
                        label: viewModel.strengthLabel,
                        color: viewModel.strengthColor
                    )
                }
            }
            .padding(.bottom, 16)

            // Confirm password
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

            // Requirements
            PasswordRequirementsBox(
                hasMinLength: viewModel.hasMinLength,
                hasUppercase: viewModel.hasUppercase,
                hasNumber: viewModel.hasNumber,
                hasSpecialChar: viewModel.hasSpecialChar
            )
            .padding(.top, 16)

            SignUpContinueButton(title: String(localized: "Continue"), isDisabled: !viewModel.isStep3Valid) {
                withAnimation(.easeInOut(duration: 0.25)) { viewModel.goNext() }
            }
            .padding(.top, 20)
        }
        .onChange(of: viewModel.isPasswordVisible) { _, _ in updateOwlSubtitle() }
        .onChange(of: viewModel.isConfirmPasswordVisible) { _, _ in updateOwlSubtitle() }
    }

    private func updateOwlSubtitle() {
        if viewModel.isAnyPasswordVisible {
            let phrases = [
                "Oh! Let me see... \u{1F440}",
                "Okay okay, I\u{2019}ll look away! \u{1F633}",
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

    // MARK: - Step 4: Property Type

    private var step4PropertyTypeView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What do you manage?")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.bottom, 8)

            Text("Select the type of rentals you manage so we can customize your experience.")
                .font(.system(size: 15))
                .foregroundStyle(AppColors.textTertiary)
                .lineSpacing(4)
                .padding(.bottom, 28)

            // Property type cards
            VStack(spacing: 12) {
                ForEach(RentalManagementType.allCases, id: \.rawValue) { type in
                    PropertyTypeCard(
                        type: type,
                        isSelected: viewModel.selectedPropertyType == type
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedPropertyType = type
                        }
                    }
                }
            }
            .padding(.bottom, 28)

            // Property count
            VStack(alignment: .leading, spacing: 12) {
                Text("How many properties do you manage?")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)

                HStack(spacing: 16) {
                    Button { viewModel.decrementPropertyCount() } label: {
                        Text("\u{2212}")
                            .font(.system(size: 20))
                            .foregroundStyle(AppColors.textTertiary)
                            .frame(width: 44, height: 44)
                            .background(AppColors.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.border, lineWidth: 2)
                            )
                    }

                    Text("\(viewModel.propertyCount)")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundStyle(AppColors.teal600)
                        .frame(minWidth: 60)

                    Button { viewModel.incrementPropertyCount() } label: {
                        Text("+")
                            .font(.system(size: 20))
                            .foregroundStyle(AppColors.textTertiary)
                            .frame(width: 44, height: 44)
                            .background(AppColors.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.border, lineWidth: 2)
                            )
                    }

                    Spacer()
                }

                Text("You can always add more later")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(20)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.bottom, 24)

            // Create Account button
            SignUpContinueButton(
                title: viewModel.isLoading ? String(localized: "Creating Account...") : String(localized: "Create Account"),
                isDisabled: viewModel.isLoading
            ) {
                viewModel.createAccount()
            }

            // Skip link
            Button { viewModel.createAccount() } label: {
                Text("Skip for now, I\u{2019}ll set this up later")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
            }
        }
    }
}

// MARK: - Progress Bar

private struct SignUpProgressBar: View {
    let progress: Double
    let step: Int
    let totalSteps: Int
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.border)
                        .frame(height: 4)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "0D9488"), Color(hex: "14B8A6")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 4)

            HStack {
                Text("Step \(step) of \(totalSteps)")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textTertiary)
                Spacer()
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
    }
}

// MARK: - Form Field

private struct SignUpFormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)

            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(text.isEmpty ? AppColors.elevated : Color(hex: "F0FDFA"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(text.isEmpty ? AppColors.border : AppColors.teal600, lineWidth: 2)
                )
        }
    }
}

// MARK: - Password Components
// AuthPasswordField, PasswordStrengthBar, PasswordRequirementRow, PasswordRequirementsBox
// are now in AuthComponents.swift as shared components

// MARK: - Property Type Card

private struct PropertyTypeCard: View {
    let type: RentalManagementType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(type.emoji)
                        .font(.system(size: 26))
                        .frame(width: 52, height: 52)
                        .background(
                            LinearGradient(
                                colors: type.iconGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(AppColors.teal600)
                            .clipShape(Circle())
                    }
                }

                Text(type.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Text(type.description)
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textTertiary)
                    .lineSpacing(2)

                if !type.chips.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(type.chips, id: \.self) { chip in
                            Text(chip)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(AppColors.textTertiary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(AppColors.elevated)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isSelected ? Color(hex: "99F6E4") : AppColors.border, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color(hex: "F0FDFA") : AppColors.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? AppColors.teal600 : AppColors.border, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Continue Button

struct SignUpContinueButton: View {
    let title: String
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    isDisabled
                        ? AnyShapeStyle(AppColors.teal300)
                        : AnyShapeStyle(
                            LinearGradient(
                                colors: [Color(hex: "0D9488"), Color(hex: "0F766E")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(
                    color: isDisabled ? .clear : AppColors.teal500.opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .disabled(isDisabled)
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Owl Character
// OwlCharacter is now in OwlCharacter.swift as a shared component
