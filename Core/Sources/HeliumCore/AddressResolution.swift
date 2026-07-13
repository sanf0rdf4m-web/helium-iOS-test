import Foundation

/// Search services supported by Helium without requiring a remote suggestion service.
public enum SearchEngine: String, Codable, CaseIterable, Identifiable, Sendable {
    case google
    case duckDuckGo
    case brave
    case bing
    case ecosia

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .google: "Google"
        case .duckDuckGo: "DuckDuckGo"
        case .brave: "Brave Search"
        case .bing: "Bing"
        case .ecosia: "Ecosia"
        }
    }

    /// Builds the provider URL using URLComponents so the query cannot inject
    /// additional query items.
    public func searchURL(for query: String) -> URL? {
        var components: URLComponents
        switch self {
        case .google:
            components = URLComponents(string: "https://www.google.com/search")!
        case .duckDuckGo:
            components = URLComponents(string: "https://duckduckgo.com/")!
        case .brave:
            components = URLComponents(string: "https://search.brave.com/search")!
        case .bing:
            components = URLComponents(string: "https://www.bing.com/search")!
        case .ecosia:
            components = URLComponents(string: "https://www.ecosia.org/search")!
        }
        components.queryItems = [URLQueryItem(name: "q", value: query)]
        return components.url
    }
}

/// A shortcut resolved entirely on-device. `key` is stored without the leading `!`.
public struct BangShortcut: Codable, Hashable, Identifiable, Sendable {
    public let key: String
    public let name: String
    public let destinationTemplate: String
    public let homepage: URL

    public var id: String { key }

    public init(key: String, name: String, destinationTemplate: String, homepage: URL) {
        self.key = key
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: "!"))
        self.name = name
        self.destinationTemplate = destinationTemplate
        self.homepage = homepage
    }

    public func destination(for query: String) -> URL? {
        guard !query.isEmpty else { return homepage }
        return URL(string: destinationTemplate.replacingOccurrences(
            of: "{query}",
            with: Self.encodeQuery(query)
        ))
    }

    private static func encodeQuery(_ query: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: ":/?#[]@!$&'()*+,;=%")
        return query.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
    }

    public static let defaults: [BangShortcut] = [
        BangShortcut(
            key: "g",
            name: "Google",
            destinationTemplate: "https://www.google.com/search?q={query}",
            homepage: URL(string: "https://www.google.com/")!
        ),
        BangShortcut(
            key: "ddg",
            name: "DuckDuckGo",
            destinationTemplate: "https://duckduckgo.com/?q={query}",
            homepage: URL(string: "https://duckduckgo.com/")!
        ),
        BangShortcut(
            key: "b",
            name: "Brave Search",
            destinationTemplate: "https://search.brave.com/search?q={query}",
            homepage: URL(string: "https://search.brave.com/")!
        ),
        BangShortcut(
            key: "w",
            name: "Wikipedia",
            destinationTemplate: "https://en.wikipedia.org/w/index.php?search={query}",
            homepage: URL(string: "https://en.wikipedia.org/")!
        ),
        BangShortcut(
            key: "yt",
            name: "YouTube",
            destinationTemplate: "https://www.youtube.com/results?search_query={query}",
            homepage: URL(string: "https://www.youtube.com/")!
        ),
        BangShortcut(
            key: "maps",
            name: "Apple Maps",
            destinationTemplate: "https://maps.apple.com/?q={query}",
            homepage: URL(string: "https://maps.apple.com/")!
        ),
        BangShortcut(
            key: "gh",
            name: "GitHub",
            destinationTemplate: "https://github.com/search?q={query}",
            homepage: URL(string: "https://github.com/")!
        )
    ]
}

public struct BangResolution: Equatable, Sendable {
    public let shortcut: BangShortcut
    public let query: String
    public let url: URL
}

/// Matches a fixed local shortcut table. Unknown bangs deliberately return nil
/// so they can be sent to the selected search engine unchanged.
public struct BangResolver: Sendable {
    public let shortcuts: [BangShortcut]
    private let shortcutsByKey: [String: BangShortcut]

