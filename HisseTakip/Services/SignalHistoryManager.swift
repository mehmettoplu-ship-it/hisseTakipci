import Foundation

final class SignalHistoryManager: ObservableObject {
    static let shared = SignalHistoryManager()

    private let storageKey = "signal_history_v1"
    private let maxRecords = 400
    private let maxDays    = 30

    @Published private(set) var records: [SignalRecord] = []

    private init() { load() }

    // MARK: - Kayıt

    func save(signals: [Signal]) {
        guard !signals.isEmpty else { return }
        let today = Calendar.current.startOfDay(for: Date())
        let todayKeys = Set(
            records
                .filter { Calendar.current.startOfDay(for: $0.signalDate) == today }
                .map { "\($0.stockSymbol)|\($0.strategyType.rawValue)|\($0.timeframe.rawValue)" }
        )
        let toAdd: [SignalRecord] = signals.compactMap { sig in
            let key = "\(sig.stock.symbol)|\(sig.type.rawValue)|\(sig.timeframe.rawValue)"
            guard !todayKeys.contains(key) else { return nil }
            return SignalRecord(
                id: UUID(),
                stockSymbol: sig.stock.symbol,
                stockName: sig.stock.name,
                strategyType: sig.type,
                timeframe: sig.timeframe,
                signalPrice: sig.price,
                signalDate: sig.timestamp
            )
        }
        records.append(contentsOf: toAdd)
        prune()
        persist()
    }

    // MARK: - Fiyat Güncelleme

    func updatePrice(symbol: String, price: Double) {
        let now = Date()
        var changed = false
        for i in records.indices where records[i].stockSymbol == symbol {
            records[i].lastSeenPrice = price
            records[i].lastSeenDate  = now
            changed = true
        }
        if changed { persist() }
    }

    // MARK: - İstatistikler

    func stats(for type: SignalType) -> StrategyStats {
        let subset    = records.filter { $0.strategyType == type }
        let evaluated = subset.filter  { $0.lastSeenPrice != nil }
        let returns   = evaluated.compactMap(\.returnPercent)
        return StrategyStats(
            signalCount:    subset.count,
            evaluatedCount: evaluated.count,
            hitCount:       evaluated.filter(\.isHit).count,
            lossCount:      evaluated.filter(\.isLoss).count,
            avgReturn:      returns.isEmpty ? nil : returns.reduce(0, +) / Double(returns.count),
            bestReturn:     returns.max(),
            worstReturn:    returns.min()
        )
    }

    var overallStats: StrategyStats {
        let evaluated = records.filter { $0.lastSeenPrice != nil }
        let returns   = evaluated.compactMap(\.returnPercent)
        return StrategyStats(
            signalCount:    records.count,
            evaluatedCount: evaluated.count,
            hitCount:       evaluated.filter(\.isHit).count,
            lossCount:      evaluated.filter(\.isLoss).count,
            avgReturn:      returns.isEmpty ? nil : returns.reduce(0, +) / Double(returns.count),
            bestReturn:     returns.max(),
            worstReturn:    returns.min()
        )
    }

    // MARK: - Dahili

    private func prune() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -maxDays, to: Date()) ?? Date()
        records = records.filter { $0.signalDate > cutoff }
        if records.count > maxRecords { records = Array(records.suffix(maxRecords)) }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([SignalRecord].self, from: data)
        else { return }
        records = decoded
    }
}
