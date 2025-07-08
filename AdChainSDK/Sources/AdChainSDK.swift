import Foundation
import UIKit

public protocol AdChainSDKProtocol {
    static var shared: AdChainSDKProtocol { get }
    
    func initialize(
        config: AdChainConfig,
        completion: ((Result<Void, AdChainError>) -> Void)?
    )
    
    func setUser(userId: String)
    func logout()
    
    func isInitialized() -> Bool
    func getVersion() -> String
    func getSessionId() -> String
    
    var carousel: AdChainCarouselProtocol { get }
    var webView: AdChainWebViewProtocol { get }
    var analytics: AdChainAnalyticsProtocol { get }
    var privacy: AdChainPrivacyProtocol { get }
}

public class AdChainSDK: AdChainSDKProtocol {
    public static let shared: AdChainSDKProtocol = AdChainSDKImpl()
    
    private init() {}
    
    public func initialize(config: AdChainConfig, completion: ((Result<Void, AdChainError>) -> Void)?) {
        (AdChainSDK.shared as? AdChainSDKImpl)?.initialize(config: config, completion: completion)
    }
    
    public func setUser(userId: String) {
        AdChainSDK.shared.setUser(userId: userId)
    }
    
    public func logout() {
        AdChainSDK.shared.logout()
    }
    
    public func isInitialized() -> Bool {
        return AdChainSDK.shared.isInitialized()
    }
    
    public func getVersion() -> String {
        return AdChainSDK.shared.getVersion()
    }
    
    public func getSessionId() -> String {
        return AdChainSDK.shared.getSessionId()
    }
    
    public var carousel: AdChainCarouselProtocol {
        return AdChainSDK.shared.carousel
    }
    
    public var webView: AdChainWebViewProtocol {
        return AdChainSDK.shared.webView
    }
    
    public var analytics: AdChainAnalyticsProtocol {
        return AdChainSDK.shared.analytics
    }
    
    public var privacy: AdChainPrivacyProtocol {
        return AdChainSDK.shared.privacy
    }
}