import Foundation
#if canImport(UIKit)
import UIKit
#endif

public struct ChatwootConfiguration {
    public let accountId: Int
    public let apiHost: String
    public let accessToken: String
    public let pubsubToken: String
    public let websocketUrl: String
    public let inboxName: String
    public let inboxNameFontSize: CGFloat
    public let disableEditor: Bool
    public let editorDisableUpload: Bool
    #if canImport(UIKit)
    public let backArrowIcon: UIImage
    public let connectedIcon: UIImage
    public let disconnectedIcon: UIImage
    #endif
    
    #if canImport(UIKit)
    public init(
        accountId: Int,
        apiHost: String,
        accessToken: String,
        pubsubToken: String,
        websocketUrl: String,
        inboxName: String,
        inboxNameFontSize: CGFloat = 18,
        disableEditor: Bool = false,
        editorDisableUpload: Bool = false,
        backArrowIcon: UIImage,
        connectedIcon: UIImage,
        disconnectedIcon: UIImage
    ) {
        self.accountId = accountId
        self.apiHost = apiHost
        self.accessToken = accessToken
        self.pubsubToken = pubsubToken
        self.websocketUrl = websocketUrl
        self.inboxName = inboxName
        self.inboxNameFontSize = inboxNameFontSize
        self.disableEditor = disableEditor
        self.editorDisableUpload = editorDisableUpload
        self.backArrowIcon = backArrowIcon
        self.connectedIcon = connectedIcon
        self.disconnectedIcon = disconnectedIcon
    }
    #else
    public init(
        accountId: Int,
        apiHost: String,
        accessToken: String,
        pubsubToken: String,
        websocketUrl: String,
        inboxName: String,
        inboxNameFontSize: CGFloat = 18,
        disableEditor: Bool = false,
        editorDisableUpload: Bool = false
    ) {
        self.accountId = accountId
        self.apiHost = apiHost
        self.accessToken = accessToken
        self.pubsubToken = pubsubToken
        self.websocketUrl = websocketUrl
        self.inboxName = inboxName
        self.inboxNameFontSize = inboxNameFontSize
        self.disableEditor = disableEditor
        self.editorDisableUpload = editorDisableUpload
    }
    #endif
}

public enum ChatwootSDK {
    private static var configuration: ChatwootConfiguration?
    
    /// Configure the SDK with Chatwoot settings
    /// - Parameter config: Configuration object containing API credentials and endpoints
    public static func setup(_ config: ChatwootConfiguration) {
        configuration = config
        print("[Chatwoot] SDK configured successfully")
    }
    
#if canImport(UIKit)
    private static var currentThemeColor: UIColor = .white // Default as per theme.md
    private static var currentTextColor: UIColor? = nil // nil means auto-detect based on theme color
    /// Sets the theme color for the Chatwoot UI
    /// - Parameter color: The UIColor to use for theming.
    public static func setThemeColor(_ color: UIColor) {
        currentThemeColor = color
    }
    
    /// Sets the theme color for the Chatwoot UI using a hex string
    /// - Parameter hex: Hex color string (supports formats: "#RRGGBB", "#RGB", "RRGGBB", "RGB")
    /// - Returns: True if the color was set successfully, false if the hex string is invalid
    @discardableResult
    public static func setThemeColor(hex: String) -> Bool {
        guard let color = UIColor(hex: hex) else {
            print("[Chatwoot] Warning: Invalid hex color string '\(hex)'. Theme color not changed.")
            return false
        }
        currentThemeColor = color
        return true
    }
    
    /// Sets the theme color for the Chatwoot UI using a hex string (convenient overload)
    /// - Parameter hexString: Hex color string (supports formats: "#RRGGBB", "#RGB", "RRGGBB", "RGB")
    /// - Returns: True if the color was set successfully, false if the hex string is invalid
    @discardableResult
    public static func setThemeColor(_ hexString: String) -> Bool {
        return setThemeColor(hex: hexString)
    }

