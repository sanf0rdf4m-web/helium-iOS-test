import SwiftUI

@main
struct HeliumApp: App {
    @StateObject private var browser = BrowserStore()

    var body: some Scene {
        WindowGroup {
            BrowserRootView()
                .environmentObject(browser)
                .tint(HeliumTheme.accent)
                .preferredColorScheme(.dark)
        }
    }
}
