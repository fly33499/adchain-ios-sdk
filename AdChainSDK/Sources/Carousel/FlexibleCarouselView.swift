import UIKit

/// Flexible carousel view that supports custom view binding
/// This allows developers to customize how ads are displayed while keeping the carousel behavior
public class FlexibleCarouselView: UIView {
    
    // Core components
    private var collectionView: UICollectionView!
    private let adLoader = AdChainSDK.shared.nativeAdLoader
    
    // Configuration
    private var unitId: String = ""
    private var itemCount: Int = 5
    private var viewBinder: CarouselViewBinder = DefaultCarouselViewBinder()
    private var autoScroll: Bool = false
    private var scrollInterval: TimeInterval = 3.0
    
    // State
    private var ads: [NativeAdData] = []
    private var isLoading = false
    private var autoScrollTimer: Timer?
    
    // Callbacks
    public var onItemClick: ((NativeAdData, Int) -> Void)?
    public var onLoadComplete: (([NativeAdData]) -> Void)?
    public var onLoadError: ((Error) -> Void)?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // Collection view layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        // Collection view
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(FlexibleCarouselCell.self, forCellWithReuseIdentifier: "FlexibleCarouselCell")
        
        addSubview(collectionView)
        
        // Constraints
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    /// Configure the carousel
    public func configure(
        unitId: String,
        itemCount: Int = 5,
        viewBinder: CarouselViewBinder? = nil,
        autoScroll: Bool = false,
        scrollInterval: TimeInterval = 3.0
    ) {
        self.unitId = unitId
        self.itemCount = itemCount
        self.viewBinder = viewBinder ?? DefaultCarouselViewBinder()
        self.autoScroll = autoScroll
        self.scrollInterval = scrollInterval
    }
    
    /// Set custom view binder
    public func setViewBinder(_ binder: CarouselViewBinder) {
        self.viewBinder = binder
        collectionView.reloadData()
    }
    
    /// Load ads into the carousel
    public func load() {
        guard !isLoading, !unitId.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                let request = NativeAdRequest(
                    unitId: unitId,
                    count: itemCount
                )
                
                let response = try await adLoader.loadAds(request: request)
                self.ads = response.ads
                
                await MainActor.run {
                    self.collectionView.reloadData()
                    self.isLoading = false
                    self.onLoadComplete?(response.ads)
                    
                    // Start auto-scroll if enabled
                    if self.autoScroll && !response.ads.isEmpty {
                        self.startAutoScroll()
                    }
                    
                    // Track initial impressions
                    self.trackVisibleItems()
                }
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    Logger.shared.log("Failed to load ads: \(error)", level: .error)
                    self.onLoadError?(error)
                }
            }
        }
    }
    
    /// Refresh carousel with new ads
    public func refresh() {
        stopAutoScroll()
        ads.removeAll()
        collectionView.reloadData()
        load()
    }
    
    /// Get current ads
    public func getAds() -> [NativeAdData] {
        return ads
    }
    
    /// Scroll to specific position
    public func scrollToPosition(_ position: Int, animated: Bool = true) {
        let indexPath = IndexPath(item: position, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    }
    
    private func trackVisibleItems() {
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        
        for indexPath in visibleIndexPaths {
            if indexPath.item < ads.count {
                let ad = ads[indexPath.item]
                adLoader.trackImpression(ad: ad)
            }
        }
    }
    
    private func startAutoScroll() {
        stopAutoScroll()
        
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: scrollInterval, repeats: true) { [weak self] _ in
            self?.scrollToNext()
        }
    }
    
    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
    
    private func scrollToNext() {
        guard !ads.isEmpty else { return }
        
        let visibleItems = collectionView.indexPathsForVisibleItems.sorted()
        guard let currentIndexPath = visibleItems.first else { return }
        
        let nextItem = (currentIndexPath.item + 1) % ads.count
        let nextIndexPath = IndexPath(item: nextItem, section: 0)
        
        collectionView.scrollToItem(at: nextIndexPath, at: .centeredHorizontally, animated: true)
    }
    
    public func pause() {
        stopAutoScroll()
    }
    
    public func resume() {
        if autoScroll && !ads.isEmpty {
            startAutoScroll()
        }
    }
    
    public func destroy() {
        stopAutoScroll()
        ads.removeAll()
        collectionView.delegate = nil
        collectionView.dataSource = nil
    }
    
    deinit {
        destroy()
    }
}

// MARK: - UICollectionViewDataSource

extension FlexibleCarouselView: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ads.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FlexibleCarouselCell", for: indexPath) as! FlexibleCarouselCell
        
        let ad = ads[indexPath.item]
        cell.configure(with: ad, viewBinder: viewBinder)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension FlexibleCarouselView: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let ad = ads[indexPath.item]
        adLoader.trackClick(ad: ad)
        onItemClick?(ad, indexPath.item)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        trackVisibleItems()
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            trackVisibleItems()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension FlexibleCarouselView: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.bounds.height
        let width = min(collectionView.bounds.width - 32, 300) // Max width 300
        return CGSize(width: width, height: height)
    }
}

// MARK: - FlexibleCarouselCell

private class FlexibleCarouselCell: UICollectionViewCell {
    
    private var customView: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with ad: NativeAdData, viewBinder: CarouselViewBinder) {
        // Remove old custom view
        customView?.removeFromSuperview()
        
        // Create and configure new view
        let view = viewBinder.createView()
        viewBinder.bindView(view, ad: ad, at: 0)
        
        // Add to content view
        contentView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        customView = view
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        customView?.removeFromSuperview()
        customView = nil
    }
}