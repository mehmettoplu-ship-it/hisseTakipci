import SwiftUI

/// Her hisse için 0–100 arası kalite skoru hesaplar.
/// Skor bileşenleri:
///   • Strateji çeşitliliği  (0-28): 4+ farklı strateji maksimum
///   • Güçlü sinyal bonusu   (0-25): kaç tane .strong sinyali var
///   • Hacim oranı           (0-20): 4x+ hacim = maksimum
///   • RSI kalite bölgesi    (0-15): 48-62 ideal, dışarı çıktıkça düşer
///   • Günlük değişim        (0-12): momentum onayı
struct StockOpportunity: Identifiable {
    let stock: Stock
    let signals: [Signal]
    let score: Int

    var id: String { stock.id }

    var grade: String { Self.grade(for: score) }
    var gradeColor: Color { Self.gradeColor(for: score) }

    static func grade(for score: Int) -> String {
        if score >= 80 { return "A" }
        if score >= 60 { return "B" }
        if score >= 40 { return "C" }
        return "D"
    }

    static func gradeColor(for score: Int) -> Color {
        if score >= 80 { return Color(red: 0.1,  green: 0.85, blue: 0.55) }
        if score >= 60 { return Color(red: 0.2,  green: 0.5,  blue: 1.0)  }
        if score >= 40 { return Color(red: 1.0,  green: 0.62, blue: 0.0)  }
        return Color(.systemGray2)
    }

    /// Tüm sinyallerden sıralanmış fırsat listesi oluşturur.
    static func build(from allSignals: [Signal]) -> [StockOpportunity] {
        Dictionary(grouping: allSignals, by: \.stock.id)
            .compactMap { _, sigs -> StockOpportunity? in
                guard let stock = sigs.first?.stock else { return nil }
                return StockOpportunity(stock: stock, signals: sigs, score: computeScore(sigs))
            }
            .sorted { $0.score > $1.score }
    }

    static func computeScore(_ signals: [Signal]) -> Int {
        guard !signals.isEmpty else { return 0 }

        let strongCount = signals.filter { $0.strength == .strong }.count
        let maxVol      = signals.compactMap(\.volumeRatio).max() ?? 1.0
        let rsi         = signals.compactMap(\.rsi).first ?? 50.0
        let maxChange   = signals.compactMap(\.dailyChangePercent).max() ?? 0.0

        let stratScore: Int = min(signals.count, 4) * 7  // max 28

        let strengthScore: Int = {
            if strongCount >= 2 { return 25 }
            if strongCount == 1 { return 16 }
            return 8
        }()

        let volScore: Int = {
            if maxVol >= 4   { return 20 }
            if maxVol >= 3   { return 14 }
            if maxVol >= 2   { return 8  }
            if maxVol >= 1.5 { return 3  }
            return 0
        }()

        let rsiScore: Int = {
            if rsi >= 48 && rsi <= 62 { return 15 }
            if rsi >= 42 && rsi <= 68 { return 10 }
            if rsi >= 35 && rsi <= 72 { return 5  }
            return 0
        }()

        let changeScore: Int = {
            if maxChange >= 3   { return 12 }
            if maxChange >= 1.5 { return 8  }
            if maxChange >= 0.5 { return 4  }
            return 0
        }()

        return min(stratScore + strengthScore + volScore + rsiScore + changeScore, 100)
    }
}
