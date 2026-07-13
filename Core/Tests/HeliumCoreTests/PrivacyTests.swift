import Foundation
import Testing
@testable import HeliumCore
#if canImport(WebKit)
@preconcurrency import WebKit
#endif

@Suite("Privacy settings and content blocker rules")
struct PrivacyTests {
    @Test func privacySettingsRoundTrip() throws {
        let original = PrivacySettings(
            shieldLevel: .aggressive,
            blockAds: false,
            blockTrackers: true,
            blockThirdPartyCookies: false,
            blockFingerprinting: true,
            blockScripts: true,
            upgradeConnections: false,
            sendGlobalPrivacyControl: false,
            sendDoNotTrack: true
        )
        let decoded = try JSONDecoder().decode(
            PrivacySettings.self,
            from: JSONEncoder().encode(original)
        )
        #expect(decoded == original)
    }

    @Test func missingSettingsUsePrivacyPreservingDefaults() throws {
        let settings = try JSONDecoder().decode(PrivacySettings.self, from: Data("{}".utf8))
        #expect(settings == PrivacySettings())
    }

    @Test func missingBrowserPreferencesUseDefaults() throws {
        let preferences = try JSONDecoder().decode(BrowserPreferences.self, from: Data("{}".utf8))
        #expect(preferences == BrowserPreferences())
    }

    @Test func offLevelProducesEmptyValidRuleList() throws {
        let json = try ContentBlockerRuleGenerator.makeJSON(
            settings: PrivacySettings(shieldLevel: .off),
            exceptions: ["example.com"]
        )
        #expect(json == "[]")
        _ = try JSONSerialization.jsonObject(with: Data(json.utf8))
    }

    @Test func standardRulesContainExpectedActions() throws {
        let rules = try decodedRules(settings: PrivacySettings())
        let actions = rules.compactMap { ($0["action"] as? [String: Any])?["type"] as? String }

        #expect(actions.contains("make-https"))
        #expect(actions.contains("block"))
        #expect(actions.contains("block-cookies"))
        #expect(!actions.contains("ignore-previous-rules"))
    }

    @Test func individualTogglesRemoveTheirRules() throws {
        let settings = PrivacySettings(
            blockAds: false,
            blockTrackers: false,
            blockThirdPartyCookies: false,
            blockFingerprinting: false,
            blockScripts: false,
            upgradeConnections: false
        )
        #expect(try decodedRules(settings: settings).isEmpty)
    }

    @Test func scriptBlockingAddsGlobalScriptRule() throws {
        let settings = PrivacySettings(
            blockAds: false,
            blockTrackers: false,
            blockThirdPartyCookies: false,
            blockFingerprinting: false,
            blockScripts: true,
            upgradeConnections: false
        )
        let rules = try decodedRules(settings: settings)
        #expect(rules.count == 1)
        let trigger = rules[0]["trigger"] as? [String: Any]
        #expect(trigger?["resource-type"] as? [String] == ["script"])
    }

    @Test func aggressiveModeAddsSocialWidgetRule() throws {
        var standard = PrivacySettings(
            blockAds: false,
            blockTrackers: false,
            blockThirdPartyCookies: false,
            blockFingerprinting: false,
            upgradeConnections: false
        )
        let standardCount = try decodedRules(settings: standard).count
        standard.shieldLevel = .aggressive
        let aggressiveCount = try decodedRules(settings: standard).count
        #expect(aggressiveCount > standardCount)
    }

    @Test func exceptionsAreNormalizedDeduplicatedAndPlacedLast() throws {
        let rules = try decodedRules(
            settings: PrivacySettings(),
            exceptions: ["Example.com", "https://www.example.com/a", " bad value ", ""]
        )
        let last = try #require(rules.last)
        let action = try #require(last["action"] as? [String: Any])
        let trigger = try #require(last["trigger"] as? [String: Any])

        #expect(action["type"] as? String == "ignore-previous-rules")
        #expect(trigger["if-domain"] as? [String] == ["example.com", "*.example.com"])
    }

    @Test func factoryAndGeneratorAgree() throws {
        let preferences = BrowserPreferences(privacy: PrivacySettings(blockScripts: true))
        #expect(
            try ContentBlockerRuleFactory.makeJSON(preferences: preferences)
                == ContentBlockerRuleGenerator.makeJSON(preferences: preferences)
        )
    }

#if canImport(WebKit)
    @Test @MainActor func generatedRulesCompileInWebKit() async throws {
        let identifier = "helium-core-tests-\(UUID().uuidString)"
        let json = try ContentBlockerRuleGenerator.makeJSON(
            settings: PrivacySettings(shieldLevel: .aggressive, blockScripts: true),
            exceptions: ["example.com"]
        )

        try await withCheckedThrowingContinuation { continuation in
            WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: identifier,
                encodedContentRuleList: json
            ) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        } as Void

        try await withCheckedThrowingContinuation { continuation in
            WKContentRuleListStore.default().removeContentRuleList(
                forIdentifier: identifier
            ) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        } as Void
    }
#endif

    private func decodedRules(
        settings: PrivacySettings,
        exceptions: [String] = []
    ) throws -> [[String: Any]] {
        let json = try ContentBlockerRuleGenerator.makeJSON(
            settings: settings,
            exceptions: exceptions
        )
        return try #require(
            JSONSerialization.jsonObject(with: Data(json.utf8)) as? [[String: Any]]
        )
    }
}
