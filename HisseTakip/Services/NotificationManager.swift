import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    // Uygulama ön plandayken de banner + ses göster
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func requestPermission() async {
        try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    func send(signal: Signal) {
        let content = UNMutableNotificationContent()
        content.title    = "\(signal.type.emoji) \(signal.notificationTitle)"
        content.body     = signal.notificationBody
        content.sound    = .default
        content.userInfo = ["symbol": signal.stock.symbol]
        let id = "\(signal.stock.id)-\(signal.type.rawValue)-\(signal.timeframe.rawValue)"
            .addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
        schedule(content, id: id)
    }

    func sendDropped(signals: [Signal]) {
        guard !signals.isEmpty,
              UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        else { return }
        for signal in signals {
            let content = UNMutableNotificationContent()
            content.title = "⚠️ Sinyal Düştü: \(signal.stock.symbol)"
            content.body  = "\(signal.type.rawValue) · \(signal.timeframe.displayName) · \(String(format: "%.2f", signal.price)) ₺"
            content.sound = .default
            content.userInfo = ["symbol": signal.stock.symbol]
            let id = "dropped-\(signal.stock.id)-\(signal.timeframe.rawValue)"
                .addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
            schedule(content, id: id)
        }
    }

    func sendBatch(signals: [Signal]) {
        guard UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true else { return }
        let onlyStrong = UserDefaults.standard.object(forKey: "onlyStrongAlert") as? Bool ?? false
        let candidates = onlyStrong ? signals.filter { $0.strength == .strong } : signals
        guard !candidates.isEmpty else { return }

        var seen = Set<String>()
        let sorted = candidates.sorted {
            let order: [SignalStrength] = [.strong, .moderate, .weak]
            return (order.firstIndex(of: $0.strength) ?? 2) < (order.firstIndex(of: $1.strength) ?? 2)
        }
        for signal in sorted {
            let key = "\(signal.stock.id)-\(signal.timeframe.rawValue)"
            if !seen.contains(key) {
                seen.insert(key)
                send(signal: signal)
            }
        }
    }

    private func schedule(_ content: UNMutableNotificationContent, id: String) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
