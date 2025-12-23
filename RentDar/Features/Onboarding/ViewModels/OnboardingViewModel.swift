import SwiftUI

@Observable
final class OnboardingViewModel {
    var currentPage = 0
    let pages = OnboardingPage.pages

    var isLastPage: Bool {
        currentPage == pages.count - 1
    }

    var isFirstThreePages: Bool {
        currentPage < pages.count - 1
    }

    func nextPage() {
        guard currentPage < pages.count - 1 else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentPage += 1
        }
    }

    func skip() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentPage = pages.count - 1
        }
    }
}
