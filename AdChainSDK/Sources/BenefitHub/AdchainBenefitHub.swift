import UIKit

/// BenefitHub 싱글톤 클래스
/// Buzzville SDK v6 호환 - 광고 및 보상 관련 통합 UI 제공
public class AdchainBenefitHub {
    
    // MARK: - Singleton
    
    /// 싱글톤 인스턴스
    public static let shared = AdchainBenefitHub()
    
    // MARK: - Properties
    
    private var currentViewController: AdchainBenefitHubViewController?
    private var config: AdchainBenefitHubConfig?
    
    // MARK: - Initialization
    
    private init() {
        Logger.shared.log("AdchainBenefitHub singleton created", level: .debug)
    }
    
    // MARK: - Public Methods
    
    /// BenefitHub 표시 (기본 설정)
    /// - Parameter viewController: 표시할 ViewController
    public func show(from viewController: UIViewController) {
        show(from: viewController, config: AdchainBenefitHubConfig.Builder().build())
    }
    
    /// BenefitHub 표시 (커스텀 설정)
    /// - Parameters:
    ///   - viewController: 표시할 ViewController
    ///   - config: BenefitHub 설정
    public func show(from viewController: UIViewController, config: AdchainBenefitHubConfig) {
        Logger.shared.log("Showing BenefitHub with config", level: .debug)
        
        // SDK 초기화 확인
        guard AdchainBenefit.shared.getInitializationStatus() else {
            Logger.shared.log("AdchainBenefit not initialized", level: .error)
            let error = AdchainError.notInitialized(
                message: "AdchainBenefit must be initialized before showing BenefitHub"
            )
            showError(error, from: viewController)
            return
        }
        
        // 로그인 확인
        guard AdchainBenefit.shared.isLoggedIn() else {
            Logger.shared.log("User not logged in", level: .error)
            let error = AdchainError.invalidState(
                message: "User must be logged in before showing BenefitHub"
            )
            showError(error, from: viewController)
            return
        }
        
        self.config = config
        
        // BenefitHub ViewController 생성
        let benefitHubVC = AdchainBenefitHubViewController(config: config)
        benefitHubVC.modalPresentationStyle = .fullScreen
        
        // 이미 표시 중인 경우 닫고 새로 표시
        if let current = currentViewController {
            current.dismiss(animated: false) { [weak self] in
                self?.presentBenefitHub(benefitHubVC, from: viewController)
            }
        } else {
            presentBenefitHub(benefitHubVC, from: viewController)
        }
    }
    
    /// BenefitHub ViewController 생성
    /// - Parameter config: BenefitHub 설정 (선택)
    /// - Returns: BenefitHub ViewController 인스턴스
    public func createViewController(config: AdchainBenefitHubConfig? = nil) -> UIViewController {
        Logger.shared.log("Creating BenefitHub ViewController", level: .debug)
        
        // SDK 초기화 확인
        guard AdchainBenefit.shared.getInitializationStatus() else {
            Logger.shared.log("AdchainBenefit not initialized", level: .error)
            fatalError("AdchainBenefit must be initialized before creating BenefitHub ViewController")
        }
        
        let finalConfig = config ?? AdchainBenefitHubConfig.Builder().build()
        return AdchainBenefitHubViewController(config: finalConfig)
    }
    
    /// BenefitHub가 표시 가능한지 확인
    /// - Returns: 표시 가능 여부
    public func isAvailable() -> Bool {
        return AdchainBenefit.shared.getInitializationStatus() && 
               AdchainBenefit.shared.isLoggedIn()
    }
    
    /// 현재 표시 중인 BenefitHub 닫기
    /// - Parameter completion: 완료 콜백
    public func dismiss(completion: (() -> Void)? = nil) {
        guard let viewController = currentViewController else {
            completion?()
            return
        }
        
        viewController.dismiss(animated: true) { [weak self] in
            self?.currentViewController = nil
            completion?()
        }
    }
    
    /// 현재 BenefitHub 표시 상태
    /// - Returns: 표시 중 여부
    public func isShowing() -> Bool {
        return currentViewController != nil && 
               currentViewController?.presentingViewController != nil
    }
    
    /// 현재 설정 반환
    /// - Returns: 현재 BenefitHub 설정
    public func getCurrentConfig() -> AdchainBenefitHubConfig? {
        return config
    }
    
    // MARK: - Private Methods
    
    private func presentBenefitHub(_ benefitHubVC: AdchainBenefitHubViewController, from viewController: UIViewController) {
        currentViewController = benefitHubVC
        
        // 델리게이트 설정
        benefitHubVC.delegate = self
        
        viewController.present(benefitHubVC, animated: true) {
            Logger.shared.log("BenefitHub presented successfully", level: .info)
        }
    }
    
    private func showError(_ error: Error, from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
}

// MARK: - AdchainBenefitHubViewControllerDelegate

extension AdchainBenefitHub: AdchainBenefitHubViewControllerDelegate {
    
    func benefitHubViewControllerDidClose(_ viewController: AdchainBenefitHubViewController) {
        Logger.shared.log("BenefitHub closed by user", level: .debug)
        currentViewController = nil
    }
    
    func benefitHubViewController(_ viewController: AdchainBenefitHubViewController, didSelectTab tab: AdchainBenefitHubConfig.TabType) {
        Logger.shared.log("BenefitHub tab selected: \(tab.rawValue)", level: .debug)
    }
    
    func benefitHubViewController(_ viewController: AdchainBenefitHubViewController, didEarnReward amount: Int) {
        Logger.shared.log("Reward earned in BenefitHub: \(amount)", level: .info)
    }
}

// MARK: - Protocol

protocol AdchainBenefitHubViewControllerDelegate: AnyObject {
    func benefitHubViewControllerDidClose(_ viewController: AdchainBenefitHubViewController)
    func benefitHubViewController(_ viewController: AdchainBenefitHubViewController, didSelectTab tab: AdchainBenefitHubConfig.TabType)
    func benefitHubViewController(_ viewController: AdchainBenefitHubViewController, didEarnReward amount: Int)
}