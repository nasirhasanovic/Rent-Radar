import SwiftUI

struct PageIndicator: View {
    let totalPages: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? AppColors.primary : AppColors.border)
                    .frame(
                        width: index == currentPage ? 24 : 8,
                        height: 8
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PageIndicator(totalPages: 4, currentPage: 0)
        PageIndicator(totalPages: 4, currentPage: 1)
        PageIndicator(totalPages: 4, currentPage: 3)
    }
}
