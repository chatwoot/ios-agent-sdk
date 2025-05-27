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
    
    public init(
        accountId: Int,
        apiHost: String,
        accessToken: String,
        pubsubToken: String,
        websocketUrl: String
    ) {
        self.accountId = accountId
        self.apiHost = apiHost
        self.accessToken = accessToken
        self.pubsubToken = pubsubToken
        self.websocketUrl = websocketUrl
    }
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