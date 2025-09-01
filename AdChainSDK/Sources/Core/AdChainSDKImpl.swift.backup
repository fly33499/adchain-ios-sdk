import Foundation
import UIKit

internal class AdChainSDKImpl: AdChainSDKProtocol {
    static let shared: AdChainSDKProtocol = AdChainSDKImpl()
    
    private var config: AdChainConfig?
    private var _isInitialized = false
    private let sessionId = UUID().uuidString
    private var userId: String?
    private var webOfferwallUrl: String?
    
    private var apiClient: ApiClient?
    private var sessionManager: SessionManager?
    private var deviceInfoCollector: DeviceInfoCollector?
    
    private let initializationQueue = DispatchQueue(label: "com.adchain.sdk.initialization")
    
    lazy var carousel: AdChainCarouselProtocol = {
        checkInitialized()
        return AdChainCarouselImpl(apiClient: apiClient!, deviceInfoCollector: deviceInfoCollector!)
    }()
    
    lazy var webView: AdChainWebViewProtocol = {
        checkInitialized()
        return AdChainWebViewImpl(sdk: self)
    }()
    
    lazy var analytics: AdChainAnalyticsProtocol = {
        checkInitialized()
        return AdChainAnalyticsImpl(apiClient: apiClient!, deviceInfoCollector: deviceInfoCollector!, sessionManager: sessionManager!)
    }()
    
    lazy var privacy: AdChainPrivacyProtocol = {
        checkInitialized()
        return AdChainPrivacyImpl()
    }()
    
    lazy var nativeAdLoader: NativeAdLoader = {
        checkInitialized()
        return NativeAdLoader(apiClient: apiClient!)
    }()
    
    internal init() {
        setupAppLifecycleObservers()
    }
    
    func initialize(config: AdChainConfig, completion: ((Result<Void, AdChainError>) -> Void)?) {
        if _isInitialized {
            completion?(.success(()))
            return
        }
        
        self.config = config
        
        Logger.shared.configure(enabled: config.enableLogging)
        Logger.shared.log("Initializing SDK with config: \(config)", level: .debug)
        
        initializationQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Initialize components
            self.apiClient = ApiClient(config: config)
            self.sessionManager = SessionManager()
            self.deviceInfoCollector = DeviceInfoCollector()
            
            // Collect device info
            let deviceInfo = self.deviceInfoCollector?.getDeviceInfo()
            Logger.shared.log("Device info collected: \(String(describing: deviceInfo))", level: .debug)
            
            // Validate app credentials with device info
            self.apiClient?.validateCredentials(appId: config.appId, appSecret: config.appSecret, deviceInfo: deviceInfo) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        self._isInitialized = true
                        self.sessionManager?.startSession(sessionId: self.sessionId)
                        
                        // Store webOfferwallUrl from server
                        if let webOfferwallUrl = response.app?.webOfferwallUrl {
                            self.webOfferwallUrl = webOfferwallUrl
                            Logger.shared.log("WebOfferwall URL set: \(webOfferwallUrl)", level: .debug)
                        }
                        
                        Logger.shared.log("SDK initialized successfully", level: .debug)
                        completion?(.success(()))
                        
                    case .failure(let error):
                        Logger.shared.log("Failed to initialize SDK: \(error)", level: .error)
                        completion?(.failure(error))
                    }
                }
            }
        }
    }
    
    func setUser(userId: String) {
        checkInitialized()
        self.userId = userId
        sessionManager?.setUserId(userId)
        Logger.shared.log("User ID set: \(userId)", level: .debug)
    }
    
    func logout() {
        checkInitialized()
        self.userId = nil
        sessionManager?.clearUserId()
        Logger.shared.log("User logged out", level: .debug)
    }
    
    func isInitialized() -> Bool {
        return _isInitialized
    }
    
    func getVersion() -> String {
        return "1.0.0"
    }
    
    func getSessionId() -> String {
        return sessionId
    }
    
    // Internal methods
    internal func getConfig() -> AdChainConfig {
        checkInitialized()
        return config!
    }
    
    internal func getUserId() -> String? {
        return userId
    }
    
    internal func getApiClient() -> ApiClient {
        checkInitialized()
        return apiClient!
    }
    
    internal func getDeviceInfoCollector() -> DeviceInfoCollector {
        checkInitialized()
        return deviceInfoCollector!
    }
    
    internal func getWebOfferwallUrl() -> String? {
        return webOfferwallUrl
    }
    
    private func checkInitialized() {
        if !_isInitialized {
            fatalError("AdChainSDK is not initialized. Call initialize() first.")
        }
    }
    
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        guard _isInitialized else { return }
        analytics.trackDAU()
    }
    
    @objc private func appDidEnterBackground() {
        guard _isInitialized else { return }
        // Flush any pending events
        apiClient?.flushPendingRequests()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}