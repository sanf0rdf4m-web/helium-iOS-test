import Foundation

public enum ShieldLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    case off
    case standard
    case aggressive

    public var id: String { rawValue }
}

/// Privacy controls modeled after browser shield controls. WebKit content rules
/// implement the network-facing subset; cookie and header policy can also be
/// consumed by the app's WKWebView configuration and navigation delegate.
public struct PrivacySettings: Codable, Equatable, Sendable {
    public var shieldLevel: ShieldLevel
    public var blockAds: Bool
    public var blockTrackers: Bool
    public var blockThirdPartyCookies: Bool
    public var blockFingerprinting: Bool
    public var blockScripts: Bool
    public var upgradeConnections: Bool
    public var sendGlobalPrivacyControl: Bool
    public var sendDoNotTrack: Bool

    public init(
        shieldLevel: ShieldLevel = .standard,
        blockAds: Bool = true,
        blockTrackers: Bool = true,
        blockThirdPartyCookies: Bool = true,
        blockFingerprinting: Bool = true,
        blockScripts: Bool = false,
        upgradeConnections: Bool = true,
        sendGlobalPrivacyControl: Bool = true,
        sendDoNotTrack: Bool = true
    ) {
        self.shieldLevel = shieldLevel
        self.blockAds = blockAds
        self.blockTrackers = blockTrackers
        self.blockThirdPartyCookies = blockThirdPartyCookies
        self.blockFingerprinting = blockFingerprinting
        self.blockScripts = blockScripts
        self.upgradeConnections = upgradeConnections
        self.sendGlobalPrivacyControl = sendGlobalPrivacyControl
        self.sendDoNotTrack = sendDoNotTrack
    }

    private enum CodingKeys: String, CodingKey {
        case shieldLevel
        case blockAds
        case blockTrackers
        case blockThirdPartyCookies
        case blockFingerprinting
        case blockScripts
        case upgradeConnections
        case sendGlobalPrivacyControl
        case sendDoNotTrack
    }

    /// Defaulted decoding keeps preferences compatible when new controls are
    /// added in a later app release.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        shieldLevel = try values.decodeIfPresent(ShieldLevel.self, forKey: .shieldLevel) ?? .standard
        blockAds = try values.decodeIfPresent(Bool.self, forKey: .blockAds) ?? true
        blockTrackers = try values.decodeIfPresent(Bool.self, forKey: .blockTrackers) ?? true
        blockThirdPartyCookies = try values.decodeIfPresent(Bool.self, forKey: .blockThirdPartyCookies) ?? true
        blockFingerprinting = try values.decodeIfPresent(Bool.self, forKey: .blockFingerprinting) ?? true
        blockScripts = try values.decodeIfPresent(Bool.self, forKey: .blockScripts) ?? false
        upgradeConnections = try values.decodeIfPresent(Bool.self, forKey: .upgradeConnections) ?? true
        sendGlobalPrivacyControl = try values.decodeIfPresent(Bool.self, forKey: .sendGlobalPrivacyControl) ?? true
        sendDoNotTrack = try values.decodeIfPresent(Bool.self, forKey: .sendDoNotTrack) ?? true
    }
}

public struct BrowserPreferences: Codable, Equatable, Sendable {
    public var searchEngine: SearchEngine
    public var privacy: PrivacySettings

    public init(
        searchEngine: SearchEngine = .google,
        privacy: PrivacySettings = PrivacySettings()
    ) {
        self.searchEngine = searchEngine
        self.privacy = privacy
    }

    private enum CodingKeys: String, CodingKey {
        case searchEngine
        case privacy
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        searchEngine = try values.decodeIfPresent(SearchEngine.self, forKey: .searchEngine) ?? .google
        privacy = try values.decodeIfPresent(PrivacySettings.self, forKey: .privacy) ?? PrivacySettings()
    }
}

public enum ContentBlockerRuleError: Error, Equatable, Sendable {
    case invalidJSONObject
    case invalidUTF8
}

/// Generates rules accepted by WKContentRuleListStore. The built-in set is a
/// compact privacy baseline, not a replacement for periodically updated filter
/// lists. Rules are deterministic so compiled lists can be cached by a settings hash.
public enum ContentBlockerRuleGenerator {
    public static func makeJSON(
        settings: PrivacySettings,
        exceptions: [String] = []
    ) throws -> String {
        let object = rules(settings: settings, exceptions: exceptions)
        guard JSONSerialization.isValidJSONObject(object) else {
            throw ContentBlockerRuleError.invalidJSONObject
        }
        let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        guard let json = String(data: data, encoding: .utf8) else {
            throw ContentBlockerRuleError.invalidUTF8
        }
        return json
    }

    public static func makeData(
        settings: PrivacySettings,
        exceptions: [String] = []
    ) throws -> Data {
        Data(try makeJSON(settings: settings, exceptions: exceptions).utf8)
    }

