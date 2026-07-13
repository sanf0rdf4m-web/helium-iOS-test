import SwiftUI
import HeliumCore

struct SettingsView: View {
    @EnvironmentObject private var browser: BrowserStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingClearConfirmation = false
    @State private var isClearing = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Search") {
                    Picker("Search engine", selection: preferenceBinding(\.searchEngine)) {
                        ForEach(SearchEngine.allCases) { engine in
                            Text(engine.displayName).tag(engine)
                        }
                    }
                }

                Section("Shields defaults") {
                    Picker("Protection level", selection: privacyBinding(\.shieldLevel)) {
                        ForEach(ShieldLevel.allCases) { level in
                            Text(level.title).tag(level)
                        }
                    }
                    Toggle("Block ads", isOn: privacyBinding(\.blockAds))
                    Toggle("Block trackers", isOn: privacyBinding(\.blockTrackers))
                    Toggle("Block third-party cookies", isOn: privacyBinding(\.blockThirdPartyCookies))
                    Toggle("Fingerprint protection", isOn: privacyBinding(\.blockFingerprinting))
                    Toggle("HTTPS upgrades", isOn: privacyBinding(\.upgradeConnections))
                }

                Section("Data") {
                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        HStack {
                            Text("Clear Browsing Data")
                            Spacer()
                            if isClearing { ProgressView() }
                        }
                    }
                    .disabled(isClearing)
                }

                Section {
                    LabeledContent("Engine", value: "Apple WebKit")
                    LabeledContent("Version", value: "0.1.0")
                    Link("Official Helium project", destination: URL(string: "https://helium.computer")!)
                } header: {
                    Text("About")
                } footer: {
                    Text("Unofficial community port. Not affiliated with or endorsed by imput LLC. No analytics or first-party advertising.")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Clear history, cookies, caches, and website storage?",
                isPresented: $showingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear Browsing Data", role: .destructive) {
                    isClearing = true
                    Task {
                        browser.clearHistory()
                        await browser.clearWebsiteData()
                        isClearing = false
                    }
                }
            }
        }
    }

    private func preferenceBinding<Value>(_ keyPath: WritableKeyPath<BrowserPreferences, Value>) -> Binding<Value> {
        Binding(
            get: { browser.preferences[keyPath: keyPath] },
            set: { value in
                var preferences = browser.preferences
                preferences[keyPath: keyPath] = value
                browser.preferences = preferences
            }
        )
    }

    private func privacyBinding<Value>(_ keyPath: WritableKeyPath<PrivacySettings, Value>) -> Binding<Value> {
        Binding(
            get: { browser.preferences.privacy[keyPath: keyPath] },
            set: { value in
                var preferences = browser.preferences
                preferences.privacy[keyPath: keyPath] = value
                browser.preferences = preferences
            }
        )
    }
}
