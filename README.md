# OGS Notifications iOS App

A minimal iOS application for receiving push notifications from Online Go Server (OGS) and opening game URLs.

## Features

- 📱 Receives push notifications for OGS game events
- 🔗 Opens game URLs in Safari when notifications are tapped
- 🎯 Supports deep linking via `ogs://` URL scheme
- ⚡ Minimal UI - focuses purely on notification handling

## Requirements

- iOS 14.0 or later
- Xcode 15.2 or later
- Physical iOS device (push notifications don't work in simulator)
- Apple Developer account for code signing

## Setup

### 1. Clone and Open Project
```bash
git clone <repository-url>
cd ogs-notifications-app
open NotificationApp.xcodeproj
```

### 2. Configure Code Signing
1. Open the project in Xcode
2. Select the `NotificationApp` target
3. Go to "Signing & Capabilities"
4. Set your Team and Bundle Identifier
5. Ensure "Push Notifications" capability is enabled

### 3. Build and Run
1. Connect a physical iOS device
2. Select your device as the build target
3. Build and run the project (⌘+R)
4. Grant notification permissions when prompted

### 4. Get Device Token
1. Check Xcode console for device token output
2. Copy the device token for server configuration
3. Provide token to your OGS server for push notifications

## Usage

### Receiving Notifications
The app automatically handles push notifications with this payload format:
```json
{
  "aps": {
    "alert": {
      "title": "Your turn in Go!",
      "body": "It's your turn in: Game Name"
    },
    "badge": 1,
    "sound": "default"
  },
  "web_url": "https://online-go.com/game/12345",
  "app_url": "ogs://game/12345",
  "action": "open_game"
}
```

### Notification Interactions
- **Tap notification**: Opens the game URL in Safari
- **Direct URL**: `ogs://game/12345` redirects to web version

## Configuration

### Bundle Identifier
Current: `online-go-server-push-notification`

### URL Scheme
- Scheme: `ogs`
- Format: `ogs://game/{gameId}`
- Behavior: Redirects to `https://online-go.com/game/{gameId}`

### Push Environment
- Development: Uses APNs development environment
- Production: Change `aps-environment` in `NotificationApp.entitlements`

## Development

### Project Structure
```
NotificationApp/
├── AppDelegate.swift          # Push notification setup & handling
├── SceneDelegate.swift        # URL scheme handling
├── ViewController.swift       # Minimal UI
├── Info.plist               # App configuration & URL schemes
├── NotificationApp.entitlements # Push notification capabilities
└── Assets.xcassets/          # App icons and resources
```

### Key Implementation Files
- **Notification Registration**: `AppDelegate.swift:9-16`
- **Notification Tap Handling**: `AppDelegate.swift:35-44`
- **URL Scheme Handling**: `SceneDelegate.swift:40-49`

### Testing Push Notifications
1. Build and run on physical device
2. Note device token from console
3. Use server or testing tool to send notifications
4. Test both notification taps and direct URL schemes

## Troubleshooting

### Common Issues

**No device token printed**
- Ensure you're running on a physical device
- Check notification permissions are granted
- Verify push notifications capability is enabled

**Notification not opening URL**
- Check console for any error messages
- Verify notification payload includes `web_url` and `action: "open_game"`
- Ensure Safari is available on device

**URL scheme not working**
- Verify URL format: `ogs://game/{gameId}`
- Check Info.plist has correct URL scheme registration
- Test with Safari address bar: type URL directly

### Debug Information
- Device tokens are printed to Xcode console
- URL handling debug info in `SceneDelegate.handleURL`
- Notification payload accessible in notification handlers

## Related Projects

This app works with the OGS server component for sending push notifications. See server repository for backend implementation details.

## License

[Add your license information here]