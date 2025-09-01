import Foundation

public enum AdchainError: Error {
    case initializationFailed(message: String)
    case notInitialized(message: String)
    case networkError(message: String, statusCode: Int?)
    case invalidConfig(message: String)
    case invalidUserId
    case noFill(message: String)
    case webViewError(message: String)
    case loadInProgress(message: String)
    case operationInProgress(message: String)
    case notFound(message: String)
    case invalidState(message: String)
    case invalidParameter(message: String)
    case limitExceeded(message: String)
    case invalidUrl(url: String)
    case invalidData(message: String)
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
        case .loadInProgress: return .unknown
        case .operationInProgress: return .unknown
        case .notFound: return .unknown
        case .invalidState: return .unknown
        case .invalidParameter: return .unknown
        case .limitExceeded: return .unknown
        case .invalidUrl: return .unknown
        case .invalidData: return .unknown
        case .unknown: return .unknown
        }
    }
    
    public var localizedDescription: String {
        switch self {
        case .initializationFailed(let message):
            return "Initialization failed: \(message)"
        case .notInitialized(let message):
            return message.isEmpty ? "AdchainSDK is not initialized" : message
        case .networkError(let message, let statusCode):
            if let statusCode = statusCode {
                return "Network error (\(statusCode)): \(message)"
            }
            return "Network error: \(message)"
        case .invalidConfig(let message):
            return "Invalid configuration: \(message)"
        case .invalidUserId:
            return "Invalid user ID"
        case .noFill(let message):
            return message.isEmpty ? "No ads available" : message
        case .webViewError(let message):
            return "WebView error: \(message)"
        case .loadInProgress(let message):
            return "Load in progress: \(message)"
        case .operationInProgress(let message):
            return "Operation in progress: \(message)"
        case .notFound(let message):
            return "Not found: \(message)"
        case .invalidState(let message):
            return "Invalid state: \(message)"
        case .invalidParameter(let message):
            return "Invalid parameter: \(message)"
        case .limitExceeded(let message):
            return "Limit exceeded: \(message)"
        case .invalidUrl(let url):
            return "Invalid URL: \(url)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
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