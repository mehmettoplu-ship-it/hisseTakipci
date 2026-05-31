import Foundation

enum Timeframe: String, CaseIterable, Codable, Identifiable {
    case oneHour  = "1S"
    case twoHour  = "2S"
    case fourHour = "4S"
    case daily    = "1G"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oneHour:  return "1 Saat"
        case .twoHour:  return "2 Saat"
        case .fourHour: return "4 Saat"
        case .daily:    return "Günlük"
        }
    }

    var yahooInterval: String {
        switch self {
        case .oneHour, .twoHour, .fourHour: return "1h"
        case .daily:                        return "1d"
        }
    }

    var yahooRange: String {
        switch self {
        case .oneHour:  return "30d"   // ~120 BIST 1h candles (BIST ~8h/day × 15 days)
        case .twoHour:  return "60d"   // ~240 1h candles → ~120 2h bars after aggregation
        case .fourHour: return "90d"   // ~180 BIST 1h candles → 45 4h bars after aggregation
        case .daily:    return "1y"    // ~250 trading days
        }
    }

    // 2h için 1h verisi 2'li, 4h için 4'erli gruplar halinde aggregate edilir
    var aggregationFactor: Int {
        switch self {
        case .oneHour, .daily: return 1
        case .twoHour:         return 2
        case .fourHour:        return 4
        }
    }
}
