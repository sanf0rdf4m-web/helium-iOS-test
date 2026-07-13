import SwiftUI

struct TabStrip: View {
    @EnvironmentObject private var browser: BrowserStore
    @Binding var isExpanded: Bool
    @Binding var isShowingSettings: Bool
    var isPhoneOverlay = false

    private let expandedWidth: CGFloat = 166
    private let phoneOverlayWidth: CGFloat = 250
    private let collapsedWidth: CGFloat = 35

    private var width: CGFloat {
        guard isExpanded else { return collapsedWidth }
        return isPhoneOverlay ? phoneOverlayWidth : expandedWidth
    }

    var body: some View {
        VStack(spacing: 0) {
            toggleRow

            ScrollViewReader { reader in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 2) {
                        ForEach(browser.tabs) { tab in
                            if isShowingSettings, browser.selectedTabID == tab.id {
                                settingsRow
                                    .id(tab.id)
                            } else {
                                VerticalTabRow(tab: tab, isExpanded: isExpanded) {
                                    isShowingSettings = false
                                    browser.select(tab)
                                }
                                .environmentObject(browser)
                                .id(tab.id)
                            }
                        }

                        newTabRow
                    }
                    .padding(.horizontal, isExpanded ? 5 : 3.5)
                    .padding(.bottom, 6)
                }
                .onChange(of: browser.selectedTabID) { _, id in
                    guard let id else { return }
                    withAnimation(.easeInOut(duration: 0.18)) {
                        reader.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
        .frame(width: width)
        .background(HeliumTheme.sidebar)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(HeliumTheme.subtleBorder)
                .frame(width: 0.5)
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Vertical tabs")
    }

    private var toggleRow: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HeliumTheme.primaryText)
                    .frame(width: 28, height: 28)
                    .background(
                        isExpanded ? HeliumTheme.selected : HeliumTheme.accent,
                        in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isExpanded ? "Collapse vertical tabs" : "Expand vertical tabs")

            if isExpanded {
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, isExpanded ? 5 : 3.5)
        .frame(height: 38)
    }

    private var newTabRow: some View {
        Button {
            isShowingSettings = false
            browser.newTab()
        } label: {
            if isExpanded {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .frame(width: 18, height: 18)
                    Text("New Tab")
                        .font(.system(size: 12.5, weight: .regular))
                    Spacer(minLength: 0)
                }
                .foregroundStyle(HeliumTheme.secondaryText)
                .padding(.horizontal, 7)
                .frame(height: 30)
                .contentShape(Rectangle())
            } else {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HeliumTheme.secondaryText)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("New tab")
    }

    private var settingsRow: some View {
        HStack(spacing: 0) {
            if isExpanded {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 12, weight: .medium))
                        .frame(width: 18, height: 18)
                    Text("Settings")
                        .font(.system(size: 12.5, weight: .regular))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 7)
                .frame(height: 30)
                .background(
                    HeliumTheme.selected,
                    in: RoundedRectangle(cornerRadius: 5, style: .continuous)
                )
            } else {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 28, height: 28)
                    .background(
                        HeliumTheme.selected,
                        in: RoundedRectangle(cornerRadius: 5, style: .continuous)
                    )
            }
        }
        .foregroundStyle(HeliumTheme.primaryText)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Settings")
        .accessibilityAddTraits(.isSelected)
    }
}

private struct VerticalTabRow: View {
    @EnvironmentObject private var browser: BrowserStore
    @ObservedObject var tab: BrowserTab
    let isExpanded: Bool
    let select: () -> Void

    private var isSelected: Bool { browser.selectedTabID == tab.id }

    var body: some View {
        Group {
            if isExpanded {
                expandedRow
            } else {
                collapsedRow
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: select)
        .contextMenu {
            Button("Close Tab", systemImage: "xmark") {
                browser.close(tab)
            }
            Button("Open in Split View", systemImage: "rectangle.split.2x1") {
                browser.openInSplitView(tab)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityAction(named: "Select tab", select)
        .accessibilityAction(named: "Close tab") {
            browser.close(tab)
        }
    }

    private var expandedRow: some View {
        HStack(spacing: 7) {
            favicon

            Text(tab.title)
                .font(.system(size: 12.5, weight: .regular))
                .foregroundStyle(HeliumTheme.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                browser.close(tab)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(HeliumTheme.secondaryText)
                    .frame(width: 20, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close \(tab.title)")
        }
        .padding(.leading, 7)
        .padding(.trailing, 3)
        .frame(height: 30)
        .background(
            isSelected ? HeliumTheme.selected : Color.clear,
            in: RoundedRectangle(cornerRadius: 5, style: .continuous)
        )
    }

    private var collapsedRow: some View {
        favicon
            .frame(width: 28, height: 28)
            .background(
                isSelected ? HeliumTheme.selected : Color.clear,
                in: RoundedRectangle(cornerRadius: 5, style: .continuous)
            )
    }

    @ViewBuilder
    private var favicon: some View {
        if tab.url == nil {
            Image("HeliumGlyph")
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
        } else if let faviconURL = tab.faviconURL {
            AsyncImage(url: faviconURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFit()
                } else {
                    fallbackFavicon
                }
            }
            .frame(width: 15, height: 15)
        } else {
            fallbackFavicon
        }
    }

    private var fallbackFavicon: some View {
        Image(systemName: "globe")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(HeliumTheme.secondaryText)
            .frame(width: 15, height: 15)
    }
}
