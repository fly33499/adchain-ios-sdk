import UIKit

/// Configuration for list ads
public struct ListAdConfig {
    public let unitId: String
    public let adInterval: Int
    public let firstAdPosition: Int
    public let preloadCount: Int
    public let viewBinder: TableViewBinder
    
    public init(
        unitId: String,
        adInterval: Int = 5,
        firstAdPosition: Int = 3,
        preloadCount: Int = 10,
        viewBinder: TableViewBinder = DefaultTableViewBinder()
    ) {
        self.unitId = unitId
        self.adInterval = adInterval
        self.firstAdPosition = firstAdPosition
        self.preloadCount = preloadCount
        self.viewBinder = viewBinder
    }
}

/// TableView adapter that automatically inserts ads between original content
public class AdChainTableAdapter: NSObject {
    private weak var tableView: UITableView?
    private let originalDataSource: UITableViewDataSource
    private let originalDelegate: UITableViewDelegate?
    private let config: ListAdConfig
    private let adLoader = AdChainSDK.shared.nativeAdLoader
    
    private var ads = [Int: NativeAdData]()
    private var loadedAds = [NativeAdData]()
    private var impressedAds = Set<String>()
    
    public var viewBinder: TableViewBinder
    public var onAdClick: ((NativeAdData, Int) -> Void)?
    public var onAdImpression: ((NativeAdData, Int) -> Void)?
    
    private let adCellIdentifier = "AdChainAdCell"
    
    public init(
        tableView: UITableView,
        originalDataSource: UITableViewDataSource,
        originalDelegate: UITableViewDelegate? = nil,
        config: ListAdConfig
    ) {
        self.tableView = tableView
        self.originalDataSource = originalDataSource
        self.originalDelegate = originalDelegate
        self.config = config
        self.viewBinder = config.viewBinder
        super.init()
        
        setupTableView()
        loadAds()
    }
    
    private func setupTableView() {
        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.register(AdTableViewCell.self, forCellReuseIdentifier: adCellIdentifier)
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
                
                AdChainLogger.log("Loaded \(response.ads.count) ads")
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
        
        let totalItems = originalDataSource.tableView(tableView!, numberOfRowsInSection: 0)
        var adIndex = 0
        var position = config.firstAdPosition
        
        while position < totalItems && adIndex < loadedAds.count {
            ads[position] = loadedAds[adIndex]
            adIndex += 1
            position += config.adInterval
        }
        
        tableView?.reloadData()
    }
    
    /// Check if position contains an ad
    public func isAdPosition(_ indexPath: IndexPath) -> Bool {
        guard indexPath.section == 0 else { return false }
        return getAdAtPosition(indexPath) != nil
    }
    
    /// Get ad at specific position
    public func getAdAtPosition(_ indexPath: IndexPath) -> NativeAdData? {
        guard indexPath.section == 0 else { return nil }
        let originalPosition = getOriginalPositionIgnoringAds(indexPath.row)
        return ads[originalPosition]
    }
    
    /// Get original position accounting for inserted ads
    public func getOriginalIndexPath(_ indexPath: IndexPath) -> IndexPath {
        guard indexPath.section == 0 else { return indexPath }
        
        var originalRow = indexPath.row
        for (adPos, _) in ads where adPos <= originalRow {
            originalRow -= 1
        }
        
        return IndexPath(row: originalRow, section: indexPath.section)
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
    
    private func getAdjustedPosition(_ originalPosition: Int) -> Int {
        var adjustedPos = originalPosition
        for (adPos, _) in ads where adPos <= originalPosition {
            adjustedPos += 1
        }
        return adjustedPos
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

// MARK: - UITableViewDataSource
extension AdChainTableAdapter: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return originalDataSource.numberOfSections?(in: tableView) ?? 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section == 0 else {
            return originalDataSource.tableView(tableView, numberOfRowsInSection: section)
        }
        
        let originalCount = originalDataSource.tableView(tableView, numberOfRowsInSection: section)
        return originalCount + ads.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isAdPosition(indexPath) {
            let cell = tableView.dequeueReusableCell(withIdentifier: adCellIdentifier, for: indexPath) as! AdTableViewCell
            
            if let ad = getAdAtPosition(indexPath) {
                cell.configure(with: ad, viewBinder: viewBinder, position: indexPath.row)
                cell.onAdClick = { [weak self] ad in
                    self?.adLoader.trackClick(ad)
                    self?.onAdClick?(ad, indexPath.row)
                }
                trackImpression(ad, position: indexPath.row)
            }
            
            return cell
        } else {
            let originalIndexPath = getOriginalIndexPath(indexPath)
            return originalDataSource.tableView(tableView, cellForRowAt: originalIndexPath)
        }
    }
}

// MARK: - UITableViewDelegate
extension AdChainTableAdapter: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isAdPosition(indexPath) {
            return viewBinder.getHeight()
        } else {
            let originalIndexPath = getOriginalIndexPath(indexPath)
            return originalDelegate?.tableView?(tableView, heightForRowAt: originalIndexPath) ?? UITableView.automaticDimension
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !isAdPosition(indexPath) {
            let originalIndexPath = getOriginalIndexPath(indexPath)
            originalDelegate?.tableView?(tableView, didSelectRowAt: originalIndexPath)
        }
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !isAdPosition(indexPath) {
            let originalIndexPath = getOriginalIndexPath(indexPath)
            originalDelegate?.tableView?(tableView, willDisplay: cell, forRowAt: originalIndexPath)
        }
    }
}

// MARK: - Ad Cell
private class AdTableViewCell: UITableViewCell {
    private var containerView: UIView?
    var onAdClick: ((NativeAdData) -> Void)?
    private var currentAd: NativeAdData?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with ad: NativeAdData, viewBinder: TableViewBinder, position: Int) {
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