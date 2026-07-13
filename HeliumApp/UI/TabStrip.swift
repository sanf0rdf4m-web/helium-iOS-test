import SwiftUI

struct TabStrip: View {
    @EnvironmentObject private var browser: BrowserStore
    var compact = false

    var body: some View {
        ScrollViewReader { reader in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: compact ? 5 : 7) {
                    ForEach(browser.tabs) { tab in
                        TabPill(tab: tab, compact: compact)
                            .environmentObject(browser)
                            .id(tab.id)
                    }
                    Button {
                        browser.newTab()
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("New tab")
                }
                .padding(.horizontal, 9)
                .padding(.vertical, compact ? 5 : 4)
            }
            .onChange(of: browser.selectedTabID) { _, id in
                guard let id else { return }
                withAnimation { reader.scrollTo(id, anchor: .center) }
            }
        }
        .background(Color(uiColor: .systemBackground))
    }
}

private struct TabPill: View {
    @EnvironmentObject private var browser: BrowserStore
    @ObservedObject var tab: BrowserTab
    let compact: Bool

    private var selected: Bool { browser.selectedTabID == tab.id }

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: tab.isPrivate ? "hand.raised.fill" : "globe")
                .font(.caption)
                .foregroundStyle(tab.isPrivate ? Color.purple : .secondary)
            Text(tab.title)
                .font(.subheadline)
                .lineLimit(1)
                .frame(maxWidth: compact ? 118 : 180, alignment: .leading)
            Button {
                browser.close(tab)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close \(tab.title)")
        }
        .padding(.leading, 10)
        .padding(.trailing, 6)
        .frame(height: 34)
        .background(
            selected ? Color(uiColor: .secondarySystemFill) : Color.clear,
            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
        )
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
}
