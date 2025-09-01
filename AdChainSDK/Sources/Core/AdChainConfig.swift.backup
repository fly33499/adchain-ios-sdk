import Foundation

public struct AdChainConfig {
    public let appId: String
    public let appSecret: String
    public let environment: Environment
    public let enableLogging: Bool
    public let apiTimeout: TimeInterval
    public let customBaseUrl: String?
    
    public enum Environment {
        case production
        case staging
        case development
        case custom
        
        var baseUrl: String {
            switch self {
            case .production:
                return "https://api.adchain.com"
            case .staging:
                return "https://staging-api.adchain.com"
            case .development:
                return "http://localhost:3000"
            case .custom:
                return "" // Will use customBaseUrl
            }
        }
    }
    
    public init(
        appId: String,
        appSecret: String,
        environment: Environment = .production,
        enableLogging: Bool = false,
        apiTimeout: TimeInterval = 10.0,
        customBaseUrl: String? = nil
    ) {
        self.appId = appId
        self.appSecret = appSecret
        self.environment = environment
        self.enableLogging = enableLogging
        self.apiTimeout = apiTimeout
        self.customBaseUrl = customBaseUrl
    }
    
    public var actualBaseUrl: String {
        if let customUrl = customBaseUrl, !customUrl.isEmpty {
            return customUrl
        }
        return environment.baseUrl
    }
}