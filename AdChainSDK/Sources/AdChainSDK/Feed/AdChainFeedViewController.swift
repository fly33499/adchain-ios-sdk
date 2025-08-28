import UIKit

/**
 * Full-screen feed view controller that displays native ads
 * This provides an immersive ad experience similar to social media feeds
 */
public class AdChainFeedViewController: UIViewController {
    
    // MARK: - Properties
    
    private let config: FeedConfig
    private let adLoader: NativeAdLoader
    
    private var collectionView: UICollectionView!
    private var refreshControl: UIRefreshControl?
    private var loadingIndicator: UIActivityIndicatorView!
    private var emptyLabel: UILabel!
    
    private var ads: [NativeAdData] = []
    private var impressedAds: Set<String> = []
    private var isLoading = false
    private var currentPage = 0
    
    // MARK: - Initialization
    
    public init(config: FeedConfig) {
        self.config = config
        self.adLoader = AdChainSDK.shared.nativeAdLoader
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadInitialAds()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: config.backgroundColor ?? "#F5F5F5")
        
        // Setup navigation
        title = config.title
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
        
        // Setup collection view
        let layout = createLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Register cells
        collectionView.register(FeedCardCell.self, forCellWithReuseIdentifier: "CardCell")
        collectionView.register(FeedListCell.self, forCellWithReuseIdentifier: "ListCell")
        collectionView.register(FeedGridCell.self, forCellWithReuseIdentifier: "GridCell")
        
        view.addSubview(collectionView)
        
        // Setup refresh control
        if config.enablePullToRefresh {
            refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(refreshFeed), for: .valueChanged)
            collectionView.refreshControl = refreshControl
        }
        
        // Setup loading indicator
        loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        
        // Setup empty label
        emptyLabel = UILabel()
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.text = "No ads available"
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .gray
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = config.itemSpacing
        layout.minimumInteritemSpacing = config.itemSpacing
        
        switch config.style {
        case .card:
            layout.sectionInset = UIEdgeInsets(top: config.itemSpacing, left: 16, bottom: config.itemSpacing, right: 16)
        case .list:
            layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        case .grid:
            layout.sectionInset = UIEdgeInsets(top: config.itemSpacing, left: config.itemSpacing, bottom: config.itemSpacing, right: config.itemSpacing)
        }
        
        return layout
    }
    
    // MARK: - Data Loading
    
    private func loadInitialAds() {
        loadAds(isLoadMore: false)
    }
    
    private func loadMoreAds() {
        loadAds(isLoadMore: true)
    }
    
    private func loadAds(isLoadMore: Bool) {
        guard !isLoading else { return }
        
        isLoading = true
        
        if !isLoadMore {
            loadingIndicator.startAnimating()
            emptyLabel.isHidden = true
        }
        
        Task {
            do {
                let request = NativeAdRequest(unitId: config.unitId, count: config.pageSize)
                let response = try await adLoader.loadAds(request: request)
                
                await MainActor.run {
                    if isLoadMore {
                        let startIndex = self.ads.count
                        self.ads.append(contentsOf: response.ads)
                        
                        let indexPaths = (startIndex..<self.ads.count).map {
                            IndexPath(item: $0, section: 0)
                        }
                        self.collectionView.insertItems(at: indexPaths)
                    } else {
                        self.ads = response.ads
                        self.currentPage = 0
                        self.collectionView.reloadData()
                    }
                    
                    self.currentPage += 1
                    self.isLoading = false
                    self.loadingIndicator.stopAnimating()
                    self.refreshControl?.endRefreshing()
                    
                    if self.ads.isEmpty {
                        self.emptyLabel.isHidden = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.loadingIndicator.stopAnimating()
                    self.refreshControl?.endRefreshing()
                    
                    Logger.error("Failed to load ads: \(error)")
                    
                    if self.ads.isEmpty {
                        self.emptyLabel.isHidden = false
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func refreshFeed() {
        currentPage = 0
        impressedAds.removeAll()
        loadAds(isLoadMore: false)
    }
    
    private func handleAdClick(ad: NativeAdData, at indexPath: IndexPath) {
        adLoader.trackClick(ad: ad)
        
        if let url = URL(string: ad.landingUrl) {
            UIApplication.shared.open(url)
        }
    }
    
    private func trackImpression(for ad: NativeAdData) {
        guard !impressedAds.contains(ad.id) else { return }
        
        impressedAds.insert(ad.id)
        adLoader.trackImpression(ad: ad)
    }
}

// MARK: - UICollectionViewDataSource

extension AdChainFeedViewController: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ads.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let ad = ads[indexPath.item]
        
        let cellIdentifier: String
        switch config.style {
        case .card:
            cellIdentifier = "CardCell"
        case .list:
            cellIdentifier = "ListCell"
        case .grid:
            cellIdentifier = "GridCell"
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! FeedAdCell
        cell.configure(with: ad)
        
        // Track impression
        trackImpression(for: ad)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension AdChainFeedViewController: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let ad = ads[indexPath.item]
        handleAdClick(ad: ad, at: indexPath)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard config.enableInfiniteScroll, !isLoading else { return }
        
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        if offsetY > contentHeight - height * 2 {
            loadMoreAds()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension AdChainFeedViewController: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let width = collectionView.frame.width - layout.sectionInset.left - layout.sectionInset.right
        
        switch config.style {
        case .card:
            return CGSize(width: width, height: 300)
        case .list:
            return CGSize(width: width, height: 100)
        case .grid:
            let columns: CGFloat = 2
            let spacing = layout.minimumInteritemSpacing * (columns - 1)
            let itemWidth = (width - spacing) / columns
            return CGSize(width: itemWidth, height: itemWidth * 1.3)
        }
    }
}

// MARK: - Helper Extension

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}