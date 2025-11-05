import SwiftUI
import SwiftData

@main
struct RiftboundApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .modelContainer(for: [
                    CachedCard.self,
                    CachedDeck.self,
                    CachedDeckItem.self
                ])
                .task {
                    await appState.initialize()
                }
        }
    }
}
