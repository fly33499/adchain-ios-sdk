import Foundation

/// BenefitHub 설정 클래스
/// Buzzville SDK v6 호환 - Builder 패턴 사용
public class AdchainBenefitHubConfig {
    
    // MARK: - Properties
    
    public let enableTopBar: Bool
    public let enableBottomBar: Bool
    public let topBarTitle: String?
    public let topBarBackgroundColor: String?
    public let topBarTextColor: String?
    public let bottomBarBackgroundColor: String?
    public let bottomBarSelectedColor: String?
    public let bottomBarUnselectedColor: String?
    public let initialTab: TabType
    public let enabledTabs: Set<TabType>
    public let customTheme: Theme?
    public let enableSwipeNavigation: Bool
    public let enablePullToRefresh: Bool
    
    // MARK: - Enums
    
    public enum TabType: String, CaseIterable {
        case home = "HOME"
        case missions = "MISSIONS"
        case rewards = "REWARDS"
        case profile = "PROFILE"
        case settings = "SETTINGS"
    }
    
    public struct Theme {
        public let primaryColor: String
        public let secondaryColor: String
        public let backgroundColor: String
        public let textColor: String
        public let accentColor: String
        
        public init(
            primaryColor: String,
            secondaryColor: String,
            backgroundColor: String,
            textColor: String,
            accentColor: String
        ) {
            self.primaryColor = primaryColor
            self.secondaryColor = secondaryColor
            self.backgroundColor = backgroundColor
            self.textColor = textColor
            self.accentColor = accentColor
        }
    }
    
    // MARK: - Private Init
    
    private init(builder: Builder) {
        self.enableTopBar = builder.enableTopBar
        self.enableBottomBar = builder.enableBottomBar
        self.topBarTitle = builder.topBarTitle
        self.topBarBackgroundColor = builder.topBarBackgroundColor
        self.topBarTextColor = builder.topBarTextColor
        self.bottomBarBackgroundColor = builder.bottomBarBackgroundColor
        self.bottomBarSelectedColor = builder.bottomBarSelectedColor
        self.bottomBarUnselectedColor = builder.bottomBarUnselectedColor
        self.initialTab = builder.initialTab
        self.enabledTabs = builder.enabledTabs
        self.customTheme = builder.customTheme
        self.enableSwipeNavigation = builder.enableSwipeNavigation
        self.enablePullToRefresh = builder.enablePullToRefresh
    }
    
    // MARK: - Builder
    
    /// Builder 클래스 - Buzzville SDK v6 패턴
    public class Builder {
        
        // Properties with defaults
        internal var enableTopBar: Bool = true
        internal var enableBottomBar: Bool = true
        internal var topBarTitle: String?
        internal var topBarBackgroundColor: String?
        internal var topBarTextColor: String?
        internal var bottomBarBackgroundColor: String?
        internal var bottomBarSelectedColor: String?
        internal var bottomBarUnselectedColor: String?
        internal var initialTab: TabType = .home
        internal var enabledTabs: Set<TabType> = Set(TabType.allCases)
        internal var customTheme: Theme?
        internal var enableSwipeNavigation: Bool = true
        internal var enablePullToRefresh: Bool = true
        
        public init() {}
        
        /// 상단바 활성화 설정
        @discardableResult
        public func setEnableTopBar(_ enable: Bool) -> Builder {
            self.enableTopBar = enable
            return self
        }
        
        /// 하단바 활성화 설정
        @discardableResult
        public func setEnableBottomBar(_ enable: Bool) -> Builder {
            self.enableBottomBar = enable
            return self
        }
        
        /// 상단바 제목 설정
        @discardableResult
        public func setTopBarTitle(_ title: String) -> Builder {
            self.topBarTitle = title
            return self
        }
        
        /// 상단바 배경색 설정
        @discardableResult
        public func setTopBarBackgroundColor(_ color: String) -> Builder {
            self.topBarBackgroundColor = color
            return self
        }
        
        /// 상단바 텍스트 색상 설정
        @discardableResult
        public func setTopBarTextColor(_ color: String) -> Builder {
            self.topBarTextColor = color
            return self
        }
        
        /// 하단바 배경색 설정
        @discardableResult
        public func setBottomBarBackgroundColor(_ color: String) -> Builder {
            self.bottomBarBackgroundColor = color
            return self
        }
        
        /// 하단바 선택된 탭 색상 설정
        @discardableResult
        public func setBottomBarSelectedColor(_ color: String) -> Builder {
            self.bottomBarSelectedColor = color
            return self
        }
        
        /// 하단바 선택되지 않은 탭 색상 설정
        @discardableResult
        public func setBottomBarUnselectedColor(_ color: String) -> Builder {
            self.bottomBarUnselectedColor = color
            return self
        }
        
        /// 초기 탭 설정
        @discardableResult
        public func setInitialTab(_ tab: TabType) -> Builder {
            self.initialTab = tab
            return self
        }
        
        /// 활성화할 탭 설정
        @discardableResult
        public func setEnabledTabs(_ tabs: Set<TabType>) -> Builder {
            self.enabledTabs = tabs
            return self
        }
        
        /// 커스텀 테마 설정
        @discardableResult
        public func setCustomTheme(_ theme: Theme) -> Builder {
            self.customTheme = theme
            return self
        }
        
        /// 스와이프 네비게이션 활성화
        @discardableResult
        public func setEnableSwipeNavigation(_ enable: Bool) -> Builder {
            self.enableSwipeNavigation = enable
            return self
        }
        
        /// Pull to Refresh 활성화
        @discardableResult
        public func setEnablePullToRefresh(_ enable: Bool) -> Builder {
            self.enablePullToRefresh = enable
            return self
        }
        
        /// Config 빌드
        public func build() -> AdchainBenefitHubConfig {
            return AdchainBenefitHubConfig(builder: self)
        }
    }
    
    // MARK: - Helpers
    
    /// 설정을 Dictionary로 변환
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "enableTopBar": enableTopBar,
            "enableBottomBar": enableBottomBar,
            "initialTab": initialTab.rawValue,
            "enabledTabs": enabledTabs.map { $0.rawValue },
            "enableSwipeNavigation": enableSwipeNavigation,
            "enablePullToRefresh": enablePullToRefresh
        ]
        
        if let title = topBarTitle {
            dict["topBarTitle"] = title
        }
        
        if let color = topBarBackgroundColor {
            dict["topBarBackgroundColor"] = color
        }
        
        if let color = topBarTextColor {
            dict["topBarTextColor"] = color
        }
        
        if let color = bottomBarBackgroundColor {
            dict["bottomBarBackgroundColor"] = color
        }
        
        if let color = bottomBarSelectedColor {
            dict["bottomBarSelectedColor"] = color
        }
        
        if let color = bottomBarUnselectedColor {
            dict["bottomBarUnselectedColor"] = color
        }
        
        if let theme = customTheme {
            dict["customTheme"] = [
                "primaryColor": theme.primaryColor,
                "secondaryColor": theme.secondaryColor,
                "backgroundColor": theme.backgroundColor,
                "textColor": theme.textColor,
                "accentColor": theme.accentColor
            ]
        }
        
        return dict
    }
}