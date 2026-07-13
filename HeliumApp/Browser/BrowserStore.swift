import Combine
import Foundation
import HeliumCore
import WebKit

@MainActor
final class BrowserStore: ObservableObject {
    @Published private(set) var tabs: [BrowserTab] = []
    @Published var selectedTabID: UUID?
    @Published var splitTabID: UUID?
    @Published var preferences: BrowserPreferences {
        didSet {
            persist(preferences, key: Keys.preferences)
            schedulePrivacyUpdate()
        }
    }
    @Published private(set) var bookmarks: [Bookmark]
    @Published private(set) var history: [HistoryEntry]
    @Published private(set) var shieldExceptions: Set<String>
    @Published private(set) var privacyError: String?

    private var privacyUpdateTask: Task<Void, Never>?
    private var currentRuleList: WKContentRuleList?

    var selectedTab: BrowserTab? {
        guard let selectedTabID else { return tabs.first }
        return tabs.first { $0.id == selectedTabID } ?? tabs.first
    }

    var splitTab: BrowserTab? {
        guard let splitTabID else { return nil }
        return tabs.first { $0.id == splitTabID }
    }

    init() {
        preferences = Self.read(BrowserPreferences.self, key: Keys.preferences) ?? BrowserPreferences(
            searchEngine: .duckDuckGo
        )
        bookmarks = Self.read([Bookmark].self, key: Keys.bookmarks) ?? []
        history = Self.read([HistoryEntry].self, key: Keys.history) ?? []
        shieldExceptions = Set(Self.read([String].self, key: Keys.shieldExceptions) ?? [])

        let session = Self.read([SavedTab].self, key: Keys.session) ?? []
        let restored = session.prefix(20).map {
            makeTab(url: $0.url, title: $0.title, isPrivate: false)
        }
        tabs = restored.isEmpty ? [makeTab()] : restored
        selectedTabID = tabs.first?.id
        schedulePrivacyUpdate()
    }

    deinit {
        privacyUpdateTask?.cancel()
    }

    @discardableResult
    func newTab(isPrivate: Bool = false, select: Bool = true, url: URL? = nil) -> BrowserTab {
        let tab = makeTab(url: url, isPrivate: isPrivate)
        tabs.append(tab)
        if select { selectedTabID = tab.id }
        persistSession()
        if currentRuleList == nil { schedulePrivacyUpdate() }
        return tab
    }

    func select(_ tab: BrowserTab) {
        guard tabs.contains(where: { $0.id == tab.id }) else { return }
        selectedTabID = tab.id
    }

    func close(_ tab: BrowserTab) {
        guard let index = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        let wasSelected = selectedTabID == tab.id
        tabs.remove(at: index)
        if splitTabID == tab.id { splitTabID = nil }

        if tabs.isEmpty {
            let replacement = makeTab()
            tabs = [replacement]
            selectedTabID = replacement.id
        } else if wasSelected {
            selectedTabID = tabs[min(index, tabs.count - 1)].id
        }
        persistSession()
    }

    func navigate(_ input: String, in tab: BrowserTab) {
        let resolver = BrowserAddressResolver(searchEngine: preferences.searchEngine)
        guard let url = resolver.resolve(input) else { return }
        tab.load(url)
    }

    func toggleSplitView() {
        if splitTabID != nil {
            splitTabID = nil
            return
        }
        if let alternative = tabs.first(where: { $0.id != selectedTabID }) {
            splitTabID = alternative.id
        } else {
            splitTabID = newTab(select: false).id
        }
    }

    func openInSplitView(_ tab: BrowserTab) {
        if tab.id == selectedTabID {
            splitTabID = newTab(select: false).id
        } else {
            splitTabID = tab.id
        }
    }

    func shieldsAreEnabled(for url: URL?) -> Bool {
        guard preferences.privacy.shieldLevel != .off else { return false }
        guard let host = normalizedHost(url?.host) else { return true }
        return !isExcepted(host)
    }

    func toggleShields(for tab: BrowserTab) {
        guard let host = normalizedHost(tab.url?.host) else { return }
        if shieldExceptions.contains(host) {
            shieldExceptions.remove(host)
        } else {
            shieldExceptions.insert(host)
        }
        persist(Array(shieldExceptions).sorted(), key: Keys.shieldExceptions)
        tab.webView.stopLoading()
        schedulePrivacyUpdate(reload: tab)
    }

    func refreshPrivacy() {
        schedulePrivacyUpdate(reload: selectedTab)
    }

    func isBookmarked(_ url: URL) -> Bool {
        bookmarks.contains { normalizedURL($0.url) == normalizedURL(url) }
    }

    func toggleBookmark(for tab: BrowserTab) {
        guard let url = tab.url else { return }
        if let index = bookmarks.firstIndex(where: { normalizedURL($0.url) == normalizedURL(url) }) {
            bookmarks.remove(at: index)
        } else {
            bookmarks.insert(Bookmark(title: tab.title, url: url), at: 0)
        }
        persist(bookmarks, key: Keys.bookmarks)
    }

