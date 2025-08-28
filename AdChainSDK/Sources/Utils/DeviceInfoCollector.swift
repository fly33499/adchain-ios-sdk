import Foundation
import UIKit
import AdSupport
import AppTrackingTransparency
import Darwin

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
            timezone: TimeZone.current.identifier,
            localIp: getLocalIpAddress()
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
    
    private func getLocalIpAddress() -> String? {
        var address: String?
        
        // Get list of all interfaces on the local machine
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        // For each interface
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // Check for IPv4 or IPv6 interface
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                
                // Check interface name
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "en1" || name == "pdp_ip0" || name == "pdp_ip1" {
                    
                    // Convert interface address to a human readable string
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    
                    let addressString = String(cString: hostname)
                    
                    // Skip link-local addresses
                    if !addressString.hasPrefix("fe80:") && !addressString.hasPrefix("169.254") {
                        // Prefer IPv4 addresses
                        if addrFamily == UInt8(AF_INET) {
                            address = addressString
                            break
                        } else if address == nil {
                            address = addressString
                        }
                    }
                }
            }
        }
        freeifaddrs(ifaddr)
        
        return address
    }
    
    func clearCache() {
        cachedDeviceInfo = nil
    }
}