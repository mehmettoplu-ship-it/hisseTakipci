import Foundation

struct QuarterlyStatement {
    let date: Date
    let revenue: Double
    let netIncome: Double
    let operatingIncome: Double

    var isProfit: Bool { netIncome > 0 }
    var isLoss:   Bool { netIncome < 0 }

    var netMargin: Double       { revenue != 0 ? netIncome / revenue : 0 }
    var operatingMargin: Double { revenue != 0 ? operatingIncome / revenue : 0 }

    var periodLabel: String {
        let cal = Calendar.current
        let q   = (cal.component(.month, from: date) - 1) / 3 + 1
        let y   = cal.component(.year,  from: date)
        return "Q\(q) \(y)"
    }
}

enum FinancialSignalType: String, CaseIterable, Codable {
    case turningProfitable        = "Kara Geçiş"
    case approachingProfit        = "Kâra Yakın"
    case consecutiveLossReduction = "Sürekli İyileşme"
    case ebitTurnaround           = "FAVÖK Toparlandı"
    case lossReducing             = "Zarar Azalıyor"
    case operatingLeverage        = "Operasyonel Kaldıraç"
    case profitConsistency        = "İstikrarlı Kâr"
    case profitGrowing            = "Kar Büyüyor"
    case revenueGrowing           = "Gelir Artışı"

    var emoji: String {
        switch self {
        case .turningProfitable:        return "🎉"
        case .approachingProfit:        return "🎯"
        case .consecutiveLossReduction: return "📊"
        case .ebitTurnaround:           return "⚙️"
        case .lossReducing:             return "📉"
        case .operatingLeverage:        return "⚡"
        case .profitConsistency:        return "🏆"
        case .profitGrowing:            return "📈"
        case .revenueGrowing:           return "💰"
        }
    }

    var priority: Int {
        switch self {
        case .turningProfitable:        return 0
        case .approachingProfit:        return 1
        case .consecutiveLossReduction: return 2
        case .ebitTurnaround:           return 3
        case .lossReducing:             return 4
        case .operatingLeverage:        return 5
        case .profitConsistency:        return 6
        case .profitGrowing:            return 7
        case .revenueGrowing:           return 8
        }
    }
}

struct FinancialSignal: Identifiable, Codable {
    let id = UUID()
    let stock: Stock
    let type: FinancialSignalType
    let currentNetIncome: Double
    let previousNetIncome: Double
    let netIncomeChangePercent: Double
    let currentRevenue: Double
    let revenueChangePercent: Double
    let period: String
    let yoyNetIncomeChangePercent: Double?
    // Ek alanlar
    let currentOperatingIncome: Double
    let operatingIncomeChangePercent: Double
    let consecutiveImprovements: Int        // ardışık iyileşme sayısı (çeyrek)
    let currentNetMargin: Double            // mevcut net kâr marjı (0.03 = %3)
    let netMarginImprovement: Double        // marj değişimi (puan cinsinden)
    let timestamp: Date = Date()
}
