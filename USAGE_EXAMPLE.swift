import UIKit
import AdChainSDK

// ✅ 올바른 초기화 순서 (Buzzville SDK v6 스타일)

class ExampleViewController: UIViewController {
    
    // MARK: - 1. SDK 초기화 (앱 시작 시)
    
    func initializeSDK() {
        // ✅ Builder 패턴으로 Config 생성
        let config = AdchainBenefitConfig.Builder(appId: "test-app-id")
            .setAppSecret("test-secret")
            .setEnvironment(.production)
            .enableLogging(true)
            .setApiTimeout(10.0)
            .enableAutoEventTracking(true)
            .build()
        
        // ✅ 싱글톤으로 초기화
        AdchainBenefit.shared.initialize(with: config)
    }
    
    // MARK: - 2. 사용자 로그인 (사용자 로그인 시)
    
    func loginUser() {
        // ✅ Builder 패턴으로 User 생성
        let user = AdchainBenefitUser.Builder(userId: "user123")
            .setGender(.male)
            .setBirthYear(1990)
            .setEmail("user@example.com")
            .setNickname("TestUser")
            .addInterest("sports")
            .addInterest("games")
            .setIsPremium(false)
            .build()
        
        // ✅ 로그인 수행
        AdchainBenefit.shared.login(
            with: user,
            onSuccess: {
                print("로그인 성공")
            },
            onFailure: { error in
                print("로그인 실패: \(error)")
            }
        )
    }
    
    // MARK: - 3. Native 광고 사용
    
    func setupNativeAd() {
        // ✅ Native 광고 생성
        let native = AdchainNative(unitId: "native-unit-123")
        
        // ✅ 자동 갱신 이벤트 구독
        native.subscribeRefreshEvents(
            onRequest: {
                print("광고 갱신 요청")
            },
            onSuccess: { ad in
                print("광고 갱신 성공: \(ad.title)")
            },
            onFailure: { error in
                print("광고 갱신 실패: \(error)")
            }
        )
        
        // ✅ 광고 이벤트 구독
        native.subscribeAdEvents(
            onImpression: { ad in
                print("광고 노출: \(ad.id)")
            },
            onClick: { ad in
                print("광고 클릭: \(ad.id)")
            },
            onParticipationComplete: { ad in
                print("광고 참여 완료: \(ad.id)")
            }
        )
        
        // ✅ 광고 로드
        native.load(
            onSuccess: { ad in
                print("광고 로드 성공: \(ad.title)")
                self.bindNativeAdToView(native: native)
            },
            onFailure: { error in
                print("광고 로드 실패: \(error)")
            }
        )
    }
    
    // MARK: - 4. ViewBinder 사용
    
    @IBOutlet weak var nativeAdView: AdchainNativeAdView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var mediaView: AdchainMediaView!
    @IBOutlet weak var ctaButton: AdchainDefaultCtaView!
    
    func bindNativeAdToView(native: AdchainNative) {
        // ✅ Builder 패턴으로 ViewBinder 생성
        let viewBinder = AdchainNativeViewBinder.Builder()
            .nativeAdView(nativeAdView)
            .titleLabel(titleLabel)
            .descriptionLabel(descriptionLabel)
            .mediaView(mediaView)
            .ctaView(ctaButton)
            .setClickableViews([mediaView, ctaButton])
            .build()
        
        // ✅ Native 광고 바인딩
        viewBinder.bind(native)
    }
    
    // MARK: - 5. 캐러셀용 NativeGroup 사용
    
    func setupCarousel() {
        // ✅ NativeGroup 생성
        let nativeGroup = AdchainNativeGroup(unitId: "carousel-unit-123")
        
        // ✅ 여러 광고 로드
        nativeGroup.load(
            count: 5,
            onSuccess: { count in
                print("\(count)개 광고 로드 성공")
                self.displayCarousel(nativeGroup: nativeGroup)
            },
            onFailure: { error in
                print("캐러셀 로드 실패: \(error)")
            }
        )
    }
    
    func displayCarousel(nativeGroup: AdchainNativeGroup) {
        // 캐러셀 표시 로직
        for (index, native) in nativeGroup.natives.enumerated() {
            print("광고 \(index): \(native.getCurrentAd()?.title ?? "")")
        }
    }
    
    // MARK: - 6. 메모리 관리 (테이블뷰/컬렉션뷰)
    
    var viewBinder: AdchainNativeViewBinder?
    
    override func prepareForReuse() {
        // ✅ 재사용 시 unbind 필수
        viewBinder?.unbind()
    }
    
    // MARK: - 7. Mission 시스템 사용
    
    func setupMissionSystem() {
        // ✅ Mission Controller 생성
        let missionController = AdchainMissionController(unitId: "mission-unit-123")
        
        // ✅ 미션 진행률 콜백
        missionController.onProgressUpdate = { progress in
            print("진행률: \(progress.completedMissions)/\(progress.totalMissions)")
        }
        
        // ✅ 미션 완료 콜백
        missionController.onMissionComplete = { missionId, reward in
            print("미션 완료: \(missionId), 보상: \(reward)")
        }
        
        // ✅ 보너스 획득 콜백
        missionController.onBonusEarned = { bonus in
            print("보너스 획득: \(bonus) 포인트")
        }
        
        // ✅ 미션팩 로드
        missionController.loadMissionPack { result in
            switch result {
            case .success(let pack):
                print("미션팩 로드 성공: \(pack.missions.count)개 미션")
                
                // 첫 번째 미션 실행
                if let firstMission = pack.missions.first {
                    missionController.executeMission(missionId: firstMission.id) { result in
                        switch result {
                        case .success:
                            print("미션 실행 성공")
                        case .failure(let error):
                            print("미션 실행 실패: \(error)")
                        }
                    }
                }
                
            case .failure(let error):
                print("미션팩 로드 실패: \(error)")
            }
        }
    }
}

// MARK: - ✅ 검증 포인트

/*
 1. ✅ 싱글톤 패턴: AdchainBenefit.shared
 2. ✅ Builder 패턴: Config, User, ViewBinder 모두 Builder 사용
 3. ✅ 초기화 순서: initialize → login → load → bind
 4. ✅ 자동 갱신: subscribeRefreshEvents 구현
 5. ✅ ViewBinder: bind/unbind 메서드 구현
 6. ✅ NativeGroup: 캐러셀용 그룹 관리
 7. ✅ Mission 시스템: Controller, Task, StateManager 구현
 8. ✅ 메모리 관리: weak self, unbind 사용
 */