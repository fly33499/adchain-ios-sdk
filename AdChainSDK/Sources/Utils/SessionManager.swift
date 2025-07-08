import Foundation

internal class SessionManager {
    private let userDefaults = UserDefaults.standard
    private let sessionIdKey = "com.adchain.sdk.session.id"
    private let sessionStartKey = "com.adchain.sdk.session.start"
    private let userIdKey = "com.adchain.sdk.user.id"
    private let lastActiveKey = "com.adchain.sdk.last.active"
    
    func startSession(sessionId: String) {
        userDefaults.set(sessionId, forKey: sessionIdKey)
        userDefaults.set(Date().timeIntervalSince1970, forKey: sessionStartKey)
    }
    
    func getSessionId() -> String? {
        return userDefaults.string(forKey: sessionIdKey)
    }
    
    func setUserId(_ userId: String) {
        userDefaults.set(userId, forKey: userIdKey)
    }
    
    func getUserId() -> String? {
        return userDefaults.string(forKey: userIdKey)
    }
    
    func clearUserId() {
        userDefaults.removeObject(forKey: userIdKey)
    }
    
    func getLastActiveTime() -> TimeInterval {
        return userDefaults.double(forKey: lastActiveKey)
    }
    
    func updateLastActiveTime() {
        userDefaults.set(Date().timeIntervalSince1970, forKey: lastActiveKey)
    }
}