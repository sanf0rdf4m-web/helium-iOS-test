import SwiftUI

@main
struct HeliumApp: App {
    @StateObject private var browser = BrowserStore()

    var body: some Scene {
        WindowGroup {
            BrowserRootView()
                .environmentObject(browser)
                .tint(Color(red: 0.20, green: 0.31, blue: 0.82))
        }
    }
}
