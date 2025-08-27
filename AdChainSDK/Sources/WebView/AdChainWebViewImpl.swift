import UIKit

internal class AdChainWebViewImpl: AdChainWebViewProtocol {
    private let sdk: AdChainSDKImpl
    
    init(sdk: AdChainSDKImpl) {
        self.sdk = sdk
    }
    
    func presentWebView(
        from viewController: UIViewController,
        config: WebViewConfig,
        delegate: WebViewDelegate?
    ) {
        let url = buildUrl(config: config)
        let webViewController = AdChainWebViewController(url: url, config: config, delegate: delegate)
        
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
        return AdChainWebViewController(url: url, config: config, delegate: delegate)
    }
    
    private func buildUrl(config: WebViewConfig) -> String {
        // Use webOfferwallUrl from server if available, otherwise fall back to default hub URL
        let baseUrl = config.url ?? sdk.getWebOfferwallUrl() ?? "\(sdk.getConfig().actualBaseUrl)/web/hub"
        
        guard var components = URLComponents(string: baseUrl) else {
            return baseUrl
        }
        
        let deviceInfo = sdk.getDeviceInfoCollector().getDeviceInfo()
        
        var queryItems = components.queryItems ?? []
        
        // Add required parameters
        queryItems.append(contentsOf: [
            URLQueryItem(name: "app_id", value: sdk.getConfig().appId),
            URLQueryItem(name: "user_id", value: sdk.getUserId() ?? ""),
            URLQueryItem(name: "session_id", value: sdk.getSessionId()),
            URLQueryItem(name: "device_id", value: deviceInfo.deviceId),
            URLQueryItem(name: "sdk_version", value: sdk.getVersion()),
            URLQueryItem(name: "platform", value: "ios")
        ])
        
        // Add optional parameters
        if let advertisingId = deviceInfo.advertisingId {
            queryItems.append(URLQueryItem(name: "idfa", value: advertisingId))
        }
        queryItems.append(URLQueryItem(name: "lat", value: String(!deviceInfo.isAdvertisingTrackingEnabled)))
        
        components.queryItems = queryItems
        
        return components.url?.absoluteString ?? baseUrl
    }
}