import Foundation

/// Buzzville SDK v6 호환 Native 광고 그룹 클래스
/// 캐러셀 등 여러 광고를 한번에 관리합니다
public class AdchainNativeGroup {
    
    // MARK: - Properties
    
    public let unitId: String
    public private(set) var natives: [AdchainNative] = []
    private var isLoading = false
    
    // Callbacks
    private var loadHandlers: LoadHandlers?
    private var refreshHandlers: RefreshHandlers?
    
    // Internal
    private let apiClient: ApiClient
    private let maxAdsCount = 10 // 최대 광고 개수
    
    // MARK: - Handler Types
    
    private struct LoadHandlers {
        let onSuccess: (Int) -> Void
        let onFailure: (Error) -> Void
    }
    
    private struct RefreshHandlers {
        let onRequest: () -> Void
        let onSuccess: (Int) -> Void
        let onFailure: (Error) -> Void
    }
    
    // MARK: - Initialization
    
    /// Native 광고 그룹 초기화
    /// - Parameter unitId: 광고 유닛 ID
    public init(unitId: String) {
        self.unitId = unitId
        
        // Get components from AdchainBenefit
        guard let apiClient = AdchainBenefit.shared.getApiClient() else {
            fatalError("AdchainNativeGroup: AdchainBenefit must be initialized first")
        }
        
        self.apiClient = apiClient
        
        Logger.shared.log("AdchainNativeGroup initialized for unit: \(unitId)", level: .debug)
    }
    
    // MARK: - Load Methods
    
