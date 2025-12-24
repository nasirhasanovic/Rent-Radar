import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Illustration
            Group {
                switch page.id {
                case 0: HouseIllustration()
                case 1: IncomeChartIllustration(isActive: isActive)
                case 2: ExpenseCardsIllustration(isActive: isActive)
                case 3: CalendarIllustration(isActive: isActive)
                default: EmptyView()
                }
            }
            .scaleEffect(isActive ? 1.0 : 0.85)
            .opacity(isActive ? 1.0 : 0.0)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.75).delay(0.1),
                value: isActive
            )

            Spacer()
                .frame(height: 40)

            // Title
            Text(page.title)
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .offset(y: isActive ? 0 : 20)
                .opacity(isActive ? 1.0 : 0.0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.8).delay(0.2),
                    value: isActive
                )

            Spacer()
                .frame(height: 12)

            // Subtitle
            Text(page.subtitle)
                .font(.system(size: 15))
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .offset(y: isActive ? 0 : 20)
                .opacity(isActive ? 1.0 : 0.0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.8).delay(0.3),
                    value: isActive
                )

            Spacer()
        }
        .padding(.horizontal, AppSpacing.screenPadding)
    }
}

// MARK: - House Illustration (Page 0)

private struct HouseIllustration: View {
    @State private var floatOffset: CGFloat = 0
    @State private var badgeBounce: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "F0FDFA"), Color(hex: "CCFBF1")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 280, height: 280)

            ZStack {
                Triangle()
                    .fill(Color(hex: "0F766E"))
                    .frame(width: 130, height: 50)
                    .offset(y: -45)

                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "0D9488"))
                    .frame(width: 100, height: 80)
                    .offset(y: 20)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "5EEAD4"))
                    .frame(width: 20, height: 20)
                    .offset(x: -22, y: -2)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "5EEAD4"))
                    .frame(width: 20, height: 20)
                    .offset(x: 22, y: -2)

                UnevenRoundedRectangle(
                    topLeadingRadius: 4,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 4
                )
                .fill(Color(hex: "134E4A"))
                .frame(width: 28, height: 40)
                .offset(y: 40)
            }

            Text("\u{1F3E0}")
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                .offset(x: 75, y: -60 + badgeBounce)
        }
        .offset(y: floatOffset)
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                floatOffset = -15
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                badgeBounce = -8
            }
        }
    }
}

// MARK: - Income Chart Illustration (Page 1)

private struct IncomeChartIllustration: View {
    let isActive: Bool

    @State private var floatOffset: CGFloat = 0
    @State private var badgeBounce: CGFloat = 0
    @State private var barHeights: [CGFloat] = [0, 0, 0, 0, 0, 0]

    private let targetHeights: [CGFloat] = [65, 90, 50, 100, 20, 20]
    private let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]

    var body: some View {
        ZStack {
            // Revenue card
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Revenue")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(hex: "94A3B8"))

                        Text("$12,450")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(Color(hex: "0F172A"))
                    }

                    Spacer()

                    Text("+24%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(hex: "059669"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "D1FAE5"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Bar chart
                HStack(alignment: .bottom, spacing: 14) {
                    ForEach(0..<6, id: \.self) { i in
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    i < 4
                                    ? LinearGradient(
                                        colors: [Color(hex: "14B8A6"), Color(hex: "0D9488")],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    : LinearGradient(
                                        colors: [Color(hex: "E2E8F0"), Color(hex: "E2E8F0")],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 28, height: barHeights[i])

                            Text(months[i])
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color(hex: "94A3B8"))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 130, alignment: .bottom)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .frame(width: 280)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.08), radius: 20, y: 8)

            // Badge
            Text("\u{1F4B0}")
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                .offset(x: 110, y: -80 + badgeBounce)
        }
        .offset(y: floatOffset)
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                floatOffset = -15
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                badgeBounce = -8
            }
        }
        .onChange(of: isActive) { _, active in
            if active {
                for i in 0..<6 {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(i) * 0.1)) {
                        barHeights[i] = targetHeights[i]
                    }
                }
            } else {
                for i in 0..<6 { barHeights[i] = 0 }
            }
        }
    }
}

// MARK: - Expense Cards Illustration (Page 2)

private struct ExpenseCardsIllustration: View {
    let isActive: Bool

    @State private var floatOffset: CGFloat = 0
    @State private var cardShown: [Bool] = [false, false, false, false]

    private struct ExpenseItem {
        let emoji: String
        let category: String
        let detail: String
        let amount: String
        let bgColor: String
    }

