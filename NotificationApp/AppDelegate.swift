import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        print("=== APP LAUNCHED ===")

        // Check existing stored values
        if let existingUserId = UserDefaults.standard.string(forKey: "user_id") {
            print("Stored User ID: \(existingUserId)")
        } else {
            print("No User ID stored yet")
        }

        if let existingToken = UserDefaults.standard.string(forKey: "device_token") {
            print("Stored Device Token: \(existingToken)")
        } else {
            print("No Device Token stored yet")
        }

        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("Notification permission granted: \(granted)")
            if let error = error {
                print("Notification permission error: \(error)")
            }

            if granted {
                DispatchQueue.main.async {
                    print("Requesting remote notification registration...")
                    application.registerForRemoteNotifications()
                }
            }
        }

        return true
    }

    // MARK: - Remote Notifications

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")

        UserDefaults.standard.set(token, forKey: "device_token")

        if let userId = UserDefaults.standard.string(forKey: "user_id") {
            print("Attempting automatic registration with User ID: \(userId)")
            Task {
                do {
                    try await NetworkManager.shared.registerDevice(userId: userId, deviceToken: token)
                    print("✅ Device registered successfully with server")
                } catch {
                    print("❌ Failed to register device with server: \(error)")
                }
            }
        } else {
            print("⚠️ No User ID set - skipping automatic registration")
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        if let action = userInfo["action"] as? String, action == "open_game" {
            if let webURL = userInfo["web_url"] as? String, let url = URL(string: webURL) {
                UIApplication.shared.open(url)
            }
        }

        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge])
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}