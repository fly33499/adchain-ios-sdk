import Foundation

/// Loader for native ads that provides data without UI components
/// This allows developers to create custom UI for displaying ads
public class NativeAdLoader {
    
    private let apiClient: ApiClient
    private let tracker: NativeAdTracker
    private let queue = DispatchQueue(label: "com.adchain.nativead.loader", attributes: .concurrent)
    
    // Cache for loaded ads
    private var adCache = [String: CachedAds]()
    
    // Preload timer
    private var preloadTimer: Timer?
    private var preloadRequests = [NativeAdRequest]()
    
    internal init(
        apiClient: ApiClient,
        tracker: NativeAdTracker = NativeAdTrackerImpl()
    ) {
        self.apiClient = apiClient
        self.tracker = tracker
    }
    
    /// Load native ads for the specified unit
    public func loadAds(request: NativeAdRequest) async throws -> NativeAdResponse {
        Logger.shared.log("Loading ads for unit: \(request.unitId), count: \(request.count)", level: .debug)
        
        // Check cache first
        if let cachedAds = getCachedAds(unitId: request.unitId),
           cachedAds.isFresh(),
           cachedAds.ads.count >= request.count {
            Logger.shared.log("Returning \(request.count) cached ads", level: .debug)
            return NativeAdResponse(
                ads: Array(cachedAds.ads.prefix(request.count)),
                requestId: cachedAds.requestId,
                hasMore: cachedAds.ads.count > request.count
            )
        }
        
        // Fetch from server
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.fetchCarouselAds(unitId: request.unitId, count: request.count) { [weak self] result in
                guard let self = self else {
                    continuation.resume(throwing: AdChainError.unknown(message: "Loader deallocated", underlyingError: nil))
                    return
                }
                
                switch result {
                case .success(let carouselAds):
                    let nativeAds = carouselAds.map { $0.toNativeAdData() }
                    let requestId = self.generateRequestId()
                    
                    // Update cache
                    self.queue.async(flags: .barrier) {
                        self.adCache[request.unitId] = CachedAds(
                            ads: nativeAds,
                            requestId: requestId,
                            timestamp: Date()
                        )
                    }
                    
                    Logger.shared.log("Loaded \(nativeAds.count) ads from server", level: .debug)
                    
                    let response = NativeAdResponse(
                        ads: nativeAds,
                        requestId: requestId,
                        hasMore: false
                    )
                    continuation.resume(returning: response)
                    
                case .failure(let error):
                    Logger.shared.log("Failed to load ads: \(error)", level: .error)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Load a single native ad
    public func loadAd(unitId: String) async throws -> NativeAdData? {
        let request = NativeAdRequest(unitId: unitId, count: 1)
        let response = try await loadAds(request: request)
        return response.ads.first
    }
    
    /// Preload ads for faster display
    public func preloadAds(request: NativeAdRequest) async {
        Logger.shared.log("Preloading ads for unit: \(request.unitId)", level: .debug)
        
        do {
            _ = try await loadAds(request: request)
            Logger.shared.log("Preloaded ads for unit: \(request.unitId)", level: .debug)
        } catch {
            Logger.shared.log("Failed to preload ads: \(error)", level: .error)
        }
    }
    
    /// Start automatic preloading for multiple ad units
    public func startPreloading(requests: [NativeAdRequest], interval: TimeInterval = 300) {
        stopPreloading()
        
        preloadRequests = requests
        
        // Initial preload
        Task {
            for request in requests {
                await preloadAds(request: request)
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds between preloads
            }
        }
        
        // Schedule periodic preloading
        preloadTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task {
                for request in self.preloadRequests {
                    await self.preloadAds(request: request)
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                }
            }
        }
        
        Logger.shared.log("Started preloading for \(requests.count) units", level: .debug)
    }
    
    /// Stop automatic preloading
    public func stopPreloading() {
        preloadTimer?.invalidate()
        preloadTimer = nil
        preloadRequests.removeAll()
        Logger.shared.log("Stopped preloading", level: .debug)
    }
    
    /// Get cached ads for a unit
    public func getCachedAds(unitId: String) -> CachedAds? {
        return queue.sync {
            adCache[unitId]?.isFresh() == true ? adCache[unitId] : nil
        }
    }
    
    /// Clear all cached ads
    public func clearCache() {
        queue.async(flags: .barrier) { [weak self] in
            self?.adCache.removeAll()
        }
        Logger.shared.log("Cleared ad cache", level: .debug)
    }
    
    /// Clear cached ads for a specific unit
    public func clearCache(unitId: String) {
        queue.async(flags: .barrier) { [weak self] in
            self?.adCache.removeValue(forKey: unitId)
        }
        Logger.shared.log("Cleared cache for unit: \(unitId)", level: .debug)
    }
    
    /// Track impression for an ad
    public func trackImpression(ad: NativeAdData) {
        tracker.trackImpression(ad: ad)
    }
    
    /// Track click for an ad
    public func trackClick(ad: NativeAdData) {
        tracker.trackClick(ad: ad)
    }
    
    /// Track conversion for an ad
    public func trackConversion(ad: NativeAdData) {
        tracker.trackConversion(ad: ad)
    }
    
    /// Track video start for an ad
    public func trackVideoStart(ad: NativeAdData) {
        tracker.trackVideoStart(ad: ad)
    }
    
    /// Track video complete for an ad
    public func trackVideoComplete(ad: NativeAdData) {
        tracker.trackVideoComplete(ad: ad)
    }
    
    /// Destroy the loader and clean up resources
    public func destroy() {
        stopPreloading()
        clearCache()
    }
    
    private func generateRequestId() -> String {
        return "req_\(Date().timeIntervalSince1970)_\(Int.random(in: 0..<10000))"
    }
    
    deinit {
        destroy()
    }
}

/// Cached ads data
public struct CachedAds {
    public let ads: [NativeAdData]
    public let requestId: String
    public let timestamp: Date
    public let ttl: TimeInterval
    
    public init(
        ads: [NativeAdData],
        requestId: String,
        timestamp: Date = Date(),
        ttl: TimeInterval = 3600 // 1 hour default
    ) {
        self.ads = ads
        self.requestId = requestId
        self.timestamp = timestamp
        self.ttl = ttl
    }
    
    public func isFresh() -> Bool {
        return Date().timeIntervalSince(timestamp) < ttl
    }
    
    public func getRemainingTTL() -> TimeInterval {
        let elapsed = Date().timeIntervalSince(timestamp)
        return max(0, ttl - elapsed)
    }
}

// MARK: - Helper Extensions

private extension CarouselAdResponse {
    func toNativeAdData() -> NativeAdData {
        return NativeAdData(
            id: id,
            title: title,
            description: description ?? "",
            imageUrl: imageUrl,
            iconUrl: nil, // Will be added when API supports it
            ctaText: "Learn More", // Default CTA, should come from API
            landingUrl: landingUrl,
            sponsorName: nil, // Will be added when API supports it
            rating: nil,
            reviewCount: nil,
            price: nil,
            metadata: metadata?.compactMapValues { "\($0)" },
            impressionTrackingUrl: nil, // Will be added when API supports it
            clickTrackingUrl: nil, // Will be added when API supports it
            adType: .display,
            isVideo: false,
            videoUrl: nil,
            videoDuration: nil
        )
    }
}