    private let items: [ExpenseItem] = [
        ExpenseItem(emoji: "\u{1F9F9}", category: "Cleaning", detail: "After checkout", amount: "-$120", bgColor: "DBEAFE"),
        ExpenseItem(emoji: "\u{1F4E3}", category: "Marketing", detail: "Ad campaign", amount: "-$85", bgColor: "FCE7F3"),
        ExpenseItem(emoji: "\u{1F4E6}", category: "Supplies", detail: "Guest amenities", amount: "-$65", bgColor: "FEF3C7"),
        ExpenseItem(emoji: "\u{1F527}", category: "Repairs", detail: "Plumbing fix", amount: "-$200", bgColor: "FEE2E2"),
    ]

    // Staircase cascade: right to left
    private let xOffsets: [CGFloat] = [20, 8, -4, -16]
    private let yOffsets: [CGFloat] = [-78, -26, 26, 78]

    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                let item = items[i]
                HStack(spacing: 14) {
                    Text(item.emoji)
                        .font(.system(size: 20))
                        .frame(width: 44, height: 44)
                        .background(Color(hex: item.bgColor))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.category)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(hex: "1E293B"))
                        Text(item.detail)
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "94A3B8"))
                    }

                    Spacer()

                    Text(item.amount)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: "EF4444"))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(width: 280)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.07), radius: 12, y: 4)
                .offset(
                    x: xOffsets[i] + (cardShown[i] ? 0 : (i % 2 == 0 ? 40 : -40)),
                    y: yOffsets[i]
                )
                .opacity(cardShown[i] ? 1 : 0)
            }
        }
        .frame(height: 290)
        .offset(y: floatOffset)
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                floatOffset = -10
            }
        }
        .onChange(of: isActive) { _, active in
            if active {
                for i in 0..<4 {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(i) * 0.1)) {
                        cardShown[i] = true
                    }
                }
            } else {
                for i in 0..<4 { cardShown[i] = false }
            }
        }
    }
}

// MARK: - Calendar Illustration (Page 3)

private struct CalendarIllustration: View {
    let isActive: Bool

    @State private var floatOffset: CGFloat = 0
    @State private var badgePulse: CGFloat = 1

    // January 2026 starts on Thursday (index 4)
    // Color types: 0=empty, 1=airbnb(red), 2=booking(blue), 3=vrbo(indigo), 4=direct(amber), 5=available(green)
    private let dayColors: [Int] = [
        0, 0, 0, 1, 1, 1, 2,
        2, 2, 3, 3, 3, 4, 4,
        5, 1, 1, 1, 1, 2, 2,
        2, 3, 3, 3, 5, 5, 4,
        4, 4, 1, 1, 1, 1, 0,
    ]

    private let dayNumbers: [Int] = [
        0,  0,  0,  1,  2,  3,  4,
        5,  6,  7,  8,  9, 10, 11,
       12, 13, 14, 15, 16, 17, 18,
       19, 20, 21, 22, 23, 24, 25,
       26, 27, 28, 29, 30, 31,  0,
    ]

    private func colorForType(_ type: Int) -> Color {
        switch type {
        case 1: return Color(hex: "F87171")
        case 2: return Color(hex: "60A5FA")
        case 3: return Color(hex: "818CF8")
        case 4: return Color(hex: "FBBF24")
        case 5: return Color(hex: "34D399")
        default: return .clear
        }
    }

    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        // Calendar card
        VStack(spacing: 0) {
            // Month header
            HStack {
                Text("January 2026")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "0F172A"))

                Spacer()

                Text("85%")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(Color(hex: "0D9488"))
                + Text(" booked")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: "94A3B8"))
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    Text(weekdays[i])
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color(hex: "94A3B8"))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)

            // Calendar grid
            VStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { col in
                            let index = row * 7 + col
                            let dayNum = dayNumbers[index]
                            let colorType = dayColors[index]

                            if dayNum > 0 {
                                Text("\(dayNum)")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(colorType > 0 ? .white : Color(hex: "64748B"))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 24)
                                    .background(
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(colorForType(colorType))
                                    )
                            } else {
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 24)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)

            // Legend
            HStack(spacing: 10) {
                CalendarLegendDot(color: Color(hex: "F87171"), label: "Airbnb")
                CalendarLegendDot(color: Color(hex: "60A5FA"), label: "Booking")
                CalendarLegendDot(color: Color(hex: "818CF8"), label: "VRBO")
                CalendarLegendDot(color: Color(hex: "FBBF24"), label: "Direct")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .frame(width: 280)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 20, y: 8)
        .overlay(alignment: .trailing) {
            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color(hex: "0D9488"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color(hex: "0D9488").opacity(0.3), radius: 8, y: 4)
                .scaleEffect(badgePulse)
                .offset(x: 22)
        }
        .offset(y: floatOffset)
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                floatOffset = -15
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                badgePulse = 1.08
            }
        }
    }
}

private struct CalendarLegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(Color(hex: "94A3B8"))
        }
    }
}

// MARK: - Triangle Shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    OnboardingPageView(
        page: OnboardingPage.pages[0],
        isActive: true
    )
}
