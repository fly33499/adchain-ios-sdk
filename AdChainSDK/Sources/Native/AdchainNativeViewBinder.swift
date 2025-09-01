import UIKit

/// Buzzville SDK v6 호환 Native 광고 View Binder
/// Builder 패턴을 사용하여 뷰와 광고 데이터를 바인딩합니다
public class AdchainNativeViewBinder {
    
    // MARK: - Properties
    
    // View references
    private weak var nativeAdView: AdchainNativeAdView?
    private weak var mediaView: AdchainMediaView?
    private weak var titleLabel: UILabel?
    private weak var descriptionLabel: UILabel?
    private weak var iconImageView: UIImageView?
    private weak var ctaView: UIView?
    private weak var sponsorLabel: UILabel?
    private weak var ratingView: UIView?
    private weak var priceLabel: UILabel?
    
    // Clickable views
    private var clickableViews: [UIView] = []
    
    // Current bound native
    private weak var boundNative: AdchainNative?
    
    // Gesture recognizers
    private var tapGestureRecognizers: [UITapGestureRecognizer] = []
    
    // Image loading tasks
    private var imageLoadingTasks: [URLSessionDataTask] = []
    
    // MARK: - Private Init
    
    private init(builder: Builder) {
        self.nativeAdView = builder.nativeAdView
        self.mediaView = builder.mediaView
        self.titleLabel = builder.titleLabel
        self.descriptionLabel = builder.descriptionLabel
        self.iconImageView = builder.iconImageView
        self.ctaView = builder.ctaView
        self.sponsorLabel = builder.sponsorLabel
        self.ratingView = builder.ratingView
        self.priceLabel = builder.priceLabel
        self.clickableViews = builder.clickableViews
        
        Logger.shared.log("AdchainNativeViewBinder created", level: .debug)
    }
    
    // MARK: - Builder
    
    /// Builder 클래스 - Buzzville SDK v6 패턴
    public class Builder {
        
        // View references
        internal weak var nativeAdView: AdchainNativeAdView?
        internal weak var mediaView: AdchainMediaView?
        internal weak var titleLabel: UILabel?
        internal weak var descriptionLabel: UILabel?
        internal weak var iconImageView: UIImageView?
        internal weak var ctaView: UIView?
        internal weak var sponsorLabel: UILabel?
        internal weak var ratingView: UIView?
        internal weak var priceLabel: UILabel?
        internal var clickableViews: [UIView] = []
        
        public init() {}
        
        /// Native 광고 컨테이너 뷰 설정
        @discardableResult
        public func nativeAdView(_ view: AdchainNativeAdView) -> Builder {
            self.nativeAdView = view
            return self
        }
        
        /// 미디어 뷰 설정
        @discardableResult
        public func mediaView(_ view: AdchainMediaView) -> Builder {
            self.mediaView = view
            return self
        }
        
        /// 제목 레이블 설정
        @discardableResult
        public func titleLabel(_ label: UILabel) -> Builder {
            self.titleLabel = label
            return self
        }
        
        /// 설명 레이블 설정
        @discardableResult
        public func descriptionLabel(_ label: UILabel) -> Builder {
            self.descriptionLabel = label
            return self
        }
        
        /// 아이콘 이미지 뷰 설정
        @discardableResult
        public func iconImageView(_ imageView: UIImageView) -> Builder {
            self.iconImageView = imageView
            return self
        }
        
        /// CTA 뷰 설정
        @discardableResult
        public func ctaView(_ view: UIView) -> Builder {
            self.ctaView = view
            return self
        }
        
        /// CTA 버튼 설정 (UIButton용 convenience)
        @discardableResult
        public func ctaButton(_ button: UIButton) -> Builder {
            self.ctaView = button
            return self
        }
        
        /// 스폰서 레이블 설정
        @discardableResult
        public func sponsorLabel(_ label: UILabel) -> Builder {
            self.sponsorLabel = label
            return self
        }
        
        /// 평점 뷰 설정
        @discardableResult
        public func ratingView(_ view: UIView) -> Builder {
            self.ratingView = view
            return self
        }
        
