import Foundation
import UIKit
import AdSupport
import AppTrackingTransparency

internal class DeviceInfoCollector {
    private var cachedDeviceInfo: DeviceInfo?
    
    func getDeviceInfo() -> DeviceInfo {
        if let cached = cachedDeviceInfo {
            return cached
        }
        
        let deviceInfo = DeviceInfo(
            deviceId: getDeviceId(),
            advertisingId: getAdvertisingId(),
            isAdvertisingTrackingEnabled: isAdvertisingTrackingEnabled(),
            os: "iOS",
            osVersion: UIDevice.current.systemVersion,
            deviceModel: getDeviceModel(),
            appVersion: getAppVersion(),
            sdkVersion: "1.0.0",
            language: Locale.current.languageCode ?? "en",
            country: Locale.current.regionCode ?? "US",
            timezone: TimeZone.current.identifier
        )
        
        cachedDeviceInfo = deviceInfo
        return deviceInfo
    }
    
    private func getDeviceId() -> String {
        if let vendorId = UIDevice.current.identifierForVendor?.uuidString {
            return vendorId
        }
        
        // Fallback to a generated ID stored in keychain
        let keychainKey = "com.adchain.sdk.device.id"
        if let storedId = KeychainHelper.shared.getString(forKey: keychainKey) {
            return storedId
        } else {
            let newId = UUID().uuidString
            KeychainHelper.shared.setString(newId, forKey: keychainKey)
            return newId
        }
    }
    
    private func getAdvertisingId() -> String? {
        if #available(iOS 14, *) {
            guard ATTrackingManager.trackingAuthorizationStatus == .authorized else {
                // ATT 권한이 거부되거나 아직 요청하지 않은 경우 nil 반환
                return nil
            }
        }
        
        // LAT가 활성화되거나 시뮬레이터인 경우 zeroed IDFA를 그대로 반환
        // 이를 통해 서버에서 권한 거부(nil)와 추적 제한(zeroed)을 구분 가능
        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        return idfa
    }
    
    private func isAdvertisingTrackingEnabled() -> Bool {
        if #available(iOS 14, *) {
            return ATTrackingManager.trackingAuthorizationStatus == .authorized
        } else {
            return ASIdentifierManager.shared().isAdvertisingTrackingEnabled
        }
    }
    
    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        return mapToDevice(identifier: identifier)
    }
    
    private func mapToDevice(identifier: String) -> String {
        switch identifier {
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,6": return "iPhone SE (3rd generation)"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPad13,16", "iPad13,17": return "iPad Air (5th generation)"
        case "iPad14,1", "iPad14,2": return "iPad mini (6th generation)"
        default:
            if identifier.hasPrefix("iPhone") {
                return "iPhone"
            } else if identifier.hasPrefix("iPad") {
                return "iPad"
            } else {
                return identifier
            }
        }
    }
    
    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return "\(version) (\(build))"
    }
    
    func clearCache() {
        cachedDeviceInfo = nil
    }
}