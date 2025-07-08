import Foundation

public enum AdChainError: Error {
    case initializationFailed(message: String)
    case notInitialized
    case networkError(message: String, statusCode: Int?)
    case invalidConfig(message: String)
    case invalidUserId
    case noFill
    case webViewError(message: String)
    case unknown(message: String, underlyingError: Error?)
    
    public var errorCode: ErrorCode {
        switch self {
        case .initializationFailed: return .initializationFailed
        case .notInitialized: return .notInitialized
        case .networkError: return .networkError
        case .invalidConfig: return .invalidConfig
        case .invalidUserId: return .invalidUserId
        case .noFill: return .noFill
        case .webViewError: return .webViewError
        case .unknown: return .unknown
        }
    }
    
    public var localizedDescription: String {
        switch self {
        case .initializationFailed(let message):
            return "Initialization failed: \(message)"
        case .notInitialized:
            return "AdChainSDK is not initialized"
        case .networkError(let message, let statusCode):
            if let statusCode = statusCode {
                return "Network error (\(statusCode)): \(message)"
            }
            return "Network error: \(message)"
        case .invalidConfig(let message):
            return "Invalid configuration: \(message)"
        case .invalidUserId:
            return "Invalid user ID"
        case .noFill:
            return "No ads available"
        case .webViewError(let message):
            return "WebView error: \(message)"
        case .unknown(let message, _):
            return "Unknown error: \(message)"
        }
    }
}

public enum ErrorCode: Int {
    case initializationFailed = 1001
    case notInitialized = 1002
    case networkError = 2001
    case timeout = 2002
    case invalidConfig = 3001
    case invalidUserId = 3002
    case noFill = 4001
    case webViewError = 5001
    case unknown = 9999
}