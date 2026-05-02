import SwiftUI
import UIKit

struct FavoritesView: View {
    @EnvironmentObject private var scanner: ScannerViewModel
    @ObservedObject private var favorites = FavoritesManager.shared

    private var favoriteStocks: [Stock] {
        scanner.stockList.filter { favorites.isFavorite($0) }
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
                            Button {
                                openTradingView(symbol: stock.symbol)
                            } label: {
                                Label("TV", systemImage: "chart.xyaxis.line")
                            }
                            .tint(Color(red: 0.1, green: 0.47, blue: 0.95))
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                openFVT(symbol: stock.symbol)
                            } label: {
                                Label("FVT", systemImage: "chart.bar.xaxis")
                            }
                            .tint(Color(red: 0.1, green: 0.6, blue: 0.35))
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                favorites.toggle(stock)
                            } label: {
                                Label("Kaldır", systemImage: "star.slash")
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Favoriler")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Hisse Satırı

    private func favoriteRow(_ stock: Stock) -> some View {
        HStack(spacing: 12) {
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
            VStack(alignment: .leading, spacing: 3) {
                Text(stock.symbol)
                    .font(.system(size: 15, weight: .bold))
                Text(stock.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            let signalCount = scanner.signals.filter { $0.stock.id == stock.id }.count
            if signalCount > 0 {
                Text("\(signalCount) sinyal")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Color(red: 0.2, green: 0.5, blue: 1.0))
                    .clipShape(Capsule())
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
