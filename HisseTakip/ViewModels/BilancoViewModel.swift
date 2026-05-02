import Foundation

@MainActor
final class BilancoViewModel: ObservableObject {
    @Published var signals: [FinancialSignal] = []
    @Published var isScanning     = false
    @Published var progress: Double = 0
    @Published var scannedCount   = 0
    @Published var totalCount     = 0
    @Published var dataFoundCount = 0
    @Published var fetchErrors   = 0
    @Published var hasScanned    = false
    @Published var errorMessage: String?

    private var scanTask: Task<Void, Never>?

    func startScan(stocks: [Stock]) {
        guard !isScanning else { return }
        scanTask?.cancel()
        scanTask = Task { await performScan(stocks: stocks) }
    }

    func cancelScan() {
        scanTask?.cancel()
        isScanning = false
    }

    // MARK: - Tarama

    private func performScan(stocks: [Stock]) async {
        isScanning     = true
        progress       = 0
        scannedCount   = 0
        dataFoundCount = 0
        fetchErrors    = 0
        hasScanned     = false
        signals        = []
        errorMessage   = nil

        // Sadece sembol kısa listesi üzerinde çalış — bilanço verisi ağır
        // Kullanıcı taraması: 50'şer stok + 300ms bekleme
        let total = stocks.count
        totalCount = total
        let chunkSize = 5

        var found: [FinancialSignal] = []
        var count = 0

        let chunks = stride(from: 0, to: total, by: chunkSize).map {
            Array(stocks[$0 ..< min($0 + chunkSize, total)])
        }

        for chunk in chunks {
            if Task.isCancelled { break }

            await withTaskGroup(of: (Bool, Bool, [FinancialSignal]).self) { group in
                for stock in chunk {
                    group.addTask {
                        guard !Task.isCancelled else { return (false, false, []) }
                        do {
                            let stmts = try await FinancialDataService.shared
                                .fetchQuarterlyStatements(symbol: stock.symbol)
                            if stmts.isEmpty { return (true, false, []) }
                            let sigs = await self.analyze(stock: stock, statements: stmts)
                            return (true, true, sigs)
                        } catch {
                            return (false, false, [])
                        }
                    }
                }
                for await (ok, hasData, partial) in group {
                    if !ok    { fetchErrors    += 1 }
                    if hasData { dataFoundCount += 1 }
                    found.append(contentsOf: partial)
                    count += 1
                    scannedCount = count
                    progress = Double(count) / Double(total)
                }
            }

            // Yahoo Finance rate limiting için kısa bekleme
            if !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
            }
        }

        if !Task.isCancelled {
            signals = found.sorted {
                if $0.type.priority != $1.type.priority {
                    return $0.type.priority < $1.type.priority
                }
                return abs($0.netIncomeChangePercent) > abs($1.netIncomeChangePercent)
            }
            hasScanned = true
        }
        isScanning = false
    }

    // MARK: - Sinyal Analizi

    private func analyze(stock: Stock, statements: [QuarterlyStatement]) -> [FinancialSignal] {
        guard statements.count >= 2 else { return [] }
        let q0 = statements[0]   // son çeyrek
        let q1 = statements[1]   // önceki çeyrek
        // yıllık karşılaştırma (4 çeyrek önce)
        let q4 = statements.count >= 5 ? statements[4] : nil

        var sigs: [FinancialSignal] = []

        let niChange = q1.netIncome != 0
            ? (q0.netIncome - q1.netIncome) / abs(q1.netIncome) * 100 : 0
        let revChange = q1.revenue != 0
            ? (q0.revenue - q1.revenue) / abs(q1.revenue) * 100 : 0
        let yoyNI: Double? = q4.map { q in
            q.netIncome != 0 ? (q0.netIncome - q.netIncome) / abs(q.netIncome) * 100 : 0
        }

        func makeSignal(_ type: FinancialSignalType) -> FinancialSignal {
            FinancialSignal(
                stock: stock, type: type,
                currentNetIncome: q0.netIncome, previousNetIncome: q1.netIncome,
                netIncomeChangePercent: niChange,
                currentRevenue: q0.revenue, revenueChangePercent: revChange,
                period: q0.periodLabel, yoyNetIncomeChangePercent: yoyNI)
        }

        // 1. Kara Geçiş: zarar → kar (en güçlü sinyal)
        if q1.isLoss && q0.isProfit {
            sigs.append(makeSignal(.turningProfitable))
        }

        // 2. Zarar Azalıyor: hâlâ zararla ama %15'ten fazla iyileşme
        else if q1.isLoss && q0.isLoss && niChange > 15 {
            sigs.append(makeSignal(.lossReducing))
        }

        // 3. Kar Büyüyor: karda ve %20'den fazla büyüme
        else if q1.isProfit && q0.isProfit && niChange > 20 {
            sigs.append(makeSignal(.profitGrowing))
        }

        // 4. Gelir Artışı: gelir %20'den fazla arttı (kar/zarar bağımsız)
        if revChange > 20, !sigs.contains(where: { $0.type == .revenueGrowing }) {
            // Sadece tek başına gelir sinyali üret (kar sinyali yoksa)
            if sigs.isEmpty {
                sigs.append(makeSignal(.revenueGrowing))
            }
        }

        return sigs
    }
}