        /// 가격 레이블 설정
        @discardableResult
        public func priceLabel(_ label: UILabel) -> Builder {
            self.priceLabel = label
            return self
        }
        
        /// 클릭 가능한 뷰 설정
        @discardableResult
        public func setClickableViews(_ views: [UIView]) -> Builder {
            self.clickableViews = views
            return self
        }
        
        /// 클릭 가능한 뷰 추가
        @discardableResult
        public func addClickableView(_ view: UIView) -> Builder {
            if !clickableViews.contains(where: { $0 === view }) {
                clickableViews.append(view)
            }
            return self
        }
        
        /// ViewBinder 객체 생성
        public func build() -> AdchainNativeViewBinder {
            // Add default clickable views if not specified
            if clickableViews.isEmpty {
                var defaultClickables: [UIView] = []
                
                if let nativeAdView = nativeAdView {
                    defaultClickables.append(nativeAdView)
                }
                if let mediaView = mediaView {
                    defaultClickables.append(mediaView)
                }
                if let ctaView = ctaView {
                    defaultClickables.append(ctaView)
                }
                
                if !defaultClickables.isEmpty {
                    clickableViews = defaultClickables
                }
            }
            
            return AdchainNativeViewBinder(builder: self)
        }
    }
    
    // MARK: - Bind Methods
    
    /// Native 광고를 뷰에 바인딩
    /// - Parameter native: 바인딩할 Native 광고
    public func bind(_ native: AdchainNative) {
        // Unbind previous if exists
        unbind()
        
        guard let ad = native.getCurrentAd() else {
            Logger.shared.log("No ad loaded in native", level: .warning)
            return
        }
        
        self.boundNative = native
        native.setViewBinder(self)
        
        // Update views with ad data
        updateViews(with: ad)
        
        // Setup click handlers
        setupClickHandlers()
        
        // Track impression
        native.trackImpression()
        
        Logger.shared.log("Bound native ad: \(ad.id)", level: .debug)
    }
    
    /// 바인딩 해제
    public func unbind() {
        // Remove click handlers
        removeClickHandlers()
        
        // Cancel image loading
        cancelImageLoading()
        
        // Clear native reference
        boundNative?.clearViewBinder()
        boundNative = nil
        
        // Clear view content
        clearViews()
        
        Logger.shared.log("Unbound native ad", level: .debug)
    }
    
    // MARK: - View Updates
    
    /// 새로운 광고로 뷰 업데이트 (자동 갱신용)
    internal func updateWithNewAd(_ ad: AdchainNativeAd) {
        updateViews(with: ad)
        
        Logger.shared.log("Updated views with new ad: \(ad.id)", level: .debug)
    }
    
    /// 뷰 업데이트
    private func updateViews(with ad: AdchainNativeAd) {
        // Update title
        titleLabel?.text = ad.title
        
        // Update description
        descriptionLabel?.text = ad.description
        
        // Update CTA
        if let ctaButton = ctaView as? UIButton {
            ctaButton.setTitle(ad.ctaText, for: .normal)
        } else if let ctaLabel = ctaView as? UILabel {
            ctaLabel.text = ad.ctaText
        } else if let defaultCta = ctaView as? AdchainDefaultCtaView {
            defaultCta.setCtaText(ad.ctaText)
        }
        
        // Update sponsor
        sponsorLabel?.text = ad.sponsorName
        
        // Update price
        if let price = ad.price {
            priceLabel?.text = price
        }
        
        // Update rating
        if let rating = ad.rating, let ratingView = ratingView {
            updateRatingView(ratingView, rating: rating)
        }
        
        // Load media
        if let mediaView = mediaView {
            mediaView.loadAd(ad)
        } else if let imageView = mediaView as? UIImageView {
            loadImage(from: ad.imageUrl, into: imageView)
        }
        
        // Load icon
        if let iconUrl = ad.iconUrl, let iconImageView = iconImageView {
            loadImage(from: iconUrl, into: iconImageView)
        }
        
        // Update native ad view
        nativeAdView?.setNativeAd(ad)
    }
    
