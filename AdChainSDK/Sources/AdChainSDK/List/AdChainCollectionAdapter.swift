import UIKit

/// CollectionView adapter that automatically inserts ads between original content
public class AdChainCollectionAdapter: NSObject {
    private weak var collectionView: UICollectionView?
    private let originalDataSource: UICollectionViewDataSource
    private let originalDelegate: UICollectionViewDelegate?
    private let originalFlowLayoutDelegate: UICollectionViewDelegateFlowLayout?
    private let config: ListAdConfig
    private let adLoader = AdChainSDK.shared.nativeAdLoader
    
    private var ads = [Int: NativeAdData]()
    private var loadedAds = [NativeAdData]()
    private var impressedAds = Set<String>()
    
    public var collectionViewBinder: CollectionViewBinder
    public var onAdClick: ((NativeAdData, Int) -> Void)?
    public var onAdImpression: ((NativeAdData, Int) -> Void)?
    
    private let adCellIdentifier = "AdChainCollectionAdCell"
    
    public init(
        collectionView: UICollectionView,
        originalDataSource: UICollectionViewDataSource,
        originalDelegate: UICollectionViewDelegate? = nil,
        config: ListAdConfig,
        collectionViewBinder: CollectionViewBinder = DefaultCollectionViewBinder()
    ) {
        self.collectionView = collectionView
        self.originalDataSource = originalDataSource
        self.originalDelegate = originalDelegate
        self.originalFlowLayoutDelegate = originalDelegate as? UICollectionViewDelegateFlowLayout
        self.config = config
        self.collectionViewBinder = collectionViewBinder
        super.init()
        
        setupCollectionView()
        loadAds()
    }
    
    private func setupCollectionView() {
        collectionView?.dataSource = self
        collectionView?.delegate = self
        collectionView?.register(AdCollectionViewCell.self, forCellWithReuseIdentifier: adCellIdentifier)
    }
    
    /// Load ads from server
    public func loadAds() {
        Task {
            do {
                let request = NativeAdRequest(
                    unitId: config.unitId,
                    count: config.preloadCount
                )
                
                let response = try await adLoader.loadAds(request: request)
                await MainActor.run {
                    self.loadedAds.append(contentsOf: response.ads)
                    self.distributeAds()
                }
                
                AdChainLogger.log("Loaded \(response.ads.count) ads for collection")
            } catch {
                AdChainLogger.error("Failed to load ads: \(error)")
            }
        }
    }
    
    /// Refresh ads
    public func refreshAds() {
        ads.removeAll()
        loadedAds.removeAll()
        impressedAds.removeAll()
        loadAds()
    }
    
    private func distributeAds() {
        ads.removeAll()
        
        let totalItems = originalDataSource.collectionView(collectionView!, numberOfItemsInSection: 0)
        var adIndex = 0
        var position = config.firstAdPosition
        
        while position < totalItems && adIndex < loadedAds.count {
            ads[position] = loadedAds[adIndex]
            adIndex += 1
            position += config.adInterval
        }
        
        collectionView?.reloadData()
    }
    
    /// Check if position contains an ad
    public func isAdPosition(_ indexPath: IndexPath) -> Bool {
        guard indexPath.section == 0 else { return false }
        return getAdAtPosition(indexPath) != nil
    }
    
    /// Get ad at specific position
    public func getAdAtPosition(_ indexPath: IndexPath) -> NativeAdData? {
        guard indexPath.section == 0 else { return nil }
        let originalPosition = getOriginalPositionIgnoringAds(indexPath.item)
        return ads[originalPosition]
    }
    
    /// Get original position accounting for inserted ads
    public func getOriginalIndexPath(_ indexPath: IndexPath) -> IndexPath {
        guard indexPath.section == 0 else { return indexPath }
        
        var originalItem = indexPath.item
        for (adPos, _) in ads where adPos <= originalItem {
            originalItem -= 1
        }
        
        return IndexPath(item: originalItem, section: indexPath.section)
    }
    
    private func getOriginalPositionIgnoringAds(_ position: Int) -> Int {
        var adsBeforePosition = 0
        for (adPos, _) in ads {
            if adPos + adsBeforePosition < position {
                adsBeforePosition += 1
            }
        }
        return position - adsBeforePosition
    }
    
