import SwiftUI

// MARK: - Owl Character

struct OwlCharacter: View {
    let isCool: Bool

    @State private var sparkleScale: CGFloat = 1

    var body: some View {
        ZStack {
            // Ears
            OwlEar(rotationAngle: -15)
                .offset(x: -30, y: -56)
            OwlEar(rotationAngle: 15)
                .offset(x: 30, y: -56)

            // Body
            UnevenRoundedRectangle(
                topLeadingRadius: 55,
                bottomLeadingRadius: 50,
                bottomTrailingRadius: 50,
                topTrailingRadius: 55
            )
            .fill(
                LinearGradient(
                    colors: [Color(hex: "0D9488"), Color(hex: "0F766E")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 110, height: 95)
            .offset(y: 22)

            // Belly
            Capsule()
                .fill(Color(hex: "99F6E4"))
                .frame(width: 65, height: 55)
                .offset(y: 34)

            // Left wing
            Ellipse()
                .fill(Color(hex: "0F766E"))
                .frame(width: 25, height: 35)
                .rotationEffect(.degrees(15))
                .offset(x: -48, y: 22)

            // Right wing (raises when cool)
            Ellipse()
                .fill(Color(hex: "0F766E"))
                .frame(width: 25, height: 35)
                .rotationEffect(.degrees(isCool ? -30 : -15))
                .offset(x: 48, y: isCool ? 16 : 22)

            // Face
            UnevenRoundedRectangle(
                topLeadingRadius: 50,
                bottomLeadingRadius: 40,
                bottomTrailingRadius: 40,
                topTrailingRadius: 50
            )
            .fill(Color(hex: "F0FDFA"))
            .frame(width: 100, height: 80)
            .offset(y: -22)

            // Eyes
            HStack(spacing: 10) {
                OwlEye(isCool: isCool)
                OwlEye(isCool: isCool)
            }
            .offset(y: -26)

            // Blush (peeking only)
            Capsule()
                .fill(Color(hex: "FDA4AF"))
                .frame(width: 14, height: 7)
                .offset(x: -33, y: -10)
                .opacity(isCool ? 0 : 0.7)

            Capsule()
                .fill(Color(hex: "FDA4AF"))
                .frame(width: 14, height: 7)
                .offset(x: 33, y: -10)
                .opacity(isCool ? 0 : 0.7)

            // Beak
            OwlBeak()
                .fill(Color(hex: "F59E0B"))
                .frame(width: 18, height: 14)
                .offset(y: -2)

            // Sunglasses
            OwlSunglasses()
                .offset(y: isCool ? -28 : -48)
                .opacity(isCool ? 1 : 0.6)
                .rotationEffect(.degrees(isCool ? 0 : 15), anchor: .center)

            // Sparkles (cool only)
            Text("\u{2728}")
                .font(.system(size: 14))
                .offset(x: -58, y: -15)
                .scaleEffect(sparkleScale)
                .opacity(isCool ? 1 : 0)

            Text("\u{2728}")
                .font(.system(size: 14))
                .offset(x: 58, y: -15)
                .scaleEffect(sparkleScale)
                .opacity(isCool ? 1 : 0)
        }
        .frame(width: 140, height: 140)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isCool)
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                sparkleScale = 1.3
            }
        }
    }
}

private struct OwlEar: View {
    let rotationAngle: Double

    var body: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 11,
            bottomLeadingRadius: 2,
            bottomTrailingRadius: 2,
            topTrailingRadius: 11
        )
        .fill(Color(hex: "0D9488"))
        .frame(width: 22, height: 28)
        .rotationEffect(.degrees(rotationAngle))
    }
}

private struct OwlEye: View {
    let isCool: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isCool ? Color(hex: "E2E8F0") : .white)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(Color(hex: "0F766E"), lineWidth: 2)
                )

            if !isCool {
                ZStack {
                    Circle()
                        .fill(Color(hex: "0F172A"))
                        .frame(width: 16, height: 16)

                    Circle()
                        .fill(.white)
                        .frame(width: 6, height: 6)
                        .offset(x: 3, y: -3)
                }
                .offset(y: -4)
                .transition(.opacity)
            }
        }
    }
}

private struct OwlSunglasses: View {
    var body: some View {
        ZStack {
            // Temples
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "0F172A"))
                .frame(width: 22, height: 4)
                .rotationEffect(.degrees(-5))
                .offset(x: -52, y: -4)

            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "0F172A"))
                .frame(width: 22, height: 4)
                .rotationEffect(.degrees(5))
                .offset(x: 52, y: -4)

            // Frame
            HStack(spacing: 0) {
                OwlLens()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "0F172A"))
                    .frame(width: 12, height: 5)
                    .offset(y: -3)

                OwlLens()
            }
        }
    }
}

private struct OwlLens: View {
    var body: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 8,
            bottomLeadingRadius: 12,
            bottomTrailingRadius: 12,
            topTrailingRadius: 8
        )
        .fill(
            LinearGradient(
                colors: [Color(hex: "1E293B"), Color(hex: "0F172A"), Color(hex: "334155")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .frame(width: 36, height: 28)
        .overlay(alignment: .topLeading) {
            Capsule()
                .fill(.white.opacity(0.25))
                .frame(width: 10, height: 6)
                .rotationEffect(.degrees(-15))
                .offset(x: 5, y: 5)
        }
    }
}

private struct OwlBeak: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack(spacing: 40) {
        OwlCharacter(isCool: true)
        OwlCharacter(isCool: false)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
