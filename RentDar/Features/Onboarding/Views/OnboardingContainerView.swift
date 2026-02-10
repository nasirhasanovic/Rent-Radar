import SwiftUI

struct OnboardingContainerView: View {
    @State private var viewModel = OnboardingViewModel()
    var onGetStarted: () -> Void
    var onAlreadyHaveAccount: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Skip button (hidden on last page)
            HStack {
                Spacer()
                if viewModel.isFirstThreePages {
                    Button {
                        viewModel.skip()
                    } label: {
                        Text("Skip")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.top, 8)
            .frame(height: 44)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isFirstThreePages)

            // Page content
            TabView(selection: $viewModel.currentPage) {
                ForEach(viewModel.pages) { page in
                    OnboardingPageView(
                        page: page,
                        isActive: viewModel.currentPage == page.id
                    )
                    .tag(page.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.currentPage)

            // Page indicators
            PageIndicator(
                totalPages: viewModel.pages.count,
                currentPage: viewModel.currentPage
            )
            .padding(.bottom, 24)

            // Bottom buttons
            VStack(spacing: 12) {
                if viewModel.isLastPage {
                    PrimaryButton(title: String(localized: "Get Started")) {
                        onGetStarted()
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                    SecondaryButton(title: String(localized: "I already have an account")) {
                        onAlreadyHaveAccount()
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                } else {
                    PrimaryButton(title: String(localized: "Next")) {
                        viewModel.nextPage()
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.bottom, 40)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isLastPage)
        }
        .background(AppColors.surface)
    }
}

#Preview {
    OnboardingContainerView(
        onGetStarted: {},
        onAlreadyHaveAccount: {}
    )
}
