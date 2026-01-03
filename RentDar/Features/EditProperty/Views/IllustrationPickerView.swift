import SwiftUI

struct IllustrationPickerView: View {
    @Binding var selectedIndex: Int?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(PropertyIllustration.presets) { preset in
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: preset.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                selectedIndex == preset.id
                                    ? AppColors.surface
                                    : Color.clear,
                                lineWidth: 3
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                selectedIndex == preset.id
                                    ? AppColors.teal500
                                    : Color.clear,
                                lineWidth: 2
                            )
                            .padding(-1)
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.2)) {
                            selectedIndex = preset.id
                        }
                    }
            }
        }
    }
}
