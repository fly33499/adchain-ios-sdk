import Foundation

/**
 * Configuration for feed display
 */
public struct FeedConfig: Codable {
    public let unitId: String
    public let title: String
    public let style: FeedStyle
    public let pageSize: Int
    public let enableInfiniteScroll: Bool
    public let enablePullToRefresh: Bool
    public let backgroundColor: String?
    public let itemSpacing: CGFloat
    
    public init(
        unitId: String,
        title: String = "Discover",
        style: FeedStyle = .card,
        pageSize: Int = 10,
        enableInfiniteScroll: Bool = true,
        enablePullToRefresh: Bool = true,
        backgroundColor: String? = nil,
        itemSpacing: CGFloat = 8
    ) {
        self.unitId = unitId
        self.title = title
        self.style = style
        self.pageSize = pageSize
        self.enableInfiniteScroll = enableInfiniteScroll
        self.enablePullToRefresh = enablePullToRefresh
        self.backgroundColor = backgroundColor
        self.itemSpacing = itemSpacing
    }
}

/**
 * Feed display styles
 */
public enum FeedStyle: String, Codable {
    case card = "CARD"
    case list = "LIST"
    case grid = "GRID"
}