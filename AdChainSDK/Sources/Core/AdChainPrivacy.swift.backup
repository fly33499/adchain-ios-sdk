import Foundation
import AppTrackingTransparency
import AdSupport

public protocol AdChainPrivacyProtocol {
    func setGDPRConsent(_ hasConsent: Bool)
    func getGDPRConsent() -> Bool?
    
    func setCCPAOptOut(_ optOut: Bool)
    func getCCPAOptOut() -> Bool?
    
    func requestATTPermission(completion: @escaping (ATTStatus) -> Void)
    func getATTStatus() -> ATTStatus
}

public enum ATTStatus {
    case notDetermined
    case restricted
    case denied
    case authorized
    
    @available(iOS 14, *)
    init(from status: ATTrackingManager.AuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .restricted:
            self = .restricted
        case .denied:
            self = .denied
        case .authorized:
            self = .authorized
        @unknown default:
            self = .denied
        }
    }
}