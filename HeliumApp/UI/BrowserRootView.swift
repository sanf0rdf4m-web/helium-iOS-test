import SwiftUI

struct BrowserRootView: View {
    @EnvironmentObject private var browser: BrowserStore
    @State private var sheet: BrowserSheet?
    @State private var isShowingSettings = false
    @State private var isSidebarExpanded = false
    @State private var isRailOverlayPresented = false
    @State private var didInitializeLayout = false

    var body: some View {
        GeometryReader { proxy in
            let mode = BrowserShellMode(
                width: proxy.size.width,
                idiom: UIDevice.current.userInterfaceIdiom
            )

            ZStack(alignment: .leading) {
                Group {
                    if let tab = browser.selectedTab {
                        browserView(tab: tab, mode: mode)
                    } else {
                        ProgressView()
                            .tint(HeliumTheme.primaryText)
                            .task { browser.newTab() }
                    }
                }

                if mode.usesOverlayRail, isRailOverlayPresented {
                    Color.black.opacity(0.42)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { dismissRailOverlay() }
                        .accessibilityHidden(true)

                    TabStrip(
                        isExpanded: overlayExpansionBinding,
                        isShowingSettings: $isShowingSettings,
                        isPhoneOverlay: mode == .phone
                    )
                    .environmentObject(browser)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .zIndex(1)
                }
            }
            .background(HeliumTheme.window)
            .onAppear { initializeLayout(for: mode) }
            .onChange(of: mode) { oldMode, newMode in
                adaptLayout(from: oldMode, to: newMode)
            }
            .onChange(of: browser.selectedTabID) { _, _ in
                if mode.usesOverlayRail { dismissRailOverlay() }
            }
            .onChange(of: isShowingSettings) { _, _ in
                if mode.usesOverlayRail { dismissRailOverlay() }
            }
        }
        .background(HeliumTheme.window.ignoresSafeArea())
        .sheet(item: $sheet) { destination in
            switch destination {
            case .shields:
                if let tab = browser.selectedTab {
                    ShieldsPanel(tab: tab)
                        .environmentObject(browser)
                        .presentationDetents([.height(430), .large])
                        .presentationDragIndicator(.visible)
                }
            case .library:
                LibraryView()
                    .environmentObject(browser)
            }
        }
    }

    @ViewBuilder
    private func browserView(tab: BrowserTab, mode: BrowserShellMode) -> some View {
        HStack(spacing: 0) {
            if mode == .wide {
                TabStrip(
                    isExpanded: $isSidebarExpanded,
                    isShowingSettings: $isShowingSettings
                )
                .environmentObject(browser)
            } else {
                TabStrip(
                    isExpanded: collapsedRailBinding,
                    isShowingSettings: $isShowingSettings
                )
                .environmentObject(browser)
            }

            VStack(spacing: 0) {
                BrowserChrome(
                    tab: tab,
                    isShowingSettings: $isShowingSettings,
                    sheet: $sheet
                )
                .environmentObject(browser)

                workspace(tab: tab, mode: mode)
            }
        }
    }

    @ViewBuilder
    private func workspace(tab: BrowserTab, mode: BrowserShellMode) -> some View {
        Group {
            if isShowingSettings {
                SettingsView()
                    .environmentObject(browser)
            } else {
                BrowserWorkspace(
                    primaryTab: tab,
                    splitTab: mode.supportsSplitView ? browser.splitTab : nil
                )
            }
        }
        .background(HeliumTheme.content)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(HeliumTheme.border, lineWidth: 0.75)
        }
        .padding(.trailing, 4)
        .padding(.bottom, 4)
    }

    private var collapsedRailBinding: Binding<Bool> {
        Binding(
            get: { false },
            set: { requestedExpansion in
                guard requestedExpansion else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    isRailOverlayPresented = true
                }
            }
        )
    }

    private var overlayExpansionBinding: Binding<Bool> {
        Binding(
            get: { true },
            set: { requestedExpansion in
                guard !requestedExpansion else { return }
                dismissRailOverlay()
            }
        )
    }

    private func initializeLayout(for mode: BrowserShellMode) {
        guard !didInitializeLayout else { return }
        didInitializeLayout = true
        isSidebarExpanded = mode == .wide
    }

    private func adaptLayout(from oldMode: BrowserShellMode, to newMode: BrowserShellMode) {
        guard didInitializeLayout, oldMode != newMode else { return }
        isRailOverlayPresented = false
        isSidebarExpanded = newMode == .wide
    }

    private func dismissRailOverlay() {
        withAnimation(.easeInOut(duration: 0.18)) {
            isRailOverlayPresented = false
        }
    }
}

private enum BrowserShellMode: Equatable {
    case wide
    case compactRail
    case phone

    init(width: CGFloat, idiom: UIUserInterfaceIdiom) {
        if idiom == .phone || width < 720 {
            self = .phone
        } else if width < 960 {
            self = .compactRail
        } else {
            self = .wide
        }
    }

    var usesOverlayRail: Bool { self != .wide }
    var supportsSplitView: Bool { self != .phone }
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
    }
}

enum BrowserSheet: String, Identifiable {
    case shields
    case library

    var id: String { rawValue }
}
