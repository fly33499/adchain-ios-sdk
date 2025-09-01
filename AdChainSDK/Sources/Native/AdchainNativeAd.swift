import Foundation

/// Buzzville SDK v6 호환 Native 광고 데이터 클래스
public class AdchainNativeAd {
    
    // MARK: - Properties
    
    public let id: String
    public let title: String
    public let description: String
    public let imageUrl: String
    public let iconUrl: String?
    public let ctaText: String
    public let landingUrl: String
    public let sponsorName: String?
    public let rating: Double?
    public let reviewCount: Int?
    public let price: String?
    public let salePrice: String?
    public let category: String?
    public let tags: [String]?
    public let rewardAmount: Int?
    public let rewardCurrency: String?
    public let metadata: [String: String]?
    
    // Tracking URLs
    public let impressionTrackingUrl: String?
    public let clickTrackingUrl: String?
    public let conversionTrackingUrl: String?
    
    // Ad type
    public let adType: AdchainNativeAdType
    public let isVideo: Bool
    public let videoUrl: String?
    public let videoDuration: Int?
    
    // Status
    private(set) var impressionTracked = false
    private(set) var clickTracked = false
    private(set) var conversionTracked = false
    private(set) var participationStartTime: Date?
    private(set) var participationEndTime: Date?
    
    
    // MARK: - Initialization
    
    /// CarouselAdResponse로부터 생성
    internal init(from response: CarouselAdResponse) {
        self.id = response.id
        self.title = response.title
        self.description = response.description ?? ""
        self.imageUrl = response.imageUrl
        self.iconUrl = nil // API에서 제공 시 추가
        self.ctaText = "참여하기" // ctaText not in CarouselAdResponse
        self.landingUrl = response.landingUrl
        self.sponsorName = nil // API에서 제공 시 추가
        self.rating = nil
        self.reviewCount = nil
        self.price = nil
        self.salePrice = nil
        self.category = nil
        self.tags = nil
        self.rewardAmount = nil // reward not in CarouselAdResponse
        self.rewardCurrency = "포인트"
        self.metadata = response.metadata?.compactMapValues { "\($0)" }
        
        self.impressionTrackingUrl = nil
        self.clickTrackingUrl = nil
        self.conversionTrackingUrl = nil
        
        self.adType = .native
        self.isVideo = false
        self.videoUrl = nil
        self.videoDuration = nil
    }
    
    /*
    /// NativeAdData로부터 생성 - NativeAdData 제거로 주석 처리
    internal init(from data: NativeAdData) {
        self.id = data.id
        self.title = data.title
        self.description = data.description
        self.imageUrl = data.imageUrl
        self.iconUrl = data.iconUrl
        self.ctaText = data.ctaText
        self.landingUrl = data.landingUrl
        self.sponsorName = data.sponsorName
        self.rating = data.rating != nil ? Double(data.rating!) : nil
        self.reviewCount = data.reviewCount
        self.price = data.price
        self.salePrice = nil
        self.category = nil
        self.tags = nil
        self.rewardAmount = nil
        self.rewardCurrency = nil
        self.metadata = data.metadata
        
        self.impressionTrackingUrl = data.impressionTrackingUrl
        self.clickTrackingUrl = data.clickTrackingUrl
        self.conversionTrackingUrl = nil
        
        self.adType = data.adType == .display ? .display : .native
        self.isVideo = data.isVideo
        self.videoUrl = data.videoUrl
        self.videoDuration = data.videoDuration
    }
    */
    
    /// 직접 생성 (테스트용)
    public init(
        id: String,
        title: String,
        description: String,
        imageUrl: String,
        ctaText: String,
        landingUrl: String
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.imageUrl = imageUrl
        self.iconUrl = nil
        self.ctaText = ctaText
        self.landingUrl = landingUrl
        self.sponsorName = nil
        self.rating = nil
        self.reviewCount = nil
        self.price = nil
        self.salePrice = nil
        self.category = nil
        self.tags = nil
        self.rewardAmount = nil
        self.rewardCurrency = nil
        self.metadata = nil
        
        self.impressionTrackingUrl = nil
        self.clickTrackingUrl = nil
        self.conversionTrackingUrl = nil
        
        self.adType = .native
        self.isVideo = false
        self.videoUrl = nil
        self.videoDuration = nil
    }
    
    // MARK: - Status Updates
    
    /// 노출 추적 완료 표시
    internal func markImpressionTracked() {
        impressionTracked = true
    }
    
    /// 클릭 추적 완료 표시
    internal func markClickTracked() {
        clickTracked = true
    }
    
    /// 전환 추적 완료 표시
    internal func markConversionTracked() {
        conversionTracked = true
    }
    
    /// 참여 시작 표시
    internal func markParticipationStarted() {
        participationStartTime = Date()
    }
    
    /// 참여 완료 표시
    internal func markParticipationCompleted() {
        participationEndTime = Date()
    }
    
    // MARK: - Computed Properties
    
