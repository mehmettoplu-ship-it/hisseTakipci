import Foundation

@MainActor
final class MarketStatusViewModel: ObservableObject {
    @Published var status: MarketStatus?
    @Published var recentCandles: [Candle] = []
    @Published var isLoading = false
    @Published var failed    = false

    func refresh() {
        Task { await fetch() }
    }

    private func fetch() async {
        guard !isLoading else { return }
        isLoading = true
        failed    = false
        do {
            let candles = try await YahooFinanceService.shared
                .fetchCandles(symbol: "XU100.IS", timeframe: .daily)
            recentCandles = Array(candles.suffix(30))
            status        = MarketStatus.make(candles: candles)
            failed        = status == nil
        } catch {
            failed = true
        }
        isLoading = false
    }
}
