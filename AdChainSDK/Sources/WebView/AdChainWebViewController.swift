import UIKit
import WebKit

internal class AdChainWebViewController: UIViewController {
    
    private let url: String
    private let config: WebViewConfig
    private weak var delegate: WebViewDelegate?
    
    private var webView: WKWebView!
    private var progressView: UIProgressView!
    private var startTime: Date!
    
    private var progressObservation: NSKeyValueObservation?
    
    init(url: String, config: WebViewConfig, delegate: WebViewDelegate?) {
        self.url = url
        self.config = config
        self.delegate = delegate
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startTime = Date()
        
        setupUI()
        configureWebView()
        loadUrl()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Navigation bar
        if config.showNavigationBar {
            navigationItem.title = "애드체인"
            
            // Create back button with < symbol
            let backButton = UIBarButtonItem(
                image: UIImage(systemName: "chevron.left"),
                style: .plain,
                target: self,
                action: #selector(closeButtonTapped)
            )
            navigationItem.leftBarButtonItem = backButton
        }
        
        // WebView configuration
        let configuration = WKWebViewConfiguration()
        configuration.preferences = WKPreferences()
        configuration.preferences.javaScriptEnabled = config.enableJavaScript
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        
        // Allow arbitrary loads for WebView (iOS 14+)
        if #available(iOS 14.5, *) {
            configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        }
        
        // Allow file access from file URLs
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        // Allow insecure content
        if #available(iOS 9.0, *) {
            configuration.allowsInlineMediaPlayback = true
        }
        
        // Note: DOM Storage is enabled by default in WKWebView
        // The enableDomStorage config is kept for compatibility but doesn't need explicit setting
        
        // User content controller for JS bridge
        let userContentController = WKUserContentController()
        userContentController.add(self, name: "AdChain")
        configuration.userContentController = userContentController
        
        // Create WebView
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        
        // Progress view
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.progressTintColor = .systemBlue
        
        // Add subviews
        view.addSubview(webView)
        view.addSubview(progressView)
        
        // Layout
        webView.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2),
            
            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Progress observation
        progressObservation = webView.observe(\.estimatedProgress, options: .new) { [weak self] _, _ in
            self?.updateProgress()
        }
    }
    
    private func configureWebView() {
        // User agent
        if let userAgentSuffix = config.userAgentSuffix {
            webView.evaluateJavaScript("navigator.userAgent") { [weak self] result, _ in
                if let userAgent = result as? String {
                    self?.webView.customUserAgent = "\(userAgent) \(userAgentSuffix) AdChainSDK/1.0.0"
                }
            }
        } else {
            webView.evaluateJavaScript("navigator.userAgent") { [weak self] result, _ in
                if let userAgent = result as? String {
                    self?.webView.customUserAgent = "\(userAgent) AdChainSDK/1.0.0"
                }
            }
        }
    }
    
    private func loadUrl() {
        guard let url = URL(string: self.url) else {
            delegate?.webView(didFailWithError: .webViewError(message: "Invalid URL"))
            return
        }
        
        var request = URLRequest(url: url)
        
        // Add custom headers
        config.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        webView.load(request)
        
        // Track webview open
        let analytics = (AdChainSDK.shared as? AdChainSDKImpl)?.analytics as? AdChainAnalyticsImpl
        analytics?.trackWebViewOpen(url: self.url)
    }
    
    private func updateProgress() {
        let progress = Float(webView.estimatedProgress)
        progressView.setProgress(progress, animated: true)
        
        if progress >= 1.0 {
            UIView.animate(withDuration: 0.3, delay: 0.5, options: [], animations: {
                self.progressView.alpha = 0
            })
        } else {
            progressView.alpha = 1
        }
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true) { [weak self] in
            self?.delegate?.webViewDidClose()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isBeingDismissed || isMovingFromParent {
            // Track close event
            let duration = Date().timeIntervalSince(startTime)
            let analytics = (AdChainSDK.shared as? AdChainSDKImpl)?.analytics as? AdChainAnalyticsImpl
            analytics?.trackWebViewClose(url: url, duration: duration)
        }
    }
    
    deinit {
        progressObservation?.invalidate()
        webView?.navigationDelegate = nil
        webView?.uiDelegate = nil
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "AdChain")
    }
}

// MARK: - WKNavigationDelegate

