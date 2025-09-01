import Foundation

/// Buzzville SDK v6 호환 설정 클래스
/// Builder 패턴을 사용하여 생성합니다
public class AdchainBenefitConfig {
    
    // MARK: - Properties
    
    public let appId: String
    public let appSecret: String?
    public let environment: Environment
    public let enableLogging: Bool
    public let apiTimeout: TimeInterval
    public let customBaseUrl: String?
    public let enableAutoEventTracking: Bool
    public let enableCrashReporting: Bool
    public let maxRetryCount: Int
    public let sessionTimeout: TimeInterval
    
    // MARK: - Environment
    
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
                return ""
            }
        }
    }
    
    // MARK: - Private Init
    
    private init(builder: Builder) {
        self.appId = builder.appId
        self.appSecret = builder.appSecret
        self.environment = builder.environment
        self.enableLogging = builder.enableLogging
        self.apiTimeout = builder.apiTimeout
        self.customBaseUrl = builder.customBaseUrl
        self.enableAutoEventTracking = builder.enableAutoEventTracking
        self.enableCrashReporting = builder.enableCrashReporting
        self.maxRetryCount = builder.maxRetryCount
        self.sessionTimeout = builder.sessionTimeout
    }
    
    // MARK: - Builder
    
    /// Builder 클래스 - Buzzville SDK v6 패턴
    public class Builder {
        
        // Required
        internal let appId: String
        
        // Optional with defaults
        internal var appSecret: String?
        internal var environment: Environment = .production
        internal var enableLogging: Bool = false
        internal var apiTimeout: TimeInterval = 10.0
        internal var customBaseUrl: String?
        internal var enableAutoEventTracking: Bool = true
        internal var enableCrashReporting: Bool = false
        internal var maxRetryCount: Int = 3
        internal var sessionTimeout: TimeInterval = 1800 // 30 minutes
        
        /// Builder 초기화
        /// - Parameter appId: 앱 ID (필수)
        public init(appId: String) {
            self.appId = appId
        }
        
        /// 앱 시크릿 설정
        @discardableResult
        public func setAppSecret(_ secret: String) -> Builder {
            self.appSecret = secret
            return self
        }
        
        /// 환경 설정
        @discardableResult
        public func setEnvironment(_ environment: Environment) -> Builder {
            self.environment = environment
            return self
        }
        
        /// 로깅 활성화
        @discardableResult
        public func enableLogging(_ enable: Bool) -> Builder {
            self.enableLogging = enable
            return self
        }
        
        /// API 타임아웃 설정
        @discardableResult
        public func setApiTimeout(_ timeout: TimeInterval) -> Builder {
            self.apiTimeout = timeout
            return self
        }
        
        /// 커스텀 베이스 URL 설정
        @discardableResult
        public func setCustomBaseUrl(_ url: String) -> Builder {
            self.customBaseUrl = url
            if !url.isEmpty {
                self.environment = .custom
            }
            return self
        }
        
        /// 자동 이벤트 추적 설정
        @discardableResult
        public func enableAutoEventTracking(_ enable: Bool) -> Builder {
            self.enableAutoEventTracking = enable
            return self
        }
        
        /// 크래시 리포팅 설정
        @discardableResult
        public func enableCrashReporting(_ enable: Bool) -> Builder {
            self.enableCrashReporting = enable
            return self
        }
        
        /// 최대 재시도 횟수 설정
        @discardableResult
        public func setMaxRetryCount(_ count: Int) -> Builder {
            self.maxRetryCount = max(0, count)
            return self
        }
        
        /// 세션 타임아웃 설정
        @discardableResult
        public func setSessionTimeout(_ timeout: TimeInterval) -> Builder {
            self.sessionTimeout = max(60, timeout) // Minimum 1 minute
            return self
        }
        
        /// Config 객체 생성
        public func build() -> AdchainBenefitConfig {
            // Validation
            if appId.isEmpty {
                fatalError("AdchainBenefitConfig: appId cannot be empty")
            }
            
            if environment == .custom && (customBaseUrl?.isEmpty ?? true) {
                fatalError("AdchainBenefitConfig: customBaseUrl is required when environment is .custom")
            }
            
            return AdchainBenefitConfig(builder: self)
        }
    }
    
    // MARK: - Computed Properties
    
    /// 실제 사용할 베이스 URL
    public var actualBaseUrl: String {
        if let customUrl = customBaseUrl, !customUrl.isEmpty {
            return customUrl
        }
        return environment.baseUrl
    }
    
    /// 설정 유효성 검사
    public func validate() -> Bool {
        guard !appId.isEmpty else { return false }
        
        if environment == .custom {
            guard let customUrl = customBaseUrl, !customUrl.isEmpty else { return false }
        }
        
        return true
    }
    
    /// 설정 정보 디버그 출력
    public func debugDescription() -> String {
        return """
        AdchainBenefitConfig:
        - App ID: \(appId)
        - Environment: \(environment)
        - Base URL: \(actualBaseUrl)
        - Logging: \(enableLogging)
        - Auto Event Tracking: \(enableAutoEventTracking)
        - Crash Reporting: \(enableCrashReporting)
        - API Timeout: \(apiTimeout)s
        - Max Retry: \(maxRetryCount)
        - Session Timeout: \(sessionTimeout)s
        """
    }
}

// MARK: - Convenience Initializers

extension AdchainBenefitConfig {
    
    /// 프로덕션 환경용 간편 생성
    public static func production(appId: String, appSecret: String? = nil) -> AdchainBenefitConfig {
        return Builder(appId: appId)
            .setAppSecret(appSecret ?? "")
            .setEnvironment(.production)
            .build()
    }
    
    /// 개발 환경용 간편 생성
    public static func development(appId: String, enableLogging: Bool = true) -> AdchainBenefitConfig {
        return Builder(appId: appId)
            .setEnvironment(.development)
            .enableLogging(enableLogging)
            .build()
    }
    
    /// 스테이징 환경용 간편 생성
    public static func staging(appId: String, appSecret: String? = nil) -> AdchainBenefitConfig {
        return Builder(appId: appId)
            .setAppSecret(appSecret ?? "")
            .setEnvironment(.staging)
            .enableLogging(true)
            .build()
    }
}