import UIKit

internal class AdchainWebViewImpl: AdchainWebViewProtocol {
    
    init() {
    }
    
    private func getWebOfferwallUrl() -> String? {
        // This would typically come from server configuration
        return nil
    }
    
    private func getConfig() -> AdchainBenefitConfig? {
        return AdchainBenefit.shared.getConfig()
    }
    
    func presentWebView(
        from viewController: UIViewController,
        config: WebViewConfig,
        delegate: WebViewDelegate?
    ) {
        let url = buildUrl(config: config)
        let webViewController = AdchainWebViewController(url: url, config: config, delegate: delegate)
        
        if config.showNavigationBar {
            let navigationController = UINavigationController(rootViewController: webViewController)
            navigationController.modalPresentationStyle = .fullScreen
            viewController.present(navigationController, animated: true)
        } else {
            webViewController.modalPresentationStyle = .fullScreen
            viewController.present(webViewController, animated: true)
        }
    }
    
    func createWebViewController(
        config: WebViewConfig,
        delegate: WebViewDelegate?
    ) -> UIViewController {
        let url = buildUrl(config: config)
        return AdchainWebViewController(url: url, config: config, delegate: delegate)
    }
    
    private func buildUrl(config: WebViewConfig) -> String {
        // Use webOfferwallUrl from server if available, otherwise fall back to default hub URL
        let baseUrl = config.url ?? getWebOfferwallUrl() ?? "\(getConfig()?.actualBaseUrl ?? "")/web/hub"
        
        guard var components = URLComponents(string: baseUrl) else {
            return baseUrl
        }
        
        let deviceInfo = AdchainBenefit.shared.deviceInfoCollector?.getDeviceInfo()
        
        var queryItems = components.queryItems ?? []
        
        // Add required parameters
        queryItems.append(contentsOf: [
            URLQueryItem(name: "app_id", value: getConfig()?.appId ?? ""),
            URLQueryItem(name: "user_id", value: AdchainBenefit.shared.getCurrentUser()?.userId ?? ""),
            URLQueryItem(name: "session_id", value: AdchainBenefit.shared.getSessionId()),
            URLQueryItem(name: "device_id", value: deviceInfo?.deviceId ?? ""),
            URLQueryItem(name: "sdk_version", value: AdchainSDK.version),
            URLQueryItem(name: "platform", value: "ios")
        ])
        
        // Add optional parameters
        if let advertisingId = deviceInfo?.advertisingId {
            queryItems.append(URLQueryItem(name: "idfa", value: advertisingId))
        }
        queryItems.append(URLQueryItem(name: "lat", value: String(!(deviceInfo?.isAdvertisingTrackingEnabled ?? false))))
        
        components.queryItems = queryItems
        
        return components.url?.absoluteString ?? baseUrl
    }
}