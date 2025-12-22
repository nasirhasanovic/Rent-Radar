import SwiftUI

/// A reusable OTP/verification code input component
/// - Configurable number of digits (4-6)
/// - Auto-advances to next field when digit is entered
/// - Supports backspace to go to previous field
/// - Handles paste of full code
struct OTPInputView: View {
    @Binding var code: [String]
    let digitCount: Int
    @FocusState private var focusedIndex: Int?

    init(code: Binding<[String]>, digitCount: Int = 6) {
        self._code = code
        self.digitCount = digitCount
    }

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<digitCount, id: \.self) { index in
                OTPDigitBox(
                    text: Binding(
                        get: { index < code.count ? code[index] : "" },
                        set: { newValue in
                            handleInput(newValue, at: index)
                        }
                    ),
                    isFocused: focusedIndex == index,
                    onBackspace: {
                        handleBackspace(at: index)
                    }
                )
                .focused($focusedIndex, equals: index)
            }
        }
        .padding(.horizontal, 4) // Extra space for shadow/stroke
        .padding(.vertical, 4)
        .onAppear {
            focusedIndex = 0
        }
    }

    private func handleInput(_ newValue: String, at index: Int) {
        // Filter to only digits
        let filtered = newValue.filter { $0.isNumber }

        // Handle paste of multiple digits
        if filtered.count > 1 {
            let digits = Array(filtered.prefix(digitCount))
            for (i, digit) in digits.enumerated() {
                if i < code.count {
                    code[i] = String(digit)
                }
            }
            // Focus the next empty field or the last field
            let nextEmpty = code.firstIndex(where: { $0.isEmpty }) ?? (digitCount - 1)
            focusedIndex = min(nextEmpty, digitCount - 1)
            return
        }

        // Handle single digit
        let digit = String(filtered.prefix(1))
        if index < code.count {
            code[index] = digit
        }

        // Auto-advance to next field
        if !digit.isEmpty && index < digitCount - 1 {
            focusedIndex = index + 1
        }
    }

    private func handleBackspace(at index: Int) {
        // If current field is empty and not the first, go back
        if index < code.count && code[index].isEmpty && index > 0 {
            focusedIndex = index - 1
        }
    }
}

// MARK: - OTP Digit Box

private struct OTPDigitBox: View {
    @Binding var text: String
    let isFocused: Bool
    let onBackspace: () -> Void

    var body: some View {
        ZStack {
            TextField("", text: $text)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .frame(width: 52, height: 64)
                .background(text.isEmpty ? AppColors.elevated : Color(hex: "F0FDFA"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            text.isEmpty
                                ? (isFocused ? AppColors.teal600 : AppColors.border)
                                : AppColors.teal600,
                            lineWidth: 2
                        )
                )
                .shadow(
                    color: isFocused ? AppColors.teal500.opacity(0.1) : .clear,
                    radius: 8
                )
                .onChange(of: text) { oldValue, newValue in
                    // Detect backspace on empty field
                    if oldValue.isEmpty && newValue.isEmpty {
                        onBackspace()
                    }
                    // Ensure only single digit
                    if newValue.count > 1 {
                        text = String(newValue.suffix(1))
                    }
                    // Filter non-digits
                    text = text.filter { $0.isNumber }
                }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var code4: [String] = ["", "", "", ""]
        @State private var code6: [String] = ["", "", "", "", "", ""]

        var body: some View {
            VStack(spacing: 40) {
                VStack(spacing: 8) {
                    Text("4-digit code")
                        .font(.caption)
                    OTPInputView(code: $code4, digitCount: 4)
                    Text("Entered: \(code4.joined())")
                        .font(.caption)
                }

                VStack(spacing: 8) {
                    Text("6-digit code")
                        .font(.caption)
                    OTPInputView(code: $code6, digitCount: 6)
                    Text("Entered: \(code6.joined())")
                        .font(.caption)
                }
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