    /// Sets the text color for the Chatwoot UI
    /// - Parameter color: The UIColor to use for text elements (close button, labels, etc.).
    public static func setTextColor(_ color: UIColor) {
        currentTextColor = color
    }
    
    /// Sets the text color for the Chatwoot UI using a hex string
    /// - Parameter hex: Hex color string (supports formats: "#RRGGBB", "#RGB", "RRGGBB", "RGB")
    /// - Returns: True if the color was set successfully, false if the hex string is invalid
    @discardableResult
    public static func setTextColor(hex: String) -> Bool {
        guard let color = UIColor(hex: hex) else {
            print("[Chatwoot] Warning: Invalid hex color string '\(hex)'. Text color not changed.")
            return false
        }
        currentTextColor = color
        return true
    }
    
    /// Sets the text color for the Chatwoot UI using a hex string (convenient overload)
    /// - Parameter hexString: Hex color string (supports formats: "#RRGGBB", "#RGB", "RRGGBB", "RGB")
    /// - Returns: True if the color was set successfully, false if the hex string is invalid
    @discardableResult
    public static func setTextColor(_ hexString: String) -> Bool {
        return setTextColor(hex: hexString)
    }

    /// Gets the current theme color
    /// - Returns: The currently set UIColor for the theme.
    public static func getCurrentThemeColor() -> UIColor {
        return currentThemeColor
    }
    
    /// Gets the current text color (auto-detects based on theme if not explicitly set)
    /// - Returns: The UIColor to use for text elements.
    public static func getCurrentTextColor() -> UIColor {
        if let textColor = currentTextColor {
            return textColor
        }
        // Auto-detect based on theme color luminance
        return currentThemeColor.isLight ? .black : .white
    }

    /// Creates and returns a UIViewController for the Chatwoot chat interface
    /// - Parameter conversationId: Conversation ID to load a specific conversation
    /// - Returns: A UIViewController that can be presented modally or pushed onto a navigation stack
    public static func createChatViewController(conversationId: Int) -> UIViewController {
        guard let config = configuration else {
            fatalError("ChatwootSDK must be configured before use. Call ChatwootSDK.setup() first.")
        }
        
        return ChatwootViewController(configuration: config, conversationId: conversationId)
    }
    
    /// Presents the chat interface modally from the given view controller
    /// - Parameters:
    ///   - presentingViewController: The view controller from which to present the chat
    ///   - conversationId: Conversation ID to load a specific conversation
    ///   - animated: Whether to animate the presentation (default: true)
    ///   - completion: Optional completion handler called after presentation
    public static func presentChat(
        from presentingViewController: UIViewController,
        conversationId: Int,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        let chatViewController = createChatViewController(conversationId: conversationId)
        chatViewController.modalPresentationStyle = .fullScreen
        presentingViewController.present(chatViewController, animated: animated, completion: completion)
    }
    
    /// Pushes the chat interface onto the given navigation controller
    /// - Parameters:
    ///   - navigationController: The navigation controller to push onto
    ///   - conversationId: Conversation ID to load a specific conversation
    ///   - animated: Whether to animate the push (default: true)
    public static func pushChat(
        onto navigationController: UINavigationController,
        conversationId: Int,
        animated: Bool = true
    ) {
        let chatViewController = createChatViewController(conversationId: conversationId)
        navigationController.pushViewController(chatViewController, animated: animated)
    }
    
    /// Legacy compatibility method that returns a UIViewController for the chat interface
    /// - Parameter conversationId: Conversation ID to load a specific conversation
    /// - Returns: A UIViewController that can be used in UIKit or wrapped for SwiftUI
    /// - Note: This is for backward compatibility. Use createChatViewController() for new code.
    public static func loadChatUI(conversationId: Int) -> UIViewController {
        return createChatViewController(conversationId: conversationId)
    }
#endif
}