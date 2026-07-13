import SwiftUI

struct TabStrip: View {
    @EnvironmentObject private var browser: BrowserStore
    var compact = false

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { reader in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(Array(browser.tabs.enumerated()), id: \.element.id) { index, tab in
                            TabPill(
                                tab: tab,
                                compact: compact,
                                showsSeparator: index < browser.tabs.count - 1
                            )
                            .environmentObject(browser)
                            .frame(width: tabWidth(in: geometry.size.width))
                            .id(tab.id)
                        }
                    }
                    .frame(minWidth: geometry.size.width - 14, alignment: .leading)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                }
                .onChange(of: browser.selectedTabID) { _, id in
                    guard let id else { return }
                    withAnimation(.easeInOut(duration: 0.18)) {
                        reader.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
        .frame(height: 41)
        .background(Color(uiColor: .systemBackground))
    }

    private func tabWidth(in availableWidth: CGFloat) -> CGFloat {
        let count = max(CGFloat(browser.tabs.count), 1)
        let reservedWidth: CGFloat = 14
        let proposed = (availableWidth - reservedWidth) / count

        if compact {
            return min(260, max(112, proposed))
        }
        return min(220, max(128, proposed))
    }
}

private struct TabPill: View {
    @EnvironmentObject private var browser: BrowserStore
    @ObservedObject var tab: BrowserTab
    let compact: Bool
    let showsSeparator: Bool

    private var selected: Bool { browser.selectedTabID == tab.id }

    var body: some View {
        HStack(spacing: 7) {
            favicon

            Text(tab.title)
                .font(.system(size: compact ? 13 : 14, weight: .regular))
                .foregroundStyle(Color(uiColor: .label))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            if selected {
                Button {
                    browser.close(tab)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10.5, weight: .semibold))
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close \(tab.title)")
            }
        }
        .padding(.leading, 10)
        .padding(.trailing, selected ? 6 : 10)
        .frame(height: 35)
        .background(
            selected ? Color(red: 0.91, green: 0.91, blue: 0.91) : Color.clear,
            in: RoundedRectangle(cornerRadius: 7, style: .continuous)
        )
        .overlay(alignment: .trailing) {
            if showsSeparator && !selected {
                Rectangle()
                    .fill(Color.black.opacity(0.11))
                    .frame(width: 0.5, height: 22)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { browser.select(tab) }
        .accessibilityElement(children: .contain)
        .contextMenu {
            Button("Close Tab", systemImage: "xmark") { browser.close(tab) }
            Button("Open in Split View", systemImage: "rectangle.split.2x1") {
                browser.openInSplitView(tab)
            }
        }
    }

    @ViewBuilder
    private var favicon: some View {
        if tab.url == nil {
            Image("HeliumGlyph")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
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
            .frame(width: 16, height: 16)
        } else {
            fallbackFavicon
        }
    }

    private var fallbackFavicon: some View {
        Image(systemName: "globe")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color(uiColor: .secondaryLabel))
            .frame(width: 16, height: 16)
    }
}
