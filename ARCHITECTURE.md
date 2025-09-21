# OGS Notifications iOS App - Architecture

## Overview

This document describes the architecture, design decisions, and implementation approach for the OGS (Online Go Server) iOS push notification app. The app serves as a bridge between OGS game events and iOS users, providing instant notifications and seamless redirection to web-based gameplay.

## Design Philosophy

### Minimalist Approach
- **Single Purpose**: Exclusively handles push notifications for OGS
- **No Native Game UI**: Redirects all gameplay to web interface
- **Lightweight**: Minimal resource usage and complexity
- **Transparent**: Acts as a notification conduit, not a standalone app

### Web-First Strategy
- **Web Redirection**: All game actions open in Safari
- **No Duplication**: Avoids recreating existing web functionality
- **Consistency**: Users experience the same interface across devices
- **Maintenance**: Reduces need to sync features between native and web

## System Architecture

### High-Level Flow
```
OGS Server → APNs → iOS Device → Safari (Web Game)
     ↑                              ↓
     └── Device Token Registration ──┘
```

### Component Breakdown

#### 1. Push Notification Registration
**Location**: `AppDelegate.swift:7-18`
```swift
UNUserNotificationCenter.current().requestAuthorization()
application.registerForRemoteNotifications()
```

**Responsibilities**:
- Request user permission for notifications
- Register with Apple Push Notification Service (APNs)
- Obtain and log device token for server configuration

#### 2. Notification Handling
**Location**: `AppDelegate.swift:35-49`
```swift
func userNotificationCenter(_:didReceive:withCompletionHandler:)
func userNotificationCenter(_:willPresent:withCompletionHandler:)
```

**Responsibilities**:
- Handle notification taps when app is backgrounded/closed
- Parse notification payload for web URLs
- Initiate web browser opening
- Present notifications when app is active

#### 3. URL Scheme Handling
**Location**: `SceneDelegate.swift:35-49`
```swift
func scene(_:openURLContexts:)
private func handleURL(_ url: URL)
```

**Responsibilities**:
- Handle `ogs://` deep link URLs
- Convert app URLs to corresponding web URLs
- Open Safari with game-specific URLs

#### 4. UI Layer
**Location**: `ViewController.swift`
```swift
class ViewController: UIViewController
```

**Responsibilities**:
- Minimal placeholder interface
- "Notification App" label for user awareness
- No functional UI elements (intentional)

## Data Flow Architecture

### 1. Notification Payload Structure
```json
{
  "aps": {
    "alert": { "title": "...", "body": "..." },
    "badge": 1,
    "sound": "default"
  },
  "web_url": "https://online-go.com/game/{gameId}",
  "app_url": "ogs://game/{gameId}",
  "game_id": 79504463,
  "action": "open_game",
  "game_name": "Game Name"
}
```

### 2. URL Transformation Logic
```
Input:  ogs://game/79504463
Process: Extract gameId from path
Output: https://online-go.com/game/79504463
Action: UIApplication.shared.open(url)
```

### 3. Notification Processing Pipeline
```
Notification Received
       ↓
Parse userInfo Dictionary
       ↓
Extract "action" Field
       ↓
Match "open_game" Action
       ↓
Extract "web_url" Field
       ↓
Open URL in Safari
```

## Technical Decisions

### iOS App Architecture Choices

#### Scene-Based Architecture
- **Decision**: Use `UISceneDelegate` over legacy `UIApplicationDelegate`
- **Rationale**: Future-proofing for iOS 13+ multi-window support
- **Impact**: Cleaner URL handling and state management

#### Notification Delegate Pattern
- **Decision**: Implement `UNUserNotificationCenterDelegate` in `AppDelegate`
- **Rationale**: Centralized notification handling, consistent with iOS patterns
- **Impact**: Single point of control for all notification behaviors

#### Safari Over In-App Browser
- **Decision**: Use `UIApplication.shared.open()` instead of `SFSafariViewController`
- **Rationale**:
  - Full browser functionality (bookmarks, passwords, etc.)
  - Reduced app complexity and maintenance
  - Better user experience for complex web games
- **Impact**: Users switch apps but get full web experience

### URL Scheme Design

#### Scheme Selection: `ogs://`
- **Decision**: Use `ogs` as the URL scheme
- **Rationale**:
  - Short and memorable
  - Directly relates to Online Go Server
  - Unlikely to conflict with other apps
- **Impact**: Clear association with OGS ecosystem

#### URL Pattern: `ogs://game/{gameId}`
- **Decision**: Simple hierarchical structure
- **Rationale**:
  - Extensible for future resource types
  - Easy to parse and validate
  - Matches web URL structure
