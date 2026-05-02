import Foundation

@MainActor
final class MarketStatusViewModel: ObservableObject {
    @Published var status: MarketStatus?
    @Published var isLoading = false
    @Published var failed    = false

    func refresh() {
        Task { await fetch() }
    }

    private func fetch() async {
        isLoading = true
        failed    = false
        do {
            let candles = try await YahooFinanceService.shared
                .fetchCandles(symbol: "XU100.IS", timeframe: .daily)
            status = MarketStatus.make(candles: candles)
            failed = status == nil
        } catch {
            failed = true
        }
        isLoading = false
    }
}