    func deleteBookmarks(at offsets: IndexSet) {
        for offset in offsets.sorted(by: >) where bookmarks.indices.contains(offset) {
            bookmarks.remove(at: offset)
        }
        persist(bookmarks, key: Keys.bookmarks)
    }

    func deleteHistory(at offsets: IndexSet) {
        for offset in offsets.sorted(by: >) where history.indices.contains(offset) {
            history.remove(at: offset)
        }
        persist(history, key: Keys.history)
    }

    func clearHistory() {
        history.removeAll()
        persist(history, key: Keys.history)
    }

    func clearWebsiteData() async {
        let store = WKWebsiteDataStore.default()
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        await withCheckedContinuation { continuation in
            store.removeData(ofTypes: types, modifiedSince: .distantPast) {
                continuation.resume()
            }
        }
    }

    private func makeTab(
        url: URL? = nil,
        title: String = "New Tab",
        isPrivate: Bool = false
    ) -> BrowserTab {
        let tab = BrowserTab(url: url, title: title, isPrivate: isPrivate)
        tab.onNavigation = { [weak self] tab, url, title in
            self?.recordNavigation(tab: tab, url: url, title: title)
        }
        tab.onOpenWindow = { [weak self] url in
            self?.newTab(url: url)
        }
        if let currentRuleList {
            configure(tab, ruleList: currentRuleList, preferences: preferences)
        }
        return tab
    }

    private func recordNavigation(tab: BrowserTab, url: URL, title: String) {
        persistSession()
        guard !tab.isPrivate, ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return }

        if let index = history.firstIndex(where: { normalizedURL($0.url) == normalizedURL(url) }) {
            history[index].recordVisit(title: title)
            let entry = history.remove(at: index)
            history.insert(entry, at: 0)
        } else {
            history.insert(HistoryEntry(title: title, url: url), at: 0)
            if history.count > 1_000 { history.removeLast(history.count - 1_000) }
        }
        persist(history, key: Keys.history)
    }

    private func schedulePrivacyUpdate(reload tabToReload: BrowserTab? = nil) {
        privacyUpdateTask?.cancel()
        let preferences = preferences
        let exceptions = Array(shieldExceptions)
        privacyUpdateTask = Task { [weak self] in
            do {
                let json = try ContentBlockerRuleGenerator.makeJSON(
                    preferences: preferences,
                    exceptions: exceptions
                )
                let list = try await WKContentRuleListStore.default().compileContentRuleList(
                    forIdentifier: "computer.helium.community.shields",
                    encodedContentRuleList: json
                )
                guard !Task.isCancelled, let self else { return }
                self.currentRuleList = list
                for tab in self.tabs {
                    self.configure(tab, ruleList: list, preferences: preferences)
                }
                self.privacyError = nil
                tabToReload?.webView.reload()
            } catch is CancellationError {
                return
            } catch {
                guard let self else { return }
                self.currentRuleList = nil
                self.privacyError = error.localizedDescription
                for tab in self.tabs {
                    self.configure(tab, ruleList: nil, preferences: preferences)
                }
            }
        }
    }

    private func configure(
        _ tab: BrowserTab,
        ruleList: WKContentRuleList?,
        preferences: BrowserPreferences
    ) {
        tab.configurePrivacy(
            ruleList: ruleList,
            blockScripts: preferences.privacy.blockScripts,
            fingerprintProtection: preferences.privacy.blockFingerprinting,
            sendGlobalPrivacyControl: preferences.privacy.sendGlobalPrivacyControl,
            sendDoNotTrack: preferences.privacy.sendDoNotTrack
        )
    }

    private func persistSession() {
        let saved = tabs.compactMap { tab -> SavedTab? in
            guard !tab.isPrivate else { return nil }
            return SavedTab(title: tab.title, url: tab.url)
        }
        persist(saved, key: Keys.session)
    }

    private func normalizedURL(_ url: URL) -> String {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.fragment = nil
        return components?.string ?? url.absoluteString
    }

    private func normalizedHost(_ host: String?) -> String? {
        guard var host = host?.lowercased(), !host.isEmpty else { return nil }
        if host.hasPrefix("www.") { host.removeFirst(4) }
        return host
    }

    private func isExcepted(_ host: String) -> Bool {
        shieldExceptions.contains { exception in
            host == exception || host.hasSuffix(".\(exception)")
        }
    }

    private func persist<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    nonisolated private static func read<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private struct SavedTab: Codable {
        let title: String
        let url: URL?
    }

    private enum Keys {
        static let preferences = "browser.preferences.v1"
        static let bookmarks = "browser.bookmarks.v1"
        static let history = "browser.history.v1"
        static let shieldExceptions = "browser.shieldExceptions.v1"
        static let session = "browser.session.v1"
    }
}
