import UIKit

/// Buzzville SDK v6 호환 CTA(Call-to-Action) 버튼 뷰
/// 광고 참여 상태를 자동으로 관리합니다
public class AdchainDefaultCtaView: UIView {
    
    // MARK: - State
    
    public enum State: Equatable {
        case normal           // "참여하기"
        case loading         // "참여 확인 중"
        case completed       // "참여 완료"
        case rewarded(Int)   // "100 포인트 받기"
        case disabled        // 비활성화
        
        var title: String {
            switch self {
            case .normal:
                return "참여하기"
            case .loading:
                return "참여 확인 중"
            case .completed:
                return "참여 완료"
            case .rewarded(let points):
                return "\(points) 포인트 받기"
            case .disabled:
                return "참여 불가"
            }
        }
        
        var isEnabled: Bool {
            switch self {
            case .normal, .rewarded:
                return true
            case .loading, .completed, .disabled:
                return false
            }
        }
    }
    
    // MARK: - Properties
    
    private var currentState: State = .normal {
        didSet {
            updateAppearance()
        }
    }
    
    // UI Components
    private lazy var button: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = cornerRadius
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = .white
        return indicator
    }()
    
    private lazy var checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark.circle.fill")
        imageView.tintColor = .white
        imageView.isHidden = true
        return imageView
    }()
    
    private lazy var rewardImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "gift.fill")
        imageView.tintColor = .white
        imageView.isHidden = true
        return imageView
    }()
    
    // Configuration
    public var cornerRadius: CGFloat = 8 {
        didSet {
            button.layer.cornerRadius = cornerRadius
        }
    }
    
    public var normalBackgroundColor = UIColor.systemBlue {
        didSet {
            updateAppearance()
        }
    }
    
    public var loadingBackgroundColor = UIColor.systemGray {
        didSet {
            updateAppearance()
        }
    }
    
    public var completedBackgroundColor = UIColor.systemGreen {
        didSet {
            updateAppearance()
        }
    }
    
    public var rewardedBackgroundColor = UIColor.systemOrange {
        didSet {
            updateAppearance()
        }
    }
    
    public var disabledBackgroundColor = UIColor.systemGray3 {
        didSet {
            updateAppearance()
        }
    }
    
    public var textColor = UIColor.white {
        didSet {
            button.setTitleColor(textColor, for: .normal)
        }
    }
    
    // Custom text
    private var customCtaText: String?
    
    // Delegate
    public weak var delegate: AdchainDefaultCtaViewDelegate?
    
    // Animation
    private var pulseAnimation: CABasicAnimation?
    
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
        // Add button
        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Add loading indicator
        button.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingIndicator.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            loadingIndicator.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16)
        ])
        
        // Add checkmark
        button.addSubview(checkmarkImageView)
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            checkmarkImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            checkmarkImageView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 20),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        // Add reward icon
        button.addSubview(rewardImageView)
        rewardImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rewardImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            rewardImageView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            rewardImageView.widthAnchor.constraint(equalToConstant: 20),
            rewardImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        // Initial appearance
        updateAppearance()
        
        Logger.shared.log("AdchainDefaultCtaView initialized", level: .debug)
    }
    
    // MARK: - Public Methods
    
    /// CTA 텍스트 설정
    public func setCtaText(_ text: String) {
        customCtaText = text
        updateAppearance()
    }
    
    /// 상태 설정
    public func setState(_ state: State, animated: Bool = true) {
        guard currentState != state else { return }
        
        let previousState = currentState
        currentState = state
        
        if animated {
            animateStateTransition(from: previousState, to: state)
        }
        
        delegate?.ctaViewDidChangeState(self, from: previousState, to: state)
        
        Logger.shared.log("CTA state changed: \(previousState) -> \(state)", level: .debug)
    }
    
    /// 보상형 광고 설정
    public func setRewardedAd(points: Int) {
        setState(.rewarded(points))
    }
    
    /// 참여 시작
    public func startParticipation() {
        setState(.loading)
        delegate?.ctaViewDidStartParticipation(self)
    }
    
    /// 참여 완료
    public func completeParticipation(success: Bool) {
        if success {
            setState(.completed)
            delegate?.ctaViewDidCompleteParticipation(self, success: true)
        } else {
            setState(.normal)
            delegate?.ctaViewDidCompleteParticipation(self, success: false)
        }
    }
    
    /// 리셋
    public func reset() {
        setState(.normal)
        customCtaText = nil
    }
    
    /// 펄스 애니메이션 시작
    public func startPulseAnimation() {
        stopPulseAnimation()
        
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1.0
        animation.toValue = 1.05
        animation.duration = 0.8
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        button.layer.add(animation, forKey: "pulse")
        pulseAnimation = animation
    }
    
    /// 펄스 애니메이션 중지
    public func stopPulseAnimation() {
        button.layer.removeAnimation(forKey: "pulse")
        pulseAnimation = nil
    }
    
    // MARK: - Private Methods
    
    private func updateAppearance() {
        // Update title
        let title = customCtaText ?? currentState.title
        button.setTitle(title, for: .normal)
        button.setTitleColor(textColor, for: .normal)
        
        // Update background color
        let backgroundColor: UIColor
        switch currentState {
        case .normal:
            backgroundColor = normalBackgroundColor
        case .loading:
            backgroundColor = loadingBackgroundColor
        case .completed:
            backgroundColor = completedBackgroundColor
        case .rewarded:
            backgroundColor = rewardedBackgroundColor
        case .disabled:
            backgroundColor = disabledBackgroundColor
        }
        button.backgroundColor = backgroundColor
        
        // Update enabled state
        button.isEnabled = currentState.isEnabled
        button.alpha = currentState.isEnabled ? 1.0 : 0.7
        
        // Update icons
        loadingIndicator.stopAnimating()
        checkmarkImageView.isHidden = true
        rewardImageView.isHidden = true
        
        switch currentState {
        case .loading:
            loadingIndicator.startAnimating()
        case .completed:
            checkmarkImageView.isHidden = false
        case .rewarded:
            rewardImageView.isHidden = false
        default:
            break
        }
    }
    
    private func animateStateTransition(from: State, to: State) {
        // Scale animation
        UIView.animate(withDuration: 0.1, animations: {
            self.button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.button.transform = .identity
            }
        }
        
        // Success animation for completed state
        if case .completed = to {
            animateSuccess()
        }
        
        // Bounce animation for rewarded state
        if case .rewarded = to {
            animateBounce()
        }
    }
    
    private func animateSuccess() {
        // Checkmark pop animation
        checkmarkImageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 5,
            options: .curveEaseOut,
            animations: {
                self.checkmarkImageView.transform = .identity
            }
        )
        
        // Flash effect
        let flash = UIView()
        flash.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        flash.frame = button.bounds
        button.addSubview(flash)
        
        UIView.animate(withDuration: 0.3, animations: {
            flash.alpha = 0
        }) { _ in
            flash.removeFromSuperview()
        }
    }
    
    private func animateBounce() {
        // Bounce animation
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [1.0, 1.2, 0.9, 1.1, 1.0]
        animation.duration = 0.5
        animation.calculationMode = .cubic
        
        button.layer.add(animation, forKey: "bounce")
    }
    
    // MARK: - Actions
    
    @objc private func buttonTapped() {
        guard currentState.isEnabled else { return }
        
        delegate?.ctaViewDidTap(self)
        
        // Auto start participation for normal and rewarded states
        switch currentState {
        case .normal, .rewarded:
            startParticipation()
        default:
            break
        }
        
        Logger.shared.log("CTA button tapped", level: .debug)
    }
    
    // MARK: - Touch Feedback
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard currentState.isEnabled else { return }
        
        UIView.animate(withDuration: 0.1) {
            self.button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        UIView.animate(withDuration: 0.1) {
            self.button.transform = .identity
        }
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        UIView.animate(withDuration: 0.1) {
            self.button.transform = .identity
        }
    }
}

