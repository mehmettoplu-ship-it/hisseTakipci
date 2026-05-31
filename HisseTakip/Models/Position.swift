import Foundation

struct Position: Identifiable, Codable {
    let id: UUID
    let stockSymbol: String
    let stockName: String
    let stockSector: String
    let buyPrice: Double
    let quantity: Double
    let buyDate: Date
    var currentPrice: Double?

    var cost: Double { buyPrice * quantity }
    var currentValue: Double? { currentPrice.map { $0 * quantity } }
    var profitLoss: Double? { currentValue.map { $0 - cost } }
    var profitLossPercent: Double? {
        guard cost > 0 else { return nil }
        return profitLoss.map { $0 / cost * 100 }
    }
}
