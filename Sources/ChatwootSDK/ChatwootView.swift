import Foundation
import WebKit
import ObjectiveC
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
/// A UIKit view controller that wraps a WKWebView to display the Chatwoot chat widget
public class ChatwootViewController: UIViewController {
    /// Configuration containing Chatwoot settings
    private let configuration: ChatwootConfiguration
    /// Optional conversation ID
    private let conversationId: Int?
    /// The WebView instance
    private var webView: WKWebView!
    /// Close button for the interface
    private var closeButton: UIButton!
    /// Header view for profile information
    private var headerView: UIView!
    /// Profile label
    private var profileLabel: UILabel!
    /// Avatar image view
    private var avatarImageView: UIImageView!
    /// Loading indicator
    private var loadingIndicator: UIActivityIndicatorView!
    
    /// Profile data
    private var profile: ChatwootProfile = ChatwootProfile(name: "Loading...")
    private var isProfileLoading: Bool = true
    
    // Private class for bundle reference
    private class BundleClass {}
    
    public init(configuration: ChatwootConfiguration, conversationId: Int? = nil) {
        self.configuration = configuration
        self.conversationId = conversationId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadProfileData()
        loadWebView()
    }
    
    /// Sets up the UI components
    private func setupUI() {
        view.backgroundColor = UIColor.white
        
        // Create header view
        headerView = UIView()
        headerView.backgroundColor = UIColor.white
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        
        // Create close button
        closeButton = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            closeButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        } else {
            // For iOS 12, use a simple text-based back button or custom image
            closeButton.setTitle("‹", for: .normal)
            closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        }
        closeButton.tintColor = UIColor.black
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(closeButton)
        
        // Create avatar image view
        avatarImageView = UIImageView()
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 18
        avatarImageView.layer.masksToBounds = true
        avatarImageView.backgroundColor = UIColor.blue.withAlphaComponent(0.2)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(avatarImageView)
        
        // Create profile label
        profileLabel = UILabel()
        profileLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        profileLabel.textColor = UIColor.black
        profileLabel.text = profile.name
        profileLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(profileLabel)
        
        // Create loading indicator
        if #available(iOS 13.0, *) {
            loadingIndicator = UIActivityIndicatorView(style: .medium)
        } else {
            loadingIndicator = UIActivityIndicatorView(style: .gray)
        }
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.addSubview(loadingIndicator)
        
        // Configure WebView
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        
        // Set up JavaScript bridge
        let contentController = WKUserContentController()
        contentController.add(self, name: "console")
        contentController.add(self, name: "close")
        webConfiguration.userContentController = contentController
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        webConfiguration.preferences = preferences
        
        // Enable debugging in development
        #if DEBUG
        webConfiguration.websiteDataStore = WKWebsiteDataStore.default()
        
        if #available(iOS 16.4, *) {
            if let setter = class_getInstanceMethod(WKWebViewConfiguration.self, NSSelectorFromString("setInspectable:")) {
                let implementation = method_getImplementation(setter)
                let function = unsafeBitCast(implementation, to: (@convention(c) (Any, Selector, Bool) -> Void).self)
                function(webConfiguration, NSSelectorFromString("setInspectable:"), true)
            }
        }
        #endif
        
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        
        view.addSubview(webView)
        
        // Add separator line
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor.lightGray
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(separatorView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Header view constraints
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 56),
            
            // Close button constraints
            closeButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Avatar constraints
            avatarImageView.leadingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: 12),
            avatarImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 36),
            avatarImageView.heightAnchor.constraint(equalToConstant: 36),
            
            // Loading indicator constraints
            loadingIndicator.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            
            // Profile label constraints
            profileLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            profileLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            profileLabel.trailingAnchor.constraint(lessThanOrEqualTo: headerView.trailingAnchor, constant: -16),
            
            // Separator constraints
            separatorView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),
            
            // WebView constraints
            webView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        updateUI()
    }
    
    /// Updates the UI based on current state
    private func updateUI() {
        profileLabel.text = profile.name
        profileLabel.textColor = isProfileLoading ? UIColor.gray : UIColor.black
        
        if isProfileLoading {
            loadingIndicator.startAnimating()
            avatarImageView.image = nil
        } else {
            loadingIndicator.stopAnimating()
            
            if let avatarUrl = profile.avatarUrl, let url = URL(string: avatarUrl) {
                loadAvatarImage(from: url)
            } else {
                setInitialsAvatar()
            }
        }
    }
    
    /// Loads avatar image from URL
    private func loadAvatarImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self,
                      let data = data,
                      let image = UIImage(data: data) else { 
                    self?.setInitialsAvatar()
                    return 
                }
                self.avatarImageView.image = image
            }
        }.resume()
    }
    
    /// Sets initials avatar
    private func setInitialsAvatar() {
        let initials = profile.name.initials
        let size = CGSize(width: 36, height: 36)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        // Draw background circle
        UIColor.blue.withAlphaComponent(0.2).setFill()
        context?.fillEllipse(in: CGRect(origin: .zero, size: size))
        
        // Draw initials text
        let font = UIFont.systemFont(ofSize: 16, weight: .medium)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.blue
        ]
        
        let textSize = initials.size(withAttributes: textAttributes)
        let textRect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        initials.draw(in: textRect, withAttributes: textAttributes)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        avatarImageView.image = image
    }
    
    /// Loads the WebView content
    private func loadWebView() {
        print("Loading HTML from SDK bundle")
        
        guard let bundlePath = Bundle.module.path(forResource: "index", ofType: "html"),
              let htmlContent = try? String(contentsOfFile: bundlePath, encoding: .utf8) else {
            print("Error: Could not load index.html from SDK bundle")
            return
        }
        
        let bundleURL = Bundle.module.bundleURL
        webView.loadHTMLString(htmlContent, baseURL: bundleURL)
    }
    
    /// Loads profile data from API
    private func loadProfileData() {
        ProfileAPI.fetchProfile(
            baseUrl: configuration.apiHost,
            token: configuration.accessToken
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let fetchedProfile):
                    self.profile = fetchedProfile
                    self.isProfileLoading = false
                case .failure(let error):
                    print("[Chatwoot] Error loading profile: \(error.localizedDescription)")
                    self.profile = ChatwootProfile(name: "Chat User")
                    self.isProfileLoading = false
                }
                
                self.updateUI()
            }
        }
    }
    
    /// Handles close button tap
    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    /// Programmatically close the chat view
    public func close() {
        print("[Chatwoot] Swift: Attempting to close chat view")
        
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
}

