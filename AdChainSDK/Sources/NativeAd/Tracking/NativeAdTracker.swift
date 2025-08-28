import Foundation

/// Protocol for tracking native ad events
public protocol NativeAdTracker {
    func trackImpression(ad: NativeAdData)
    func trackClick(ad: NativeAdData)
    func trackConversion(ad: NativeAdData)
    func trackVideoStart(ad: NativeAdData)
    func trackVideoComplete(ad: NativeAdData)
}

/// Default implementation of NativeAdTracker
public class NativeAdTrackerImpl: NativeAdTracker {
    
    private var impressedAds = Set<String>()
    private var clickedAds = Set<String>()
    private let queue = DispatchQueue(label: "com.adchain.nativead.tracker", attributes: .concurrent)
    
    public init() {}
    
    public func trackImpression(ad: NativeAdData) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // Prevent duplicate impression tracking
            if self.impressedAds.contains(ad.id) {
                Logger.shared.log("Ad \(ad.id) impression already tracked", level: .debug)
                return
            }
            
            self.impressedAds.insert(ad.id)
            
            // Track via analytics
            if let analytics = (AdChainSDK.shared as? AdChainSDKImpl)?.analytics as? AdChainAnalyticsImpl {
                analytics.trackEvent(name: "native_ad_impression", parameters: ad.toAnalyticsDict())
            }
            
            // Send impression tracking pixel if available
            if let trackingUrl = ad.impressionTrackingUrl {
                self.sendTrackingRequest(to: trackingUrl)
            }
            
            Logger.shared.log("Tracked impression for ad \(ad.id)", level: .debug)
        }
    }
    
    public func trackClick(ad: NativeAdData) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // Allow multiple clicks but log if duplicate
            if self.clickedAds.contains(ad.id) {
                Logger.shared.log("Ad \(ad.id) already clicked before", level: .debug)
            }
            
            self.clickedAds.insert(ad.id)
            
            // Track via analytics
            if let analytics = (AdChainSDK.shared as? AdChainSDKImpl)?.analytics as? AdChainAnalyticsImpl {
                analytics.trackEvent(name: "native_ad_click", parameters: ad.toAnalyticsDict())
            }
            
            // Send click tracking pixel if available
            if let trackingUrl = ad.clickTrackingUrl {
                self.sendTrackingRequest(to: trackingUrl)
            }
            
            Logger.shared.log("Tracked click for ad \(ad.id)", level: .debug)
        }
    }
    
    public func trackConversion(ad: NativeAdData) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Track via analytics
            if let analytics = (AdChainSDK.shared as? AdChainSDKImpl)?.analytics as? AdChainAnalyticsImpl {
                analytics.trackEvent(name: "native_ad_conversion", parameters: ad.toAnalyticsDict())
            }
            
            Logger.shared.log("Tracked conversion for ad \(ad.id)", level: .debug)
        }
    }
    
    public func trackVideoStart(ad: NativeAdData) {
        guard ad.isVideo else { return }
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Track via analytics
            if let analytics = (AdChainSDK.shared as? AdChainSDKImpl)?.analytics as? AdChainAnalyticsImpl {
                var params = ad.toAnalyticsDict()
                params["video_duration"] = ad.videoDuration ?? 0
                analytics.trackEvent(name: "native_ad_video_start", parameters: params)
            }
            
            Logger.shared.log("Tracked video start for ad \(ad.id)", level: .debug)
        }
    }
    
    public func trackVideoComplete(ad: NativeAdData) {
        guard ad.isVideo else { return }
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Track via analytics
            if let analytics = (AdChainSDK.shared as? AdChainSDKImpl)?.analytics as? AdChainAnalyticsImpl {
                var params = ad.toAnalyticsDict()
                params["video_duration"] = ad.videoDuration ?? 0
                analytics.trackEvent(name: "native_ad_video_complete", parameters: params)
            }
            
            Logger.shared.log("Tracked video complete for ad \(ad.id)", level: .debug)
        }
    }
    
    /// Send a tracking request to the given URL
    private func sendTrackingRequest(to urlString: String) {
        guard let url = URL(string: urlString) else {
            Logger.shared.log("Invalid tracking URL: \(urlString)", level: .error)
            return
        }
        
        Task {
            do {
                let (_, response) = try await URLSession.shared.data(from: url)
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    Logger.shared.log("Tracking request sent successfully", level: .debug)
                }
            } catch {
                Logger.shared.log("Failed to send tracking request: \(error)", level: .error)
            }
        }
    }
    
    /// Clear tracking cache (useful for testing)
    public func clearCache() {
        queue.async(flags: .barrier) { [weak self] in
            self?.impressedAds.removeAll()
            self?.clickedAds.removeAll()
        }
    }
}

/// Helper class to batch track multiple ads
public class NativeAdBatchTracker {
    private let tracker: NativeAdTracker
    private var pendingImpressions = [NativeAdData]()
    private let batchSize: Int
    private let batchInterval: TimeInterval
    private var timer: Timer?
    
    public init(
        tracker: NativeAdTracker = NativeAdTrackerImpl(),
        batchSize: Int = 10,
        batchInterval: TimeInterval = 2.0
    ) {
        self.tracker = tracker
        self.batchSize = batchSize
        self.batchInterval = batchInterval
        startTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: batchInterval, repeats: true) { [weak self] _ in
            self?.flushPendingImpressions()
        }
    }
    
    public func trackImpression(ad: NativeAdData) {
        pendingImpressions.append(ad)
        
        if pendingImpressions.count >= batchSize {
            flushPendingImpressions()
        }
    }
    
    private func flushPendingImpressions() {
        let impressionsToTrack = pendingImpressions
        pendingImpressions.removeAll()
        
        for ad in impressionsToTrack {
            tracker.trackImpression(ad: ad)
        }
    }
    
    deinit {
        timer?.invalidate()
        flushPendingImpressions()
    }
}