import Foundation

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
}