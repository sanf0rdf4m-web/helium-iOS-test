import Foundation
import Testing
@testable import HeliumCore

@Suite("Address resolution")
struct AddressResolutionTests {
    @Test func emptyInputHasNoDestination() {
        #expect(BrowserAddressResolver().resolve("  \n ") == nil)
    }

    @Test func explicitHTTPSURLIsPreserved() {
        let result = BrowserAddressResolver().resolveDetailed("https://example.com/path?q=one")
        #expect(result?.url.absoluteString == "https://example.com/path?q=one")
        #expect(result?.kind == .direct)
    }

    @Test func schemelessDomainGetsHTTPS() {
        #expect(
            BrowserAddressResolver().resolve("example.com/articles/1")?.absoluteString
                == "https://example.com/articles/1"
        )
    }

    @Test func localhostAndIPAddressesAreNavigable() {
        #expect(
            BrowserAddressResolver().resolve("localhost:8080/health")?.absoluteString
                == "https://localhost:8080/health"
        )
        #expect(
            BrowserAddressResolver().resolve("192.168.1.8:3000")?.absoluteString
                == "https://192.168.1.8:3000"
        )
    }

    @Test func invalidNumericAddressBecomesSearch() {
        let result = BrowserAddressResolver().resolveDetailed("999.999.999.999")
        #expect(result?.kind == .search(query: "999.999.999.999", engine: .google))
    }

    @Test func wordsAndEmailsBecomeSearches() throws {
        let resolver = BrowserAddressResolver(searchEngine: .duckDuckGo)
        let words = try #require(resolver.resolveDetailed("helium browser ios"))
        let email = resolver.resolveDetailed("hello@example.com")

        #expect(words.kind == .search(query: "helium browser ios", engine: .duckDuckGo))
        #expect(
            URLComponents(url: words.url, resolvingAgainstBaseURL: false)?.queryItems?.first?.value
                == "helium browser ios"
        )
        #expect(email?.kind == .search(query: "hello@example.com", engine: .duckDuckGo))
    }

    @Test func unsupportedSchemesBecomeSearches() {
        let result = BrowserAddressResolver().resolveDetailed("javascript:alert(1)")
        #expect(result?.kind == .search(query: "javascript:alert(1)", engine: .google))
    }

    @Test func aboutBlankIsAllowed() {
        #expect(BrowserAddressResolver().resolve("about:blank")?.absoluteString == "about:blank")
    }

    @Test func knownBangIsResolvedLocallyAndCaseInsensitively() throws {
        let result = try #require(BrowserAddressResolver().resolveDetailed("!YT swift concurrency"))
        #expect(result.kind == .bang(key: "yt", query: "swift concurrency"))
        #expect(result.url.host == "www.youtube.com")
        #expect(
            URLComponents(url: result.url, resolvingAgainstBaseURL: false)?.queryItems?.first?.value
                == "swift concurrency"
        )
    }

    @Test func bareBangOpensItsHomepage() {
        #expect(
            BrowserAddressResolver().resolve("!w")?.absoluteString
                == "https://en.wikipedia.org/"
        )
    }

    @Test func unknownBangFallsBackToSearchUnchanged() {
        let result = BrowserAddressResolver(searchEngine: .brave).resolveDetailed("!unknown query")
        #expect(result?.kind == .search(query: "!unknown query", engine: .brave))
    }

    @Test func bangQueryCannotInjectAnotherParameter() throws {
        let result = try #require(BrowserAddressResolver().resolve("!g cats&safe=off"))
        let components = URLComponents(url: result, resolvingAgainstBaseURL: false)
        #expect(components?.queryItems?.count == 1)
        #expect(components?.queryItems?.first?.value == "cats&safe=off")
    }

    @Test func allSearchProvidersRoundTripQueryAsOneItem() throws {
        for engine in SearchEngine.allCases {
            let url = try #require(engine.searchURL(for: "a&b = c"))
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            #expect(items == [URLQueryItem(name: "q", value: "a&b = c")])
        }
    }

    @Test func preferencesSelectSearchEngine() {
        let preferences = BrowserPreferences(searchEngine: .ecosia)
        #expect(
            AddressResolver.resolve("tree planting", preferences: preferences)?.host
                == "www.ecosia.org"
        )
    }
}
