import Foundation

struct QuarterlyStatement {
    let date: Date
    let revenue: Double
    let netIncome: Double       // pozitif = kar, negatif = zarar
    let operatingIncome: Double

    var isProfit: Bool { netIncome > 0 }
    var isLoss:   Bool { netIncome < 0 }

    var periodLabel: String {
        let cal = Calendar.current
        let q   = (cal.component(.month, from: date) - 1) / 3 + 1
        let y   = cal.component(.year,  from: date)
        return "Q\(q) \(y)"
    }
}

enum FinancialSignalType: String, CaseIterable {
    case turningProfitable = "Kara Geçiş"
    case lossReducing      = "Zarar Azalıyor"
    case profitGrowing     = "Kar Büyüyor"
    case revenueGrowing    = "Gelir Artışı"

    var emoji: String {
        switch self {
        case .turningProfitable: return "🎉"
        case .lossReducing:      return "📉"
        case .profitGrowing:     return "📈"
        case .revenueGrowing:    return "💰"
        }
    }

    var priority: Int {
        switch self {
        case .turningProfitable: return 0
        case .lossReducing:      return 1
        case .profitGrowing:     return 2
        case .revenueGrowing:    return 3
        }
    }
}

struct FinancialSignal: Identifiable {
    let id = UUID()
    let stock: Stock
    let type: FinancialSignalType
    let currentNetIncome: Double
    let previousNetIncome: Double
    let netIncomeChangePercent: Double
    let currentRevenue: Double
    let revenueChangePercent: Double
    let period: String
    let yoyNetIncomeChangePercent: Double?  // yıllık karşılaştırma
    let timestamp: Date = Date()
}
