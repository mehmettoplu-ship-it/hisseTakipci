import Foundation

enum SignalType: String, Codable, CaseIterable {
    case resistanceBreakout = "Direnç Kırıldı"
    case oversoldReversal   = "RSI Dip Dönüşü"
    case emaBullishCross    = "EMA Altın Kesişim"
    case goldenCross        = "EMA Altın Haç"
    case bollingerBounce    = "Bollinger Dip Zıplama"
    case squeezeBounce      = "Sıkışma Patlaması"
    case rsiDivergence      = "RSI Boğa Diverjansı"
    case maStack            = "EMA Hizalanması"
    case breakoutRetest     = "Kırılma Geri Testi"
    case trendPullback      = "Trend Desteği"
    case smartMomentum      = "Akıllı Momentum"

    var emoji: String {
        switch self {
        case .resistanceBreakout: return "🚀"
        case .oversoldReversal:   return "🔄"
        case .emaBullishCross:    return "⚡"
        case .goldenCross:        return "🌟"
        case .bollingerBounce:    return "🔻"
        case .squeezeBounce:      return "💥"
        case .rsiDivergence:      return "🔀"
        case .maStack:            return "📊"
        case .breakoutRetest:     return "🎯"
        case .trendPullback:      return "↩️"
        case .smartMomentum:      return "🧠"
        }
    }

    var storageKey: String {
        switch self {
        case .resistanceBreakout: return "strategy_resistanceBreakout"
        case .oversoldReversal:   return "strategy_oversoldReversal"
        case .emaBullishCross:    return "strategy_emaBullishCross"
        case .goldenCross:        return "strategy_goldenCross"
        case .bollingerBounce:    return "strategy_bollingerBounce"
        case .squeezeBounce:      return "strategy_squeezeBounce"
        case .rsiDivergence:      return "strategy_rsiDivergence"
        case .maStack:            return "strategy_maStack"
        case .breakoutRetest:     return "strategy_breakoutRetest"
        case .trendPullback:      return "strategy_trendPullback"
        case .smartMomentum:      return "strategy_smartMomentum"
        }
    }
}

enum SignalStrength: String, Codable {
    case strong   = "Güçlü"
    case moderate = "Orta"
    case weak     = "Zayıf"

    var color: String {
        switch self {
        case .strong:   return "green"
        case .moderate: return "orange"
        case .weak:     return "gray"
        }
    }
}

struct Signal: Identifiable, Codable {
    let id: UUID
    let stock: Stock
    let type: SignalType
    let strength: SignalStrength
    let timeframe: Timeframe
    let price: Double
    let timestamp: Date
    let rsi: Double?
    let macdHistogram: Double?
    let volumeRatio: Double?
    let dailyChangePercent: Double?

    var notificationTitle: String {
        "\(stock.symbol) — \(type.rawValue) (\(timeframe.displayName))"
    }

    var notificationBody: String {
        var parts: [String] = ["Fiyat: \(String(format: "%.2f", price)) ₺"]
        if let rsi { parts.append("RSI: \(String(format: "%.1f", rsi))") }
        if let vr = volumeRatio { parts.append("Hacim: \(String(format: "%.1f", vr))x") }
        return parts.joined(separator: " | ")
    }
}
