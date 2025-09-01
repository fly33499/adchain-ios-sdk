import Foundation
import UIKit

/// Analytics 프로토콜
/// 이벤트 추적 및 분석 기능 정의
public protocol AdchainAnalytics {
    func trackEvent(_ event: String, parameters: [String: Any]?)
    func trackDAU()
    func setUser(_ user: AdchainBenefitUser)
    func clearUser()
}

/// 기존 프로토콜 호환성 유지
public protocol AdChainAnalyticsProtocol {
    func trackDAU()
    func trackEvent(name: String, parameters: [String: Any]?)
    func getDeviceInfo() -> DeviceInfo
}

public struct DeviceInfo {
    public let deviceId: String
    public let advertisingId: String?
    public let isAdvertisingTrackingEnabled: Bool
    public let os: String
    public let osVersion: String
    public let deviceModel: String
    public let appVersion: String
    public let sdkVersion: String
    public let language: String
    public let country: String
    public let timezone: String
    public let localIp: String?  // 로컬 IP (선택적, 서버에서 외부 IP 자동 감지)
}

/// Analytics 구현체
/// Buzzville SDK v6 호환 - 이벤트 추적 및 사용자 분석
public class AdchainAnalyticsImpl: AdchainAnalytics, AdChainAnalyticsProtocol {
    
    // MARK: - Properties
    
    private var currentUser: AdchainBenefitUser?
    private var sessionStartTime: Date?
    private var lastEventTime: Date?
    
    // Event queue for batch processing
    private var eventQueue: [AnalyticsEvent] = []
    private let eventQueueLock = NSLock()
    private var flushTimer: Timer?
    
    // Constants
    private let maxQueueSize = 100
    private let flushInterval: TimeInterval = 30.0 // 30 seconds
    
    // MARK: - Types
    
    private struct AnalyticsEvent {
        let name: String
        let parameters: [String: Any]?
        let timestamp: Date
        let sessionId: String
        let userId: String?
    }
    
    // MARK: - Initialization
    
    public init() {
        setupFlushTimer()
        trackAppLaunch()
        
        Logger.shared.log("AdchainAnalytics initialized", level: .debug)
    }
    
    deinit {
        flushTimer?.invalidate()
        flushEvents()
    }
    
    // MARK: - AdchainAnalytics Protocol Methods
    
    /// 이벤트 추적
    /// - Parameters:
    ///   - event: 이벤트 이름
    ///   - parameters: 이벤트 파라미터
    public func trackEvent(_ event: String, parameters: [String: Any]? = nil) {
        let analyticsEvent = AnalyticsEvent(
            name: event,
            parameters: parameters,
            timestamp: Date(),
            sessionId: AdchainBenefit.shared.getSessionId(),
            userId: currentUser?.userId
        )
        
        eventQueueLock.lock()
        eventQueue.append(analyticsEvent)
        eventQueueLock.unlock()
        
        Logger.shared.log("Event tracked: \(event)", level: .debug)
        
        // Flush if queue is full
        if eventQueue.count >= maxQueueSize {
            flushEvents()
        }
        
        lastEventTime = Date()
    }
    
    /// DAU (Daily Active User) 추적
    public func trackDAU() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDAUKey = "adchain_last_dau_date"
        
        if let lastDAUDate = UserDefaults.standard.object(forKey: lastDAUKey) as? Date {
            if Calendar.current.isDate(lastDAUDate, inSameDayAs: today) {
                // Already tracked today
                return
            }
        }
        
        trackEvent("dau", parameters: [
            "date": ISO8601DateFormatter().string(from: today),
            "user_id": currentUser?.userId ?? "anonymous",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "sdk_version": AdchainBenefit.shared.getVersion()
        ])
        