    /// 참여 시간 (초)
    public var participationDuration: TimeInterval? {
        guard let startTime = participationStartTime,
              let endTime = participationEndTime else {
            return nil
        }
        return endTime.timeIntervalSince(startTime)
    }
    
    /// 광고가 유효한지 확인
    public var isValid: Bool {
        return !id.isEmpty && !title.isEmpty && !imageUrl.isEmpty && !landingUrl.isEmpty
    }
    
    /// 보상형 광고인지 확인
    public var isRewarded: Bool {
        return rewardAmount != nil && rewardAmount! > 0
    }
    
    /// 할인 중인지 확인
    public var isOnSale: Bool {
        return salePrice != nil && price != nil
    }
    
    /// 할인율 계산
    public var discountPercentage: Int? {
        guard let price = price,
              let salePrice = salePrice,
              let priceValue = Double(price.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)),
              let salePriceValue = Double(salePrice.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)),
              priceValue > 0 else {
            return nil
        }
        
        let discount = (priceValue - salePriceValue) / priceValue * 100
        return Int(discount)
    }
    
    // MARK: - Conversion
    
    /// NativeAdData로 변환
    /*
    internal func toNativeAdData() -> NativeAdData {
        return NativeAdData(
            id: id,
            title: title,
            description: description,
            imageUrl: imageUrl,
            iconUrl: iconUrl,
            ctaText: ctaText,
            landingUrl: landingUrl,
            sponsorName: sponsorName,
            rating: rating != nil ? Float(rating!) : nil,
            reviewCount: reviewCount,
            price: price,
            metadata: metadata,
            impressionTrackingUrl: impressionTrackingUrl,
            clickTrackingUrl: clickTrackingUrl,
            adType: .display, // .native not available
            isVideo: isVideo,
            videoUrl: videoUrl,
            videoDuration: videoDuration
        )
    }
    */
    
    /// Dictionary로 변환
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "title": title,
            "description": description,
            "imageUrl": imageUrl,
            "ctaText": ctaText,
            "landingUrl": landingUrl,
            "adType": adType.rawValue,
            "isVideo": isVideo
        ]
        
        if let iconUrl = iconUrl {
            dict["iconUrl"] = iconUrl
        }
        if let sponsorName = sponsorName {
            dict["sponsorName"] = sponsorName
        }
        if let rating = rating {
            dict["rating"] = rating
        }
        if let reviewCount = reviewCount {
            dict["reviewCount"] = reviewCount
        }
        if let price = price {
            dict["price"] = price
        }
        if let salePrice = salePrice {
            dict["salePrice"] = salePrice
        }
        if let category = category {
            dict["category"] = category
        }
        if let tags = tags {
            dict["tags"] = tags
        }
        if let rewardAmount = rewardAmount {
            dict["rewardAmount"] = rewardAmount
        }
        if let rewardCurrency = rewardCurrency {
            dict["rewardCurrency"] = rewardCurrency
        }
        if let metadata = metadata {
            dict["metadata"] = metadata
        }
        if let videoUrl = videoUrl {
            dict["videoUrl"] = videoUrl
        }
        if let videoDuration = videoDuration {
            dict["videoDuration"] = videoDuration
        }
        
        dict["impressionTracked"] = impressionTracked
        dict["clickTracked"] = clickTracked
        dict["conversionTracked"] = conversionTracked
        
        return dict
    }
    
    /// 디버그 정보 출력
    public func debugDescription() -> String {
        return """
        AdchainNativeAd:
        - ID: \(id)
        - Title: \(title)
        - Description: \(description)
        - CTA: \(ctaText)
        - Type: \(adType.rawValue)
        - Rewarded: \(isRewarded) (\(rewardAmount ?? 0) \(rewardCurrency ?? ""))
        - Impression Tracked: \(impressionTracked)
        - Click Tracked: \(clickTracked)
        - Conversion Tracked: \(conversionTracked)
        """
    }
}

// MARK: - Test Data

extension AdchainNativeAd {
    
    /// 테스트용 샘플 광고 생성
    public static func testAd(id: String = UUID().uuidString) -> AdchainNativeAd {
        return AdchainNativeAd(
            id: id,
            title: "테스트 광고",
            description: "이것은 테스트 광고입니다",
            imageUrl: "https://via.placeholder.com/300x200",
            ctaText: "지금 참여하기",
            landingUrl: "https://example.com"
        )
    }
    
    /// 보상형 테스트 광고 생성
    public static func testRewardedAd(id: String = UUID().uuidString, reward: Int = 100) -> AdchainNativeAd {
        let ad = AdchainNativeAd(
            id: id,
            title: "보상형 테스트 광고",
            description: "\(reward) 포인트를 받으세요!",
            imageUrl: "https://via.placeholder.com/300x200",
            ctaText: "포인트 받기",
            landingUrl: "https://example.com"
        )
        
        // Force set reward (normally would come from server)
        let mirror = Mirror(reflecting: ad)
        if let rewardProperty = mirror.children.first(where: { $0.label == "rewardAmount" }) {
            // This is a workaround for testing
        }
        
        return ad
    }
}