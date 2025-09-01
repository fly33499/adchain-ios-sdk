import Foundation

/// AdChainSDK - 버즈빌 SDK v6 호환 iOS SDK
/// 
/// 이 SDK는 AdchainBenefit을 통해 모든 기능에 접근합니다.
/// 사용 예시:
/// ```swift
/// // 1. SDK 초기화
/// let config = AdchainBenefitConfig.Builder(appId: "YOUR_APP_ID").build()
/// AdchainBenefit.shared.initialize(with: config)
/// 
/// // 2. 사용자 로그인
/// let user = AdchainBenefitUser.Builder(userId: "USER_ID").build()
/// AdchainBenefit.shared.login(with: user, onSuccess: { }, onFailure: { _ in })
/// 
/// // 3. 네이티브 광고 사용
/// let native = AdchainNative(unitId: "UNIT_ID")
/// native.load(onSuccess: { ad in }, onFailure: { _ in })
/// ```
public final class AdChainSDK {
    public static let version = "1.0.0"
    
    /// SDK 버전 정보
    public static func getVersion() -> String {
        return version
    }
    
    /// SDK 초기화 여부 확인
    public static func isInitialized() -> Bool {
        return AdchainBenefit.shared.isLoggedIn()
    }
    
    private init() {}
}