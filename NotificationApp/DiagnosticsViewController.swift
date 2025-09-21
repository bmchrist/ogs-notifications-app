import UIKit

class DiagnosticsViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    private let titleLabel = UILabel()
    private let userIdLabel = UILabel()
    private let registrationStatusLabel = UILabel()
    private let deviceTokenLabel = UILabel()
    private let lastNotificationLabel = UILabel()
    private let serverStatusLabel = UILabel()
    private let gamesHeaderLabel = UILabel()
    private let gamesStackView = UIStackView()
    private let refreshButton = UIButton(type: .system)
    private let manualCheckButton = UIButton(type: .system)

    private var currentUserId: String?
    private var diagnostics: UserDiagnostics?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadDiagnostics()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Diagnostics"

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        setupLabels()
        setupButtons()

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(createSeparator())
        stackView.addArrangedSubview(userIdLabel)
        stackView.addArrangedSubview(registrationStatusLabel)
        stackView.addArrangedSubview(deviceTokenLabel)
        stackView.addArrangedSubview(lastNotificationLabel)
        stackView.addArrangedSubview(serverStatusLabel)
        stackView.addArrangedSubview(createSeparator())
        stackView.addArrangedSubview(refreshButton)
        stackView.addArrangedSubview(manualCheckButton)
        stackView.addArrangedSubview(createSeparator())
        stackView.addArrangedSubview(gamesHeaderLabel)
        stackView.addArrangedSubview(gamesStackView)
    }

    private func setupLabels() {
        titleLabel.text = "OGS Notification Status"
        titleLabel.font = .preferredFont(forTextStyle: .title1)
        titleLabel.textAlignment = .center

        [userIdLabel, registrationStatusLabel, deviceTokenLabel, lastNotificationLabel, serverStatusLabel, gamesHeaderLabel].forEach { label in
            label.font = .preferredFont(forTextStyle: .body)
            label.numberOfLines = 0
        }

        gamesHeaderLabel.font = .preferredFont(forTextStyle: .headline)
        gamesStackView.axis = .vertical
        gamesStackView.spacing = 8
    }

    private func setupButtons() {
        refreshButton.setTitle("🔄 Refresh Diagnostics", for: .normal)
        refreshButton.backgroundColor = .systemBlue
        refreshButton.setTitleColor(.white, for: .normal)
        refreshButton.layer.cornerRadius = 8
        refreshButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        refreshButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)

        manualCheckButton.setTitle("⚡ Trigger Manual Check", for: .normal)
        manualCheckButton.backgroundColor = .systemOrange
        manualCheckButton.setTitleColor(.white, for: .normal)
        manualCheckButton.layer.cornerRadius = 8
        manualCheckButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        manualCheckButton.addTarget(self, action: #selector(manualCheckTapped), for: .touchUpInside)
    }

    private func createSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }

    private func loadDiagnostics() {
        guard let userId = UserDefaults.standard.string(forKey: "user_id") else {
            showError("No user ID configured. Please set your OGS user ID.")
            return
        }

        currentUserId = userId

        Task {
            do {
                let diagnostics = try await NetworkManager.shared.fetchDiagnostics(userId: userId)
                await MainActor.run {
                    self.diagnostics = diagnostics
                    updateUI(with: diagnostics)
                }
            } catch {
                await MainActor.run {
                    showError("Failed to load diagnostics: \(error.localizedDescription)")
                }
            }
        }
    }

    private func updateUI(with diagnostics: UserDiagnostics) {
        userIdLabel.text = "👤 User ID: \(diagnostics.userId)"

        registrationStatusLabel.text = diagnostics.deviceTokenRegistered ?
            "✅ Device registered for notifications" :
            "❌ Device not registered"

        if let tokenPreview = diagnostics.deviceTokenPreview {
            deviceTokenLabel.text = "📱 Device Token: \(tokenPreview)..."
        } else {
            deviceTokenLabel.text = "📱 Device Token: Not available"
        }

        if let lastNotification = diagnostics.lastNotificationDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            lastNotificationLabel.text = "🕐 Last notification: \(formatter.string(from: lastNotification))"
        } else {
            lastNotificationLabel.text = "🕐 Last notification: Never"
        }

        serverStatusLabel.text = "🔄 Server checks every \(diagnostics.serverCheckInterval)"

        gamesHeaderLabel.text = "📊 Monitoring \(diagnostics.totalActiveGames) active games"

        updateGamesList(with: diagnostics.monitoredGames)
    }

    private func updateGamesList(with games: [GameInfo]) {
        gamesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if games.isEmpty {
            let noGamesLabel = UILabel()
            noGamesLabel.text = "No active games"
            noGamesLabel.textAlignment = .center
            noGamesLabel.textColor = .secondaryLabel
            gamesStackView.addArrangedSubview(noGamesLabel)
            return
        }

        for game in games {
            let gameView = createGameView(for: game)
            gamesStackView.addArrangedSubview(gameView)
        }
    }

    private func createGameView(for game: GameInfo) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 8

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.text = "\(game.isYourTurn ? "🔴" : "⚪") \(game.gameName)"

        let idLabel = UILabel()
        idLabel.font = .preferredFont(forTextStyle: .caption1)
        idLabel.textColor = .secondaryLabel
        idLabel.text = "Game ID: \(game.gameId)"

        let statusLabel = UILabel()
        statusLabel.font = .preferredFont(forTextStyle: .body)
        statusLabel.text = game.isYourTurn ? "Your turn!" : "Waiting for opponent"

        let lastMoveLabel = UILabel()
        lastMoveLabel.font = .preferredFont(forTextStyle: .caption1)
        lastMoveLabel.textColor = .secondaryLabel
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        lastMoveLabel.text = "Last move: \(formatter.string(from: game.lastMoveDate))"

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(idLabel)
        stackView.addArrangedSubview(statusLabel)
        stackView.addArrangedSubview(lastMoveLabel)

        if game.isYourTurn {
            let playButton = UIButton(type: .system)
            playButton.setTitle("🎯 Play Game", for: .normal)
            playButton.backgroundColor = .systemGreen
            playButton.setTitleColor(.white, for: .normal)
            playButton.layer.cornerRadius = 6
            playButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
            playButton.addTarget(self, action: #selector(openGame(_:)), for: .touchUpInside)
            playButton.tag = game.gameId
            stackView.addArrangedSubview(playButton)
        }

        containerView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])

        return containerView
    }

    @objc private func refreshTapped() {
        loadDiagnostics()
    }

    @objc private func manualCheckTapped() {
        guard let userId = currentUserId else { return }

        Task {
            do {
                try await NetworkManager.shared.triggerManualCheck(userId: userId)
                await MainActor.run {
                    showSuccess("Manual check triggered successfully")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.loadDiagnostics()
                    }
                }
            } catch {
                await MainActor.run {
                    showError("Failed to trigger manual check: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc private func openGame(_ sender: UIButton) {
        let gameId = sender.tag
        let urlString = "https://online-go.com/game/\(gameId)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showSuccess(_ message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}