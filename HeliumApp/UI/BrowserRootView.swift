import SwiftUI

struct BrowserRootView: View {
    @EnvironmentObject private var browser: BrowserStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var sheet: BrowserSheet?

    private var isWide: Bool { horizontalSizeClass == .regular }

    var body: some View {
        Group {
            if let tab = browser.selectedTab {
                browserView(tab: tab)
            } else {
                ProgressView()
                    .task { browser.newTab() }
            }
        }
        .background(Color(uiColor: .systemBackground))
        .sheet(item: $sheet) { destination in
            switch destination {
            case .shields:
                if let tab = browser.selectedTab {
                    ShieldsPanel(tab: tab)
                        .environmentObject(browser)
                        .presentationDetents([.medium, .large])
                }
            case .settings:
                SettingsView()
                    .environmentObject(browser)
            case .library:
                LibraryView()
                    .environmentObject(browser)
            }
        }
    }

    @ViewBuilder
    private func browserView(tab: BrowserTab) -> some View {
        VStack(spacing: 0) {
            if isWide {
                BrowserChrome(tab: tab, placement: .top, sheet: $sheet)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                TabStrip()
                    .environmentObject(browser)
                Divider()
            } else {
                TabStrip(compact: true)
                    .environmentObject(browser)
                Divider()
            }

            BrowserWorkspace(primaryTab: tab, splitTab: isWide ? browser.splitTab : nil)

            if !isWide {
                Divider()
                BrowserChrome(tab: tab, placement: .bottom, sheet: $sheet)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
            }
        }
    }
}

private struct BrowserWorkspace: View {
    @ObservedObject var primaryTab: BrowserTab
    var splitTab: BrowserTab?

    var body: some View {
        HStack(spacing: 0) {
            BrowserPage(tab: primaryTab)
            if let splitTab, splitTab.id != primaryTab.id {
                Divider()
                BrowserPage(tab: splitTab)
            }
        }
    }
}

private struct BrowserPage: View {
    @EnvironmentObject private var browser: BrowserStore
    @ObservedObject var tab: BrowserTab

    var body: some View {
        ZStack {
            if tab.url == nil {
                NewTabView(tab: tab)
                    .environmentObject(browser)
            } else {
                BrowserWebView(tab: tab)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }

            if let error = tab.lastError {
                ContentUnavailableView {
                    Label("Couldn’t Open Page", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(error)
                } actions: {
                    Button("Try Again") { tab.reloadOrStop() }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.background)
            }
        }
        .overlay(alignment: .top) {
            if tab.isLoading {
                GeometryReader { proxy in
                    Capsule()
                        .fill(.tint)
                        .frame(width: max(8, proxy.size.width * tab.estimatedProgress), height: 2)
                        .animation(.easeOut(duration: 0.15), value: tab.estimatedProgress)
                }
                .frame(height: 2)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(isPad ? 6 : 0)
    }

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
}

enum BrowserSheet: String, Identifiable {
    case shields
    case settings
    case library

    var id: String { rawValue }
}
