import Foundation
import UserNotifications

@MainActor
final class PriceAlarmManager: ObservableObject {
    static let shared = PriceAlarmManager()

    @Published private(set) var alarms: [PriceAlarm] = []
    private let key = "priceAlarms_v1"

    private init() { load() }

    func add(stockSymbol: String, stockName: String, targetPrice: Double, direction: PriceAlarm.Direction) {
        let alarm = PriceAlarm(stockSymbol: stockSymbol, stockName: stockName,
                               targetPrice: targetPrice, direction: direction)
        alarms.insert(alarm, at: 0)
        save()
    }

    func remove(_ alarm: PriceAlarm) {
        alarms.removeAll { $0.id == alarm.id }
        save()
    }

    func activeAlarms(for symbol: String) -> [PriceAlarm] {
        alarms.filter { $0.stockSymbol == symbol && !$0.isTriggered }
    }

    func checkAndFire(symbol: String, price: Double) {
        var changed = false
        for i in alarms.indices {
            guard alarms[i].stockSymbol == symbol, !alarms[i].isTriggered else { continue }
            let fired: Bool
            switch alarms[i].direction {
            case .above: fired = price >= alarms[i].targetPrice
            case .below: fired = price <= alarms[i].targetPrice
            }
            if fired {
                alarms[i].isTriggered = true
                sendNotification(alarm: alarms[i], currentPrice: price)
                changed = true
            }
        }
        if changed { save() }
    }

    private func sendNotification(alarm: PriceAlarm, currentPrice: Double) {
        let content = UNMutableNotificationContent()
        content.title = "🔔 Fiyat Alarmı — \(alarm.stockSymbol)"
        content.body  = "\(alarm.direction.rawValue): \(String(format: "%.2f ₺", currentPrice)) · Hedef: \(String(format: "%.2f ₺", alarm.targetPrice))"
        content.sound = .default
        let req = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([PriceAlarm].self, from: data)
        else { return }
        alarms = decoded
    }
}
