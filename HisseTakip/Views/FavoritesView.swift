import SwiftUI
import UIKit

struct FavoritesView: View {
    @EnvironmentObject private var scanner: ScannerViewModel
    @ObservedObject private var favorites = FavoritesManager.shared
    @StateObject private var pricesVM = FavoritePriceViewModel()

    private var favoriteStocks: [Stock] {
        scanner.stockList
            .filter { favorites.isFavorite($0) }
            .sorted {
                let d0 = favorites.addDate(for: $0) ?? .distantPast
                let d1 = favorites.addDate(for: $1) ?? .distantPast
                return d0 > d1
            }
    }

    var body: some View {
        NavigationStack {
            Group {
                if favoriteStocks.isEmpty {
                    emptyState
                } else {
                    List(favoriteStocks) { stock in
                        NavigationLink {
                            StockDetailView(stock: stock)
                        } label: {
                            favoriteRow(stock)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(.init(top: 5, leading: 14, bottom: 5, trailing: 14))
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button { openTradingView(symbol: stock.symbol) } label: {
                                Label("TV", systemImage: "chart.xyaxis.line")
                            }
                            .tint(Color(red: 0.1, green: 0.47, blue: 0.95))
                        }
                        .swipeActions(edge: .leading) {
                            Button { openFVT(symbol: stock.symbol) } label: {
                                Label("FVT", systemImage: "chart.bar.xaxis")
                            }
                            .tint(Color(red: 0.1, green: 0.6, blue: 0.35))
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) { favorites.toggle(stock) } label: {
                                Label("Kaldır", systemImage: "star.slash")
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await pricesVM.fetchPrices(for: favoriteStocks)
                    }
                }
            }
            .navigationTitle("Favoriler")
            .navigationBarTitleDisplayMode(.large)
            .task(id: favoriteStocks.map(\.id).joined()) {
                await pricesVM.fetchPrices(for: favoriteStocks)
            }
        }
    }

    // MARK: - Hisse Satırı

    private func favoriteRow(_ stock: Stock) -> some View {
        let info        = pricesVM.priceMap[stock.id]
        let signalCount = scanner.signals.filter { $0.stock.id == stock.id }.count
        let addDate     = favorites.addDate(for: stock)

        return HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(red: 1.0, green: 0.75, blue: 0.0),
                                 Color(red: 0.9, green: 0.45, blue: 0.0)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 42, height: 42)
                Text(String(stock.symbol.prefix(2)))
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
            }

            // Sol: sembol + isim
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(stock.symbol)
                        .font(.system(size: 15, weight: .bold))
                    if signalCount > 0 {
                        Text("\(signalCount) sinyal")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Color(red: 0.2, green: 0.5, blue: 1.0))
                            .clipShape(Capsule())
                    }
                }
                HStack(spacing: 4) {
                    Text(stock.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if let date = addDate {
                        Text("·")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(dateLabel(date))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer(minLength: 8)

            // Sağ: fiyat + değişim
            VStack(alignment: .trailing, spacing: 4) {
                if let info {
                    Text(String(format: "%.2f ₺", info.price))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.primary)
                    if let change = info.dailyChange {
                        let up = change >= 0
                        Text(String(format: "%+.2f%%", change))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(up
                                ? Color(red: 0.1, green: 0.85, blue: 0.55)
                                : Color(red: 1.0, green: 0.28, blue: 0.32))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background((up
                                ? Color(red: 0.1, green: 0.85, blue: 0.55)
                                : Color(red: 1.0, green: 0.28, blue: 0.32)).opacity(0.12))
                            .clipShape(Capsule())
                    }
                } else if pricesVM.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 40)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.3), .clear],
                                startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.06), radius: 4, y: 2)
    }

    // MARK: - Yardımcılar

    private func dateLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Bugün" }
        if cal.isDateInYesterday(date) { return "Dün" }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "tr_TR")
        fmt.dateFormat = cal.isDate(date, equalTo: Date(), toGranularity: .year)
            ? "d MMM" : "d MMM yy"
        return fmt.string(from: date)
    }

    // MARK: - Boş Durum

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.15), .clear],
                        center: .center, startRadius: 0, endRadius: 50))
                    .frame(width: 100, height: 100)
                Image(systemName: "star.slash.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 8) {
                Text("Favori Yok")
                    .font(.title3.weight(.bold))
                Text("Hisse detay sayfasında yıldız simgesine\nbasarak favori ekleyebilirsiniz")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Dış Bağlantılar

    private func openTradingView(symbol: String) {
        let encoded = "BIST%3A\(symbol)"
        guard let url = URL(string: "https://www.tradingview.com/chart/?symbol=\(encoded)") else { return }
        UIApplication.shared.open(url)
    }

    private func openFVT(symbol: String) {
        guard let url = URL(string: "https://fvt.com.tr/hisseler/yerli/\(symbol)") else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Fiyat ViewModel

@MainActor
private final class FavoritePriceViewModel: ObservableObject {
    struct PriceInfo {
        let price: Double
        let dailyChange: Double?
    }

    @Published var priceMap: [String: PriceInfo] = [:]
    @Published var isLoading = false

    func fetchPrices(for stocks: [Stock]) async {
        guard !stocks.isEmpty else { return }
        isLoading = true
        await withTaskGroup(of: (String, PriceInfo)?.self) { group in
            for stock in stocks {
                group.addTask {
                    guard let candles = try? await YahooFinanceService.shared
                        .fetchCandles(symbol: stock.id, timeframe: .daily),
                          let last = candles.last else { return nil }
                    let prev   = candles.dropLast().last
                    let change = prev.map { (last.close - $0.close) / $0.close * 100 }
                    return (stock.id, PriceInfo(price: last.close, dailyChange: change))
                }
            }
            for await result in group {
                if let (id, info) = result {
                    priceMap[id] = info
                }
            }
        }
        isLoading = false
    }
}