// MARK: - Delegate Protocol

public protocol AdchainDefaultCtaViewDelegate: AnyObject {
    /// CTA 버튼이 탭되었을 때 호출
    func ctaViewDidTap(_ view: AdchainDefaultCtaView)
    
    /// 상태가 변경되었을 때 호출
    func ctaViewDidChangeState(_ view: AdchainDefaultCtaView, from: AdchainDefaultCtaView.State, to: AdchainDefaultCtaView.State)
    
    /// 참여가 시작되었을 때 호출
    func ctaViewDidStartParticipation(_ view: AdchainDefaultCtaView)
    
    /// 참여가 완료되었을 때 호출
    func ctaViewDidCompleteParticipation(_ view: AdchainDefaultCtaView, success: Bool)
}

// MARK: - Default Delegate Implementation

public extension AdchainDefaultCtaViewDelegate {
    func ctaViewDidTap(_ view: AdchainDefaultCtaView) {}
    func ctaViewDidChangeState(_ view: AdchainDefaultCtaView, from: AdchainDefaultCtaView.State, to: AdchainDefaultCtaView.State) {}
    func ctaViewDidStartParticipation(_ view: AdchainDefaultCtaView) {}
    func ctaViewDidCompleteParticipation(_ view: AdchainDefaultCtaView, success: Bool) {}
}