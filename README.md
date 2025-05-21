# 💬 Chatwoot iOS SDK (SwiftUI)

iOS SDK for Chatwoot



## 📦 Installation

### Option 1: Swift Package Manager (Recommended)

You can integrate the Chatwoot iOS SDK using Swift Package Manager:

1. Open your Xcode project.
2. Navigate to `File > Add Packages...`
3. Enter the following URL in the search field:
   ```
   https://github.com/chatwoot/agent-ios-sdk.git
   ```
4. Select the version you want to use (e.g. from version `1.0.0`) and click **Add Package**.

Then, import the SDK in your code:
```swift
import ChatwootSDK
```

### Option 2: Manual via `Package.swift`

If you're managing dependencies directly with Swift Package Manager via `Package.swift`:

```swift
.package(url: "https://github.com/chatwoot/agent-ios-sdk.git", from: "1.0.0")
```

Then, import the SDK where needed:
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
|-----------------|-----------|----------|---------------------------------------------|
| `accountId`     | `Int`     | ✅        | Unique ID for the Chatwoot account          |
| `apiHost`       | `String`  | ✅        | Chatwoot API host URL                       |
| `accessToken`   | `String`  | ✅        | Access token for authentication             |
| `pubsubToken`   | `String`  | ✅        | Token for real-time updates                 |
| `websocketUrl`  | `String`  | ✅        | WebSocket URL for real-time communication   |


## 🛠️ Example Usage

### Step 1: Set up the SDK

```swift
ChatwootSDK.setup(ChatwootConfiguration(
    accountId: 1,
    apiHost: "https://your-chatwoot.com",
    accessToken: "YOUR_ACCESS_TOKEN",
    pubsubToken: "YOUR_PUBSUB_TOKEN",
    websocketUrl: "wss://your-chatwoot.com"
))
```

### Step 2: Show the Chat Interface

```swift
@State private var showChat = false
@State private var conversationId: Int = 123 // Required: conversation ID to load

var body: some View {
    Button("Open Chat") {
        showChat = true
    }
    .fullScreenCover(isPresented: $showChat) {
        ChatwootSDK.loadChatUI(conversationId: conversationId)
    }
}
```

The `conversationId` is required to load the chat UI. Make sure you have a valid conversation ID before calling `loadChatUI`.

