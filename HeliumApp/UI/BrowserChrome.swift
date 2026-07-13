import SwiftUI

struct BrowserChrome: View {
    @EnvironmentObject private var browser: BrowserStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var tab: BrowserTab
    @Binding var isShowingSettings: Bool
    @Binding var sheet: BrowserSheet?

    @State private var isShowingMenu = false
    @State private var isShowingExtensions = false
    @State private var isShowingProfile = false

    private var isWide: Bool { horizontalSizeClass == .regular }

    var body: some View {
        HStack(spacing: 3) {
            navigationButtons

            AddressField(
                tab: tab,
                displayOverride: isShowingSettings ? "helium://settings" : nil,
                onNavigate: { isShowingSettings = false }
            )
            .environmentObject(browser)
            .frame(maxWidth: .infinity)

            trailingControls
        }
        .padding(.horizontal, 4)
        .frame(height: 38)
        .buttonStyle(.plain)
        .foregroundStyle(HeliumTheme.primaryText)
        .background(HeliumTheme.toolbar)
    }

    private var navigationButtons: some View {
        HStack(spacing: 0) {
            Button {
                if isShowingSettings {
                    isShowingSettings = false
                } else {
                    tab.goBack()
                }
            } label: {
                chromeIcon("chevron.left")
            }
            .disabled(!isShowingSettings && !tab.canGoBack)
            .accessibilityLabel("Back")

            Button(action: tab.goForward) {
                chromeIcon("chevron.right")
            }
            .disabled(isShowingSettings || !tab.canGoForward)
            .accessibilityLabel("Forward")

            Button {
                if isShowingSettings { return }
                tab.reloadOrStop()
            } label: {
                chromeIcon(tab.isLoading ? "xmark" : "arrow.clockwise")
            }
            .disabled(isShowingSettings)
            .accessibilityLabel(tab.isLoading ? "Stop" : "Reload")
        }
    }

    private var trailingControls: some View {
        HStack(spacing: 0) {
            Button {
                sheet = .shields
            } label: {
                Image(systemName: browser.shieldsAreEnabled(for: tab.url) ? "shield.fill" : "shield.slash.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(HeliumTheme.shield)
                    .frame(width: 30, height: 32)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Privacy shields")

            if isWide {
                Button {
                    isShowingExtensions.toggle()
                } label: {
                    chromeIcon("puzzlepiece.extension")
                }
                .accessibilityLabel("Extensions")
                .popover(isPresented: $isShowingExtensions, arrowEdge: .top) {
                    compactInfoPopover(
                        icon: "puzzlepiece.extension",
                        title: "Extensions",
                        detail: "Helium Shields is built into this iOS port."
                    )
                    .presentationCompactAdaptation(.popover)
                }

                Button {
                    isShowingProfile.toggle()
                } label: {
                    chromeIcon("person.circle")
                }
                .accessibilityLabel("Profile")
                .popover(isPresented: $isShowingProfile, arrowEdge: .top) {
                    compactInfoPopover(
                        icon: "person.circle.fill",
                        title: "You",
                        detail: "Bookmarks and preferences stay on this device."
                    )
                    .presentationCompactAdaptation(.popover)
                }
            }

            Button {
                isShowingMenu.toggle()
            } label: {
                chromeIcon("ellipsis", rotation: 90)
            }
            .accessibilityLabel("Helium menu")
            .popover(isPresented: $isShowingMenu, arrowEdge: .top) {
                browserMenu
                    .presentationCompactAdaptation(.popover)
            }
        }
    }

    private var browserMenu: some View {
        VStack(spacing: 2) {
            menuButton("New Tab", icon: "plus", shortcut: "⌘T") {
                browser.newTab()
                isShowingSettings = false
            }
            menuButton("New Private Tab", icon: "hand.raised", shortcut: "⇧⌘N") {
                browser.newTab(isPrivate: true)
                isShowingSettings = false
            }
            menuDivider
            menuButton("History and Bookmarks", icon: "clock.arrow.circlepath") {
                sheet = .library
            }
            menuButton("Extensions", icon: "puzzlepiece.extension") {
                isShowingExtensions = true
            }
            menuButton("Reload", icon: tab.isLoading ? "xmark" : "arrow.clockwise") {
                tab.reloadOrStop()
            }
            if let url = tab.url {
                ShareLink(item: url) {
                    BrowserMenuRow(title: "Share", icon: "square.and.arrow.up")
                }
                .buttonStyle(.plain)
                menuButton(
                    browser.isBookmarked(url) ? "Remove Bookmark" : "Add Bookmark",
                    icon: browser.isBookmarked(url) ? "star.slash" : "star"
                ) {
                    browser.toggleBookmark(for: tab)
                }
            }
            if isWide {
                menuButton("Toggle Split View", icon: "rectangle.split.2x1") {
                    browser.toggleSplitView()
                }
            }
            menuDivider
            menuButton("Settings", icon: "gearshape", shortcut: "⌘,") {
                isShowingSettings = true
            }
        }
        .padding(6)
        .frame(width: 286)
        .background(HeliumTheme.raised)
        .environment(\.colorScheme, .dark)
    }

    private func menuButton(
        _ title: String,
        icon: String,
        shortcut: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            isShowingMenu = false
            action()
        } label: {
            BrowserMenuRow(title: title, icon: icon, shortcut: shortcut)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var menuDivider: some View {
        Rectangle()
            .fill(HeliumTheme.border)
            .frame(height: 1)
            .padding(.vertical, 4)
    }

    private func compactInfoPopover(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(HeliumTheme.primaryText)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(HeliumTheme.secondaryText)
            }
        }
        .padding(16)
        .frame(width: 270, alignment: .leading)
        .background(HeliumTheme.raised)
        .environment(\.colorScheme, .dark)
    }

    private func chromeIcon(_ systemName: String, rotation: Double = 0) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 13, weight: .medium))
            .rotationEffect(.degrees(rotation))
            .foregroundStyle(HeliumTheme.secondaryText)
            .frame(width: 29, height: 32)
            .contentShape(Rectangle())
    }
}

