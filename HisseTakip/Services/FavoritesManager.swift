import Foundation
import Combine

final class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    private let key = "favoriteStockIDs"

    @Published private(set) var favoriteIDs: Set<String> = []

    private init() {
        let arr = UserDefaults.standard.stringArray(forKey: key) ?? []
        favoriteIDs = Set(arr)
    }

    func isFavorite(_ stock: Stock) -> Bool {
        favoriteIDs.contains(stock.id)
    }

    func toggle(_ stock: Stock) {
        if favoriteIDs.contains(stock.id) {
            favoriteIDs.remove(stock.id)
        } else {
            favoriteIDs.insert(stock.id)
        }
        UserDefaults.standard.set(Array(favoriteIDs), forKey: key)
    }
}
