import SwiftUI
import HeliumCore

struct ShieldsPanel: View {
    @EnvironmentObject private var browser: BrowserStore
    @ObservedObject var tab: BrowserTab

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: shieldsEnabled ? "shield.fill" : "shield.slash")
                            .font(.system(size: 30))
                            .foregroundStyle(shieldsEnabled ? Color.red : .secondary)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(shieldsEnabled ? "Shields are up" : "Shields are down")
                                .font(.headline)
                            Text(host)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Toggle("", isOn: siteShieldBinding)
                            .labelsHidden()
                            .disabled(tab.url?.host == nil)
                    }
                }

                Section("Protection level") {
                    Picker("Blocking", selection: privacyBinding(\.shieldLevel)) {
                        ForEach(ShieldLevel.allCases) { level in
                            Text(level.title).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Protections") {
                    Toggle("Block ads", isOn: privacyBinding(\.blockAds))
                    Toggle("Block trackers", isOn: privacyBinding(\.blockTrackers))
                    Toggle("Block third-party cookies", isOn: privacyBinding(\.blockThirdPartyCookies))
                    Toggle("Fingerprint protection", isOn: privacyBinding(\.blockFingerprinting))
                    Toggle("Upgrade connections to HTTPS", isOn: privacyBinding(\.upgradeConnections))
                    Toggle("Block all scripts", isOn: privacyBinding(\.blockScripts))
                        .tint(.orange)
                }

                Section {
                    LabeledContent("Global Privacy Control") {
                        Toggle("", isOn: privacyBinding(\.sendGlobalPrivacyControl)).labelsHidden()
                    }
                    LabeledContent("Do Not Track") {
                        Toggle("", isOn: privacyBinding(\.sendDoNotTrack)).labelsHidden()
                    }
                } footer: {
                    Text("Network rules are compiled and applied locally by WebKit. Script blocking can break sites.")
                }

                if let error = browser.privacyError {
                    Section("Rule-list error") {
                        Text(error).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Shields")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var shieldsEnabled: Bool { browser.shieldsAreEnabled(for: tab.url) }
    private var host: String { tab.url?.host(percentEncoded: false) ?? "This site" }

    private var siteShieldBinding: Binding<Bool> {
        Binding(
            get: { shieldsEnabled },
            set: { _ in browser.toggleShields(for: tab) }
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

extension ShieldLevel {
    var title: String {
        switch self {
        case .off: "Off"
        case .standard: "Standard"
        case .aggressive: "Aggressive"
        }
    }
}
