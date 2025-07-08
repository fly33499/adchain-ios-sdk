import Foundation

public struct AdChainConfig {
    public let appId: String
    public let appSecret: String
    public let environment: Environment
    public let enableLogging: Bool
    public let apiTimeout: TimeInterval
    
    public enum Environment {
        case production
        case staging
        case development
        
        var baseUrl: String {
            switch self {
            case .production:
                return "https://api.adchain.com"
            case .staging:
                return "https://staging-api.adchain.com"
            case .development:
                return "https://dev-api.adchain.com"
            }
        }
    }
    
    public init(
        appId: String,
        appSecret: String,
        environment: Environment = .production,
        enableLogging: Bool = false,
        apiTimeout: TimeInterval = 10.0
    ) {
        self.appId = appId
        self.appSecret = appSecret
        self.environment = environment
        self.enableLogging = enableLogging
        self.apiTimeout = apiTimeout
    }
}