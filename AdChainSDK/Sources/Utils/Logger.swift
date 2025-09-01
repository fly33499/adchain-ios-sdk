import Foundation

internal class Logger {
    static let shared = Logger()
    
    private var isEnabled = false
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    enum Level: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }
    
    private init() {}
    
    func configure(enabled: Bool) {
        isEnabled = enabled
    }
    
    func log(_ message: String, level: Level = .info, file: String = #file, function: String = #function, line: Int = #line) {
        guard isEnabled else { return }
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = dateFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] [AdchainSDK] [\(level.rawValue)] [\(fileName):\(line)] \(function) - \(message)"
        
        print(logMessage)
    }
}