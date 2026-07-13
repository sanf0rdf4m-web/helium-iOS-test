import SwiftUI

struct LibraryView: View {
    private enum Section: String, CaseIterable, Identifiable {
        case history = "History"
        case bookmarks = "Bookmarks"
        var id: String { rawValue }
    }

    @EnvironmentObject private var browser: BrowserStore
    @Environment(\.dismiss) private var dismiss
    @State private var selection: Section = .history

    var body: some View {
        VStack(spacing: 0) {
            header
            sectionPicker
            Rectangle().fill(HeliumTheme.border).frame(height: 1)
            content
        }
        .background(HeliumTheme.window)
        .environment(\.colorScheme, .dark)
    }

    private var header: some View {
        HStack {
            Text("History and bookmarks")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(HeliumTheme.primaryText)
            Spacer()
            if selection == .history, !browser.history.isEmpty {
                Button("Clear") { browser.clearHistory() }
                    .font(.system(size: 13))
                    .foregroundStyle(HeliumTheme.focus)
            }
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 30, height: 30)
                    .background(HeliumTheme.raised, in: Circle())
            }
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
    }

    private var sectionPicker: some View {
        HStack(spacing: 4) {
            ForEach(Section.allCases) { section in
                Button {
                    selection = section
                } label: {
                    Text(section.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(selection == section ? HeliumTheme.primaryText : HeliumTheme.secondaryText)
                        .padding(.horizontal, 14)
                        .frame(height: 30)
                        .background(
                            selection == section ? HeliumTheme.selected : Color.clear,
                            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var content: some View {
        switch selection {
        case .bookmarks:
            if browser.bookmarks.isEmpty {
                emptyState(title: "No bookmarks", detail: "Bookmark a page from the Helium menu.", icon: "star")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(browser.bookmarks.enumerated()), id: \.element.id) { index, bookmark in
                            libraryRow(title: bookmark.title, url: bookmark.url, detail: nil) {
                                browser.deleteBookmarks(at: IndexSet(integer: index))
                            }
                        }
                    }
                    .padding(10)
                }
            }
        case .history:
            if browser.history.isEmpty {
                emptyState(title: "No history", detail: "Private tabs never appear here.", icon: "clock")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(browser.history.enumerated()), id: \.element.id) { index, entry in
                            libraryRow(
                                title: entry.title,
                                url: entry.url,
                                detail: entry.lastVisitedAt.formatted(date: .abbreviated, time: .shortened)
                            ) {
                                browser.deleteHistory(at: IndexSet(integer: index))
                            }
                        }
                    }
                    .padding(10)
                }
            }
        }
    }

    private func libraryRow(
        title: String,
        url: URL,
        detail: String?,
        delete: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 10) {
            Button {
                if let tab = browser.selectedTab {
                    browser.navigate(url.absoluteString, in: tab)
                }
                dismiss()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "globe")
                        .font(.system(size: 13))
                        .foregroundStyle(HeliumTheme.secondaryText)
                        .frame(width: 22)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.system(size: 13))
                            .foregroundStyle(HeliumTheme.primaryText)
                            .lineLimit(1)
                        Text(detail ?? (url.host(percentEncoded: false) ?? url.absoluteString))
                            .font(.system(size: 11))
                            .foregroundStyle(HeliumTheme.secondaryText)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(role: .destructive, action: delete) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundStyle(HeliumTheme.secondaryText)
                    .frame(width: 28, height: 28)
            }
            .accessibilityLabel("Delete (title)")
        }
        .padding(.horizontal, 10)
        .frame(height: 52)
        .background(HeliumTheme.raised)
        .overlay(alignment: .bottom) {
            Rectangle().fill(HeliumTheme.border).frame(height: 1)
        }
    }

    private func emptyState(title: String, detail: String, icon: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(HeliumTheme.secondaryText)
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(HeliumTheme.primaryText)
            Text(detail)
                .font(.system(size: 13))
                .foregroundStyle(HeliumTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
