import SwiftUI

struct BrowserChrome: View {
    enum Placement { case top, bottom }

    @EnvironmentObject private var browser: BrowserStore
    @ObservedObject var tab: BrowserTab
    let placement: Placement
    @Binding var sheet: BrowserSheet?

    var body: some View {
        HStack(spacing: 8) {
            if placement == .top {
                navigationButtons
            }

            AddressField(tab: tab)
                .environmentObject(browser)

            Button {
                sheet = .shields
            } label: {
                Image(systemName: browser.shieldsAreEnabled(for: tab.url) ? "shield.fill" : "shield.slash")
                    .foregroundStyle(browser.shieldsAreEnabled(for: tab.url) ? Color.red : .secondary)
                    .frame(width: 28, height: 28)
            }
            .accessibilityLabel("Privacy shields")

            Menu {
                Button("New Tab", systemImage: "plus") { browser.newTab() }
                Button("New Private Tab", systemImage: "hand.raised") { browser.newTab(isPrivate: true) }
                Divider()
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
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .frame(width: 28, height: 28)
            }
            .accessibilityLabel("Browser menu")

            if placement == .bottom {
                Button {
                    browser.newTab()
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 28, height: 28)
                }
                .accessibilityLabel("New tab")
            }
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 2) {
            Button(action: tab.goBack) {
                Image(systemName: "chevron.left").frame(width: 28, height: 28)
            }
            .disabled(!tab.canGoBack)
            .accessibilityLabel("Back")

            Button(action: tab.goForward) {
                Image(systemName: "chevron.right").frame(width: 28, height: 28)
            }
            .disabled(!tab.canGoForward)
            .accessibilityLabel("Forward")

            Button(action: tab.reloadOrStop) {
                Image(systemName: tab.isLoading ? "xmark" : "arrow.clockwise")
                    .frame(width: 28, height: 28)
            }
            .accessibilityLabel(tab.isLoading ? "Stop" : "Reload")
        }
        .buttonStyle(.plain)
    }
}

private struct AddressField: View {
    @EnvironmentObject private var browser: BrowserStore
    @ObservedObject var tab: BrowserTab
    @FocusState private var isFocused: Bool
    @State private var text = ""

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: securityIcon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField("Search or enter address", text: $text)
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
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            } else if tab.url != nil {
                Button(action: tab.reloadOrStop) {
                    Image(systemName: tab.isLoading ? "xmark" : "arrow.clockwise")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.isLoading ? "Stop" : "Reload")
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 38)
        .background(Color(uiColor: .secondarySystemFill), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(isFocused ? Color.accentColor.opacity(0.55) : .clear, lineWidth: 1.5)
        }
        .onAppear { text = displayText }
    }

    private var displayText: String {
        guard let url = tab.url else { return "" }
        return url.host(percentEncoded: false) ?? url.absoluteString
    }

    private var securityIcon: String {
        guard let url = tab.url else { return "magnifyingglass" }
        return url.scheme == "https" ? "lock.fill" : "exclamationmark.triangle.fill"
    }
}
