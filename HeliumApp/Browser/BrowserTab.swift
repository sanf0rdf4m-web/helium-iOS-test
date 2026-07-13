import Combine
import Foundation
import UIKit
import WebKit

@MainActor
final class BrowserTab: NSObject, ObservableObject, Identifiable {
    let id: UUID
    let isPrivate: Bool
    let webView: WKWebView

    @Published var title: String
    @Published var url: URL?
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var estimatedProgress = 0.0
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var faviconURL: URL?

    var onNavigation: ((BrowserTab, URL, String) -> Void)?
    var onOpenWindow: ((URL) -> Void)?

    private var observations: [NSKeyValueObservation] = []
    private var privacyConfigured = false
    private var pendingURL: URL?

    init(
        id: UUID = UUID(),
        url: URL? = nil,
        title: String = "New Tab",
        isPrivate: Bool = false
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.isPrivate = isPrivate

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = isPrivate ? .nonPersistent() : .default()
        configuration.preferences.isElementFullscreenEnabled = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.upgradeKnownHostsToHTTPS = true
        self.webView = WKWebView(frame: .zero, configuration: configuration)

        super.init()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        observeWebView()

        pendingURL = url
    }

    deinit {
        observations.forEach { $0.invalidate() }
    }

    func load(_ url: URL) {
        self.url = url
        faviconURL = nil
        lastError = nil
        guard privacyConfigured else {
            pendingURL = url
            return
        }
        pendingURL = nil
        webView.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy))
    }

    func reloadOrStop() {
        if webView.isLoading {
            webView.stopLoading()
        } else if webView.url != nil {
            webView.reload()
        } else if let url = url {
            load(url)
        }
    }

    func goBack() {
        guard webView.canGoBack else { return }
        webView.goBack()
    }

    func goForward() {
        guard webView.canGoForward else { return }
        webView.goForward()
    }

    func configurePrivacy(
        ruleList: WKContentRuleList?,
        blockScripts: Bool,
        fingerprintProtection: Bool,
        sendGlobalPrivacyControl: Bool,
        sendDoNotTrack: Bool
    ) {
        let controller = webView.configuration.userContentController
        controller.removeAllContentRuleLists()
        controller.removeAllUserScripts()
        if let ruleList {
            controller.add(ruleList)
        }
        if fingerprintProtection || sendGlobalPrivacyControl || sendDoNotTrack {
            controller.addUserScript(
                WKUserScript(
                    source: Self.privacyScript(
                        fingerprintProtection: fingerprintProtection,
                        sendGlobalPrivacyControl: sendGlobalPrivacyControl,
                        sendDoNotTrack: sendDoNotTrack
                    ),
                    injectionTime: .atDocumentStart,
                    forMainFrameOnly: false
                )
            )
        }
        webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = !blockScripts
        privacyConfigured = true
        if let pendingURL {
            load(pendingURL)
        }
    }

    private func observeWebView() {
        observations = [
            webView.observe(\.title, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in
                    guard let self else { return }
                    self.title = webView.title?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                        ?? webView.url?.host
                        ?? "New Tab"
                }
            },
            webView.observe(\.url, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in
                    self?.url = webView.url
                }
            },
            webView.observe(\.canGoBack, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in self?.canGoBack = webView.canGoBack }
            },
            webView.observe(\.canGoForward, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in self?.canGoForward = webView.canGoForward }
            },
            webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in self?.estimatedProgress = webView.estimatedProgress }
            },
            webView.observe(\.isLoading, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in self?.isLoading = webView.isLoading }
            }
        ]
    }

    private static func privacyScript(
        fingerprintProtection: Bool,
        sendGlobalPrivacyControl: Bool,
        sendDoNotTrack: Bool
    ) -> String {
        """
    (() => {
      const define = (object, key, getter) => {
        try { Object.defineProperty(object, key, { get: getter, configurable: true }); } catch (_) {}
      };
      if (\(fingerprintProtection ? "true" : "false")) {
        define(Navigator.prototype, 'hardwareConcurrency', () => 4);
        define(Navigator.prototype, 'deviceMemory', () => 4);
        define(Navigator.prototype, 'webdriver', () => undefined);
        const original = HTMLCanvasElement.prototype.toDataURL;
        HTMLCanvasElement.prototype.toDataURL = function(...args) {
          try {
            const context = this.getContext('2d');
            if (context && this.width && this.height) {
              const pixel = context.getImageData(0, 0, 1, 1);
            const originalPixel = new Uint8ClampedArray(pixel.data);
            pixel.data[0] ^= 1;
            context.putImageData(pixel, 0, 0);
            const result = original.apply(this, args);
            pixel.data.set(originalPixel);
            context.putImageData(pixel, 0, 0);
            return result;
          }
        } catch (_) {}
        return original.apply(this, args);
        };
      }
      if (\(sendGlobalPrivacyControl ? "true" : "false")) {
        define(Navigator.prototype, 'globalPrivacyControl', () => true);
      }
      if (\(sendDoNotTrack ? "true" : "false")) {
        define(Navigator.prototype, 'doNotTrack', () => '1');
      }
    })();
    """
    }
}

extension BrowserTab: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        lastError = nil
        guard let url = webView.url else { return }
        let resolvedTitle = webView.title?.nilIfEmpty ?? url.host ?? url.absoluteString
        onNavigation?(self, url, resolvedTitle)
        Task {
            let script = "Array.from(document.querySelectorAll('link[rel~=icon]')).map(link => link.href).filter(Boolean).pop() || ''"
            guard let value = try? await webView.evaluateJavaScript(script) as? String,
                  let favicon = URL(string: value),
                  ["http", "https"].contains(favicon.scheme?.lowercased() ?? "") else {
                return
            }
            faviconURL = favicon
        }
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: any Error
    ) {
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        lastError = error.localizedDescription
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: any Error
    ) {
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        lastError = error.localizedDescription
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url else {
            return .cancel
        }
        if ["http", "https", "about", "data", "blob"].contains(url.scheme?.lowercased() ?? "") {
            return .allow
        } else {
            await UIApplication.shared.open(url)
            return .cancel
        }
    }
}

extension BrowserTab: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            onOpenWindow?(url)
        }
        return nil
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
