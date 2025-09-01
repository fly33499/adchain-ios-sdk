import UIKit

public protocol AdchainCarouselProtocol {
    func createCarousel(
        in container: UIView,
        config: CarouselConfig,
        delegate: CarouselDelegate?
    ) -> CarouselView
}

public protocol CarouselView: UIView {
    func load()
    func refresh()
    func pause()
    func resume()
    func destroy()
    var isLoading: Bool { get }
    var itemCount: Int { get }
}

public struct CarouselConfig {
    public let unitId: String
    public let itemCount: Int
    public let autoScroll: Bool
    public let scrollInterval: TimeInterval
    public let showLoadingIndicator: Bool
    public let enableInfiniteScroll: Bool
    
    public init(
        unitId: String,
        itemCount: Int = 5,
        autoScroll: Bool = false,
        scrollInterval: TimeInterval = 5.0,
        showLoadingIndicator: Bool = true,
        enableInfiniteScroll: Bool = false
    ) {
        self.unitId = unitId
        self.itemCount = itemCount
        self.autoScroll = autoScroll
        self.scrollInterval = scrollInterval
        self.showLoadingIndicator = showLoadingIndicator
        self.enableInfiniteScroll = enableInfiniteScroll
    }
}

public protocol CarouselDelegate: AnyObject {
    func carouselDidLoad(itemCount: Int)
    func carousel(didFailToLoadWithError error: AdchainError)
    func carousel(didSelectItemAt position: Int, item: CarouselItem)
    func carousel(didImpressionItemAt position: Int, item: CarouselItem)
    func carouselDidRefresh()
}

public struct CarouselItem {
    public let id: String
    public let title: String
    public let description: String?
    public let imageUrl: String
    public let landingUrl: String
    public let metadata: [String: Any]?
}