# 💬 Chatwoot Agent iOS SDK (UIKit)

A lightweight iOS SDK built with **Swift** and **UIKit** to embed a Chatwoot-powered chat interface in any iOS app.



## 🎯 Objective

- Enable any iOS app to launch a full-featured Chatwoot chat screen
- Use UIKit for broad iOS compatibility (iOS 12+)

## 🧱 Supported Platforms

- ✅ **Swift 5.7+**
- ✅ **UIKit Framework**
- ✅ **iOS 12+** (Broad device compatibility)
- ✅ **SwiftUI Compatible** (via UIViewControllerRepresentable)



## 📦 Installation

### **Via Swift Package Manager (Remote)**

In `Package.swift`:

```swift
.package(url: "https://github.com/chatwoot/ios-agent-sdk", from: "1.0.0")
```

### **Via Xcode (Local Package)**

1. **Open your Xcode project**
2. **Add Package Dependency:**
   - Go to **File → Add Package Dependencies...**
   - Click **Add Local..** (bottom left)
   - Navigate to your local `ios-sdk` folder
   - Select the folder and click **Add Package**
3. **Configure Package:** Select your target(s) and click **Add Package**

### **Import in your app:**

```swift
import ChatwootSDK
```



## 📸 Camera and Photo Library Permissions (Required)

To enable photo capture or image upload features in the chat interface, **you must add the following keys to your app’s `Info.plist`:**

```xml
<key>NSCameraUsageDescription</key>
<string>This app uses the camera to let you capture and upload photos in chat.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to your photo library to let you pick images for chat.</string>
```

#### How to add in Xcode:

1. Open your project in Xcode.
2. Locate your app target’s `Info.plist` file in the Project Navigator.
3. Right-click and select “Add Row”, then add each key above with a clear description string.
   - **NSCameraUsageDescription**: Explains why the app uses the camera (e.g., photo capture for chat).
   - **NSPhotoLibraryUsageDescription**: Explains why the app needs photo library access (e.g., image upload for chat).



## ⚙️ Configuration Parameters

| Parameter             | Type      | Required | Default | Description                                 |
|----------------------|-----------|----------|---------|---------------------------------------------|
| `accountId`          | `Int`     | ✅        | -       | Unique ID for the Chatwoot account          |
| `apiHost`            | `String`  | ✅        | -       | Chatwoot API host URL                       |
| `accessToken`        | `String`  | ✅        | -       | Access token for authentication             |
| `pubsubToken`        | `String`  | ✅        | -       | Token for real-time updates                 |
| `websocketUrl`       | `String`  | ✅        | -       | WebSocket URL for real-time communication   |
| `inboxName`          | `String`  | ✅        | -       | Display name for the inbox/chat channel     |
| `inboxNameFontSize`  | `CGFloat` | ❌        | `18`    | Font size for the inbox name in header      |
| `backArrowIcon`      | `UIImage` | ✅        | -       | Back arrow icon for the header bar          |
| `connectedIcon`      | `UIImage` | ✅        | -       | Icon displayed when the app is online       |
| `disconnectedIcon`   | `UIImage` | ✅        | -       | Icon displayed when the app is offline      |
| `disableEditor`      | `Bool`    | ❌        | `false` | Disables the message editor in chat UI      |
| `editorDisableUpload`| `Bool`    | ❌        | `false` | Disables file upload in the message editor  |

---

## 🛠️ Example Usage

### Step 1: Set up the SDK

```swift
// Create mandatory header icons as UIImage objects from SVG files using SVGKit
let backArrowIcon = createUIImageFromSVG(named: "back_arrow.svg")
let connectedIcon = createUIImageFromSVG(named: "connected_icon.svg")
let disconnectedIcon = createUIImageFromSVG(named: "disconnected_icon.svg")

ChatwootSDK.setup(ChatwootConfiguration(
    accountId: 1,
    apiHost: "https://your-chatwoot.com",
    accessToken: "YOUR_ACCESS_TOKEN",
    pubsubToken: "YOUR_PUBSUB_TOKEN",
    websocketUrl: "wss://your-chatwoot.com",
    inboxName: "Support",          // Display name for the inbox
    inboxNameFontSize: 20,       // Optional: font size for inbox name (default: 18)
    backArrowIcon: backArrowIcon,  // Required: UIImage object
    connectedIcon: connectedIcon,  // Required: UIImage object
    disconnectedIcon: disconnectedIcon, // Required: UIImage object
    disableEditor: false,        // Optional: disable message editor
    editorDisableUpload: false   // Optional: disable file uploads
))
```

### Step 2: Show the Chat Interface (Recommended: Always Present from UIKit)

**Present Modally from UIKit (Recommended for Theming):**

```swift
// UIKit Example
ChatwootSDK.presentChat(from: self, conversationId: 123)
```

**SwiftUI Example (Call UIKit Presentation):**

```swift
import SwiftUI
import ChatwootSDK

struct ContentView: View {
    @State private var conversationId: String = "14635"
    
    var body: some View {
        Button("Open Chat") {
            presentChatFromRoot()
        }
    }
    
    private func presentChatFromRoot() {
        guard let conversationIdInt = Int(conversationId) else { return }
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            ChatwootSDK.presentChat(from: rootVC, conversationId: conversationIdInt)
        }
    }
}
```

- This approach ensures correct status bar theming and avoids SwiftUI modal limitations.
- Do **not** use `.fullScreenCover` or `UIViewControllerRepresentable` for presenting the chat if you want full theming support.

---

The conversationId is required to load the chat UI. Make sure you have a valid conversation ID before calling loadChatUI.

## 🎨 Theme Customization

```swift
// Set colors using UIColor or hex string
ChatwootSDK.setThemeColor(.systemBlue)
ChatwootSDK.setThemeColor("#1f93ff")
ChatwootSDK.setTextColor(.white)
```

---