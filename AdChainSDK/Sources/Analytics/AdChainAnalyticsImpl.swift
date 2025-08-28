import Foundation

internal class AdChainAnalyticsImpl: AdChainAnalyticsProtocol {
    private let apiClient: ApiClient
    private let deviceInfoCollector: DeviceInfoCollector
    private let sessionManager: SessionManager
    
    private var deviceInfo: DeviceInfo?
    
    init(apiClient: ApiClient, deviceInfoCollector: DeviceInfoCollector, sessionManager: SessionManager) {
        self.apiClient = apiClient
        self.deviceInfoCollector = deviceInfoCollector
        self.sessionManager = sessionManager
    }
    
    func trackDAU() {
        trackEvent(name: "dau", parameters: nil)
        sessionManager.updateLastActiveTime()
    }
    
    func trackEvent(name: String, parameters: [String: Any]?) {
        let deviceInfo = getDeviceInfo()
        let event = AnalyticsEvent(
            name: name,
            timestamp: Date().timeIntervalSince1970,
            sessionId: sessionManager.getSessionId() ?? "",
            userId: sessionManager.getUserId(),
            deviceId: deviceInfo.deviceId,
            advertisingId: deviceInfo.advertisingId,
            os: deviceInfo.os,
            osVersion: deviceInfo.osVersion,
            parameters: parameters
        )
        
        apiClient.trackEvent(event)
        Logger.shared.log("Event tracked: \(name) with IDFA: \(deviceInfo.advertisingId ?? "none")", level: .debug)
    }
    
    func getDeviceInfo() -> DeviceInfo {
        if let cached = deviceInfo {
            return cached
        }
        
        let info = deviceInfoCollector.getDeviceInfo()
        deviceInfo = info
        return info
    }
    
    // Internal methods for carousel and webview tracking
    func trackCarouselImpression(position: Int, itemId: String) {
        trackEvent(
            name: "carousel_impression",
            parameters: [
                "position": position,
                "item_id": itemId
            ]
        )
    }
    
    func trackCarouselClick(position: Int, itemId: String) {
        trackEvent(
            name: "carousel_click",
            parameters: [
                "position": position,
                "item_id": itemId
            ]
        )
    }
    
    func trackWebViewOpen(url: String) {
        trackEvent(
            name: "webview_open",
            parameters: ["url": url]
        )
    }
    
    func trackWebViewClose(url: String, duration: TimeInterval) {
        trackEvent(
            name: "webview_close",
            parameters: [
                "url": url,
                "duration_ms": Int(duration * 1000)
            ]
        )
    }
}