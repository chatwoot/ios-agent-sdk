// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import Foundation
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Utilities

// Extension to create Color from hex string
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 253, 253, 253) // Default to #fdfdfd if invalid
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Extension to help formatting a string into initials
extension String {
    /// Returns initials from the string (first letter of first word and first letter of last word)
    /// Examples:
    /// - "John Doe" -> "JD"
    /// - "Jane" -> "J"
    /// - "" -> "?"
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

/// Custom loading spinner view
private struct LoadingSpinner: View {
    @State private var isRotating = false
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Color.gray, lineWidth: 1.5)
            .frame(width: 14, height: 14)
            .rotationEffect(Angle(degrees: isRotating ? 360 : 0))
            .onAppear {
                withAnimation(
                    Animation
                        .linear(duration: 1)
                        .repeatForever(autoreverses: false)
                ) {
                    isRotating = true
                }
            }
    }
}

/// URLImage view for loading remote images (iOS 13+ compatible)
private struct URLImage: View {
    let url: URL
    @State private var image: Image?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                loadingView
            } else {
                fallbackView
            }
        }
        .onAppear(perform: loadImage)
    }
    
    private var loadingView: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .overlay(LoadingSpinner())
    }
    
    private var fallbackView: some View {
        Circle()
            .fill(Color.blue.opacity(0.2))
    }
    
    private func loadImage() {
        guard isLoading else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, let uiImage = UIImage(data: data) {
                    self.image = Image(uiImage: uiImage)
                }
                self.isLoading = false
            }
        }.resume()
    }
}

// MARK: - Models

/// Profile data model
struct ChatwootProfile {
    let name: String
    let avatarUrl: String?
    
    init(name: String, avatarUrl: String? = nil) {
        self.name = name
        self.avatarUrl = avatarUrl
    }
}

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

// MARK: - API Utilities

/// Utility for Chatwoot Profile API operations
private struct ProfileAPI {
    
    /// Fetches profile data from the Chatwoot API
    /// - Parameters:
    ///   - baseUrl: The base URL for the Chatwoot API
    ///   - token: API access token
    ///   - completion: Callback with Result containing profile data or error
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
                // Parse the JSON to extract profile data
                guard let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] else {
                    throw NSError(domain: "ChatwootSDK", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
                }
                
                // Try to extract the best name to display using our priority order
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
                
                // Extract avatar URL if available
                var avatarUrl: String? = nil
                if let avatar = json["avatar_url"] as? String, !avatar.isEmpty {
                    avatarUrl = avatar
                }
                
                let profile = ChatwootProfile(name: displayName, avatarUrl: avatarUrl)
                // print("[Chatwoot] Successfully parsed profile name: \(displayName)")
                
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

// MARK: - View Components

/// Header bar component for Chatwoot chat interface
struct ChatHeaderBar: View {
    let profile: ChatwootProfile
    let isLoading: Bool
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                // Call dismiss handler
                onDismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(.black))
                    .padding(8)
            }
            
            // Avatar with initials on the left
            if isLoading {
                // Loading state - show placeholder with spinner
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 36, height: 36)
                    .overlay(LoadingSpinner())
            } else if let avatarUrl = profile.avatarUrl, let url = URL(string: avatarUrl) {
                // Show avatar image from URL
                URLImage(url: url)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                // Show initials avatar when no URL
                initialsAvatar
            }
            
            // Name
            if isLoading {
                Text(profile.name)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(Color(.systemGray))
            
            } else {
                Text(profile.name)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(Color(.black))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.systemGray4))
                .offset(y: 28)
        )
    }
    
    // Helper view for initials avatar
    private var initialsAvatar: some View {
        ZStack {
            Circle()
                .fill(Color(.systemBlue).opacity(0.2))
                .frame(width: 36, height: 36)
            
            Text(profile.name.initials)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(.systemBlue))
        }
    }
}

/// Container view with the profile data and header
struct ChatwootMainView: View {
    let configuration: ChatwootConfiguration
    @State private var profile: ChatwootProfile = ChatwootProfile(name: "Loading...")
    @State private var isLoading: Bool = true
    @Environment(\.presentationMode) private var presentationMode
    let conversationId: Int?
    
    init(configuration: ChatwootConfiguration, conversationId: Int? = nil) {
        self.configuration = configuration
        self.conversationId = conversationId
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header view - now using refactored ChatHeaderBar component
            ChatHeaderBar(
                profile: profile,
                isLoading: isLoading,
                onDismiss: {
                    // Use dismiss mechanism via notification
                    NotificationCenter.default.post(name: Notification.Name("ChatwootDismiss"), object: nil)
                }
            )
            
            // Chat view
            ChatwootView(configuration: configuration, conversationId: conversationId)
        }
        // Use improved safe area handling that avoids keyboard jumping
        .modifier(SafeAreaModifier())
        // Allow keyboard to adjust view naturally
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            loadProfileData()
        }
    }
    
    private func loadProfileData() {
        // Fetch profile data using the refactored ProfileAPI utility
        ProfileAPI.fetchProfile(
            baseUrl: configuration.apiHost, 
            token: configuration.accessToken
        ) { result in
            switch result {
            case .success(let fetchedProfile):
                self.profile = fetchedProfile
                self.isLoading = false
            case .failure(let error):
                print("[Chatwoot] Error loading profile in header: \(error.localizedDescription)")
                self.profile = ChatwootProfile(name: "Chat User")
                self.isLoading = false
            }
        }
    }
}

// MARK: - Safe Area Handling

/// A modifier that handles safe area insets properly across iOS versions
/// This implementation avoids interference with keyboard animations
private struct SafeAreaModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            // On iOS 15+, use ignoresSafeArea instead of safeAreaInset to avoid keyboard issues
            content
                .ignoresSafeArea(.keyboard) // This prevents keyboard from pushing the view
        } else {
            // On iOS 14, use a minimal approach that won't interfere with keyboard
            content
                .ignoresSafeArea(.keyboard)
        }
    }
}

// MARK: - Public SDK Interface

public enum ChatwootSDK {
    private static var configuration: ChatwootConfiguration?
    
    public static func setup(_ config: ChatwootConfiguration) {
        configuration = config
        print("[Chatwoot] SDK configured successfully")
    }
    
    /// Returns a SwiftUI view for the Chatwoot chat interface
    /// - Parameter conversationId: Conversation ID to load a specific conversation
    /// - Returns: A SwiftUI view that can be used in SwiftUI views
    public static func loadChatUI(conversationId: Int) -> some View {
        guard let config = configuration else {
            fatalError("ChatwootSDK must be configured before use. Call ChatwootSDK.setup() first.")
        }
        
        // Create a container view with the ChatHeaderView
            return ChatwootMainView(configuration: config, conversationId: conversationId)
        .preferredColorScheme(.light) // Force light mode
    }
}