    /// 뷰 내용 지우기
    private func clearViews() {
        titleLabel?.text = nil
        descriptionLabel?.text = nil
        sponsorLabel?.text = nil
        priceLabel?.text = nil
        
        if let ctaButton = ctaView as? UIButton {
            ctaButton.setTitle(nil, for: .normal)
        } else if let ctaLabel = ctaView as? UILabel {
            ctaLabel.text = nil
        }
        
        mediaView?.clear()
        iconImageView?.image = nil
        nativeAdView?.clear()
    }
    
    /// 평점 뷰 업데이트
    private func updateRatingView(_ view: UIView, rating: Double) {
        // Simple implementation - can be customized
        if let label = view as? UILabel {
            label.text = String(format: "★ %.1f", rating)
        }
    }
    
    // MARK: - Image Loading
    
    /// 이미지 로드
    private func loadImage(from urlString: String, into imageView: UIImageView) {
        guard let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak imageView] data, _, error in
            guard let data = data, error == nil,
                  let image = UIImage(data: data) else { return }
            
            DispatchQueue.main.async {
                imageView?.image = image
            }
        }
        
        task.resume()
        imageLoadingTasks.append(task)
    }
    
    /// 이미지 로딩 취소
    private func cancelImageLoading() {
        imageLoadingTasks.forEach { $0.cancel() }
        imageLoadingTasks.removeAll()
    }
    
    // MARK: - Click Handling
    
    /// 클릭 핸들러 설정
    private func setupClickHandlers() {
        clickableViews.forEach { view in
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleClick))
            view.addGestureRecognizer(tapGesture)
            view.isUserInteractionEnabled = true
            tapGestureRecognizers.append(tapGesture)
        }
    }
    
    /// 클릭 핸들러 제거
    private func removeClickHandlers() {
        tapGestureRecognizers.forEach { gesture in
            gesture.view?.removeGestureRecognizer(gesture)
        }
        tapGestureRecognizers.removeAll()
    }
    
    /// 클릭 처리
    @objc private func handleClick() {
        boundNative?.startParticipation()
    }
    
    // MARK: - Getters
    
    /// 현재 바인딩된 Native 반환
    public func getBoundNative() -> AdchainNative? {
        return boundNative
    }
    
    /// 바인딩 상태 확인
    public func isBound() -> Bool {
        return boundNative != nil
    }
    
    // MARK: - Cleanup
    
    deinit {
        unbind()
    }
}

// MARK: - Convenience Methods

extension AdchainNativeViewBinder {
    
    /// 간단한 바인딩 (최소 요구사항)
    public static func simple(
        titleLabel: UILabel,
        ctaButton: UIButton
    ) -> AdchainNativeViewBinder {
        return Builder()
            .titleLabel(titleLabel)
            .ctaButton(ctaButton)
            .build()
    }
    
    /// 기본 바인딩 (일반적인 사용)
    public static func standard(
        titleLabel: UILabel,
        descriptionLabel: UILabel,
        mediaView: AdchainMediaView,
        ctaButton: UIButton
    ) -> AdchainNativeViewBinder {
        return Builder()
            .titleLabel(titleLabel)
            .descriptionLabel(descriptionLabel)
            .mediaView(mediaView)
            .ctaButton(ctaButton)
            .build()
    }
    
    /// 전체 바인딩 (모든 요소)
    public static func full(
        nativeAdView: AdchainNativeAdView,
        titleLabel: UILabel,
        descriptionLabel: UILabel,
        mediaView: AdchainMediaView,
        iconImageView: UIImageView,
        ctaView: UIView,
        sponsorLabel: UILabel
    ) -> AdchainNativeViewBinder {
        return Builder()
            .nativeAdView(nativeAdView)
            .titleLabel(titleLabel)
            .descriptionLabel(descriptionLabel)
            .mediaView(mediaView)
            .iconImageView(iconImageView)
            .ctaView(ctaView)
            .sponsorLabel(sponsorLabel)
            .build()
    }
}