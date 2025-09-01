import Foundation
import UIKit

/// Buzzville SDK v6 호환 Native 광고 클래스
/// 단일 네이티브 광고를 관리합니다
public class AdchainNative {
    
    // MARK: - Properties
    
    public let unitId: String
    internal var currentAd: AdchainNativeAd?
    private var isLoading = false
    private var isParticipating = false
    
    // Event handlers
    private var refreshHandlers: RefreshHandlers?
    private var adEventHandlers: AdEventHandlers?
    
    // Internal
    private weak var viewBinder: AdchainNativeViewBinder?
    private let apiClient: ApiClient?
    // private let tracker: NativeAdTracker - NativeAdTracker 제거
    
    // Auto refresh
    private var autoRefreshTimer: Timer?
    private var autoRefreshInterval: TimeInterval = 0
    
    // MARK: - Event Handler Types
    
    private struct RefreshHandlers {
        let onRequest: () -> Void
        let onSuccess: (AdchainNativeAd) -> Void
        let onFailure: (Error) -> Void
    }
    
    private struct AdEventHandlers {
        let onImpression: ((AdchainNativeAd) -> Void)?
        let onClick: ((AdchainNativeAd) -> Void)?
        let onParticipationStart: ((AdchainNativeAd) -> Void)?
        let onParticipationComplete: ((AdchainNativeAd) -> Void)?
        let onRewardEarned: ((AdchainNativeAd, Int) -> Void)?
    }
    
    // MARK: - Initialization
    
    /// Native 광고 초기화
    /// - Parameter unitId: 광고 유닛 ID
    public init(unitId: String) {
        self.unitId = unitId
        
        // Get components from AdchainBenefit
        guard let apiClient = AdchainBenefit.shared.getApiClient() else {
            fatalError("AdchainNative: AdchainBenefit must be initialized first")
        }
        
        self.apiClient = apiClient
        // self.tracker = NativeAdTrackerImpl() - NativeAdTracker 제거
        
        Logger.shared.log("AdchainNative initialized for unit: \(unitId)", level: .debug)
    }
    
    // MARK: - Load Methods
    
