import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var radarAngle: Double = 0
    @State private var ring1Scale: CGFloat = 1.0
    @State private var ring2Scale: CGFloat = 1.0
    @State private var ring3Scale: CGFloat = 1.0
    @State private var blip1Opacity: Double = 0.3
    @State private var blip2Opacity: Double = 0.2
    @State private var blip3Opacity: Double = 0.3
    @State private var blip4Opacity: Double = 0.2
    @State private var logoGlow: CGFloat = 0.3
    @State private var particle1Offset: CGFloat = 0
    @State private var particle2Offset: CGFloat = 0
    @State private var loaderRotation: Double = 0
    @State private var showContent = false

    private let darkBg = Color(hex: "0B1120")
    private let tealAccent = Color(hex: "2DD4A8")
    private let tealDark = Color(hex: "0D9488")
    private let tealDarker = Color(hex: "0D7C6E")

    var body: some View {
        ZStack {
            // Background
            darkBg.ignoresSafeArea()

            // Animated grid
            gridPattern

            // Radar glow
            radarGlow

            // Radar rings
            radarRings

            // Rotating sweep line
            radarSweep

            // Blipping dots
            blippingDots

            // Floating particles
            floatingParticles

            // Main content
            mainContent
        }
        .onAppear {
            startAnimations()
            // Transition after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isActive = true
                }
            }
        }
    }

    // MARK: - Grid Pattern

    private var gridPattern: some View {
        Canvas { context, size in
            let gridSize: CGFloat = 40
            let lineColor = tealAccent.opacity(0.03)

            // Vertical lines
            for x in stride(from: 0, to: size.width, by: gridSize) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(lineColor), lineWidth: 1)
            }

            // Horizontal lines
            for y in stride(from: 0, to: size.height, by: gridSize) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(lineColor), lineWidth: 1)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Radar Glow

    private var radarGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        tealDark.opacity(0.12),
                        tealDark.opacity(0.04),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 180
                )
            )
            .frame(width: 360, height: 360)
            .offset(y: -40)
    }

    // MARK: - Radar Rings

    private var radarRings: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(tealAccent.opacity(0.08), lineWidth: 1)
                .frame(width: 300, height: 300)
                .scaleEffect(ring1Scale)

            // Middle ring
            Circle()
                .stroke(tealAccent.opacity(0.12), lineWidth: 1)
                .frame(width: 220, height: 220)
                .scaleEffect(ring2Scale)

            // Inner ring
            Circle()
                .stroke(tealAccent.opacity(0.18), lineWidth: 1)
                .frame(width: 140, height: 140)
                .scaleEffect(ring3Scale)
        }
        .offset(y: -40)
    }

    // MARK: - Radar Sweep

    private var radarSweep: some View {
        ZStack {
            // Sweep line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [tealAccent.opacity(0.6), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 75, height: 2)
                .offset(x: 37.5)

            // Sweep trail (cone)
            SweepTrail()
                .fill(tealAccent.opacity(0.08))
                .frame(width: 75, height: 60)
                .offset(x: 37.5, y: -30)
        }
        .rotationEffect(.degrees(radarAngle))
        .offset(y: -40)
    }

    // MARK: - Blipping Dots

    private var blippingDots: some View {
        ZStack {
            // Dot 1 - top left
            Circle()
                .fill(tealAccent)
                .frame(width: 8, height: 8)
                .shadow(color: tealAccent.opacity(blip1Opacity * 2), radius: blip1Opacity > 0.5 ? 12 : 4)
                .opacity(blip1Opacity)
                .offset(x: -60, y: -120)

            // Dot 2 - top right
            Circle()
                .fill(tealAccent)
                .frame(width: 6, height: 6)
                .shadow(color: tealAccent.opacity(blip2Opacity * 2), radius: blip2Opacity > 0.5 ? 10 : 3)
                .opacity(blip2Opacity)
                .offset(x: 80, y: -80)

            // Dot 3 - left
            Circle()
                .fill(Color(hex: "10B981"))
                .frame(width: 5, height: 5)
                .shadow(color: tealAccent.opacity(blip3Opacity * 2), radius: blip3Opacity > 0.5 ? 8 : 4)
                .opacity(blip3Opacity)
                .offset(x: -90, y: 0)

            // Dot 4 - right
            Circle()
                .fill(tealAccent)
                .frame(width: 7, height: 7)
                .shadow(color: tealAccent.opacity(blip4Opacity * 2), radius: blip4Opacity > 0.5 ? 10 : 3)
                .opacity(blip4Opacity)
                .offset(x: 100, y: -20)
        }
        .offset(y: -40)
    }

    // MARK: - Floating Particles

    private var floatingParticles: some View {
        ZStack {
            Circle()
                .fill(tealAccent.opacity(0.3))
                .frame(width: 3, height: 3)
                .offset(x: -140, y: -250 + particle1Offset)

            Circle()
                .fill(tealAccent.opacity(0.25))
                .frame(width: 2, height: 2)
                .offset(x: 130, y: 150 - particle2Offset)

            Circle()
                .fill(tealDark.opacity(0.3))
                .frame(width: 2, height: 2)
                .offset(x: -100, y: 200 + particle1Offset * 0.5)

            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 3, height: 3)
                .offset(x: 110, y: -220 - particle2Offset * 0.7)
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            logoView
                .padding(.bottom, 24)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 15)

            // App name
            Text("RentDar")
                .font(.system(size: 34, weight: .heavy))
                .foregroundStyle(.white)
                .tracking(-0.5)
                .padding(.bottom, 6)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 15)

            // Tagline with accents
            HStack(spacing: 12) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, tealAccent.opacity(0.5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 24, height: 1)

                Text("See what others miss")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .tracking(1)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [tealAccent.opacity(0.5), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 24, height: 1)
            }
            .padding(.bottom, 56)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 15)

            // Spinning loader
            spinningLoader
                .padding(.bottom, 48)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 15)

            Spacer()

            // Bottom text
            Text("Track · Optimize · Earn")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.25))
                .tracking(2.5)
                .textCase(.uppercase)
                .padding(.bottom, 52)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 15)
        }
    }

    // MARK: - Logo View

    private var logoView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [tealDarker, tealDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(tealAccent.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: tealDark.opacity(logoGlow), radius: 40)
                .shadow(color: tealDark.opacity(logoGlow * 0.5), radius: 80)

            // House + radar icon
            Image(systemName: "house.fill")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(.white.opacity(0.95))
                .overlay(alignment: .topTrailing) {
                    // Radar signal
                    ZStack {
                        // Signal arcs
                        Arc(startAngle: .degrees(-60), endAngle: .degrees(30))
                            .stroke(tealAccent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .frame(width: 20, height: 20)

                        Arc(startAngle: .degrees(-50), endAngle: .degrees(20))
                            .stroke(tealAccent.opacity(0.5), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                            .frame(width: 28, height: 28)

                        // Signal dot
                        Circle()
                            .fill(tealAccent)
                            .frame(width: 5, height: 5)
                            .offset(x: 2, y: -8)
                    }
                    .offset(x: 14, y: -10)
                }
        }
    }

    // MARK: - Spinning Loader

    private var spinningLoader: some View {
        ZStack {
            Circle()
                .stroke(tealAccent.opacity(0.1), lineWidth: 2)
                .frame(width: 30, height: 30)

            Circle()
                .trim(from: 0, to: 0.25)
                .stroke(tealAccent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 30, height: 30)
                .rotationEffect(.degrees(loaderRotation))
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Show content with fade in
        withAnimation(.easeOut(duration: 0.8)) {
            showContent = true
        }

        // Radar sweep rotation
        withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
            radarAngle = 360
        }

        // Ring pulsing
        withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
            ring1Scale = 1.03
        }
        withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true).delay(0.5)) {
            ring2Scale = 1.02
        }
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true).delay(1)) {
            ring3Scale = 1.01
        }

        // Blip animations
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            blip1Opacity = 1.0
        }
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(0.8)) {
            blip2Opacity = 0.8
        }
        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(1.5)) {
            blip3Opacity = 1.0
        }
        withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true).delay(0.4)) {
            blip4Opacity = 0.8
        }

        // Logo glow breathing
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            logoGlow = 0.45
        }

        // Particle floating
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
            particle1Offset = -15
        }
        withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true).delay(1)) {
            particle2Offset = 12
        }

        // Loader rotation
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            loaderRotation = 360
        }
    }
}

// MARK: - Sweep Trail Shape

private struct SweepTrail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Arc Shape

private struct Arc: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

#Preview {
    SplashScreenView()
}
