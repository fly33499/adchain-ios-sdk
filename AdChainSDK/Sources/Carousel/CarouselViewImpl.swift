import UIKit

internal class CarouselViewImpl: UIView, CarouselView {
    
    private let config: CarouselConfig
    private let apiClient: ApiClient
    private weak var delegate: CarouselDelegate?
    
    private var collectionView: UICollectionView!
    private var refreshControl: UIRefreshControl!
    private var loadingIndicator: UIActivityIndicatorView!
    
    private var items: [CarouselItem] = []
    private var isLoadingState = false
    private var isPaused = false
    private var impressionTracker = Set<String>()
    private var autoScrollTimer: Timer?
    
    private let analytics: AdChainAnalyticsImpl? = nil // 임시 - AdchainBenefit.shared 통해 접근 필요
    
    init(config: CarouselConfig, apiClient: ApiClient, delegate: CarouselDelegate?) {
        self.config = config
        self.apiClient = apiClient
        self.delegate = delegate
        
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // Collection View Layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        
        // Collection View
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CarouselItemCell.self, forCellWithReuseIdentifier: "CarouselItemCell")
        
        // Refresh Control
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        
        // Loading Indicator
        loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingIndicator.hidesWhenStopped = true
        
        // Add subviews
        addSubview(collectionView)
        addSubview(loadingIndicator)
        
        // Layout
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        if config.autoScroll {
            setupAutoScroll()
        }
    }
    
    // MARK: - CarouselView Protocol
    
    func load() {
        guard !isLoadingState else { return }
        
        isLoadingState = true
        if config.showLoadingIndicator {
            loadingIndicator.startAnimating()
        }
        
        apiClient.fetchCarouselAds(unitId: config.unitId, count: config.itemCount) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.loadingIndicator.stopAnimating()
                self.isLoadingState = false
                
                switch result {
                case .success(let ads):
                    self.items = ads.map { $0.toCarouselItem() }
                    self.collectionView.reloadData()
                    self.delegate?.carouselDidLoad(itemCount: self.items.count)
                    
                    // Track initial impressions
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.trackVisibleItems()
                    }
                    
                case .failure(let error):
                    Logger.shared.log("Failed to load carousel ads: \(error)", level: .error)
                    self.delegate?.carousel(didFailToLoadWithError: error)
                }
            }
        }
    }
    
    func refresh() {
        impressionTracker.removeAll()
        handleRefresh()
    }
    
    @objc private func handleRefresh() {
        apiClient.fetchCarouselAds(unitId: config.unitId, count: config.itemCount) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.refreshControl.endRefreshing()
                
                switch result {
                case .success(let ads):
                    self.items = ads.map { $0.toCarouselItem() }
                    self.collectionView.reloadData()
                    self.delegate?.carouselDidRefresh()
                    
                    // Track new impressions
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.trackVisibleItems()
                    }
                    
                case .failure(let error):
                    Logger.shared.log("Failed to refresh carousel ads: \(error)", level: .error)
                }
            }
        }
    }
    
    func pause() {
        isPaused = true
        stopAutoScroll()
    }
    
    func resume() {
        isPaused = false
        if config.autoScroll {
            setupAutoScroll()
        }
    }
    
    func destroy() {
        stopAutoScroll()
        delegate = nil
        collectionView.delegate = nil
        collectionView.dataSource = nil
    }
    
    var isLoading: Bool {
        return isLoadingState
    }
    
    var itemCount: Int {
        return items.count
    }
    
    // MARK: - Auto Scroll
    
    private func setupAutoScroll() {
        autoScrollTimer = Timer.scheduledTimer(
            timeInterval: config.scrollInterval,
            target: self,
            selector: #selector(autoScroll),
            userInfo: nil,
            repeats: true
        )
    }
    
    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
    
    @objc private func autoScroll() {
        guard !isPaused, items.count > 0 else { return }
        
        let visibleItems = collectionView.indexPathsForVisibleItems.sorted()
        guard let currentIndexPath = visibleItems.first else { return }
        
        let nextItem: Int
        if config.enableInfiniteScroll {
            nextItem = (currentIndexPath.item + 1) % items.count
        } else {
            nextItem = min(currentIndexPath.item + 1, items.count - 1)
        }
        
        let nextIndexPath = IndexPath(item: nextItem, section: 0)
        collectionView.scrollToItem(at: nextIndexPath, at: .centeredHorizontally, animated: true)
    }
    
    // MARK: - Impression Tracking
    
    private func trackVisibleItems() {
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        
        for indexPath in visibleIndexPaths {
            let item = items[indexPath.item]
            if !impressionTracker.contains(item.id) {
                impressionTracker.insert(item.id)
                
                analytics?.trackCarouselImpression(position: indexPath.item, itemId: item.id)
                delegate?.carousel(didImpressionItemAt: indexPath.item, item: item)
            }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension CarouselViewImpl: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CarouselItemCell", for: indexPath) as! CarouselItemCell
        cell.configure(with: items[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension CarouselViewImpl: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.item]
        
        analytics?.trackCarouselClick(position: indexPath.item, itemId: item.id)
        delegate?.carousel(didSelectItemAt: indexPath.item, item: item)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        trackVisibleItems()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            trackVisibleItems()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension CarouselViewImpl: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.bounds.height - 16 // Account for section insets
        let width = height * 0.8 // 4:5 aspect ratio
        return CGSize(width: width, height: height)
    }
}

// MARK: - Helper Extensions

private extension CarouselAdResponse {
    func toCarouselItem() -> CarouselItem {
        return CarouselItem(
            id: id,
            title: title,
            description: description,
            imageUrl: imageUrl,
            landingUrl: landingUrl,
            metadata: metadata
        )
    }
}