import SwiftUI

struct SignUpSuccessView: View {
    let firstName: String
    var onAddProperty: () -> Void
    var onExplore: () -> Void

    @State private var showContent = false
    @State private var confettiParticles: [ConfettiParticle] = []

    private let confettiColors: [Color] = [
        Color(hex: "FCD34D"), Color(hex: "F87171"), Color(hex: "60A5FA"),
        Color(hex: "34D399"), Color(hex: "A78BFA"), Color(hex: "FB923C"),
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "0D9488"), Color(hex: "0F766E")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Confetti
            ForEach(confettiParticles) { particle in
                RoundedRectangle(cornerRadius: 2)
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .rotationEffect(.degrees(particle.rotation))
                    .position(particle.position)
                    .opacity(particle.opacity)
            }

            // Content
            VStack(spacing: 0) {
                Spacer().frame(height: 80)

                // Success icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 120, height: 120)

                    Circle()
                        .fill(.white)
                        .frame(width: 90, height: 90)
                        .overlay(
                            Text("\u{1F389}")
                                .font(.system(size: 48))
                        )
                }
                .scaleEffect(showContent ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showContent)
                .padding(.bottom, 32)

                // Title
                Text("Welcome aboard!")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(.white)
                    .offset(y: showContent ? 0 : 20)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: showContent)
                    .padding(.bottom, 12)

                // Subtitle
                Group {
                    Text("You\u{2019}re all set, ")
                        .foregroundStyle(.white.opacity(0.9))
                    +
                    Text(firstName.isEmpty ? "there" : firstName)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    +
                    Text("!\nLet\u{2019}s start managing your properties.")
                        .foregroundStyle(.white.opacity(0.9))
                }
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .offset(y: showContent ? 0 : 20)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: showContent)
                .padding(.bottom, 40)

                // Feature cards
                VStack(spacing: 12) {
                    FeatureCard(
                        emoji: "\u{1F3E0}",
                        title: "Add your first property",
                        subtitle: "Set up your rental in minutes"
                    )
                    FeatureCard(
                        emoji: "\u{1F4C5}",
                        title: "Connect your calendar",
                        subtitle: "Sync with Airbnb, VRBO & more"
                    )
                    FeatureCard(
                        emoji: "\u{1F4B3}",
                        title: "Track your income",
                        subtitle: "See all earnings in one place"
                    )
                }
                .offset(y: showContent ? 0 : 30)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: showContent)

                Spacer()

                // Add Property button
                Button(action: onAddProperty) {
                    Text("Add Your First Property")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: "0D9488"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                }
                .buttonStyle(PressableButtonStyle())
                .offset(y: showContent ? 0 : 20)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.5), value: showContent)

                // Explore link
                Button(action: onExplore) {
                    Text("Explore the app first \u{2192}")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.top, 16)
                .offset(y: showContent ? 0 : 20)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.6), value: showContent)

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            showContent = true
            spawnConfetti()
        }
    }

    private func spawnConfetti() {
        let screenWidth: CGFloat = 390
        let screenHeight: CGFloat = 844
        for i in 0..<30 {
            let particle = ConfettiParticle(
                id: i,
                color: confettiColors[i % confettiColors.count],
                size: CGFloat.random(in: 6...12),
                position: CGPoint(
                    x: CGFloat.random(in: 0...screenWidth),
                    y: CGFloat.random(in: -50...0)
                ),
                rotation: Double.random(in: 0...360),
                opacity: 1
            )
            confettiParticles.append(particle)
        }

        // Animate particles falling
        for i in confettiParticles.indices {
            let delay = Double(i) * 0.05
            let duration = Double.random(in: 2.5...4.0)
            withAnimation(.easeIn(duration: duration).delay(delay).repeatForever(autoreverses: false)) {
                confettiParticles[i].position.y = screenHeight + 50
                confettiParticles[i].rotation += 720
                confettiParticles[i].opacity = 0
            }
        }
    }
}

// MARK: - Confetti Particle

private struct ConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var rotation: Double
    var opacity: Double
}

// MARK: - Feature Card

private struct FeatureCard: View {
    let emoji: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Text("\u{203A}")
                .font(.system(size: 20))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
