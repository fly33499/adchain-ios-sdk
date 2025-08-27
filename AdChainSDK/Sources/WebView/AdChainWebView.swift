import UIKit

public protocol AdChainWebViewProtocol {
    func presentWebView(
        from viewController: UIViewController,
        config: WebViewConfig,
        delegate: WebViewDelegate?
    )
    
    func createWebViewController(
        config: WebViewConfig,
        delegate: WebViewDelegate?
    ) -> UIViewController
}

public struct WebViewConfig {
    public let url: String?
    public let showNavigationBar: Bool
    public let enableJavaScript: Bool
    public let enableDomStorage: Bool
    public let userAgentSuffix: String?
    public let headers: [String: String]?
    
    public init(
        url: String? = nil,
        showNavigationBar: Bool = false,
        enableJavaScript: Bool = true,
        enableDomStorage: Bool = true,
        userAgentSuffix: String? = nil,
        headers: [String: String]? = nil
    ) {
        self.url = url
        self.showNavigationBar = showNavigationBar
        self.enableJavaScript = enableJavaScript
        self.enableDomStorage = enableDomStorage
        self.userAgentSuffix = userAgentSuffix
        self.headers = headers
    }
}

public protocol WebViewDelegate: AnyObject {
    func webViewDidStartLoading(url: String)
    func webViewDidFinishLoading(url: String)
    func webView(didFailWithError error: AdChainError)
    func webView(shouldOverrideUrlLoading url: String) -> Bool
    func webViewDidClose()
    func webView(didReceiveMessage message: WebViewMessage)
}

public struct WebViewMessage {
    public let type: String
    public let data: [String: Any]?
}