    private func trackImpression(_ ad: NativeAdData, position: Int) {
        guard !impressedAds.contains(ad.id) else { return }
        
        impressedAds.insert(ad.id)
        adLoader.trackImpression(ad)
        onAdImpression?(ad, position)
    }
    
    /// Clean up resources
    public func destroy() {
        ads.removeAll()
        loadedAds.removeAll()
        impressedAds.removeAll()
    }
}

// MARK: - UICollectionViewDataSource
extension AdChainCollectionAdapter: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return originalDataSource.numberOfSections?(in: collectionView) ?? 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard section == 0 else {
            return originalDataSource.collectionView(collectionView, numberOfItemsInSection: section)
        }
        
        let originalCount = originalDataSource.collectionView(collectionView, numberOfItemsInSection: section)
        return originalCount + ads.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if isAdPosition(indexPath) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: adCellIdentifier, for: indexPath) as! AdCollectionViewCell
            
            if let ad = getAdAtPosition(indexPath) {
                cell.configure(with: ad, viewBinder: collectionViewBinder, position: indexPath.item)
                cell.onAdClick = { [weak self] ad in
                    self?.adLoader.trackClick(ad)
                    self?.onAdClick?(ad, indexPath.item)
                }
                trackImpression(ad, position: indexPath.item)
            }
            
            return cell
        } else {
            let originalIndexPath = getOriginalIndexPath(indexPath)
            return originalDataSource.collectionView(collectionView, cellForItemAt: originalIndexPath)
        }
    }
}

// MARK: - UICollectionViewDelegate
extension AdChainCollectionAdapter: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !isAdPosition(indexPath) {
            let originalIndexPath = getOriginalIndexPath(indexPath)
            originalDelegate?.collectionView?(collectionView, didSelectItemAt: originalIndexPath)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if !isAdPosition(indexPath) {
            let originalIndexPath = getOriginalIndexPath(indexPath)
            originalDelegate?.collectionView?(collectionView, willDisplay: cell, forItemAt: originalIndexPath)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension AdChainCollectionAdapter: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if isAdPosition(indexPath) {
            return collectionViewBinder.getSize(collectionView: collectionView)
        } else {
            let originalIndexPath = getOriginalIndexPath(indexPath)
            return originalFlowLayoutDelegate?.collectionView?(collectionView, layout: collectionViewLayout, sizeForItemAt: originalIndexPath) ?? (collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize ?? CGSize(width: 50, height: 50)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return originalFlowLayoutDelegate?.collectionView?(collectionView, layout: collectionViewLayout, insetForSectionAt: section) ?? (collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset ?? .zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return originalFlowLayoutDelegate?.collectionView?(collectionView, layout: collectionViewLayout, minimumLineSpacingForSectionAt: section) ?? (collectionViewLayout as? UICollectionViewFlowLayout)?.minimumLineSpacing ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return originalFlowLayoutDelegate?.collectionView?(collectionView, layout: collectionViewLayout, minimumInteritemSpacingForSectionAt: section) ?? (collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing ?? 0
    }
}

// MARK: - Ad Cell
private class AdCollectionViewCell: UICollectionViewCell {
    private var containerView: UIView?
    var onAdClick: ((NativeAdData) -> Void)?
    private var currentAd: NativeAdData?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with ad: NativeAdData, viewBinder: CollectionViewBinder, position: Int) {
        currentAd = ad
        
        // Remove previous container if exists
        containerView?.removeFromSuperview()
        
        // Create new ad view
        let adView = viewBinder.createView()
        viewBinder.bindView(adView, ad: ad, position: position)
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        adView.addGestureRecognizer(tapGesture)
        adView.isUserInteractionEnabled = true
        
        // Add to cell
        containerView = adView
        contentView.addSubview(adView)
        
        // Setup constraints
        adView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            adView.topAnchor.constraint(equalTo: contentView.topAnchor),
            adView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            adView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            adView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    @objc private func handleTap() {
        if let ad = currentAd {
            onAdClick?(ad)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        containerView?.removeFromSuperview()
        containerView = nil
        currentAd = nil
    }
}