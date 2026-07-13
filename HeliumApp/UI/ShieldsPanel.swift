import SwiftUI
import HeliumCore

struct ShieldsPanel: View {
    @EnvironmentObject private var browser: BrowserStore
    @ObservedObject var tab: BrowserTab
    @State private var isShowingMore = false

    private let panelWidth: CGFloat = 266

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                panel
                    .frame(width: min(panelWidth, max(240, proxy.size.width - 24)))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(HeliumTheme.window)
        }
        .foregroundStyle(HeliumTheme.primaryText)
        .background(HeliumTheme.window.ignoresSafeArea())
        .presentationBackground(HeliumTheme.window)
        .preferredColorScheme(.dark)
    }

    private var panel: some View {
        VStack(spacing: 0) {
            hostHeader
            powerControl
            statistics
            actionRow

            if isShowingMore {
                expandedProtections
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            moreLessFooter
        }
        .background(HeliumTheme.window)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(HeliumTheme.border, lineWidth: 1)
        }
    }

    private var hostHeader: some View {
        Text(host)
            .font(.system(size: 13, weight: .semibold))
            .lineLimit(1)
            .truncationMode(.middle)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .padding(.horizontal, 12)
            .background(HeliumTheme.border)
            .accessibilityLabel("Shields for \(host)")
    }

    private var powerControl: some View {
        Button {
            siteShieldBinding.wrappedValue.toggle()
        } label: {
            Image(systemName: "power")
                .font(.system(size: 88, weight: .medium))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(shieldsEnabled ? HeliumTheme.shieldAccent : HeliumTheme.tertiaryText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(height: 128)
        .background(HeliumTheme.window)
        .accessibilityLabel(shieldsEnabled ? "Turn shields off for this site" : "Turn shields on for this site")
        .accessibilityValue(shieldsEnabled ? "On" : "Off")
        .overlay(alignment: .bottom) { sectionDivider }
    }

    private var statistics: some View {
        VStack(spacing: 12) {
            metric(title: "Blocked on this page", value: "0")
            metric(title: "Domains connected", value: "0 out of 0")
            metric(title: "Blocked since install", value: "0")
        }
        .padding(.vertical, 12)
        .frame(height: 156)
        .frame(maxWidth: .infinity)
        .background(HeliumTheme.window)
        .accessibilityElement(children: .combine)
        .overlay(alignment: .bottom) { sectionDivider }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(spacing: 0) {
            Text(title)
            Text(value)
        }
        .font(.system(size: 15, weight: .regular))
        .lineLimit(1)
    }

    private var actionRow: some View {
        HStack(spacing: 20) {
            Spacer(minLength: 0)

            Button {
                showMore()
            } label: {
                Image(systemName: "list.bullet.rectangle")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Show protection details")

            Button {
                showMore()
            } label: {
                Image(systemName: "gearshape.2.fill")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Show shield settings")
        }
        .font(.system(size: 20, weight: .medium))
        .buttonStyle(.plain)
        .foregroundStyle(HeliumTheme.primaryText)
        .padding(.horizontal, 9)
        .frame(height: 44)
        .background(HeliumTheme.border)
        .overlay(alignment: .bottom) { sectionDivider }
    }

    private var expandedProtections: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Protection level")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HeliumTheme.secondaryText)

                Picker("Protection level", selection: privacyBinding(\.shieldLevel)) {
                    ForEach(ShieldLevel.allCases) { level in
                        Text(level.title).tag(level)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }
            .padding(12)

            sectionDivider

            VStack(spacing: 0) {
                protectionToggle("Block ads", keyPath: \.blockAds)
                protectionToggle("Block trackers", keyPath: \.blockTrackers)
                protectionToggle("Block third-party cookies", keyPath: \.blockThirdPartyCookies)
                protectionToggle("Fingerprint protection", keyPath: \.blockFingerprinting)
                protectionToggle("Upgrade connections to HTTPS", keyPath: \.upgradeConnections)
                protectionToggle("Block all scripts", keyPath: \.blockScripts, tint: .orange)
                protectionToggle("Global Privacy Control", keyPath: \.sendGlobalPrivacyControl)
                protectionToggle("Do Not Track", keyPath: \.sendDoNotTrack, showsDivider: false)
            }

            if let error = browser.privacyError {
                sectionDivider
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.red.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }

            sectionDivider
        }
        .background(HeliumTheme.raised)
    }

    private func protectionToggle(
        _ title: String,
        keyPath: WritableKeyPath<PrivacySettings, Bool>,
        tint: Color = HeliumTheme.shieldAccent,
        showsDivider: Bool = true
    ) -> some View {
        Toggle(title, isOn: privacyBinding(keyPath))
            .font(.system(size: 12))
            .tint(tint)
            .controlSize(.mini)
            .frame(minHeight: 36)
            .padding(.horizontal, 12)
            .overlay(alignment: .bottom) {
                if showsDivider {
                    sectionDivider
                        .padding(.leading, 12)
                }
            }
    }

    private var moreLessFooter: some View {
        HStack {
            Button {
                showMore()
            } label: {
                HStack(spacing: 8) {
                    Text("More")
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                }
                .frame(minWidth: 74, minHeight: 44, alignment: .leading)
            }

            Spacer(minLength: 0)

            Button {
                hideMore()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 11, weight: .bold))
                    Text("Less")
                }
                .frame(minWidth: 74, minHeight: 44, alignment: .trailing)
            }
        }
        .font(.system(size: 15, weight: .semibold))
        .buttonStyle(.plain)
        .foregroundStyle(HeliumTheme.primaryText)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(HeliumTheme.window)
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(HeliumTheme.border.opacity(0.9))
            .frame(height: 1)
            .accessibilityHidden(true)
    }

    private func showMore() {
        withAnimation(.easeInOut(duration: 0.18)) {
            isShowingMore = true
        }
    }

    private func hideMore() {
        withAnimation(.easeInOut(duration: 0.18)) {
            isShowingMore = false
        }
    }

    private var shieldsEnabled: Bool { browser.shieldsAreEnabled(for: tab.url) }

    private var host: String {
        tab.url?.host(percentEncoded: false) ?? "newtab.chrome-scheme"
    }

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
