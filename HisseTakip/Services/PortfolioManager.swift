import Foundation

@MainActor
final class PortfolioManager: ObservableObject {
    static let shared = PortfolioManager()

    @Published private(set) var positions: [Position] = []
    private let key = "portfolio_v1"

    private init() { load() }

    func add(stock: Stock, buyPrice: Double, quantity: Double, buyDate: Date) {
        let p = Position(id: UUID(), stockSymbol: stock.symbol, stockName: stock.name,
                         stockSector: stock.sector, buyPrice: buyPrice,
                         quantity: quantity, buyDate: buyDate, currentPrice: nil)
        positions.insert(p, at: 0)
        save()
    }

    func remove(_ position: Position) {
        positions.removeAll { $0.id == position.id }
        save()
    }

    func updatePrice(symbol: String, price: Double) {
        for i in positions.indices where positions[i].stockSymbol == symbol {
            positions[i].currentPrice = price
        }
    }

    var totalCost: Double  { positions.reduce(0) { $0 + $1.cost } }
    var totalValue: Double { positions.compactMap(\.currentValue).reduce(0, +) }
    var totalPL: Double    { positions.filter { $0.currentPrice != nil }.reduce(0) { $0 + ($1.profitLoss ?? 0) } }

    var totalPLPercent: Double {
        let base = positions.filter { $0.currentPrice != nil }.reduce(0) { $0 + $1.cost }
        guard base > 0 else { return 0 }
        return totalPL / base * 100
    }

    private func save() {
        if let data = try? JSONEncoder().encode(positions) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Position].self, from: data)
        else { return }
        positions = decoded
    }
}