private struct BrowserMenuRow: View {
    let title: String
    let icon: String
    var shortcut: String? = nil

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 18)
            Text(title)
                .font(.system(size: 13))
            Spacer()
            if let shortcut {
                Text(shortcut)
                    .font(.system(size: 12))
                    .foregroundStyle(HeliumTheme.tertiaryText)
            }
        }
        .foregroundStyle(HeliumTheme.primaryText)
        .padding(.horizontal, 9)
        .frame(height: 31)
        .contentShape(Rectangle())
    }
}

private struct AddressField: View {
    @EnvironmentObject private var browser: BrowserStore
    @ObservedObject var tab: BrowserTab
    let displayOverride: String?
    let onNavigate: () -> Void

    @FocusState private var isFocused: Bool
    @State private var text = ""

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: tab.url == nil && displayOverride == nil ? "magnifyingglass" : "globe")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(HeliumTheme.secondaryText)
                .frame(width: 17, height: 17)
                .accessibilityHidden(true)

            TextField("Search Google or type a URL", text: $text)
                .font(.system(size: 13))
                .foregroundStyle(HeliumTheme.primaryText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.webSearch)
                .submitLabel(.go)
                .focused($isFocused)
                .onSubmit {
                    onNavigate()
                    browser.navigate(text, in: tab)
                    isFocused = false
                }
                .onChange(of: isFocused) { _, focused in
                    text = focused ? editableText : displayText
                }
                .onChange(of: tab.url) { _, _ in
                    if !isFocused { text = displayText }
                }
                .onChange(of: displayOverride) { _, _ in
                    if !isFocused { text = displayText }
                }

            if isFocused, !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(HeliumTheme.tertiaryText)
                        .frame(width: 18, height: 18)
                }
                .accessibilityLabel("Clear address")
            } else if displayOverride == nil {
                Button {
                    browser.toggleBookmark(for: tab)
                } label: {
                    Image(systemName: isBookmarked ? "star.fill" : "star")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(isBookmarked ? Color.yellow : HeliumTheme.secondaryText)
                        .frame(width: 18, height: 18)
                }
                .disabled(tab.url == nil)
                .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Add bookmark")
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 29)
        .background(HeliumTheme.field, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(isFocused ? HeliumTheme.focus : HeliumTheme.border, lineWidth: isFocused ? 1.5 : 1)
        }
        .onAppear { text = displayText }
    }

    private var displayText: String {
        if let displayOverride { return displayOverride }
        guard let url = tab.url else { return "" }
        return url.host(percentEncoded: false) ?? url.absoluteString
    }

    private var editableText: String {
        displayOverride ?? tab.url?.absoluteString ?? ""
    }

    private var isBookmarked: Bool {
        guard let url = tab.url else { return false }
        return browser.isBookmarked(url)
    }
}
