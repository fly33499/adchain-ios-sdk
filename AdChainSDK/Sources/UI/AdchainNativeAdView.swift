import UIKit

/// Buzzville SDK v6 호환 Native 광고 컨테이너 뷰
/// 클릭 추적과 노출 측정 기능이 내장되어 있습니다
public class AdchainNativeAdView: UIView {
    
    // MARK: - Properties
    
    private var nativeAd: AdchainNativeAd?
    private var impressionTimer: Timer?
    private var impressionTracked = false
    private var visibilityThreshold: CGFloat = 0.5 // 50% 이상 보여야 노출로 인정
    private var impressionDelay: TimeInterval = 1.0 // 1초 이상 보여야 노출로 인정
    
    // Overlay views
    private lazy var sponsorBadge: UILabel = {
        let label = UILabel()
        label.text = "광고"
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        label.layer.cornerRadius = 3
        label.clipsToBounds = true
        label.textAlignment = .center
        return label
    }()
    
    private lazy var privacyIcon: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "info.circle.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(privacyIconTapped), for: .touchUpInside)
        return button
    }()
    
    // Configuration
    public var showSponsorBadge = true {
        didSet {
            sponsorBadge.isHidden = !showSponsorBadge
        }
    }
    
    public var showPrivacyIcon = true {
        didSet {
            privacyIcon.isHidden = !showPrivacyIcon
        }
    }
    
    // Delegate
    public weak var delegate: AdchainNativeAdViewDelegate?
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // Setup sponsor badge
        addSubview(sponsorBadge)
        sponsorBadge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sponsorBadge.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            sponsorBadge.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            sponsorBadge.widthAnchor.constraint(equalToConstant: 30),
            sponsorBadge.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        // Setup privacy icon
        addSubview(privacyIcon)
        privacyIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            privacyIcon.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            privacyIcon.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            privacyIcon.widthAnchor.constraint(equalToConstant: 20),
            privacyIcon.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        // Add border for debugging (optional)
        layer.borderColor = UIColor.clear.cgColor
        layer.borderWidth = 0
        
        Logger.shared.log("AdchainNativeAdView initialized", level: .debug)
    }
    
    // MARK: - Public Methods
    
    /// Native 광고 설정
    public func setNativeAd(_ ad: AdchainNativeAd) {
        self.nativeAd = ad
        impressionTracked = false
        
        // Start impression tracking
        startImpressionTracking()
        
        // Notify delegate
        delegate?.nativeAdViewDidSetAd(self, ad: ad)
        
        Logger.shared.log("Set native ad: \(ad.id)", level: .debug)
    }
    
    /// 뷰 내용 지우기
    public func clear() {
        stopImpressionTracking()
        nativeAd = nil
        impressionTracked = false
        
        Logger.shared.log("Cleared native ad view", level: .debug)
    }
    
    /// 수동으로 노출 추적
    public func trackImpression() {
        guard let ad = nativeAd, !impressionTracked else { return }
        
        impressionTracked = true
        ad.markImpressionTracked()
        
        delegate?.nativeAdViewDidTrackImpression(self, ad: ad)
        
        Logger.shared.log("Manually tracked impression for ad: \(ad.id)", level: .debug)
    }
    
    /// 수동으로 클릭 추적
    public func trackClick() {
        guard let ad = nativeAd else { return }
        
        ad.markClickTracked()
        delegate?.nativeAdViewDidTrackClick(self, ad: ad)
        
        Logger.shared.log("Manually tracked click for ad: \(ad.id)", level: .debug)
    }
    
    // MARK: - Impression Tracking
    
    private func startImpressionTracking() {
        stopImpressionTracking()
        
        // Check visibility immediately
        checkVisibilityAndStartTimer()
        
        // Observe scroll events if in scroll view
        if let scrollView = findSuperview(ofType: UIScrollView.self) {
            // Observe scroll view changes
            // Note: Direct scroll observation would require delegation
        }
    }
    
    private func stopImpressionTracking() {
        impressionTimer?.invalidate()
        impressionTimer = nil
    }
    
    private func checkVisibilityAndStartTimer() {
        guard !impressionTracked else { return }
        
        let visiblePercentage = calculateVisiblePercentage()
        
        if visiblePercentage >= visibilityThreshold {
            // Start timer if not already running
            if impressionTimer == nil {
                impressionTimer = Timer.scheduledTimer(
                    withTimeInterval: impressionDelay,
                    repeats: false
                ) { [weak self] _ in
                    self?.recordImpression()
                }
            }
        } else {
            // Stop timer if view is not visible enough
            impressionTimer?.invalidate()
            impressionTimer = nil
        }
    }
    
    private func calculateVisiblePercentage() -> CGFloat {
        guard let window = window else { return 0 }
        
        let viewFrame = convert(bounds, to: window)
        let windowBounds = window.bounds
        
        let intersection = viewFrame.intersection(windowBounds)
        guard !intersection.isNull else { return 0 }
        
        let visibleArea = intersection.width * intersection.height
        let totalArea = bounds.width * bounds.height
        
        guard totalArea > 0 else { return 0 }
        
        return visibleArea / totalArea
    }
    
    private func recordImpression() {
        guard let ad = nativeAd, !impressionTracked else { return }
        
        impressionTracked = true
        ad.markImpressionTracked()
        
        delegate?.nativeAdViewDidTrackImpression(self, ad: ad)
        
        Logger.shared.log("Auto-tracked impression for ad: \(ad.id)", level: .debug)
    }
    
    
    // MARK: - Touch Handling
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard let ad = nativeAd else { return }
        
        // Track click
        trackClick()
        
        // Open landing URL
        if let url = URL(string: ad.landingUrl) {
            UIApplication.shared.open(url)
        }
        
        delegate?.nativeAdViewDidClick(self, ad: ad)
    }
    
    // MARK: - Privacy
    
    @objc private func privacyIconTapped() {
        guard let ad = nativeAd else { return }
        
        delegate?.nativeAdViewDidTapPrivacyIcon(self, ad: ad)
        
        // Show privacy information
        showPrivacyInfo()
    }
    
    private func showPrivacyInfo() {
        let alert = UIAlertController(
            title: "광고 정보",
            message: "이 광고는 AdChain SDK를 통해 제공됩니다.\n개인화된 광고 설정은 앱 설정에서 변경할 수 있습니다.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        
        if let viewController = findViewController() {
            viewController.present(alert, animated: true)
        }
    }
    
    // MARK: - View Lifecycle
    
    public override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        
        if newWindow != nil {
            // View is being added to window
            startImpressionTracking()
        } else {
            // View is being removed from window
            stopImpressionTracking()
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // Bring overlay views to front
        bringSubviewToFront(sponsorBadge)
        bringSubviewToFront(privacyIcon)
    }
    
    // MARK: - Helper Methods
    
    private func findSuperview<T: UIView>(ofType type: T.Type) -> T? {
        var currentView: UIView? = superview
        while let view = currentView {
            if let typedView = view as? T {
                return typedView
            }
            currentView = view.superview
        }
        return nil
    }
    
    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }
    
    // MARK: - Cleanup
    
    deinit {
        stopImpressionTracking()
    }
}