extension AdChainWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        delegate?.webViewDidStartLoading(url: webView.url?.absoluteString ?? "")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        navigationItem.title = webView.title ?? "애드체인"
        delegate?.webViewDidFinishLoading(url: webView.url?.absoluteString ?? "")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Logger.shared.log("WebView navigation failed: \(error)", level: .error)
        let adChainError = AdChainError.webViewError(message: error.localizedDescription)
        delegate?.webView(didFailWithError: adChainError)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Logger.shared.log("WebView provisional navigation failed: \(error)", level: .error)
        let nsError = error as NSError
        Logger.shared.log("Error domain: \(nsError.domain), code: \(nsError.code)", level: .error)
        
        // Handle ATS error specifically
        if nsError.domain == NSURLErrorDomain && nsError.code == -1022 {
            Logger.shared.log("App Transport Security blocked HTTP load. Please check Info.plist settings.", level: .error)
        }
        
        let adChainError = AdChainError.webViewError(message: "Failed to load: \(error.localizedDescription)")
        delegate?.webView(didFailWithError: adChainError)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        let urlString = url.absoluteString
        
        // Let delegate decide
        if delegate?.webView(shouldOverrideUrlLoading: urlString) == true {
            decisionHandler(.cancel)
            return
        }
        
        // Handle external URLs
        if shouldOpenExternally(url: urlString) {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
    
    private func shouldOpenExternally(url: String) -> Bool {
        return url.hasPrefix("tel:") ||
               url.hasPrefix("mailto:") ||
               url.hasPrefix("sms:") ||
               url.hasPrefix("maps:") ||
               url.hasPrefix("itms:") ||
               url.hasPrefix("itms-apps:") ||
               url.contains("itunes.apple.com") ||
               url.contains("apps.apple.com")
    }
}

// MARK: - WKUIDelegate

extension AdChainWebViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler()
        })
        present(alert, animated: true)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(false)
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(true)
        })
        present(alert, animated: true)
    }
}

// MARK: - WKScriptMessageHandler

extension AdChainWebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "AdChain" else { return }
        
        if let body = message.body as? [String: Any] {
            let type = body["type"] as? String ?? "unknown"
            let data = body["data"] as? [String: Any]
            
            let webViewMessage = WebViewMessage(type: type, data: data)
            delegate?.webView(didReceiveMessage: webViewMessage)
            
            // Handle special message types
            switch type {
            case "close":
                closeButtonTapped()
            case "getDeviceInfo":
                provideDeviceInfo()
            case "openWebView":
                handleOpenWebView(data: data)
            case "goBack":
                handleGoBack()
            case "goForward":
                handleGoForward()
            case "reload":
                handleReload()
            default:
                break
            }
        }
    }
    
    private func provideDeviceInfo() {
        let deviceInfo = AdChainSDK.shared.analytics.getDeviceInfo()
        let deviceInfoDict: [String: Any] = [
            "deviceId": deviceInfo.deviceId,
            "advertisingId": deviceInfo.advertisingId ?? "",
            "isAdvertisingTrackingEnabled": deviceInfo.isAdvertisingTrackingEnabled,
            "os": deviceInfo.os,
            "osVersion": deviceInfo.osVersion,
            "deviceModel": deviceInfo.deviceModel,
            "appVersion": deviceInfo.appVersion,
            "sdkVersion": deviceInfo.sdkVersion,
            "language": deviceInfo.language,
            "country": deviceInfo.country,
            "timezone": deviceInfo.timezone
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: deviceInfoDict),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let script = "window.postMessage({type: 'deviceInfo', data: \(jsonString)}, '*')"
            webView.evaluateJavaScript(script)
        }
    }
    
    private func handleOpenWebView(data: [String: Any]?) {
        guard let urlString = data?["url"] as? String else { return }
        
        // Create new WebView config
        let showNav = data?["showNavigationBar"] as? Bool ?? false
        let modal = data?["modal"] as? Bool ?? true
        
        let config = WebViewConfig(
            url: urlString,
            showNavigationBar: showNav,
            enableJavaScript: true,
            enableDomStorage: true
        )
        
        // Create new WebView controller
        let newWebViewController = AdChainWebViewController(
            url: urlString,
            config: config,
            delegate: nil
        )
        
        if modal {
            let navController = UINavigationController(rootViewController: newWebViewController)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        } else {
            navigationController?.pushViewController(newWebViewController, animated: true)
        }
    }
    
    private func handleGoBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    private func handleGoForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    private func handleReload() {
        webView.reload()
    }
}