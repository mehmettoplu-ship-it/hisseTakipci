import Foundation

enum SignalType: String, Codable, CaseIterable {
    case resistanceBreakout = "Direnç Kırıldı"
    case oversoldReversal   = "RSI Dip Dönüşü"
    case macdBullishCross   = "MACD Altın Kesişim"
    case emaBullishCross    = "EMA Altın Kesişim"
    case bollingerBounce    = "Bollinger Dip Zıplama"
    case ecHFTPro           = "EC HFT Pro"
    case rsiDivergence      = "RSI Boğa Diverjansı"
    case maStack            = "EMA Hizalanması"
    case breakoutRetest     = "Kırılma Geri Testi"
    case smartMomentum      = "Akıllı Momentum"

    var emoji: String {
        switch self {
        case .resistanceBreakout: return "🚀"
        case .oversoldReversal:   return "🔄"
        case .macdBullishCross:   return "📈"
        case .emaBullishCross:    return "⚡"
        case .bollingerBounce:    return "🎯"
        case .ecHFTPro:           return "💹"
        case .rsiDivergence:      return "🔀"
        case .maStack:            return "📊"
        case .breakoutRetest:     return "🎯"
        case .smartMomentum:      return "🧠"
        }
    }

    var storageKey: String {
        switch self {
        case .resistanceBreakout: return "strategy_resistanceBreakout"
        case .oversoldReversal:   return "strategy_oversoldReversal"
        case .macdBullishCross:   return "strategy_macdBullishCross"
        case .emaBullishCross:    return "strategy_emaBullishCross"
        case .bollingerBounce:    return "strategy_bollingerBounce"
        case .ecHFTPro:           return "strategy_ecHFTPro"
        case .rsiDivergence:      return "strategy_rsiDivergence"
        case .maStack:            return "strategy_maStack"
        case .breakoutRetest:     return "strategy_breakoutRetest"
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
    let dailyChangePercent: Double?  // (son kapanış - önceki kapanış) / önceki kapanış * 100

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
