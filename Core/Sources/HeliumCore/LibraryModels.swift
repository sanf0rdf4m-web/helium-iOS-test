import Foundation

public struct Bookmark: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var url: URL
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        url: URL,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.createdAt = createdAt
    }
}

public struct HistoryEntry: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var url: URL
    public var lastVisitedAt: Date
    public var visitCount: Int

    public init(
        id: UUID = UUID(),
        title: String,
        url: URL,
        lastVisitedAt: Date = Date(),
        visitCount: Int = 1
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.lastVisitedAt = lastVisitedAt
        self.visitCount = max(1, visitCount)
    }

    public mutating func recordVisit(at date: Date = Date(), title: String? = nil) {
        visitCount += 1
        lastVisitedAt = date
        if let title, !title.isEmpty {
            self.title = title
        }
    }
}