// MARK: - Delegate Protocol

public protocol AdchainNativeAdViewDelegate: AnyObject {
    /// 광고가 설정되었을 때 호출
    func nativeAdViewDidSetAd(_ view: AdchainNativeAdView, ad: AdchainNativeAd)
    
    /// 노출이 추적되었을 때 호출
    func nativeAdViewDidTrackImpression(_ view: AdchainNativeAdView, ad: AdchainNativeAd)
    
    /// 클릭이 추적되었을 때 호출
    func nativeAdViewDidTrackClick(_ view: AdchainNativeAdView, ad: AdchainNativeAd)
    
    /// 광고가 클릭되었을 때 호출
    func nativeAdViewDidClick(_ view: AdchainNativeAdView, ad: AdchainNativeAd)
    
    /// 개인정보 아이콘이 탭되었을 때 호출
    func nativeAdViewDidTapPrivacyIcon(_ view: AdchainNativeAdView, ad: AdchainNativeAd)
}

// MARK: - Default Delegate Implementation

public extension AdchainNativeAdViewDelegate {
    func nativeAdViewDidSetAd(_ view: AdchainNativeAdView, ad: AdchainNativeAd) {}
    func nativeAdViewDidTrackImpression(_ view: AdchainNativeAdView, ad: AdchainNativeAd) {}
    func nativeAdViewDidTrackClick(_ view: AdchainNativeAdView, ad: AdchainNativeAd) {}
    func nativeAdViewDidClick(_ view: AdchainNativeAdView, ad: AdchainNativeAd) {}
    func nativeAdViewDidTapPrivacyIcon(_ view: AdchainNativeAdView, ad: AdchainNativeAd) {}
}