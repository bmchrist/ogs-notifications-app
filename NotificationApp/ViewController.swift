import UIKit

class ViewController: UIViewController {
    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    private let serverHealthLabel = UILabel()
    private let serverToggleLabel = UILabel()
    private let serverToggleSegmentedControl = UISegmentedControl(items: ServerEnvironment.allCases.map { $0.displayName })
    private let userIdTextField = UITextField()
    private let setUserIdButton = UIButton(type: .system)
    private let diagnosticsButton = UIButton(type: .system)
    private let registerButton = UIButton(type: .system)
    private let refreshHealthButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateStatus()
        checkServerHealth()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateStatus()
        checkServerHealth()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "OGS Notifications"

        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = "OGS Notification App"
        titleLabel.font = .preferredFont(forTextStyle: .title1)
        titleLabel.textAlignment = .center

        statusLabel.font = .preferredFont(forTextStyle: .body)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0

        serverHealthLabel.font = .preferredFont(forTextStyle: .body)
        serverHealthLabel.textAlignment = .center
        serverHealthLabel.numberOfLines = 0
        serverHealthLabel.text = "🔄 Checking server..."

        serverToggleLabel.text = "Server Environment:"
        serverToggleLabel.font = .preferredFont(forTextStyle: .headline)
        serverToggleLabel.textAlignment = .center

        let currentEnvironment = NetworkManager.shared.getCurrentEnvironment()
        if let index = ServerEnvironment.allCases.firstIndex(of: currentEnvironment) {
            serverToggleSegmentedControl.selectedSegmentIndex = index
        }
        serverToggleSegmentedControl.addTarget(self, action: #selector(serverToggleChanged), for: .valueChanged)

        userIdTextField.placeholder = "Enter your OGS User ID (e.g., 1783478)"
        userIdTextField.borderStyle = .roundedRect
        userIdTextField.keyboardType = .numberPad

        setUserIdButton.setTitle("Set User ID", for: .normal)
        setUserIdButton.backgroundColor = .systemBlue
        setUserIdButton.setTitleColor(.white, for: .normal)
        setUserIdButton.layer.cornerRadius = 8
        setUserIdButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        setUserIdButton.addTarget(self, action: #selector(setUserIdTapped), for: .touchUpInside)

        diagnosticsButton.setTitle("📊 View Diagnostics", for: .normal)
        diagnosticsButton.backgroundColor = .systemGreen
        diagnosticsButton.setTitleColor(.white, for: .normal)
        diagnosticsButton.layer.cornerRadius = 8
        diagnosticsButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        diagnosticsButton.addTarget(self, action: #selector(diagnosticsTapped), for: .touchUpInside)

        registerButton.setTitle("🔄 Re-register Device", for: .normal)
        registerButton.backgroundColor = .systemOrange
        registerButton.setTitleColor(.white, for: .normal)
        registerButton.layer.cornerRadius = 8
        registerButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)

        refreshHealthButton.setTitle("🩺 Check Server Health", for: .normal)
        refreshHealthButton.backgroundColor = .systemPurple
        refreshHealthButton.setTitleColor(.white, for: .normal)
        refreshHealthButton.layer.cornerRadius = 8
        refreshHealthButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        refreshHealthButton.addTarget(self, action: #selector(refreshHealthTapped), for: .touchUpInside)

        view.addSubview(stackView)

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(statusLabel)
        stackView.addArrangedSubview(createSeparator())
        stackView.addArrangedSubview(serverToggleLabel)
        stackView.addArrangedSubview(serverToggleSegmentedControl)
        stackView.addArrangedSubview(serverHealthLabel)
        stackView.addArrangedSubview(refreshHealthButton)
        stackView.addArrangedSubview(createSeparator())
        stackView.addArrangedSubview(userIdTextField)
        stackView.addArrangedSubview(setUserIdButton)
        stackView.addArrangedSubview(createSeparator())
        stackView.addArrangedSubview(diagnosticsButton)
        stackView.addArrangedSubview(registerButton)

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])

        if let userId = UserDefaults.standard.string(forKey: "user_id") {
            userIdTextField.text = userId
        }
    }

    private func createSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }

    private func updateStatus() {
        let hasUserId = UserDefaults.standard.string(forKey: "user_id") != nil
        let hasDeviceToken = UserDefaults.standard.string(forKey: "device_token") != nil

        var statusText = ""
        if hasUserId && hasDeviceToken {
            statusText = "✅ Ready to receive notifications"
        } else if hasUserId {
            statusText = "⚠️ User ID set, waiting for device token"
        } else {
            statusText = "❌ Please set your OGS User ID"
        }

        statusLabel.text = statusText
        diagnosticsButton.isEnabled = hasUserId
        registerButton.isEnabled = hasUserId && hasDeviceToken
    }

    @objc private func setUserIdTapped() {
        guard let userId = userIdTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !userId.isEmpty else {
            print("❌ Invalid User ID entered")
            showAlert(title: "Invalid Input", message: "Please enter a valid User ID")
            return
        }

        print("📝 Setting User ID: \(userId)")
        UserDefaults.standard.set(userId, forKey: "user_id")
        updateStatus()

        if let deviceToken = UserDefaults.standard.string(forKey: "device_token") {
            print("🔄 Manual registration attempt - User ID: \(userId), Device Token: \(deviceToken)")
            Task {
                do {
                    try await NetworkManager.shared.registerDevice(userId: userId, deviceToken: deviceToken)
                    await MainActor.run {
                        print("✅ Manual registration successful")
                        showAlert(title: "Success", message: "User ID set and device registered!")
                    }
                } catch {
                    await MainActor.run {
                        print("❌ Manual registration failed: \(error)")
                        showAlert(title: "Registration Failed", message: "User ID saved but server registration failed: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            print("⚠️ No device token available yet")
            showAlert(title: "User ID Saved", message: "Device will be registered when app gets notification permission")
        }
    }

    @objc private func diagnosticsTapped() {
        let diagnosticsVC = DiagnosticsViewController()
        let navController = UINavigationController(rootViewController: diagnosticsVC)
        present(navController, animated: true)
    }

    @objc private func registerTapped() {
        guard let userId = UserDefaults.standard.string(forKey: "user_id"),
              let deviceToken = UserDefaults.standard.string(forKey: "device_token") else {
            showAlert(title: "Error", message: "Missing User ID or device token")
            return
        }

        Task {
            do {
                try await NetworkManager.shared.registerDevice(userId: userId, deviceToken: deviceToken)
                await MainActor.run {
                    showAlert(title: "Success", message: "Device re-registered successfully!")
                }
            } catch {
                await MainActor.run {
                    showAlert(title: "Registration Failed", message: error.localizedDescription)
                }
            }
        }
    }

    @objc private func refreshHealthTapped() {
        checkServerHealth()
    }

    @objc private func serverToggleChanged() {
        let selectedIndex = serverToggleSegmentedControl.selectedSegmentIndex
        guard selectedIndex < ServerEnvironment.allCases.count else { return }

        let selectedEnvironment = ServerEnvironment.allCases[selectedIndex]
        NetworkManager.shared.setServerEnvironment(selectedEnvironment)

        print("🔄 Server environment changed to: \(selectedEnvironment.displayName)")

        // Automatically check health of new server
        checkServerHealth()

        showAlert(title: "Server Changed", message: "Now using: \(selectedEnvironment.displayName)")
    }

    private func checkServerHealth() {
        serverHealthLabel.text = "🔄 Checking server..."

        Task {
            let healthStatus = await NetworkManager.shared.checkServerHealth()
            await MainActor.run {
                serverHealthLabel.text = healthStatus.displayText
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}