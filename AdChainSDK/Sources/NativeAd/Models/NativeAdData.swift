import Foundation

/// Native Ad data model that can be used independently from UI components
/// This allows complete customization of how ads are displayed
public struct NativeAdData: Codable, Equatable {
    public let id: String
    public let title: String
    public let description: String
    public let imageUrl: String
    public let iconUrl: String?
    public let ctaText: String // Call-to-action text: "Install", "Learn More", etc.
    public let landingUrl: String
    public let sponsorName: String?
    public let rating: Float?
    public let reviewCount: Int?
    public let price: String?
    public let metadata: [String: String]?
    
    // Tracking URLs
    public let impressionTrackingUrl: String?
    public let clickTrackingUrl: String?
    
    // Ad metadata
    public let adType: AdType
    public let isVideo: Bool
    public let videoUrl: String?
    public let videoDuration: Int? // in seconds
    
    // Timestamp
    public let fetchedAt: Date
    
    public init(
        id: String,
        title: String,
        description: String,
        imageUrl: String,
        iconUrl: String? = nil,
        ctaText: String,
        landingUrl: String,
        sponsorName: String? = nil,
        rating: Float? = nil,
        reviewCount: Int? = nil,
        price: String? = nil,
        metadata: [String: String]? = nil,
        impressionTrackingUrl: String? = nil,
        clickTrackingUrl: String? = nil,
        adType: AdType = .display,
        isVideo: Bool = false,
        videoUrl: String? = nil,
        videoDuration: Int? = nil,
        fetchedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.imageUrl = imageUrl
        self.iconUrl = iconUrl
        self.ctaText = ctaText
        self.landingUrl = landingUrl
        self.sponsorName = sponsorName
        self.rating = rating
        self.reviewCount = reviewCount
        self.price = price
        self.metadata = metadata
        self.impressionTrackingUrl = impressionTrackingUrl
        self.clickTrackingUrl = clickTrackingUrl
        self.adType = adType
        self.isVideo = isVideo
        self.videoUrl = videoUrl
        self.videoDuration = videoDuration
        self.fetchedAt = fetchedAt
    }
    
    /// Check if this ad data is still fresh (not expired)
    /// Default expiry is 1 hour
    public func isFresh(expiryInterval: TimeInterval = 3600) -> Bool {
        return Date().timeIntervalSince(fetchedAt) < expiryInterval
    }
    
    /// Convert to a dictionary for analytics tracking
    public func toAnalyticsDict() -> [String: Any] {
        return [
            "ad_id": id,
            "ad_type": adType.rawValue,
            "sponsor": sponsorName ?? "unknown",
            "cta_text": ctaText,
            "is_video": isVideo
        ]
    }
}

/// Types of native ads
public enum AdType: String, Codable, CaseIterable {
    case display = "DISPLAY"        // Standard display ad
    case video = "VIDEO"            // Video ad
    case appInstall = "APP_INSTALL" // App installation ad
    case content = "CONTENT"        // Content recommendation
    case product = "PRODUCT"        // E-commerce product ad
    case custom = "CUSTOM"          // Custom type
}

/// Configuration for loading native ads
public struct NativeAdRequest {
    public let unitId: String
    public let count: Int
    public let adTypes: [AdType]
    public let includeVideo: Bool
    public let targetingParams: [String: String]?
    
    public init(
        unitId: String,
        count: Int = 1,
        adTypes: [AdType] = [.display],
        includeVideo: Bool = false,
        targetingParams: [String: String]? = nil
    ) {
        self.unitId = unitId
        self.count = count
        self.adTypes = adTypes
        self.includeVideo = includeVideo
        self.targetingParams = targetingParams
    }
}

/// Response wrapper for native ads
public struct NativeAdResponse: Codable {
    public let ads: [NativeAdData]
    public let requestId: String
    public let hasMore: Bool
    public let nextPageToken: String?
    
    public init(
        ads: [NativeAdData],
        requestId: String,
        hasMore: Bool = false,
        nextPageToken: String? = nil
    ) {
        self.ads = ads
        self.requestId = requestId
        self.hasMore = hasMore
        self.nextPageToken = nextPageToken
    }
}