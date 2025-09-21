import Foundation

enum ServerHealthStatus {
    case healthy(String)
    case offline
    case error(String)

    var displayText: String {
        switch self {
        case .healthy(let status):
            return "🟢 Server: \(status)"
        case .offline:
            return "🔴 Server: Offline"
        case .error(let message):
            return "🟡 Server: \(message)"
        }
    }

    var isHealthy: Bool {
        switch self {
        case .healthy:
            return true
        case .offline, .error:
            return false
        }
    }
}

struct UserDiagnostics: Codable {
    let userId: String
    let deviceTokenRegistered: Bool
    let deviceTokenPreview: String?
    let lastNotificationTime: TimeInterval
    let monitoredGames: [GameInfo]
    let totalActiveGames: Int
    let serverCheckInterval: String
    let lastServerCheckTime: TimeInterval?

    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case deviceTokenRegistered = "device_token_registered"
        case deviceTokenPreview = "device_token_preview"
        case lastNotificationTime = "last_notification_time"
        case monitoredGames = "monitored_games"
        case totalActiveGames = "total_active_games"
        case serverCheckInterval = "server_check_interval"
        case lastServerCheckTime = "last_server_check_time"
    }

    var lastNotificationDate: Date? {
        guard lastNotificationTime > 0 else { return nil }
        return Date(timeIntervalSince1970: lastNotificationTime / 1000)
    }

    var lastServerCheckDate: Date? {
        guard let checkTime = lastServerCheckTime else { return nil }
        return Date(timeIntervalSince1970: checkTime)
    }

    var gamesRequiringTurn: [GameInfo] {
        return monitoredGames.filter { $0.isYourTurn }
    }
}

struct GameInfo: Codable {
    let gameId: Int
    let lastMoveTimestamp: TimeInterval
    let currentPlayer: Int
    let isYourTurn: Bool
    let gameName: String

    private enum CodingKeys: String, CodingKey {
        case gameId = "game_id"
        case lastMoveTimestamp = "last_move_timestamp"
        case currentPlayer = "current_player"
        case isYourTurn = "is_your_turn"
        case gameName = "game_name"
    }

    var lastMoveDate: Date {
        return Date(timeIntervalSince1970: lastMoveTimestamp / 1000)
    }

    var webURL: String {
        return "https://online-go.com/game/\(gameId)"
    }

    var appURL: String {
        return "ogs://game/\(gameId)"
    }
}

struct DeviceRegistration: Codable {
    let userId: String
    let deviceToken: String

    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case deviceToken = "device_token"
    }
}

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .noData:
            return "No data received from server"
        case .decodingError:
            return "Failed to decode server response"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}