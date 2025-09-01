import Foundation

/// Buzzville SDK v6 호환 메인 관리 클래스
/// 싱글톤 패턴으로 SDK의 모든 기능을 관리합니다
public class AdchainBenefit {
    
    // MARK: - Singleton
    
    /// 싱글톤 인스턴스
    public static let shared = AdchainBenefit()
    
    // MARK: - Properties
    
    private var config: AdchainBenefitConfig?
    private var currentUser: AdchainBenefitUser?
    private var isInitialized = false
    private let sessionId = UUID().uuidString
    
    // Internal components
    internal var apiClient: ApiClient?
    internal var sessionManager: SessionManager?
    internal var deviceInfoCollector: DeviceInfoCollector?
    internal var analytics: AdchainAnalytics?
    
    // MARK: - Initialization
    
    private init() {
        Logger.shared.log("AdchainBenefit singleton created", level: .debug)
    }
    
    /// SDK 초기화
    /// - Parameter config: SDK 설정 (Builder 패턴으로 생성)
    public func initialize(with config: AdchainBenefitConfig) {
        guard !isInitialized else {
            Logger.shared.log("AdchainBenefit already initialized", level: .warning)
            return
        }
        
        self.config = config
        
        Logger.shared.configure(enabled: config.enableLogging)
        Logger.shared.log("Initializing AdchainBenefit with appId: \(config.appId)", level: .debug)
        
        // Initialize internal components
        self.apiClient = ApiClient(config: config)
        self.sessionManager = SessionManager()
        self.deviceInfoCollector = DeviceInfoCollector()
        self.analytics = AdchainAnalyticsImpl()
        
        // Validate credentials
        let deviceInfo = deviceInfoCollector?.getDeviceInfo()
        
        apiClient?.validateCredentials(
            appId: config.appId,
            appSecret: config.appSecret ?? "",
            deviceInfo: deviceInfo
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                self.isInitialized = true
                self.sessionManager?.startSession(sessionId: self.sessionId)
                Logger.shared.log("AdchainBenefit initialized successfully", level: .info)
                
            case .failure(let error):
                Logger.shared.log("Failed to initialize AdchainBenefit: \(error)", level: .error)
            }
        }
    }
    
    /// 사용자 로그인
    /// - Parameters:
    ///   - user: 사용자 정보 (Builder 패턴으로 생성)
    ///   - onSuccess: 로그인 성공 콜백
    ///   - onFailure: 로그인 실패 콜백
    public func login(
        with user: AdchainBenefitUser,
        onSuccess: @escaping () -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        guard isInitialized else {
            onFailure(AdChainError.notInitialized(
                message: "AdchainBenefit not initialized. Call initialize() first."
            ))
            return
        }
        
        self.currentUser = user
        sessionManager?.setUserId(user.userId)
        
        // Set user in analytics
        analytics?.setUser(user)
        
        // Simulate user login (sendEvent method doesn't exist in ApiClient)
        Logger.shared.log("User logged in: \(user.userId)", level: .info)
        onSuccess()
    }
    
    /// 사용자 로그아웃
    public func logout() {
        guard isInitialized else { return }
        
        // Log logout event
        if let userId = currentUser?.userId {
            Logger.shared.log("User logout: \(userId)", level: .info)
        }
        
        currentUser = nil
        sessionManager?.clearUserId()
        analytics?.clearUser()
        Logger.shared.log("User logged out", level: .info)
    }
    
    /// 로그인 상태 확인
    /// - Returns: 로그인 여부
    public func isLoggedIn() -> Bool {
        return currentUser != nil
    }
    
    // MARK: - Getters
    
    /// 현재 설정 반환
    public func getConfig() -> AdchainBenefitConfig? {
        return config
    }
    
    /// 현재 사용자 반환
    public func getCurrentUser() -> AdchainBenefitUser? {
        return currentUser
    }
    
    /// SDK 버전 반환
    public func getVersion() -> String {
        return "2.0.0" // Buzzville 호환 버전
    }
    
    /// 세션 ID 반환
    public func getSessionId() -> String {
        return sessionId
    }
    
    /// 초기화 상태 반환
    public func getInitializationStatus() -> Bool {
        return isInitialized
    }
    
    // MARK: - Internal Methods
    
    internal func checkInitialized() throws {
        guard isInitialized else {
            throw AdChainError.notInitialized(
                message: "AdchainBenefit is not initialized. Call initialize() first."
            )
        }
    }
    
    internal func getApiClient() -> ApiClient? {
        return apiClient
    }
    
    internal func getDeviceInfoCollector() -> DeviceInfoCollector? {
        return deviceInfoCollector
    }
}

