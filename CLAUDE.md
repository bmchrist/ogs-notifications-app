# Claude Code Context - OGS Notifications iOS App

## Project Overview
iOS push notification app for Online Go Server (OGS) that receives game notifications and opens web URLs.

## Related Repositories
- **iOS App**: `ogs-notifications-app` (current repository)
- **Server**: `ogs-server` (separate repository)
- **Coordination**: Both Claude agents should reference this document for consistency

## Current Implementation Status

### ✅ Completed Features
- [x] Basic iOS app structure with Xcode project
- [x] Push notification registration and device token handling
- [x] UNUserNotificationCenterDelegate implementation
- [x] Notification tap handling to open web URLs
- [x] URL scheme support (`ogs://`) for deep linking
- [x] Scene-based URL handling in SceneDelegate

### 📋 Key Files
- `AppDelegate.swift:35-44` - Notification tap handling
- `SceneDelegate.swift:40-49` - URL scheme handling
- `Info.plist:5-15` - URL scheme registration
- `NotificationApp.entitlements` - Push notification capabilities

## API Contracts & Interfaces

### Push Notification Payload Format
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
  "web_url": "https://online-go.com/game/79504463",
  "app_url": "ogs://game/79504463",
  "game_id": 79504463,
  "action": "open_game",
  "game_name": "Game Name"
}
```

### URL Schemes
- **Web URLs**: `https://online-go.com/game/{gameId}`
- **App URLs**: `ogs://game/{gameId}` (redirects to web)
- **Bundle ID**: `online-go-server-push-notification`

### Notification Actions
- `"action": "open_game"` - Opens the game URL when notification is tapped

## Configuration Details

### Development Setup
- **Team ID**: `7GNARLCG65`
- **Bundle Identifier**: `online-go-server-push-notification`
- **Deployment Target**: iOS 14.0+
- **Push Environment**: Development (can be changed to production)

### Entitlements
- `aps-environment: development` in `NotificationApp.entitlements`

## Cross-Repository Coordination

### When Server Changes Affect iOS
- Notification payload structure changes
- New action types or URL schemes
- Authentication/security updates

### When iOS Changes Affect Server
- Bundle identifier changes
- New URL scheme patterns
- Additional notification payload requirements

### Sync Points
- Device token registration endpoint
- Push notification sending logic
- URL generation for deep links

## Current Architecture Decisions

### Push Notification Flow
1. App requests notification permissions on launch
2. Registers for remote notifications with APNs
3. Device token printed to console (for development)
4. Server uses device token to send notifications
5. User taps notification → opens web URL in Safari

### URL Handling Strategy
- Prioritize web URLs over native app implementation
- Use `ogs://` scheme as fallback/redirect mechanism
- Always redirect app URLs to corresponding web URLs

### Security Considerations
- Development environment for APNs (not production)
- No authentication required for basic notification receiving
- Web URLs are opened in Safari (sandboxed from app)

## Development Notes

### Testing Push Notifications
- It IS possible to send push notifications to the simulator
- Device token needed for server to send notifications
- Test both notification tap and direct URL scheme handling

### Key Implementation Details
- `UNUserNotificationCenter.current().delegate = self` in AppDelegate
- Notification handling in `userNotificationCenter(_:didReceive:withCompletionHandler:)`
- URL scheme handling in `scene(_:openURLContexts:)` in SceneDelegate

## Future Considerations
- Production APNs environment setup
- Enhanced notification payload with more game context
- Notification categories for different actions
- Badge count management
- Background notification handling