    /// 여러 광고 로드
    /// - Parameters:
    ///   - count: 로드할 광고 개수
    ///   - onSuccess: 성공 콜백 (로드된 광고 개수 반환)
    ///   - onFailure: 실패 콜백
    public func load(
        count: Int,
        onSuccess: @escaping (Int) -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        guard !isLoading else {
            onFailure(AdchainError.loadInProgress(message: "Ads are already loading"))
            return
        }
        
        guard count > 0 && count <= maxAdsCount else {
            onFailure(AdchainError.invalidParameter(
                message: "Count must be between 1 and \(maxAdsCount)"
            ))
            return
        }
        
        isLoading = true
        
        // Store handlers
        self.loadHandlers = LoadHandlers(onSuccess: onSuccess, onFailure: onFailure)
        
        Logger.shared.log("Loading \(count) native ads for unit: \(unitId)", level: .debug)
        
        // Clear existing natives
        clearNatives()
        
        // Fetch ads from server
        apiClient.fetchCarouselAds(unitId: unitId, count: count) { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case .success(let adsData):
                // Create AdchainNative instances for each ad
                self.natives = adsData.map { adData in
                    let native = AdchainNative(unitId: self.unitId)
                    
                    // Manually set the ad data (bypass normal load)
                    let nativeAd = AdchainNativeAd(from: adData)
                    native.loadWithPreloadedAd(nativeAd)
                    
                    // Setup auto refresh for individual ads
                    native.subscribeRefreshEvents(
                        onRequest: { [weak self] in
                            self?.handleIndividualRefresh(native)
                        },
                        onSuccess: { _ in },
                        onFailure: { _ in }
                    )
                    
                    return native
                }
                
                Logger.shared.log("Loaded \(self.natives.count) native ads", level: .debug)
                onSuccess(self.natives.count)
                
            case .failure(let error):
                Logger.shared.log("Failed to load native ads: \(error)", level: .error)
                onFailure(error)
            }
        }
    }
    
    /// 추가 광고 로드
    /// - Parameters:
    ///   - count: 추가로 로드할 광고 개수
    ///   - onSuccess: 성공 콜백 (추가된 광고 개수 반환)
    ///   - onFailure: 실패 콜백
    public func loadMore(
        count: Int,
        onSuccess: @escaping (Int) -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        guard !isLoading else {
            onFailure(AdchainError.loadInProgress(message: "Ads are already loading"))
            return
        }
        
        let remainingCapacity = maxAdsCount - natives.count
        guard remainingCapacity > 0 else {
            onFailure(AdchainError.limitExceeded(
                message: "Maximum ad count (\(maxAdsCount)) reached"
            ))
            return
        }
        
        let loadCount = min(count, remainingCapacity)
        
        isLoading = true
        
        Logger.shared.log("Loading \(loadCount) more native ads", level: .debug)
        
        apiClient.fetchCarouselAds(unitId: unitId, count: loadCount) { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case .success(let adsData):
                let newNatives = adsData.map { adData in
                    let native = AdchainNative(unitId: self.unitId)
                    let nativeAd = AdchainNativeAd(from: adData)
                    native.loadWithPreloadedAd(nativeAd)
                    return native
                }
                
                self.natives.append(contentsOf: newNatives)
                
                Logger.shared.log("Added \(newNatives.count) native ads", level: .debug)
                onSuccess(newNatives.count)
                
            case .failure(let error):
                Logger.shared.log("Failed to load more native ads: \(error)", level: .error)
                onFailure(error)
            }
        }
    }
    
    /// 모든 광고 새로고침
    public func refreshAll() {
        guard !natives.isEmpty else {
            Logger.shared.log("No ads to refresh", level: .warning)
            return
        }
        
        refreshHandlers?.onRequest()
        
        load(
            count: natives.count,
            onSuccess: { [weak self] count in
                self?.refreshHandlers?.onSuccess(count)
            },
            onFailure: { [weak self] error in
                self?.refreshHandlers?.onFailure(error)
            }
        )
    }
    
    /// 특정 인덱스의 광고 새로고침
    /// - Parameter index: 새로고침할 광고 인덱스
    public func refreshAt(index: Int) {
        guard index >= 0 && index < natives.count else {
            Logger.shared.log("Invalid index: \(index)", level: .warning)
            return
        }
        
        natives[index].refresh()
    }
    
    // MARK: - Event Subscriptions
    
    /// 새로고침 이벤트 구독
    public func subscribeRefreshEvents(
        onRequest: @escaping () -> Void,
        onSuccess: @escaping (Int) -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        self.refreshHandlers = RefreshHandlers(
            onRequest: onRequest,
            onSuccess: onSuccess,
            onFailure: onFailure
        )
    }
    
    // MARK: - Individual Ad Management
    
    /// 특정 인덱스의 Native 광고 반환
    /// - Parameter index: 광고 인덱스
    /// - Returns: AdchainNative 인스턴스
    public func getNativeAt(index: Int) -> AdchainNative? {
        guard index >= 0 && index < natives.count else {
            return nil
        }
        return natives[index]
    }
    
    /// 특정 광고 제거
    /// - Parameter index: 제거할 광고 인덱스
    public func removeAt(index: Int) {
        guard index >= 0 && index < natives.count else { return }
        
        natives[index].destroy()
        natives.remove(at: index)
        
        Logger.shared.log("Removed native ad at index: \(index)", level: .debug)
    }
    
    /// 모든 광고 제거
    public func removeAll() {
        clearNatives()
        Logger.shared.log("Removed all native ads", level: .debug)
    }
    
    // MARK: - Private Methods
    
    /// 개별 광고 새로고침 처리
    private func handleIndividualRefresh(_ native: AdchainNative) {
        guard let index = natives.firstIndex(where: { $0 === native }) else { return }
        
        Logger.shared.log("Individual refresh requested at index: \(index)", level: .debug)
        
        // Load a single new ad to replace
        apiClient.fetchCarouselAds(unitId: unitId, count: 1) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let adsData):
                if let adData = adsData.first {
                    let nativeAd = AdchainNativeAd(from: adData)
                    native.loadWithPreloadedAd(nativeAd)
                    Logger.shared.log("Refreshed ad at index: \(index)", level: .debug)
                }
                
            case .failure(let error):
                Logger.shared.log("Failed to refresh individual ad: \(error)", level: .error)
            }
        }
    }
    
    /// 모든 Native 인스턴스 정리
    private func clearNatives() {
        natives.forEach { $0.destroy() }
        natives.removeAll()
    }
    
    // MARK: - Getters
    
    /// 로드된 광고 개수
    public var count: Int {
        return natives.count
    }
    
    /// 광고가 로드되었는지 확인
    public var hasAds: Bool {
        return !natives.isEmpty
    }
    
    /// 로딩 중인지 확인
    public func getIsLoading() -> Bool {
        return isLoading
    }
    
    // MARK: - Cleanup
    
    /// 리소스 정리
    public func destroy() {
        clearNatives()
        loadHandlers = nil
        refreshHandlers = nil
        
        Logger.shared.log("AdchainNativeGroup destroyed for unit: \(unitId)", level: .debug)
    }
    
    deinit {
        destroy()
    }
}

// MARK: - Extensions for AdchainNative

extension AdchainNative {
    /// 미리 로드된 광고로 설정 (AdchainNativeGroup 전용)
    internal func loadWithPreloadedAd(_ ad: AdchainNativeAd) {
        // This is a workaround to set pre-loaded ad data
        // In real implementation, this would be handled differently
        self.currentAd = ad
        self.trackImpression()
    }
}