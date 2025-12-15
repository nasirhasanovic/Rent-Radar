import SwiftUI

struct TipBar: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\u{1F4A1}")
                .font(.system(size: 16))
                .frame(width: 32, height: 32)
                .background(AppColors.teal100.opacity(0.6))
                .clipShape(Circle())

            Text(text)
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.teal500)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.teal100.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
