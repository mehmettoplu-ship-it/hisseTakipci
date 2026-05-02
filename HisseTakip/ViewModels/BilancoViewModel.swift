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
        let q0 = statements[0]
        let q1 = statements[1]
        let q2 = statements.count >= 3 ? statements[2] : nil
        let q3 = statements.count >= 4 ? statements[3] : nil
        let q4 = statements.count >= 5 ? statements[4] : nil

        let niChange = q1.netIncome != 0
            ? (q0.netIncome - q1.netIncome) / abs(q1.netIncome) * 100 : 0
        let revChange = q1.revenue != 0
            ? (q0.revenue - q1.revenue) / abs(q1.revenue) * 100 : 0
        let yoyNI: Double? = q4.map { q in
            q.netIncome != 0 ? (q0.netIncome - q.netIncome) / abs(q.netIncome) * 100 : 0
        }
        let opChange = q1.operatingIncome != 0
            ? (q0.operatingIncome - q1.operatingIncome) / abs(q1.operatingIncome) * 100 : 0

        // Ardışık iyileşme sayısı: net gelir her çeyrekte artıyor mu?
        let allQ = [q0, q1, q2, q3].compactMap { $0 }
        var consecutive = 0
        for i in 0..<allQ.count - 1 {
            if allQ[i].netIncome > allQ[i + 1].netIncome { consecutive += 1 }
            else { break }
        }

        func sig(_ type: FinancialSignalType) -> FinancialSignal {
            FinancialSignal(
                stock: stock, type: type,
                currentNetIncome: q0.netIncome, previousNetIncome: q1.netIncome,
                netIncomeChangePercent: niChange,
                currentRevenue: q0.revenue, revenueChangePercent: revChange,
                period: q0.periodLabel, yoyNetIncomeChangePercent: yoyNI,
                currentOperatingIncome: q0.operatingIncome,
                operatingIncomeChangePercent: opChange,
                consecutiveImprovements: consecutive,
                currentNetMargin: q0.netMargin,
                netMarginImprovement: q0.netMargin - q1.netMargin)
        }

        var sigs: [FinancialSignal] = []

        // 1. Kara Geçiş — zarar → kâr (en güçlü sinyal, diğerleri atlanır)
        if q1.isLoss && q0.isProfit {
            return [sig(.turningProfitable)]
        }

        // 2. Kâra Yakın — zararda ama net marj -5% ile 0% arası + iyileşiyor
        //    Tipik durum: az zararlı + trend pozitif → bir sonraki dönem kâr olası
        if q0.isLoss, q0.revenue > 0, q0.netMargin > -0.05, niChange > 0 {
            sigs.append(sig(.approachingProfit))
        }

        // 3. Sürekli İyileşme — 3+ ardışık çeyrek net gelir artışı (zarar azalıyor)
        if consecutive >= 2, q0.isLoss, sigs.isEmpty {
            sigs.append(sig(.consecutiveLossReduction))
        }

        // 4. FAVÖK Toparlandı — operasyonel kâr (EBIT) pozitif ama net zarar
        //    Faiz gideri / kur farkı sürüklüyor; esas iş kârlı
        if q0.operatingIncome > 0, q0.isLoss, q0.operatingMargin > 0.02, sigs.isEmpty {
            sigs.append(sig(.ebitTurnaround))
        }

        // 5. Zarar Azalıyor — tek çeyreklik %15+ iyileşme (yukarıdaki sinyaller yoksa)
        if q1.isLoss, q0.isLoss, niChange > 15, sigs.isEmpty {
            sigs.append(sig(.lossReducing))
        }

        // 6. Kar Büyüyor — zaten kârdayken %20+ büyüme
        if q1.isProfit, q0.isProfit, niChange > 20 {
            sigs.append(sig(.profitGrowing))
        }

        // 7. Gelir Artışı — başka sinyal yoksa ve %20+ gelir artışı
        if revChange > 20, sigs.isEmpty {
            sigs.append(sig(.revenueGrowing))
        }

        // 8. Operasyonel Kaldıraç — gelir büyüyor, faaliyet kârı daha hızlı büyüyor (ölçek verimliliği)
        if q0.revenue > 0, q1.revenue > 0,
           q0.operatingIncome > 0, q1.operatingIncome > 0,
           revChange > 5,
           opChange > revChange + 10 {
            sigs.append(sig(.operatingLeverage))
        }

        // 9. İstikrarlı Kâr — 4 çeyrek kârlı ve yıllık net kâr %10+ büyüme
        if let q2v = q2, let q3v = q3,
           q0.isProfit, q1.isProfit, q2v.isProfit, q3v.isProfit,
           let yoy = yoyNI, yoy > 10 {
            sigs.append(sig(.profitConsistency))
        }

        return sigs
    }
}