    public init(shortcuts: [BangShortcut] = BangShortcut.defaults) {
        self.shortcuts = shortcuts
        self.shortcutsByKey = Dictionary(
            shortcuts.map { ($0.key.lowercased(), $0) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    public func resolve(_ input: String) -> BangResolution? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.first == "!" else { return nil }

        let parts = trimmed.split(
            maxSplits: 1,
            omittingEmptySubsequences: true,
            whereSeparator: { $0.isWhitespace }
        )
        guard let rawKey = parts.first, rawKey.count > 1 else { return nil }
        let key = rawKey.dropFirst().lowercased()
        guard let shortcut = shortcutsByKey[key] else { return nil }

        let query = parts.count == 2
            ? String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            : ""
        guard let url = shortcut.destination(for: query) else { return nil }
        return BangResolution(shortcut: shortcut, query: query, url: url)
    }
}

public struct ResolvedAddress: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case direct
        case search(query: String, engine: SearchEngine)
        case bang(key: String, query: String)
    }

    public let url: URL
    public let kind: Kind
}

/// Converts omnibox text into a URL, prioritizing local bangs, then navigable
/// host names, and finally the selected search engine.
public struct BrowserAddressResolver: Sendable {
    public let searchEngine: SearchEngine
    public let bangResolver: BangResolver

    public init(
        searchEngine: SearchEngine = .google,
        shortcuts: [BangShortcut] = BangShortcut.defaults
    ) {
        self.searchEngine = searchEngine
        self.bangResolver = BangResolver(shortcuts: shortcuts)
    }

    public init(searchEngine: SearchEngine = .google, bangResolver: BangResolver) {
        self.searchEngine = searchEngine
        self.bangResolver = bangResolver
    }

    public func resolve(_ input: String) -> URL? {
        resolveDetailed(input)?.url
    }

    public func resolve(_ input: String, preferences: BrowserPreferences) -> URL? {
        BrowserAddressResolver(
            searchEngine: preferences.searchEngine,
            bangResolver: bangResolver
        ).resolve(input)
    }

    public func resolveDetailed(_ input: String) -> ResolvedAddress? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let bang = bangResolver.resolve(trimmed) {
            return ResolvedAddress(
                url: bang.url,
                kind: .bang(key: bang.shortcut.key, query: bang.query)
            )
        }

        if let url = Self.directURL(from: trimmed) {
            return ResolvedAddress(url: url, kind: .direct)
        }

        guard let url = searchEngine.searchURL(for: trimmed) else { return nil }
        return ResolvedAddress(
            url: url,
            kind: .search(query: trimmed, engine: searchEngine)
        )
    }

    private static func directURL(from input: String) -> URL? {
        guard !input.contains(where: { $0.isWhitespace }) else { return nil }

        if input.caseInsensitiveCompare("about:blank") == .orderedSame {
            return URL(string: "about:blank")
        }

        // Only treat the prefix as an explicit scheme when it uses the standard
        // scheme separator. This avoids mistaking `localhost:8080` for a custom
        // `localhost` URL scheme.
        if input.contains("://"), let components = URLComponents(string: input) {
            guard let scheme = components.scheme?.lowercased(),
                  ["http", "https"].contains(scheme),
                  components.host != nil else {
                return nil
            }
            return components.url
        }

        // An @ in schemeless input is much more likely an email/search than a URL
        // containing credentials.
        guard !input.contains("@"),
              let components = URLComponents(string: "https://\(input)"),
              let host = components.host,
              looksLikeHost(host) else {
            return nil
        }
        return components.url
    }

    private static func looksLikeHost(_ host: String) -> Bool {
        let normalized = host.lowercased()
        if normalized == "localhost" { return true }
        if normalized.contains(":") { return true } // IPv6 literal

        let labels = normalized.split(separator: ".", omittingEmptySubsequences: false)
        if labels.count == 4,
           labels.allSatisfy({ label in
               guard let byte = UInt8(label) else { return false }
               return String(byte) == label || label == "0"
           }) {
            return true
        }

        guard labels.count >= 2,
              let topLevelDomain = labels.last,
              topLevelDomain.count >= 2,
              topLevelDomain.contains(where: \Character.isLetter) else {
            return false
        }
        return labels.allSatisfy { label in
            guard !label.isEmpty,
                  label.first != "-",
                  label.last != "-" else { return false }
            return label.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" }
        }
    }
}

/// Convenience namespace for UI code that does not need to retain a resolver.
public enum AddressResolver {
    public static func resolve(
        _ input: String,
        preferences: BrowserPreferences = BrowserPreferences()
    ) -> URL? {
        BrowserAddressResolver(searchEngine: preferences.searchEngine).resolve(input)
    }
}
