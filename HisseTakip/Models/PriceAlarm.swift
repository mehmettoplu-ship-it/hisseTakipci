import Foundation

struct PriceAlarm: Identifiable, Codable {
    var id: UUID = UUID()
    let stockSymbol: String
    let stockName: String
    let targetPrice: Double
    let direction: Direction
    var isTriggered: Bool = false
    let createdAt: Date = Date()

    enum Direction: String, Codable, CaseIterable {
        case above = "Üzerine Çıkınca"
        case below = "Altına Düşünce"
    }
}
