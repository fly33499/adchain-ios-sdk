import UIKit
import WebKit

/// BenefitHub ViewController
/// Buzzville SDK v6 호환 - 광고 및 보상 관련 통합 UI
public class AdchainBenefitHubViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: AdchainBenefitHubViewControllerDelegate?
    private let config: AdchainBenefitHubConfig
    
    // UI Components
    private var topBar: UIView?
    private var bottomBar: UITabBar?
    private var contentContainer: UIView!
    private var webView: WKWebView?
    private var currentTab: AdchainBenefitHubConfig.TabType
    
    // Child ViewControllers
    private var tabViewControllers: [AdchainBenefitHubConfig.TabType: UIViewController] = [:]
    
    // MARK: - Initialization
    
    public init(config: AdchainBenefitHubConfig) {
        self.config = config
        self.currentTab = config.initialTab
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadInitialTab()
        trackPageView()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // Setup top bar if enabled
        if config.enableTopBar {
            setupTopBar()
        }
        
        // Setup content container
        setupContentContainer()
        
        // Setup bottom bar if enabled
        if config.enableBottomBar {
            setupBottomBar()
        }
        
        // Apply custom theme if provided
        if let theme = config.customTheme {
            applyTheme(theme)
        }
        
        // Setup swipe gestures if enabled
        if config.enableSwipeNavigation {
            setupSwipeGestures()
        }
    }
    
    private func setupTopBar() {
        let topBar = UIView()
        topBar.translatesAutoresizingMaskIntoConstraints = false
        topBar.backgroundColor = UIColor.systemBlue
        
        // Title label
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = config.topBarTitle ?? "Benefit Hub"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        
        // Close button
        let closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        topBar.addSubview(titleLabel)
        topBar.addSubview(closeButton)
        view.addSubview(topBar)
        
        // Constraints
        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 50),
            
            titleLabel.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            
            closeButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -16),
            closeButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        self.topBar = topBar
        
        // Apply custom colors if provided
        if let bgColor = config.topBarBackgroundColor {
            topBar.backgroundColor = UIColor(hex: bgColor)
        }
        if let textColor = config.topBarTextColor {
            titleLabel.textColor = UIColor(hex: textColor)
            closeButton.tintColor = UIColor(hex: textColor)
        }
    }
    
    private func setupContentContainer() {
        contentContainer = UIView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentContainer)
        
        // Constraints
        let topAnchor = topBar?.bottomAnchor ?? view.safeAreaLayoutGuide.topAnchor
        let bottomAnchor = bottomBar?.topAnchor ?? view.safeAreaLayoutGuide.bottomAnchor
        
        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func setupBottomBar() {
        let tabBar = UITabBar()
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        
        // Create tab items for enabled tabs
        var tabItems: [UITabBarItem] = []
        for tab in config.enabledTabs.sorted(by: { $0.rawValue < $1.rawValue }) {
            let item = UITabBarItem(
                title: tab.rawValue.capitalized,
                image: tabIcon(for: tab),
                tag: tabIndex(for: tab)
            )
            tabItems.append(item)
        }
        
        tabBar.items = tabItems
        tabBar.selectedItem = tabItems.first { $0.tag == tabIndex(for: currentTab) }
        tabBar.delegate = self
        
        view.addSubview(tabBar)
        
        // Constraints
        NSLayoutConstraint.activate([
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        self.bottomBar = tabBar
        
        // Apply custom colors if provided
        if let bgColor = config.bottomBarBackgroundColor {
            tabBar.barTintColor = UIColor(hex: bgColor)
        }
        if let selectedColor = config.bottomBarSelectedColor {
            tabBar.tintColor = UIColor(hex: selectedColor)
        }
        if let unselectedColor = config.bottomBarUnselectedColor {
            tabBar.unselectedItemTintColor = UIColor(hex: unselectedColor)
        }
    }
    
    private func setupSwipeGestures() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
    }
    
    // MARK: - Tab Management
    
    private func loadInitialTab() {
        loadTab(currentTab)
    }
    
    private func loadTab(_ tab: AdchainBenefitHubConfig.TabType) {
        // Remove current child view controller
        children.forEach { child in
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        
        // Get or create view controller for tab
        let viewController = getViewController(for: tab)
        
        // Add as child
        addChild(viewController)
        contentContainer.addSubview(viewController.view)
        viewController.view.frame = contentContainer.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.didMove(toParent: self)
        
        currentTab = tab
        delegate?.benefitHubViewController(self, didSelectTab: tab)
    }
    
    private func getViewController(for tab: AdchainBenefitHubConfig.TabType) -> UIViewController {
        if let existing = tabViewControllers[tab] {
            return existing
        }
        
        let viewController: UIViewController
        
        switch tab {
        case .home:
            viewController = createHomeViewController()
        case .missions:
            viewController = createMissionsViewController()
        case .rewards:
            viewController = createRewardsViewController()
        case .profile:
            viewController = createProfileViewController()
        case .settings:
            viewController = createSettingsViewController()
        }
        
        tabViewControllers[tab] = viewController
        return viewController
    }
    
    // MARK: - Tab View Controllers
    
    private func createHomeViewController() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        
        // Create a simple home view with ads
        let label = UILabel()
        label.text = "Home - Featured Ads"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        vc.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            label.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 50)
        ])
        
        // Add native ad view
        addNativeAdToViewController(vc)
        
        return vc
    }
    
    private func createMissionsViewController() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "Missions"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        vc.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            label.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 50)
        ])
        
        return vc
    }
    
    private func createRewardsViewController() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "Rewards"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        vc.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            label.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 50)
        ])
        
        return vc
    }
    
    private func createProfileViewController() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "Profile"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        vc.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            label.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 50)
        ])
        
        return vc
    }
    
    private func createSettingsViewController() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "Settings"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        vc.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            label.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 50)
        ])
        
        return vc
    }
    
    private func addNativeAdToViewController(_ viewController: UIViewController) {
        // This would integrate with the Native ad system
        // For now, just add a placeholder
        let adContainer = UIView()
        adContainer.backgroundColor = .systemGray6
        adContainer.layer.cornerRadius = 8
        adContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let adLabel = UILabel()
        adLabel.text = "Native Ad Space"
        adLabel.textAlignment = .center
        adLabel.translatesAutoresizingMaskIntoConstraints = false
        
        adContainer.addSubview(adLabel)
        viewController.view.addSubview(adContainer)
        
        NSLayoutConstraint.activate([
            adContainer.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            adContainer.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor),
            adContainer.widthAnchor.constraint(equalTo: viewController.view.widthAnchor, multiplier: 0.9),
            adContainer.heightAnchor.constraint(equalToConstant: 200),
            
            adLabel.centerXAnchor.constraint(equalTo: adContainer.centerXAnchor),
            adLabel.centerYAnchor.constraint(equalTo: adContainer.centerYAnchor)
        ])
    }
    
    // MARK: - Helpers
    
    private func tabIcon(for tab: AdchainBenefitHubConfig.TabType) -> UIImage? {
        switch tab {
        case .home:
            return UIImage(systemName: "house.fill")
        case .missions:
            return UIImage(systemName: "target")
        case .rewards:
            return UIImage(systemName: "gift.fill")
        case .profile:
            return UIImage(systemName: "person.fill")
        case .settings:
            return UIImage(systemName: "gearshape.fill")
        }
    }
    
    private func tabIndex(for tab: AdchainBenefitHubConfig.TabType) -> Int {
        switch tab {
        case .home: return 0
        case .missions: return 1
        case .rewards: return 2
        case .profile: return 3
        case .settings: return 4
        }
    }
    
    private func tabForIndex(_ index: Int) -> AdchainBenefitHubConfig.TabType? {
        switch index {
        case 0: return .home
        case 1: return .missions
        case 2: return .rewards
        case 3: return .profile
        case 4: return .settings
        default: return nil
        }
    }
    
    private func applyTheme(_ theme: AdchainBenefitHubConfig.Theme) {
        view.backgroundColor = UIColor(hex: theme.backgroundColor)
        // Apply other theme colors as needed
    }
    
    private func trackPageView() {
        Logger.shared.log("BenefitHub page view: \(currentTab.rawValue)", level: .debug)
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        delegate?.benefitHubViewControllerDidClose(self)
        dismiss(animated: true)
    }
    
    @objc private func handleSwipeLeft() {
        // Navigate to next tab
        let enabledTabs = Array(config.enabledTabs.sorted(by: { $0.rawValue < $1.rawValue }))
        if let currentIndex = enabledTabs.firstIndex(of: currentTab),
           currentIndex < enabledTabs.count - 1 {
            let nextTab = enabledTabs[currentIndex + 1]
            loadTab(nextTab)
            
            // Update tab bar selection
            if let tabBar = bottomBar,
               let item = tabBar.items?.first(where: { $0.tag == tabIndex(for: nextTab) }) {
                tabBar.selectedItem = item
            }
        }
    }
    
    @objc private func handleSwipeRight() {
        // Navigate to previous tab
        let enabledTabs = Array(config.enabledTabs.sorted(by: { $0.rawValue < $1.rawValue }))
        if let currentIndex = enabledTabs.firstIndex(of: currentTab),
           currentIndex > 0 {
            let previousTab = enabledTabs[currentIndex - 1]
            loadTab(previousTab)
            
            // Update tab bar selection
            if let tabBar = bottomBar,
               let item = tabBar.items?.first(where: { $0.tag == tabIndex(for: previousTab) }) {
                tabBar.selectedItem = item
            }
        }
    }
}

// MARK: - UITabBarDelegate

extension AdchainBenefitHubViewController: UITabBarDelegate {
    
    public func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if let tab = tabForIndex(item.tag) {
            loadTab(tab)
        }
    }
}

