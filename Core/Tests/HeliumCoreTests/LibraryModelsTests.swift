import Foundation
import Testing
@testable import HeliumCore

@Suite("Bookmark and history models")
struct LibraryModelsTests {
    @Test func bookmarkCodableRoundTrip() throws {
        let bookmark = Bookmark(
            id: UUID(uuidString: "71C65FC9-E35B-4250-BDE4-8B9B7C3D9FB4")!,
            title: "Helium",
            url: URL(string: "https://example.com/")!,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let decoded = try JSONDecoder().decode(
            Bookmark.self,
            from: JSONEncoder().encode(bookmark)
        )
        #expect(decoded == bookmark)
    }

    @Test func historyEntryClampsInitialVisitCount() {
        let entry = HistoryEntry(
            title: "Example",
            url: URL(string: "https://example.com/")!,
            visitCount: -4
        )
        #expect(entry.visitCount == 1)
    }

    @Test func recordingVisitUpdatesCountDateAndNonemptyTitle() {
        let firstDate = Date(timeIntervalSince1970: 100)
        let secondDate = Date(timeIntervalSince1970: 200)
        var entry = HistoryEntry(
            title: "Old",
            url: URL(string: "https://example.com/")!,
            lastVisitedAt: firstDate
        )

        entry.recordVisit(at: secondDate, title: "New")
        #expect(entry.visitCount == 2)
        #expect(entry.lastVisitedAt == secondDate)
        #expect(entry.title == "New")

        entry.recordVisit(at: Date(timeIntervalSince1970: 300), title: "")
        #expect(entry.visitCount == 3)
        #expect(entry.title == "New")
    }

    @Test func historyEntryCodableRoundTrip() throws {
        let history = HistoryEntry(
            id: UUID(uuidString: "EE069EA7-4BE7-4819-A38F-952F66F21DB2")!,
            title: "Example",
            url: URL(string: "https://example.com/page")!,
            lastVisitedAt: Date(timeIntervalSince1970: 500),
            visitCount: 7
        )
        let decoded = try JSONDecoder().decode(
            HistoryEntry.self,
            from: JSONEncoder().encode(history)
        )
        #expect(decoded == history)
    }
}
