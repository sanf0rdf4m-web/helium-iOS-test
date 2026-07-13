import SwiftUI

struct BrowserChrome: View {
    enum Placement { case top, bottom }

    @EnvironmentObject private var browser: BrowserStore
    @ObservedObject var tab: BrowserTab
    let placement: Placement
    @Binding var sheet: BrowserSheet?

    var body: some View {
        HStack(spacing: 7) {
            if placement == .top {
                navigationButtons
                Spacer(minLength: 4)
            }

            AddressField(tab: tab)
                .environmentObject(browser)
                .frame(maxWidth: 680)

            if placement == .top { Spacer(minLength: 4) }
            trailingControls
        }
        .frame(height: 38)
        .buttonStyle(.plain)
        .foregroundStyle(Color(uiColor: .label))
    }

    private var trailingControls: some View {
        HStack(spacing: 3) {
            if placement == .bottom {
                Button(action: tab.reloadOrStop) {
                    chromeIcon(tab.isLoading ? "xmark" : "arrow.clockwise")
                }
                .accessibilityLabel(tab.isLoading ? "Stop" : "Reload")
            }

            Button {
                sheet = .shields
            } label: {
                Image(systemName: browser.shieldsAreEnabled(for: tab.url) ? "shield.fill" : "shield.slash")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(browser.shieldsAreEnabled(for: tab.url) ? Color.red : .secondary)
                    .frame(width: 30, height: 32)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Privacy shields")

            Menu {
                Button("New Tab", systemImage: "plus") { browser.newTab() }
                Button("New Private Tab", systemImage: "hand.raised") { browser.newTab(isPrivate: true) }
                Divider()
                Button(tab.isLoading ? "Stop Loading" : "Reload", systemImage: tab.isLoading ? "xmark" : "arrow.clockwise") {
                    tab.reloadOrStop()
                }
                Button("Bookmarks and History", systemImage: "books.vertical") { sheet = .library }
                if let url = tab.url {
                    ShareLink(item: url)
                    Button(
                        browser.isBookmarked(url) ? "Remove Bookmark" : "Add Bookmark",
                        systemImage: browser.isBookmarked(url) ? "star.slash" : "star"
                    ) {
                        browser.toggleBookmark(for: tab)
                    }
                }
                if UIDevice.current.userInterfaceIdiom == .pad {
                    Button("Toggle Split View", systemImage: "rectangle.split.2x1") {
                        browser.toggleSplitView()
                    }
                }
                Divider()
                Button("Settings", systemImage: "gearshape") { sheet = .settings }
            } label: {
                chromeIcon("ellipsis", rotation: 90)
            }
            .accessibilityLabel("Browser menu")

            Button {
                browser.newTab()
            } label: {
                chromeIcon("plus")
            }
            .accessibilityLabel("New tab")
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 3) {
            Button(action: tab.goBack) {
                chromeIcon("chevron.left")
            }
            .disabled(!tab.canGoBack)
            .accessibilityLabel("Back")

            Button(action: tab.goForward) {
                chromeIcon("chevron.right")
            }
            .disabled(!tab.canGoForward)
            .accessibilityLabel("Forward")

            Button(action: tab.reloadOrStop) {
                chromeIcon(tab.isLoading ? "xmark" : "arrow.clockwise")
            }
            .accessibilityLabel(tab.isLoading ? "Stop" : "Reload")
        }
    }

    private func chromeIcon(_ systemName: String, rotation: Double = 0) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .medium))
            .rotationEffect(.degrees(rotation))
            .frame(width: 30, height: 32)
            .contentShape(Rectangle())
    }
}

private struct AddressField: View {
    @EnvironmentObject private var browser: BrowserStore
    @ObservedObject var tab: BrowserTab
    @FocusState private var isFocused: Bool
    @State private var text = ""

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
                .frame(width: 18, height: 18)
                .accessibilityHidden(true)

            TextField("Search or enter address", text: $text)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color(uiColor: .label))
                .multilineTextAlignment(isFocused ? .leading : .center)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.webSearch)
                .submitLabel(.go)
                .focused($isFocused)
                .onSubmit {
                    browser.navigate(text, in: tab)
                    isFocused = false
                }
                .onChange(of: isFocused) { _, focused in
                    text = focused ? (tab.url?.absoluteString ?? "") : displayText
                }
                .onChange(of: tab.url) { _, _ in
                    if !isFocused { text = displayText }
                }

            if isFocused, !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear address")
            } else {
                Button {
                    browser.toggleBookmark(for: tab)
                } label: {
                    Image(systemName: isBookmarked ? "star.fill" : "star")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isBookmarked ? Color.yellow : Color(uiColor: .secondaryLabel))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .disabled(tab.url == nil)
                .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Add bookmark")
            }
        }
        .padding(.horizontal, 10)
        .frame(minHeight: 38)
        .background(
            Color(red: 0.91, green: 0.91, blue: 0.91),
            in: RoundedRectangle(cornerRadius: 11, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(isFocused ? Color.black.opacity(0.24) : Color.black.opacity(0.055), lineWidth: 1)
        }
        .onAppear { text = displayText }
    }

    private var displayText: String {
        guard let url = tab.url else { return "" }
        return url.host(percentEncoded: false) ?? url.absoluteString
    }

    private var isBookmarked: Bool {
        guard let url = tab.url else { return false }
        return browser.isBookmarked(url)
    }
}
