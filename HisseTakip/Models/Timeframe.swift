import Foundation

enum Timeframe: String, CaseIterable, Codable, Identifiable {
    case oneHour  = "1S"
    case fourHour = "4S"
    case daily    = "1G"
    case weekly   = "1H"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oneHour:  return "1 Saat"
        case .fourHour: return "4 Saat"
        case .daily:    return "Günlük"
        case .weekly:   return "Haftalık"
        }
    }

    var yahooInterval: String {
        switch self {
        case .oneHour, .fourHour: return "1h"
        case .daily:              return "1d"
        case .weekly:             return "1wk"
        }
    }

    var yahooRange: String {
        switch self {
        case .oneHour:  return "30d"   // ~120 BIST 1h candles (BIST ~8h/day × 15 days)
        case .fourHour: return "90d"   // ~180 BIST 1h candles → 45 4h bars after aggregation
        case .daily:    return "1y"    // ~250 trading days — required for weeklyBreakout
        case .weekly:   return "5y"    // ~260 haftalık mum — uzun vadeli trend analizi
        }
    }

    // 4h için 1h verisi 4'erli gruplar halinde aggregate edilir
    var aggregationFactor: Int {
        switch self {
        case .oneHour, .daily, .weekly: return 1
        case .fourHour:                 return 4
        }
    }
}