    /// 광고 로드
    /// - Parameters:
    ///   - onSuccess: 성공 콜백
    ///   - onFailure: 실패 콜백
    public func load(
        onSuccess: @escaping (AdchainNativeAd) -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        guard !isLoading else {
            onFailure(AdChainError.loadInProgress(message: "Ad is already loading"))
            return
        }
        
        isLoading = true
        Logger.shared.log("Loading native ad for unit: \(unitId)", level: .debug)
        
        apiClient?.fetchCarouselAds(unitId: unitId, count: 1) { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case .success(let ads):
                guard let adData = ads.first else {
                    onFailure(AdChainError.noFill(message: "No ads available"))
                    return
                }
                
                let nativeAd = AdchainNativeAd(from: adData)
                self.currentAd = nativeAd
                
                Logger.shared.log("Native ad loaded: \(nativeAd.id)", level: .debug)
                onSuccess(nativeAd)
                
                // Trigger impression tracking
                self.trackImpression()
                
            case .failure(let error):
                Logger.shared.log("Failed to load native ad: \(error)", level: .error)
                onFailure(error)
            }
        }
    }
    
    /// 광고 새로고침
    public func refresh() {
        guard let handlers = refreshHandlers else {
            Logger.shared.log("No refresh handlers registered", level: .warning)
            return
        }
        
        handlers.onRequest()
        
        load(
            onSuccess: { [weak self] ad in
                handlers.onSuccess(ad)
                // Auto-update bound views
                self?.viewBinder?.updateWithNewAd(ad)
            },
            onFailure: handlers.onFailure
        )
    }
    
    // MARK: - Event Subscriptions
    
    /// 광고 새로고침 이벤트 구독
    /// - Parameters:
    ///   - onRequest: 새로고침 요청 시 호출
    ///   - onSuccess: 새로고침 성공 시 호출
    ///   - onFailure: 새로고침 실패 시 호출
    public func subscribeRefreshEvents(
        onRequest: @escaping () -> Void,
        onSuccess: @escaping (AdchainNativeAd) -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        self.refreshHandlers = RefreshHandlers(
            onRequest: onRequest,
            onSuccess: onSuccess,
            onFailure: onFailure
        )
        
        Logger.shared.log("Refresh events subscribed", level: .debug)
    }
    
    /// 광고 이벤트 구독
    /// - Parameters:
    ///   - onImpression: 노출 시 호출
    ///   - onClick: 클릭 시 호출
    ///   - onParticipationStart: 참여 시작 시 호출
    ///   - onParticipationComplete: 참여 완료 시 호출
    ///   - onRewardEarned: 보상 획득 시 호출
    public func subscribeAdEvents(
        onImpression: ((AdchainNativeAd) -> Void)? = nil,
        onClick: ((AdchainNativeAd) -> Void)? = nil,
        onParticipationStart: ((AdchainNativeAd) -> Void)? = nil,
        onParticipationComplete: ((AdchainNativeAd) -> Void)? = nil,
        onRewardEarned: ((AdchainNativeAd, Int) -> Void)? = nil
    ) {
        self.adEventHandlers = AdEventHandlers(
            onImpression: onImpression,
            onClick: onClick,
            onParticipationStart: onParticipationStart,
            onParticipationComplete: onParticipationComplete,
            onRewardEarned: onRewardEarned
        )
        
        Logger.shared.log("Ad events subscribed", level: .debug)
    }
    
    // MARK: - Auto Refresh
    
    /// 자동 새로고침 시작
    /// - Parameter interval: 새로고침 간격 (초)
    public func startAutoRefresh(interval: TimeInterval) {
        stopAutoRefresh()
        
        guard interval > 0 else { return }
        
        self.autoRefreshInterval = interval
        
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        
        Logger.shared.log("Auto refresh started with interval: \(interval)s", level: .debug)
    }
    
    /// 자동 새로고침 중지
    public func stopAutoRefresh() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
        autoRefreshInterval = 0
        
        Logger.shared.log("Auto refresh stopped", level: .debug)
    }
    
    // MARK: - Participation
    
    /// 광고 참여 시작
    public func startParticipation() {
        guard let ad = currentAd else {
            Logger.shared.log("No ad loaded for participation", level: .warning)
            return
        }
        
        guard !isParticipating else {
            Logger.shared.log("Already participating in ad", level: .warning)
            return
        }
        
        isParticipating = true
        adEventHandlers?.onParticipationStart?(ad)
        
        // Track click
        trackClick()
        
        // Open landing URL
        if let url = URL(string: ad.landingUrl) {
            UIApplication.shared.open(url)
        }
        
        // Simulate participation completion after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.completeParticipation()
        }
    }
    
    /// 광고 참여 완료 (내부용)
    private func completeParticipation() {
        guard let ad = currentAd else { return }
        
        isParticipating = false
        
        // Track conversion
        trackConversion()
        
        // Trigger handlers
        adEventHandlers?.onParticipationComplete?(ad)
        
        if let reward = ad.rewardAmount {
            adEventHandlers?.onRewardEarned?(ad, reward)
        }
        
        // Auto refresh after participation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refresh()
        }
    }
    
    // MARK: - Tracking
    
    /// 노출 추적
    public func trackImpression() {
        guard let ad = currentAd else { return }
        
        // tracker.trackImpression(ad: ad.toNativeAdData()) - NativeAdTracker 제거
        adEventHandlers?.onImpression?(ad)
        
        Logger.shared.log("Impression tracked for ad: \(ad.id)", level: .debug)
    }
    
    /// 클릭 추적
    public func trackClick() {
        guard let ad = currentAd else { return }
        
        // tracker.trackClick(ad: ad.toNativeAdData()) - NativeAdTracker 제거
        adEventHandlers?.onClick?(ad)
        
        Logger.shared.log("Click tracked for ad: \(ad.id)", level: .debug)
    }
    
    /// 전환 추적
    public func trackConversion() {
        guard let ad = currentAd else { return }
        
        // tracker.trackConversion(ad: ad.toNativeAdData()) - NativeAdTracker 제거
        
        Logger.shared.log("Conversion tracked for ad: \(ad.id)", level: .debug)
    }
    
    // MARK: - View Binding
    
    /// ViewBinder 설정 (내부용)
    internal func setViewBinder(_ binder: AdchainNativeViewBinder) {
        self.viewBinder = binder
    }
    
    /// ViewBinder 해제 (내부용)
    internal func clearViewBinder() {
        self.viewBinder = nil
    }
    
    // MARK: - Getters
    
    /// 현재 로드된 광고 반환
    public func getCurrentAd() -> AdchainNativeAd? {
        return currentAd
    }
    
    /// 로딩 상태 반환
    public func getIsLoading() -> Bool {
        return isLoading
    }
    
    /// 참여 상태 반환
    public func getIsParticipating() -> Bool {
        return isParticipating
    }
    
    // MARK: - Cleanup
    
    /// 리소스 정리
    public func destroy() {
        stopAutoRefresh()
        clearViewBinder()
        currentAd = nil
        refreshHandlers = nil
        adEventHandlers = nil
        
        Logger.shared.log("AdchainNative destroyed for unit: \(unitId)", level: .debug)
    }
    
    deinit {
        destroy()
    }
}