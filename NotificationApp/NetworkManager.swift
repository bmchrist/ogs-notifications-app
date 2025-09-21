import Foundation

enum ServerEnvironment: String, CaseIterable {
    case localhost = "http://localhost:8080"
    case production = "https://ogs-notifications-server-578849264983.us-east1.run.app"

    var displayName: String {
        switch self {
        case .localhost:
            return "Local (localhost:8080)"
        case .production:
            return "Production (Cloud Run)"
        }
    }
}

class NetworkManager {
    static let shared = NetworkManager()

    private var currentEnvironment: ServerEnvironment {
        if let savedEnvironment = UserDefaults.standard.string(forKey: "server_environment"),
           let environment = ServerEnvironment(rawValue: savedEnvironment) {
            return environment
        }
        return .localhost
    }

    private var baseURL: String {
        return currentEnvironment.rawValue
    }

    private let session = URLSession.shared

    private init() {}

    func setServerEnvironment(_ environment: ServerEnvironment) {
        UserDefaults.standard.set(environment.rawValue, forKey: "server_environment")
        print("🔄 Server environment changed to: \(environment.displayName)")
    }

    func getCurrentEnvironment() -> ServerEnvironment {
        return currentEnvironment
    }

    func registerDevice(userId: String, deviceToken: String) async throws {
        guard let url = URL(string: "\(baseURL)/register") else {
            throw NetworkError.invalidURL
        }

        let registration = DeviceRegistration(userId: userId, deviceToken: deviceToken)
        let jsonData = try JSONEncoder().encode(registration)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        print("Registering device at URL: \(url)")
        print("Request body: \(String(data: jsonData, encoding: .utf8) ?? "nil")")

        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("Registration response status: \(httpResponse.statusCode)")
            if let responseData = String(data: data, encoding: .utf8) {
                print("Registration response body: \(responseData)")
            }

            guard httpResponse.statusCode == 200 else {
                throw NetworkError.serverError("HTTP \(httpResponse.statusCode)")
            }
        }
    }

    func fetchDiagnostics(userId: String) async throws -> UserDiagnostics {
        guard let url = URL(string: "\(baseURL)/diagnostics/\(userId)") else {
            throw NetworkError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        if let httpResponse = response as? HTTPURLResponse {
            guard httpResponse.statusCode == 200 else {
                throw NetworkError.serverError("HTTP \(httpResponse.statusCode)")
            }
        }

        do {
            let diagnostics = try JSONDecoder().decode(UserDiagnostics.self, from: data)
            return diagnostics
        } catch {
            print("Decoding error: \(error)")
            throw NetworkError.decodingError
        }
    }

    func triggerManualCheck(userId: String) async throws {
        guard let url = URL(string: "\(baseURL)/check/\(userId)") else {
            throw NetworkError.invalidURL
        }

        let (_, response) = try await session.data(from: url)

        if let httpResponse = response as? HTTPURLResponse {
            guard httpResponse.statusCode == 200 else {
                throw NetworkError.serverError("HTTP \(httpResponse.statusCode)")
            }
        }
    }

    func checkServerHealth() async -> ServerHealthStatus {
        guard let url = URL(string: "\(baseURL)/health") else {
            return .error("Invalid URL")
        }

        do {
            let (data, response) = try await session.data(from: url)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    if let healthData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let status = healthData["status"] as? String {
                        return .healthy(status)
                    } else {
                        return .healthy("OK")
                    }
                } else {
                    return .error("HTTP \(httpResponse.statusCode)")
                }
            }
            return .error("No response")
        } catch {
            // Check if it's a network connectivity issue vs server down
            if let urlError = error as? URLError {
                switch urlError.code {
                case .cannotConnectToHost, .networkConnectionLost, .notConnectedToInternet:
                    return .offline
                default:
                    return .error(urlError.localizedDescription)
                }
            }
            return .offline
        }
    }
}