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
public protocol AdchainAnalyticsProtocol {
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