    public static func makeJSON(
        preferences: BrowserPreferences,
        exceptions: [String] = []
    ) throws -> String {
        try makeJSON(settings: preferences.privacy, exceptions: exceptions)
    }

    private static func rules(
        settings: PrivacySettings,
        exceptions: [String]
    ) -> [[String: Any]] {
        guard settings.shieldLevel != .off else { return [] }
        var result: [[String: Any]] = []

        if settings.upgradeConnections {
            result.append(rule(urlFilter: "^http://", action: "make-https"))
        }

        if settings.blockAds {
            result.append(contentsOf: blockingRules(
                domains: [
                    "doubleclick.net", "googlesyndication.com", "googleadservices.com",
                    "adnxs.com", "amazon-adsystem.com", "adsrvr.org", "criteo.com",
                    "taboola.com", "outbrain.com"
                ],
                resourceTypes: ["image", "style-sheet", "script", "font", "media", "raw", "popup", "svg-document"]
            ))
            result.append(cssHidingRule(
                selector: "#onetrust-banner-sdk, #onetrust-consent-sdk, .qc-cmp2-container, .fc-consent-root, .didomi-popup-container, .truste_overlay, .cookie-consent-banner"
            ))
        }

        if settings.blockTrackers {
            result.append(contentsOf: blockingRules(
                domains: [
                    "google-analytics.com", "googletagmanager.com", "scorecardresearch.com",
                    "segment.io", "mixpanel.com", "hotjar.com", "fullstory.com",
                    "clarity.ms", "branch.io"
                ],
                resourceTypes: ["image", "script", "raw"]
            ))
        }

        if settings.blockFingerprinting {
            result.append(contentsOf: blockingRules(
                domains: ["fingerprint.com", "fingerprintjs.com", "fpjs.io", "deviceatlas.com"],
                resourceTypes: ["script", "raw"]
            ))
        }

        if settings.shieldLevel == .aggressive {
            result.append(contentsOf: blockingRules(
                domains: [
                    "connect.facebook.net", "platform.twitter.com", "platform.linkedin.com",
                    "widgets.pinterest.com", "disqus.com"
                ],
                resourceTypes: ["script", "raw"]
            ))
        }

        if settings.blockThirdPartyCookies {
            result.append(rule(
                urlFilter: ".*",
                action: "block-cookies",
                loadTypes: ["third-party"]
            ))
        }

        if settings.blockScripts {
            result.append(rule(
                urlFilter: ".*",
                action: "block",
                resourceTypes: ["script"]
            ))
        }

        let domains = normalizedExceptionDomains(exceptions)
        if !domains.isEmpty {
            result.append([
                "trigger": [
                    "url-filter": ".*",
                    "if-domain": domains.flatMap { [$0, "*.\($0)"] }
                ],
                "action": ["type": "ignore-previous-rules"]
            ])
        }
        return result
    }

    private static func rule(
        urlFilter: String,
        action: String,
        resourceTypes: [String]? = nil,
        loadTypes: [String]? = nil
    ) -> [String: Any] {
        var trigger: [String: Any] = ["url-filter": urlFilter]
        if let resourceTypes { trigger["resource-type"] = resourceTypes }
        if let loadTypes { trigger["load-type"] = loadTypes }
        return ["trigger": trigger, "action": ["type": action]]
    }

    private static func cssHidingRule(selector: String) -> [String: Any] {
        [
            "trigger": ["url-filter": ".*"],
            "action": ["type": "css-display-none", "selector": selector]
        ]
    }

    /// WebKit's content-blocker regex dialect intentionally does not support
    /// alternation, so domain groups must be emitted as separate rules.
    private static func blockingRules(
        domains: [String],
        resourceTypes: [String]
    ) -> [[String: Any]] {
        domains.map { domain in
            let escapedDomain = domain.replacingOccurrences(of: ".", with: #"\."#)
            return rule(
                urlFilter: #"^https?://([^/]+\.)?"# + escapedDomain + "/",
                action: "block",
                resourceTypes: resourceTypes
            )
        }
    }

    private static func normalizedExceptionDomains(_ domains: [String]) -> [String] {
        var seen = Set<String>()
        return domains.compactMap { rawDomain in
            let candidate = rawDomain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !candidate.isEmpty else { return nil }
            let withScheme = candidate.contains("://") ? candidate : "https://\(candidate)"
            guard let host = URLComponents(string: withScheme)?.host,
                  host.contains("." ) || host == "localhost" else { return nil }
            let domain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
            guard seen.insert(domain).inserted else { return nil }
            return domain
        }.sorted()
    }
}

/// App-friendly spelling retained alongside the more focused generator name.
public enum ContentBlockerRuleFactory {
    public static func makeJSON(
        preferences: BrowserPreferences,
        exceptions: [String] = []
    ) throws -> String {
        try ContentBlockerRuleGenerator.makeJSON(
            settings: preferences.privacy,
            exceptions: exceptions
        )
    }
}
