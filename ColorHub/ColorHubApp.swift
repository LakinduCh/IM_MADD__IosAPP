import SwiftUI
import SwiftData

@main
struct ColorHubApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                CaptureView()
                    .tabItem { Label("Capture", systemImage: "camera.viewfinder") }
                LibraryView()
                    .tabItem { Label("Library", systemImage: "square.grid.2x2") }
            }
            .tint(AppTheme.accent)
        }
        // Creates the on-device SwiftData store for saved palettes.
        .modelContainer(for: SavedPalette.self)
    }
}