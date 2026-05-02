import Foundation
import Combine

final class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()

    private let entriesKey = "favoriteEntries_v2"
    private let legacyKey  = "favoriteStockIDs"

    @Published private(set) var entries: [String: Date] = [:]

    var favoriteIDs: Set<String> { Set(entries.keys) }

    private init() {
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([String: Date].self, from: data) {
            entries = decoded
        } else {
            // Eski Set<String> formatından taşı — eklenme tarihi olarak bugünü kullan
            let arr = UserDefaults.standard.stringArray(forKey: legacyKey) ?? []
            entries = Dictionary(uniqueKeysWithValues: arr.map { ($0, Date()) })
            save()
        }
    }

    func isFavorite(_ stock: Stock) -> Bool {
        entries[stock.id] != nil
    }

    func addDate(for stock: Stock) -> Date? {
        entries[stock.id]
    }

    func toggle(_ stock: Stock) {
        if entries[stock.id] != nil {
            entries.removeValue(forKey: stock.id)
        } else {
            entries[stock.id] = Date()
        }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: entriesKey)
    }
}
