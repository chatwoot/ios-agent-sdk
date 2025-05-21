import SwiftUI
import WebKit
import Foundation
import ObjectiveC

/// A SwiftUI view that wraps a WKWebView to display the Chatwoot chat widget
public struct ChatwootView: UIViewRepresentable {
    /// Configuration containing Chatwoot settings
    private let configuration: ChatwootConfiguration
    /// Optional conversation ID
    private let conversationId: Int?
    /// Environment value for presentation mode
    @Environment(\.presentationMode) private var presentationMode
    /// Reference to the WebView for programmatic control
    @State private var webView: WKWebView?
    
    // Private class for bundle reference
    private class BundleClass {}
    
    public init(configuration: ChatwootConfiguration, conversationId: Int? = nil) {
        self.configuration = configuration
        self.conversationId = conversationId
    }
    
    /// Programmatically close the chat view
    public func close() {
        print("[Chatwoot] Swift: Attempting to close chat view")
        guard let webView = webView else {
            print("[Chatwoot] Swift: Error - WebView reference is nil")
            return
        }
        
        let script = """
        console.log('[Chatwoot] Swift: Dispatching chatwootClose event');
        document.dispatchEvent(new Event('chatwootClose'));
        """
        
        print("[Chatwoot] Swift: Evaluating close script")
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("[Chatwoot] Swift: Error evaluating close script: \(error)")
            } else {
                print("[Chatwoot] Swift: Close script executed successfully")
            }
        }
    }
    
    /// Creates and configures the WKWebView instance
    public func makeUIView(context: Context) -> WKWebView {
        print("[Chatwoot] Swift: Creating WebView")
        // Configure WebView settings
        let configuration = WKWebViewConfiguration()
        // Enable inline media playback (videos play within the page)
        configuration.allowsInlineMediaPlayback = true
        // Allow media to play without user interaction
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Set up JavaScript bridge for console logging
        let contentController = WKUserContentController()
        // Add message handler to receive console logs from JavaScript
        contentController.add(context.coordinator, name: "console")
        // Add message handler for close button
        contentController.add(context.coordinator, name: "close")
        configuration.userContentController = contentController
        
        // Configure JavaScript preferences
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        configuration.preferences = preferences
        
        // Enable debugging tools in development
        #if DEBUG
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        
        if #available(iOS 16.4, *) {
            // Enable Web Inspector for debugging in iOS 16.4+
            // Uses private API through reflection
            if let setter = class_getInstanceMethod(WKWebViewConfiguration.self, NSSelectorFromString("setInspectable:")) {
                let implementation = method_getImplementation(setter)
                let function = unsafeBitCast(implementation, to: (@convention(c) (Any, Selector, Bool) -> Void).self)
                function(configuration, NSSelectorFromString("setInspectable:"), true)
            }
        }
        #endif
        
        // Create and configure the WebView
        let webView = WKWebView(frame: .zero, configuration: configuration)
        // Store reference to webView
        DispatchQueue.main.async {
            print("[Chatwoot] Swift: Storing WebView reference")
            self.webView = webView
        }
        // Enable swipe navigation gestures
        webView.allowsBackForwardNavigationGestures = true
        // Enable link previews
        webView.allowsLinkPreview = true
        // Set navigation delegate to handle page loads
        webView.navigationDelegate = context.coordinator

        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        
        // Set up notification observer for dismiss actions
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.handleDismiss),
            name: Notification.Name("ChatwootDismiss"),
            object: nil
        )
        
        return webView
    }
    
    /// Creates the coordinator to handle WebView events
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// Coordinator class to handle WebView navigation and JavaScript messages
    public class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: ChatwootView
        
        init(_ parent: ChatwootView) {
            self.parent = parent
        }
        
        @objc func handleDismiss() {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }
        
        /// Handles messages from JavaScript
        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            switch message.name {
            case "console":
                if let log = message.body as? [String: Any] {
                    let type = log["type"] as? String ?? "log"
                    let message = log["message"] as? String ?? ""
                    
                    // Forward console messages to native logging
                    switch type {
                    case "log": print("[WebView] \(message)")
                    case "error": print("[WebView Error] \(message)")
                    case "warn": print("[WebView Warning] \(message)")
                    case "info": print("[WebView Info] \(message)")
                    default: print("[WebView] \(message)")
                    }
                }
            case "close":
                print("[Chatwoot] Swift: Received close message from JavaScript")
                DispatchQueue.main.async {
                    print("[Chatwoot] Swift: Dismissing view using presentation mode")
                    self.parent.presentationMode.wrappedValue.dismiss()
                }
            default:
                print("[Chatwoot] Swift: Received unknown message type: \(message.name)")
                break
            }
        }
        
        /// Called when WebView finishes loading a page
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // print("[Chatwoot] Swift: WebView finished loading")
            // Inject Chatwoot configuration into the page
            let script = """
            const chatwootConfig = {
                accountId: \(parent.configuration.accountId),
                apiHost: '\(parent.configuration.apiHost)',
                accessToken: '\(parent.configuration.accessToken)',
                pubsubToken: '\(parent.configuration.pubsubToken)',
                websocketUrl: '\(parent.configuration.websocketUrl)',
                \(parent.conversationId != nil ? "conversationId: \(parent.conversationId!)," : "")
            };
            
            // Set window variables from configuration
            window.__WOOT_ACCOUNT_ID__ = chatwootConfig.accountId;
            window.__WOOT_API_HOST__ = chatwootConfig.apiHost;
            window.__WOOT_ACCESS_TOKEN__ = chatwootConfig.accessToken;
            window.__PUBSUB_TOKEN__ = chatwootConfig.pubsubToken;
            window.__WEBSOCKET_URL__ = chatwootConfig.websocketUrl;
            \(parent.conversationId != nil ? "window.__WOOT_CONVERSATION_ID__ = \(parent.conversationId!);" : "")
            
            // Add Chatwoot configuration to window object
            window.chatwootConfig = chatwootConfig;
            
            // Create custom event to notify the web component
            const event = new CustomEvent('chatwootConfigLoaded', { detail: chatwootConfig });
            document.dispatchEvent(event);
            
            // Log configuration
            console.log('Chatwoot configuration from didFinish:', chatwootConfig);
            console.log('Window variables:', {
                __WOOT_ACCOUNT_ID__: window.__WOOT_ACCOUNT_ID__,
                __WOOT_API_HOST__: window.__WOOT_API_HOST__,
                __WOOT_ACCESS_TOKEN__: window.__WOOT_ACCESS_TOKEN__,
                __PUBSUB_TOKEN__: window.__PUBSUB_TOKEN__,
                __WEBSOCKET_URL__: window.__WEBSOCKET_URL__,
                __WOOT_CONVERSATION_ID__: window.__WOOT_CONVERSATION_ID__,
                __WOOT_ISOLATED_SHELL__: window.__WOOT_ISOLATED_SHELL__
            });
            """
            
            webView.evaluateJavaScript(script, completionHandler: nil)
        }
    }
    
    /// Cleans up resources when the view is removed
    public static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        // Remove notification observers
        NotificationCenter.default.removeObserver(coordinator, name: Notification.Name("ChatwootDismiss"), object: nil)
    }
    
    /// Updates the WebView when SwiftUI view updates
    public func updateUIView(_ webView: WKWebView, context: Context) {
        print("Loading HTML from SDK bundle")
        
        // Load the HTML content from SDK bundle
        guard let bundlePath = Bundle.module.path(forResource: "index", ofType: "html"),
              let htmlContent = try? String(contentsOfFile: bundlePath, encoding: .utf8) else {
            print("Error: Could not load index.html from SDK bundle")
            return
        }
        
        // Create a base URL for relative resources
        let baseURL = URL(fileURLWithPath: bundlePath).deletingLastPathComponent()
        
        // Print base URL for debugging
        // print("[Chatwoot] Swift: Base URL for resources: \(baseURL.path)")
        
        // Get Bundle directory and content
        let bundleURL = Bundle.module.bundleURL
        let cssURL = bundleURL.appendingPathComponent("style.css")
        
        // print("[Chatwoot] Swift: Bundle URL: \(bundleURL)")
        // print("[Chatwoot] Swift: CSS URL: \(cssURL)")
        
        // Load HTML with the bundle URL so resources can be found
        webView.loadHTMLString(htmlContent, baseURL: bundleURL)
        
        // Inject configuration after a short delay to ensure page is loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            print("Injecting Chatwoot configuration")
            
            // Create configuration object as JSON
            let config = """
            {
                "accountId": \(self.configuration.accountId),
                "apiHost": "\(self.configuration.apiHost)",
                "accessToken": "\(self.configuration.accessToken)",
                "pubsubToken": "\(self.configuration.pubsubToken)",
                "websocketUrl": "\(self.configuration.websocketUrl)",
                "conversationId": \(self.conversationId != nil ? String(self.conversationId!) : "null")
            }
            """
            
            // Inject configuration and initialize widget
            let script = """
            try {
                const chatwootConfig = JSON.parse(\(config));
                
                // Set window variables from configuration
                window.__WOOT_ACCOUNT_ID__ = chatwootConfig.accountId;
                window.__WOOT_API_HOST__ = chatwootConfig.apiHost;
                window.__WOOT_ACCESS_TOKEN__ = chatwootConfig.accessToken;
                window.__PUBSUB_TOKEN__ = chatwootConfig.pubsubToken;
                window.__WEBSOCKET_URL__ = chatwootConfig.websocketUrl;
                if (chatwootConfig.conversationId) {
                    window.__WOOT_CONVERSATION_ID__ = chatwootConfig.conversationId;
                }
                
                // Store it globally
                window.chatwootConfig = chatwootConfig;
                
                // Notify any listeners
                const event = new CustomEvent('chatwootConfigLoaded', { detail: chatwootConfig });
                document.dispatchEvent(event);
                
                console.log('Chatwoot configuration injected successfully, window variables:', {
                    __WOOT_ACCOUNT_ID__: window.__WOOT_ACCOUNT_ID__,
                    __WOOT_API_HOST__: window.__WOOT_API_HOST__,
                    __WOOT_ACCESS_TOKEN__: window.__WOOT_ACCESS_TOKEN__,
                    __PUBSUB_TOKEN__: window.__PUBSUB_TOKEN__,
                    __WEBSOCKET_URL__: window.__WEBSOCKET_URL__,
                    __WOOT_CONVERSATION_ID__: window.__WOOT_CONVERSATION_ID__,
                    __WOOT_ISOLATED_SHELL__: window.__WOOT_ISOLATED_SHELL__
                });
                
                // Force page reload if needed to apply configuration
                // Uncomment this if the widget still doesn't initialize properly
                // location.reload();
                
                true; // Return success
            } catch (error) {
                console.error('Error injecting Chatwoot config:', error);
                false; // Return failure
            }
            """
            
            // Execute the script and handle result
            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    print("Error injecting Chatwoot config: \(error)")
                } else if let success = result as? Bool, success {
                    print("Chatwoot config injected successfully")
                } else {
                    // print("Chatwoot config injection returned unexpected result: \(String(describing: result))")
                }
            }
        }
    }
}