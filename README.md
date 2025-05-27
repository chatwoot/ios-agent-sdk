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

| Parameter        | Type      | Required | Description                                 |
|--|-----------|----------|---------------------------------------------|
| `accountId`     | `Int`     | ✅        | Unique ID for the Chatwoot account          |
| `apiHost`       | `String`  | ✅        | Chatwoot API host URL                       |
| `accessToken`   | `String`  | ✅        | Access token for authentication             |
| `pubsubToken`   | `String`  | ✅        | Token for real-time updates                 |
| `websocketUrl`  | `String`  | ✅        | WebSocket URL for real-time communication   |

---

## 🛠️ Example Usage

### UIKit

```swift
import ChatwootSDK

// 1. Setup in AppDelegate/SceneDelegate
ChatwootSDK.setup(ChatwootConfiguration(
    accountId: 1,
    apiHost: "https://your-chatwoot.com",
    accessToken: "YOUR_ACCESS_TOKEN",
    pubsubToken: "YOUR_PUBSUB_TOKEN",
    websocketUrl: "wss://your-chatwoot.com"
))

// 2. Present chat modally
ChatwootSDK.presentChat(from: self, conversationId: 123)
```

### SwiftUI

```swift
import SwiftUI
import ChatwootSDK

struct ChatwootWrapper: UIViewControllerRepresentable {
    let conversationId: Int
    
    func makeUIViewController(context: Context) -> UIViewController {
        return ChatwootSDK.loadChatUI(conversationId: conversationId)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

struct ContentView: View {
    @State private var showChat = false
    
    var body: some View {
        Button("Open Chat") {
            showChat = true
        }
        .fullScreenCover(isPresented: $showChat) {
            ChatwootWrapper(conversationId: 123)
        }
    }
}
```

The conversationId is required to load the chat UI. Make sure you have a valid conversation ID before calling loadChatUI.