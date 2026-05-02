import SwiftUI

enum MarketCondition {
    case strongBull, bull, neutral, bear, strongBear

    var label: String {
        switch self {
        case .strongBull: return "Güçlü Yükseliş"
        case .bull:       return "Yükseliş"
        case .neutral:    return "Yatay"
        case .bear:       return "Düşüş"
        case .strongBear: return "Sert Düşüş"
        }
    }

    var systemImage: String {
        switch self {
        case .strongBull: return "arrow.up.circle.fill"
        case .bull:       return "arrow.up.right.circle.fill"
        case .neutral:    return "minus.circle.fill"
        case .bear:       return "arrow.down.right.circle.fill"
        case .strongBear: return "arrow.down.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .strongBull: return .green
        case .bull:       return Color(red: 0.3, green: 0.75, blue: 0.4)
        case .neutral:    return .yellow
        case .bear:       return .orange
        case .strongBear: return .red
        }
    }
}

struct MarketStatus {
    let price: Double
    let changePercent: Double
    let dayHigh: Double
    let dayLow: Double
    let condition: MarketCondition
    let isAboveEMA50: Bool
    let isBelowSupport: Bool
    let updatedAt: Date

    static func makeFromQuote(price: Double, changePercent: Double) -> MarketStatus {
        let condition: MarketCondition
        if changePercent >= 2.0       { condition = .strongBull }
        else if changePercent > 0.0   { condition = .bull }
        else if changePercent >= -0.5 { condition = .neutral }
        else if changePercent >= -2.0 { condition = .bear }
        else                          { condition = .strongBear }

        return MarketStatus(
            price: price, changePercent: changePercent,
            dayHigh: price, dayLow: price,
            condition: condition, isAboveEMA50: true,
            isBelowSupport: false, updatedAt: Date()
        )
    }

    static func make(candles: [Candle]) -> MarketStatus? {
        guard candles.count >= 20,
              let last = candles.last,
              let prev = candles.dropLast().last
        else { return nil }

        let changePercent = (last.close - prev.close) / prev.close * 100

        let closes = candles.map(\.close)
        let ema50Arr = TechnicalAnalysis.ema(values: closes, period: min(50, candles.count))
        let ema50 = ema50Arr.last ?? 0
        let isAboveEMA50 = ema50 > 0 && last.close > ema50

        let support20 = candles.suffix(21).dropLast().map(\.low).min() ?? 0
        let isBelowSupport = last.close < support20

        let condition: MarketCondition
        if changePercent >= 2.0       { condition = .strongBull }
        else if changePercent > 0.0   { condition = .bull }
        else if changePercent >= -0.5 { condition = .neutral }
        else if changePercent >= -2.0 { condition = .bear }
        else                          { condition = .strongBear }

        return MarketStatus(
            price: last.close, changePercent: changePercent,
            dayHigh: last.high, dayLow: last.low,
            condition: condition, isAboveEMA50: isAboveEMA50,
            isBelowSupport: isBelowSupport, updatedAt: Date()
        )
    }
}
