import Foundation

@MainActor
final class StockDetailViewModel: ObservableObject {
    @Published var candles: [Candle]            = []
    @Published var indicators: TechnicalIndicators?
    @Published var isLoading                    = false
    @Published var selectedTimeframe: Timeframe = .daily
    @Published var errorMessage: String?

    let stock: Stock

    init(stock: Stock) { self.stock = stock }

    func load() {
        Task { await fetch() }
    }

    func switchTimeframe(_ tf: Timeframe) {
        selectedTimeframe = tf
        Task { await fetch() }
    }

    private func fetch() async {
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
}
