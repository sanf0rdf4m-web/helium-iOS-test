import SwiftUI

struct LibraryView: View {
    private enum Section: String, CaseIterable, Identifiable {
        case bookmarks = "Bookmarks"
        case history = "History"
        var id: String { rawValue }
    }

    @EnvironmentObject private var browser: BrowserStore
    @Environment(\.dismiss) private var dismiss
    @State private var selection: Section = .bookmarks

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Library", selection: $selection) {
                    ForEach(Section.allCases) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch selection {
                case .bookmarks: bookmarksList
                case .history: historyList
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                if selection == .history, !browser.history.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Clear", role: .destructive) { browser.clearHistory() }
                    }
                }
            }
        }
    }

    private var bookmarksList: some View {
        Group {
            if browser.bookmarks.isEmpty {
                ContentUnavailableView("No Bookmarks", systemImage: "star", description: Text("Bookmark a page from the browser menu."))
            } else {
                List {
                    ForEach(browser.bookmarks) { bookmark in
                        libraryRow(title: bookmark.title, url: bookmark.url, detail: nil)
                    }
                    .onDelete(perform: browser.deleteBookmarks)
                }
                .listStyle(.plain)
            }
        }
    }

    private var historyList: some View {
        Group {
            if browser.history.isEmpty {
                ContentUnavailableView("No History", systemImage: "clock", description: Text("Private tabs never appear here."))
            } else {
                List {
                    ForEach(browser.history) { entry in
                        libraryRow(
                            title: entry.title,
                            url: entry.url,
                            detail: entry.lastVisitedAt.formatted(date: .abbreviated, time: .shortened)
                        )
                    }
                    .onDelete(perform: browser.deleteHistory)
                }
                .listStyle(.plain)
            }
        }
    }

    private func libraryRow(title: String, url: URL, detail: String?) -> some View {
        Button {
            if let tab = browser.selectedTab {
                browser.navigate(url.absoluteString, in: tab)
            }
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .foregroundStyle(.tint)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).foregroundStyle(.primary).lineLimit(1)
                    Text(detail ?? (url.host(percentEncoded: false) ?? url.absoluteString))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
