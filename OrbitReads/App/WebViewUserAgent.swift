import WebKit

enum WebViewUserAgent {
    static let safari =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Mobile/15E148 Safari/604.1"

    static func install() {
        let clazz: AnyClass = WKWebView.self
        let originalSelector = NSSelectorFromString("initWithFrame:configuration:")
        let swizzledSelector = #selector(WKWebView.nt_init(frame:configuration:))

        guard
            let originalMethod = class_getInstanceMethod(clazz, originalSelector),
            let swizzledMethod = class_getInstanceMethod(clazz, swizzledSelector)
        else { return }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

private extension WKWebView {
    @objc func nt_init(frame: CGRect, configuration: WKWebViewConfiguration) -> WKWebView {
        let webView = nt_init(frame: frame, configuration: configuration)
        webView.customUserAgent = WebViewUserAgent.safari
        return webView
    }
}