        UserDefaults.standard.set(today, forKey: lastDAUKey)
        Logger.shared.log("DAU tracked for date: \(today)", level: .info)
    }
    
    /// 사용자 설정
    /// - Parameter user: 사용자 정보
    public func setUser(_ user: AdchainBenefitUser) {
        self.currentUser = user
        
        trackEvent("user_login", parameters: [
            "user_id": user.userId,
            "gender": user.gender?.rawValue ?? "unknown",
            "birth_year": user.birthYear ?? 0,
            "is_premium": user.isPremium
        ])
        
        Logger.shared.log("Analytics user set: \(user.userId)", level: .debug)
    }
    
    /// 사용자 정보 초기화
    public func clearUser() {
        if let userId = currentUser?.userId {
            trackEvent("user_logout", parameters: ["user_id": userId])
        }
        
        self.currentUser = nil
        Logger.shared.log("Analytics user cleared", level: .debug)
    }
    
    // MARK: - AdChainAnalyticsProtocol Methods (Legacy Compatibility)
    
    public func trackEvent(name: String, parameters: [String: Any]?) {
        trackEvent(name, parameters: parameters)
    }
    
    public func getDeviceInfo() -> DeviceInfo {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        return DeviceInfo(
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
            advertisingId: nil, // Would need AdSupport framework
            isAdvertisingTrackingEnabled: false,
            os: "iOS",
            osVersion: UIDevice.current.systemVersion,
            deviceModel: identifier,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            sdkVersion: AdchainBenefit.shared.getVersion(),
            language: Locale.current.languageCode ?? "en",
            country: Locale.current.regionCode ?? "US",
            timezone: TimeZone.current.identifier,
            localIp: nil
        )
    }
    
    // MARK: - Session Management
    
    /// 세션 시작
    public func startSession() {
        sessionStartTime = Date()
        
        let deviceInfo = getDeviceInfo()
        
        trackEvent("session_start", parameters: [
            "session_id": AdchainBenefit.shared.getSessionId(),
            "device_id": deviceInfo.deviceId,
            "os_version": deviceInfo.osVersion,
            "device_model": deviceInfo.deviceModel
        ])
        
        Logger.shared.log("Analytics session started", level: .debug)
    }
    
    /// 세션 종료
    public func endSession() {
        guard let startTime = sessionStartTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        
        trackEvent("session_end", parameters: [
            "session_id": AdchainBenefit.shared.getSessionId(),
            "duration_seconds": Int(duration),
            "events_count": eventQueue.count
        ])
        
        sessionStartTime = nil
        flushEvents()
        
        Logger.shared.log("Analytics session ended. Duration: \(duration)s", level: .debug)
    }
    
    // MARK: - WebView Events
    
    /// WebView 열기 추적
    public func trackWebViewOpen(url: String) {
        trackEvent("webview_open", parameters: [
            "url": url,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    /// WebView 닫기 추적
    public func trackWebViewClose(url: String, duration: TimeInterval) {
        trackEvent("webview_close", parameters: [
            "url": url,
            "duration": duration,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - Ad Events
    
    /// 광고 노출 추적
    public func trackAdImpression(adId: String, unitId: String) {
        trackEvent("ad_impression", parameters: [
            "ad_id": adId,
            "unit_id": unitId,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    /// 광고 클릭 추적
    public func trackAdClick(adId: String, unitId: String) {
        trackEvent("ad_click", parameters: [
            "ad_id": adId,
            "unit_id": unitId,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    /// 리워드 지급 추적
    public func trackRewardEarned(adId: String, amount: Int, type: String) {
        trackEvent("reward_earned", parameters: [
            "ad_id": adId,
            "amount": amount,
            "type": type,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - Private Methods
    
    private func setupFlushTimer() {
        flushTimer = Timer.scheduledTimer(withTimeInterval: flushInterval, repeats: true) { [weak self] _ in
            self?.flushEvents()
        }
    }
    
    private func flushEvents() {
        eventQueueLock.lock()
        let eventsToSend = eventQueue
        eventQueue.removeAll()
        eventQueueLock.unlock()
        
        guard !eventsToSend.isEmpty else { return }
        
        // Convert events to dictionary array
        let eventData = eventsToSend.map { event -> [String: Any] in
            var data: [String: Any] = [
                "name": event.name,
                "timestamp": ISO8601DateFormatter().string(from: event.timestamp),
                "session_id": event.sessionId
            ]
            
            if let userId = event.userId {
                data["user_id"] = userId
            }
            
            if let params = event.parameters {
                data["parameters"] = params
            }
            
            return data
        }
        
        // Send events to server
        sendEvents(eventData)
        
        Logger.shared.log("Flushed \(eventsToSend.count) analytics events", level: .debug)
    }
    
    private func sendEvents(_ events: [[String: Any]]) {
        // This would normally send to the analytics server
        // For now, just log
        Logger.shared.log("Sending \(events.count) events to analytics server", level: .debug)
        
        // TODO: Implement actual network call
        // AdchainBenefit.shared.getApiClient()?.sendAnalyticsEvents(events) { result in ... }
    }
    
    private func trackAppLaunch() {
        let deviceInfo = getDeviceInfo()
        
        trackEvent("app_launch", parameters: [
            "app_version": deviceInfo.appVersion,
            "sdk_version": deviceInfo.sdkVersion,
            "device_model": deviceInfo.deviceModel,
            "os_version": deviceInfo.osVersion
        ])
    }
}