- **Impact**: Consistent mental model for users and developers

### Security Considerations

#### Minimal Attack Surface
- **Decision**: No authentication, user data storage, or network requests
- **Rationale**: Reduces security risks and complexity
- **Impact**: App acts as pure notification relay

#### URL Validation
- **Decision**: Basic scheme and structure validation
- **Rationale**: Prevent malicious URL redirection
- **Implementation**: Check scheme and extract gameId safely

#### Sandbox Compliance
- **Decision**: Use Safari for web content instead of embedded browser
- **Rationale**: Leverage iOS security sandboxing
- **Impact**: Web content isolated from app permissions

## Integration Architecture

### Server-Side Integration Points

#### Device Token Management
- **Flow**: iOS App → Server Database → Push Notification Service
- **Format**: Hexadecimal device token string
- **Storage**: Server maintains user → device token mapping

#### Notification Payload Construction
- **Server Responsibility**: Construct proper notification JSON
- **Required Fields**: `aps`, `web_url`, `action`
- **Optional Fields**: `app_url`, `game_id`, `game_name`

#### APNs Environment Configuration
- **Development**: Uses APNs sandbox environment
- **Production**: Requires production APNs certificate
- **Configuration**: `aps-environment` in entitlements file

### Cross-Platform Considerations

#### URL Compatibility
- **Web URLs**: Work on any platform with browser
- **App URLs**: iOS-specific but fallback to web
- **Strategy**: Always provide both URL types

#### Notification Format Consistency
- **Standard**: Follow APNs notification structure
- **Extensibility**: Custom fields in root payload object
- **Backward Compatibility**: Graceful handling of missing fields

## Error Handling Strategy

### Notification Registration Failures
```swift
func application(_:didFailToRegisterForRemoteNotificationsWithError:)
```
- **Log Error**: Print registration failure details
- **User Impact**: App still functional, just no notifications
- **Recovery**: User can retry by restarting app

### URL Opening Failures
```swift
UIApplication.shared.open(url) // No completion handler needed
```
- **System Handling**: iOS handles URL opening failures
- **Fallback**: Users can manually navigate to OGS website
- **Logging**: Basic URL logging for debugging

### Malformed Payload Handling
```swift
guard let webURL = userInfo["web_url"] as? String else { return }
```
- **Safe Extraction**: Optional binding prevents crashes
- **Graceful Degradation**: Ignore malformed notifications
- **User Experience**: No error shown, notification simply dismissed

## Performance Characteristics

### Memory Usage
- **Minimal UI**: Single view controller with static label
- **No Data Storage**: Zero persistent storage
- **URL Handling**: Immediate processing and disposal

### Battery Impact
- **Push Notifications**: Minimal battery usage (system-managed)
- **Background Activity**: None (no background refresh)
- **Network Usage**: Zero (notifications handled by system)

### Launch Time
- **Cold Launch**: Immediate - minimal initialization
- **Notification Launch**: Direct URL opening
- **Background Launch**: Not applicable

## Future Architecture Considerations

### Potential Enhancements
1. **Multiple Game Types**: Extend URL scheme for different game actions
2. **Rich Notifications**: Add notification categories and actions
3. **Badge Management**: Automatic badge count updates
4. **Silent Notifications**: Background game state updates

### Scalability Considerations
1. **URL Scheme Versioning**: Plan for URL format evolution
2. **Notification Categories**: Structured approach to different notification types
3. **Deep Link Analytics**: Track URL opening success rates
4. **Multi-Server Support**: Handle notifications from different OGS instances

### Migration Strategies
1. **Bundle ID Changes**: Plan for App Store migration
2. **Certificate Rotation**: APNs certificate renewal process
3. **Payload Evolution**: Backward-compatible notification format changes

## Development and Maintenance

### Code Organization Principles
- **Single Responsibility**: Each class has one clear purpose
- **Minimal Dependencies**: Standard iOS frameworks only
- **Clear Separation**: Notification logic separate from UI logic
- **Readable Code**: Self-documenting with minimal comments

### Testing Strategy
- **Device Testing**: Push notifications require physical devices
- **URL Testing**: Direct URL scheme testing via Safari
- **Payload Testing**: Various notification payload formats
- **Edge Cases**: Malformed URLs and payloads

### Deployment Considerations
- **Development Builds**: APNs sandbox environment
- **Production Builds**: Production APNs certificates
- **Code Signing**: Apple Developer account requirements
- **App Store**: Minimal app review requirements due to simplicity