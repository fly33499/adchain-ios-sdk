import Foundation
import AppTrackingTransparency
import AdSupport

internal class AdChainPrivacyImpl: AdChainPrivacyProtocol {
    private let userDefaults = UserDefaults.standard
    private let gdprConsentKey = "com.adchain.sdk.gdpr.consent"
    private let ccpaOptOutKey = "com.adchain.sdk.ccpa.optout"
    
    func setGDPRConsent(_ hasConsent: Bool) {
        userDefaults.set(hasConsent, forKey: gdprConsentKey)
    }
    
    func getGDPRConsent() -> Bool? {
        if userDefaults.object(forKey: gdprConsentKey) != nil {
            return userDefaults.bool(forKey: gdprConsentKey)
        }
        return nil
    }
    
    func setCCPAOptOut(_ optOut: Bool) {
        userDefaults.set(optOut, forKey: ccpaOptOutKey)
    }
    
    func getCCPAOptOut() -> Bool? {
        if userDefaults.object(forKey: ccpaOptOutKey) != nil {
            return userDefaults.bool(forKey: ccpaOptOutKey)
        }
        return nil
    }
    
    func requestATTPermission(completion: @escaping (ATTStatus) -> Void) {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    completion(ATTStatus(from: status))
                }
            }
        } else {
            // Pre-iOS 14, advertising tracking is always available
            completion(.authorized)
        }
    }
    
    func getATTStatus() -> ATTStatus {
        if #available(iOS 14, *) {
            return ATTStatus(from: ATTrackingManager.trackingAuthorizationStatus)
        } else {
            // Pre-iOS 14, advertising tracking is always available
            return .authorized
        }
    }
}