// MARK: - WKNavigationDelegate

extension ChatwootViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Inject Chatwoot configuration into the page
        let script = """
        const chatwootConfig = {
            accountId: \(configuration.accountId),
            apiHost: '\(configuration.apiHost)',
            accessToken: '\(configuration.accessToken)',
            pubsubToken: '\(configuration.pubsubToken)',
            websocketUrl: '\(configuration.websocketUrl)',
            \(conversationId != nil ? "conversationId: \(conversationId!)," : "")
        };
        
        // Set window variables from configuration
        window.__WOOT_ACCOUNT_ID__ = chatwootConfig.accountId;
        window.__WOOT_API_HOST__ = chatwootConfig.apiHost;
        window.__WOOT_ACCESS_TOKEN__ = chatwootConfig.accessToken;
        window.__PUBSUB_TOKEN__ = chatwootConfig.pubsubToken;
        window.__WEBSOCKET_URL__ = chatwootConfig.websocketUrl;
        \(conversationId != nil ? "window.__WOOT_CONVERSATION_ID__ = \(conversationId!);" : "")
        
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
        
        // Additional configuration injection after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            print("Injecting Chatwoot configuration")
            
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
                
                console.log('Chatwoot configuration injected successfully');
                
                true;
            } catch (error) {
                console.error('Error injecting Chatwoot config:', error);
                false;
            }
            """
            
            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    print("Error injecting Chatwoot config: \(error)")
                } else if let success = result as? Bool, success {
                    print("Chatwoot config injected successfully")
                }
            }
        }
    }
}

// MARK: - WKScriptMessageHandler

extension ChatwootViewController: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "console":
            if let log = message.body as? [String: Any] {
                let type = log["type"] as? String ?? "log"
                let message = log["message"] as? String ?? ""
                
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
                print("[Chatwoot] Swift: Dismissing view")
                self.dismiss(animated: true, completion: nil)
            }
        default:
            print("[Chatwoot] Swift: Received unknown message type: \(message.name)")
            break
        }
    }
}

// MARK: - Models and Utilities (moved from ChatwootSDK.swift)

/// Profile data model
struct ChatwootProfile {
    let name: String
    let avatarUrl: String?
    
    init(name: String, avatarUrl: String? = nil) {
        self.name = name
        self.avatarUrl = avatarUrl
    }
}

/// API Utilities
private struct ProfileAPI {
    static func fetchProfile(baseUrl: String, token: String, completion: @escaping (Result<ChatwootProfile, Error>) -> Void) {
        guard let url = URL(string: "\(baseUrl)/api/v1/profile") else {
            let error = NSError(domain: "ChatwootSDK", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            completion(.failure(error))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(token, forHTTPHeaderField: "api_access_token")
        
        print("[Chatwoot] Fetching profile from: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[Chatwoot] Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                guard (200...299).contains(statusCode) else {
                    let error = NSError(domain: "ChatwootSDK", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(statusCode)"])
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
            }
            
            guard let responseData = data else {
                let error = NSError(domain: "ChatwootSDK", code: 1002, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] else {
                    throw NSError(domain: "ChatwootSDK", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
                }
                
                var displayName: String = "Chat User"
                
                if let name = json["name"] as? String, !name.isEmpty {
                    displayName = name
                }
                
                if let availableName = json["available_name"] as? String, !availableName.isEmpty {
                    displayName = availableName
                }
                
                if let dispName = json["display_name"] as? String, !dispName.isEmpty {
                    displayName = dispName
                }
                
                var avatarUrl: String? = nil
                if let avatar = json["avatar_url"] as? String, !avatar.isEmpty {
                    avatarUrl = avatar
                }
                
                let profile = ChatwootProfile(name: displayName, avatarUrl: avatarUrl)
                
                DispatchQueue.main.async {
                    completion(.success(profile))
                }
            } catch {
                print("[Chatwoot] JSON parsing error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}

// String extension for initials
extension String {
    var initials: String {
        let components = self.split(separator: " ")
        guard let first = components.first?.first else { return "?" }
        
        if components.count > 1, let last = components.last?.first {
            return "\(first)\(last)".uppercased()
        } else {
            return String(first).uppercased()
        }
    }
}
#endif