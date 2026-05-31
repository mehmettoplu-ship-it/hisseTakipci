import Foundation

@MainActor
final class StockDetailViewModel: ObservableObject {
    @Published var candles: [Candle]             = []
    @Published var indicators: TechnicalIndicators?
    @Published var isLoading                     = false
    @Published var selectedTimeframe: Timeframe  = .daily
    @Published var errorMessage: String?

    // Finansal veri
    @Published var statements: [QuarterlyStatement] = []
    @Published var financialSignal: FinancialSignal?
    @Published var isLoadingFinancial = false

    let stock: Stock

    init(stock: Stock) { self.stock = stock }

    func load() {
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.fetchTechnical() }
                group.addTask { await self.fetchFinancial() }
            }
        }
    }

    func switchTimeframe(_ tf: Timeframe) {
        selectedTimeframe = tf
        Task { await fetchTechnical() }
    }

    // MARK: - Teknik Analiz

    private func fetchTechnical() async {
        isLoading    = true
        errorMessage = nil
        do {
            candles    = try await YahooFinanceService.shared
                .fetchCandles(symbol: stock.id, timeframe: selectedTimeframe)
            indicators = TechnicalAnalysis.calculate(candles: candles)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Finansal Analiz

    private func fetchFinancial() async {
        isLoadingFinancial = true
        do {
            let stmts  = try await FinancialDataService.shared
                .fetchQuarterlyStatements(symbol: stock.symbol)
            statements = stmts
            financialSignal = analyzeFinancial(stmts)
        } catch {
            // Finansal veri opsiyonel — sessizce geç
        }
        isLoadingFinancial = false
    }

    private func analyzeFinancial(_ stmts: [QuarterlyStatement]) -> FinancialSignal? {
        guard stmts.count >= 2 else { return nil }
        let q0 = stmts[0], q1 = stmts[1]
        let q2 = stmts.count >= 3 ? stmts[2] : nil
        let q3 = stmts.count >= 4 ? stmts[3] : nil
        let q4 = stmts.count >= 5 ? stmts[4] : nil

        let niChange  = q1.netIncome != 0 ? (q0.netIncome - q1.netIncome) / abs(q1.netIncome) * 100 : 0
        let revChange = q1.revenue   != 0 ? (q0.revenue   - q1.revenue)   / abs(q1.revenue)   * 100 : 0
        let opChange  = q1.operatingIncome != 0
            ? (q0.operatingIncome - q1.operatingIncome) / abs(q1.operatingIncome) * 100 : 0
        let yoyNI: Double? = q4.map { q in
            q.netIncome != 0 ? (q0.netIncome - q.netIncome) / abs(q.netIncome) * 100 : 0
        }

        let allQ = [q0, q1, q2, q3].compactMap { $0 }
        var consecutive = 0
        for i in 0..<allQ.count - 1 {
            if allQ[i].netIncome > allQ[i + 1].netIncome { consecutive += 1 } else { break }
        }

        func makeSig(_ type: FinancialSignalType) -> FinancialSignal {
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

        if q1.isLoss && q0.isProfit                                                  { return makeSig(.turningProfitable) }
        if q0.isLoss, q0.revenue > 0, q0.netMargin > -0.05, niChange > 0             { return makeSig(.approachingProfit) }
        if consecutive >= 2, q0.isLoss                                               { return makeSig(.consecutiveLossReduction) }
        if q0.operatingIncome > 0, q0.isLoss, q0.operatingMargin > 0.02             { return makeSig(.ebitTurnaround) }
        if q1.isLoss, q0.isLoss, niChange > 15                                       { return makeSig(.lossReducing) }
        if q1.isProfit, q0.isProfit, niChange > 20                                   { return makeSig(.profitGrowing) }
        if q0.revenue > 0, q1.revenue > 0,
           q0.operatingIncome > 0, q1.operatingIncome > 0,
           revChange > 5, opChange > revChange + 10                                  { return makeSig(.operatingLeverage) }
        if let q2v = q2, let q3v = q3,
           q0.isProfit, q1.isProfit, q2v.isProfit, q3v.isProfit,
           let yoy = yoyNI, yoy > 10                                                 { return makeSig(.profitConsistency) }
        if revChange > 20                                                             { return makeSig(.revenueGrowing) }
        return nil
    }
}
