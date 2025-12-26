import SwiftUI

struct GradientSplashScreenView: View {
    @State private var ring1Scale: CGFloat = 1.0
    @State private var ring1Opacity: Double = 0.06
    @State private var ring2Scale: CGFloat = 1.0
    @State private var ring2Opacity: Double = 0.08
    @State private var ring3Scale: CGFloat = 1.0
    @State private var ring3Opacity: Double = 0.10
    @State private var dot1Offset: CGFloat = 0
    @State private var dot1Opacity: Double = 0.5
    @State private var dot2Offset: CGFloat = 0
    @State private var dot2Opacity: Double = 0.3
    @State private var dot3Opacity: Double = 0.35
    @State private var dot4Offset: CGFloat = 0
    @State private var dot5Offset: CGFloat = 0
    @State private var logoGlow: Bool = false
    @State private var loadingProgress: CGFloat = 0
    @State private var showContent = false

    private let tealDark = Color(hex: "0A3D3D")
    private let tealMid = Color(hex: "0D7C6E")
    private let tealLight = Color(hex: "10B981")
    private let tealAccent = Color(hex: "2DD4A8")

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [tealDark, tealMid, tealLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Radar rings
            radarRings

            // Floating blips
            floatingBlips

            // Main content
            mainContent
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Radar Rings

    private var radarRings: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(.white.opacity(ring1Opacity), lineWidth: 1)
                .frame(width: 320, height: 320)
                .scaleEffect(ring1Scale)

            // Middle ring
            Circle()
                .stroke(.white.opacity(ring2Opacity), lineWidth: 1)
                .frame(width: 220, height: 220)
                .scaleEffect(ring2Scale)

            // Inner ring
            Circle()
                .stroke(.white.opacity(ring3Opacity), lineWidth: 1)
                .frame(width: 130, height: 130)
                .scaleEffect(ring3Scale)
        }
        .offset(y: -40)
    }

    // MARK: - Floating Blips

    private var floatingBlips: some View {
        ZStack {
            // Blip 1 - top left, teal
            Circle()
                .fill(tealAccent.opacity(0.5))
                .frame(width: 8, height: 8)
                .opacity(dot1Opacity)
                .offset(x: -110, y: -180 + dot1Offset)

            // Blip 2 - top right, white
            Circle()
                .fill(.white.opacity(0.3))
                .frame(width: 6, height: 6)
                .opacity(dot2Opacity)
                .offset(x: 100, y: -120 + dot2Offset)

            // Blip 3 - left, white (blinking)
            Circle()
                .fill(.white.opacity(0.25))
                .frame(width: 5, height: 5)
                .opacity(dot3Opacity)
                .offset(x: -130, y: -20)

            // Blip 4 - right, teal larger
            Circle()
                .fill(tealAccent.opacity(0.35))
                .frame(width: 10, height: 10)
                .offset(x: 125, y: -60 + dot4Offset)

            // Blip 5 - bottom left, white
            Circle()
                .fill(.white.opacity(0.2))
                .frame(width: 7, height: 7)
                .offset(x: -85, y: 50 + dot5Offset)
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo with glassmorphism
            logoView
                .padding(.bottom, 28)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

            // App name
            Text("RentDar")
                .font(.system(size: 36, weight: .heavy))
                .foregroundStyle(.white)
                .tracking(-0.5)
                .padding(.bottom, 8)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

            // Tagline
            Text("Every detail. Every dollar.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .tracking(0.5)
                .padding(.bottom, 60)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

            // Loading bar
            loadingBar
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

            Spacer()

            // Bottom text
            Text("Your rental radar, always on")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(2)
                .textCase(.uppercase)
                .padding(.bottom, 52)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
        }
    }

    // MARK: - Logo View

    private var logoView: some View {
        ZStack {
            // Glassmorphism container
            RoundedRectangle(cornerRadius: 24)
                .fill(.white.opacity(0.15))
                .frame(width: 88, height: 88)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .opacity(0.3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 32, y: 8)
                .shadow(color: logoGlow ? tealAccent.opacity(0.15) : .clear, radius: 40)

            // House + radar icon
            Image(systemName: "house.fill")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(.white.opacity(0.95))
                .overlay(alignment: .topTrailing) {
                    // Radar signal
                    ZStack {
                        // Signal arcs
                        Arc(startAngle: .degrees(-60), endAngle: .degrees(30))
                            .stroke(tealAccent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .frame(width: 22, height: 22)

                        Arc(startAngle: .degrees(-50), endAngle: .degrees(20))
                            .stroke(tealAccent.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .frame(width: 30, height: 30)

                        // Signal dot
                        Circle()
                            .fill(tealAccent)
                            .frame(width: 6, height: 6)
                            .offset(x: 2, y: -9)
                    }
                    .offset(x: 16, y: -12)
                }
        }
    }

    // MARK: - Loading Bar

    private var loadingBar: some View {
        ZStack(alignment: .leading) {
            // Track
            RoundedRectangle(cornerRadius: 2)
                .fill(.white.opacity(0.15))
                .frame(width: 160, height: 3)

            // Progress
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [tealAccent, .white],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 160 * loadingProgress, height: 3)
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Fade in content
        withAnimation(.easeOut(duration: 1)) {
            showContent = true
        }

        // Ring 1 pulse
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            ring1Scale = 1.08
            ring1Opacity = 0.12
        }

        // Ring 2 pulse (delayed)
        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(0.3)) {
            ring2Scale = 1.06
            ring2Opacity = 0.14
        }

        // Ring 3 pulse (more delayed)
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(0.6)) {
            ring3Scale = 1.04
            ring3Opacity = 0.16
        }

        // Dot 1 float
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            dot1Offset = -8
            dot1Opacity = 1.0
        }

        // Dot 2 float
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true).delay(0.5)) {
            dot2Offset = -6
            dot2Opacity = 0.7
        }

        // Dot 3 blink
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(1)) {
            dot3Opacity = 0.8
        }

        // Dot 4 float
        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(0.8)) {
            dot4Offset = -8
        }

        // Dot 5 float
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(1.2)) {
            dot5Offset = -6
        }

        // Logo glow
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            logoGlow = true
        }

        // Loading progress
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: false)) {
            loadingProgress = 0.85
        }
    }
}

// MARK: - Arc Shape (reuse if not already defined)

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
    GradientSplashScreenView()
}
