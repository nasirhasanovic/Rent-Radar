import SwiftUI
import CoreData

@main
struct RentDarApp: App {
    let persistenceController = PersistenceController.shared
    private var settings = AppSettings.shared
    @State private var showSplash = true
    @State private var splashVariant: Int = Int.random(in: 0...1)

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)

                if showSplash {
                    Group {
                        if splashVariant == 0 {
                            SplashScreenView()
                        } else {
                            GradientSplashScreenView()
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .environment(\.locale, settings.locale)
            .id(settings.refreshID) // Force rebuild when language changes
            .onAppear {
                // Dismiss splash after 2.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}
