import Foundation

struct SignalRecord: Identifiable, Codable {
    let id: UUID
    let stockSymbol: String
    let stockName: String
    let strategyType: SignalType
    let timeframe: Timeframe
    let signalPrice: Double
    let signalDate: Date
    var lastSeenPrice: Double?
    var lastSeenDate: Date?

    var returnPercent: Double? {
        guard let lsp = lastSeenPrice, signalPrice > 0 else { return nil }
        return (lsp - signalPrice) / signalPrice * 100.0
    }
    var isHit:  Bool { (returnPercent ?? 0) >= 3.0 }
    var isLoss: Bool { (returnPercent ?? 0) <= -5.0 }
    var daysSinceSignal: Int {
        Calendar.current.dateComponents([.day], from: signalDate, to: Date()).day ?? 0
    }
}

struct StrategyStats {
    let signalCount:    Int
    let evaluatedCount: Int
    let hitCount:       Int
    let lossCount:      Int
    let avgReturn:      Double?
    let bestReturn:     Double?
    let worstReturn:    Double?

    var hitRate: Double {
        evaluatedCount > 0 ? Double(hitCount) / Double(evaluatedCount) * 100.0 : 0
    }
    var neutralCount: Int { evaluatedCount - hitCount - lossCount }
}
