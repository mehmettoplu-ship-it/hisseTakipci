import SwiftUI
import UIKit

struct StockDetailView: View {
    let stock: Stock
    @StateObject private var vm: StockDetailViewModel
    @ObservedObject private var favorites = FavoritesManager.shared

    init(stock: Stock) {
        self.stock = stock
        _vm = StateObject(wrappedValue: StockDetailViewModel(stock: stock))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                priceHeader
                timeframePicker
                    .padding(.vertical, 8)

                if vm.isLoading {
                    ProgressView().frame(maxWidth: .infinity).padding(40)
                } else if let err = vm.errorMessage {
                    Text(err).foregroundStyle(.red).padding()
                } else {
                    externalLinksRow
                    indicatorsPanel
                }
            }
        }
        .navigationTitle(stock.symbol)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    favorites.toggle(stock)
                } label: {
                    Image(systemName: favorites.isFavorite(stock) ? "star.fill" : "star")
                        .foregroundStyle(favorites.isFavorite(stock)
                            ? Color(red: 1.0, green: 0.75, blue: 0.0) : .secondary)
                        .font(.system(size: 17, weight: .medium))
                }
            }
        }
        .onAppear { vm.load() }
    }

    // MARK: - Dış Bağlantı Butonları

    private var externalLinksRow: some View {
        HStack(spacing: 10) {
            externalLinkButton(
                title: "TradingView",
                subtitle: "BIST:\(stock.symbol) grafiği",
                icon: "chart.xyaxis.line",
                color: Color(red: 0.1, green: 0.47, blue: 0.95)
            ) {
                openTradingView()
            }
            externalLinkButton(
                title: "Finviz Türkiye",
                subtitle: "fvt.com.tr",
                icon: "chart.bar.xaxis",
                color: Color(red: 0.1, green: 0.6, blue: 0.35)
            ) {
                openFVT()
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private func externalLinkButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(color.opacity(0.15))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(color.opacity(0.7))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 13)
                            .strokeBorder(color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    // MARK: - TradingView / FVT

    private func openTradingView() {
        let encoded = "BIST%3A\(stock.symbol)"
        guard let url = URL(string: "https://www.tradingview.com/chart/?symbol=\(encoded)") else { return }
        UIApplication.shared.open(url)
    }

    private func openFVT() {
        guard let url = URL(string: "https://fvt.com.tr/hisseler/yerli/\(stock.symbol)") else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Fiyat Başlığı

    private var priceHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.name).font(.subheadline).foregroundStyle(.secondary)
                if let last = vm.candles.last {
                    Text(String(format: "%.2f ₺", last.close))
                        .font(.largeTitle.bold())
                    if let prev = vm.candles.dropLast().last {
                        let change = (last.close - prev.close) / prev.close * 100
                        Text(String(format: "%+.2f%%", change))
                            .font(.subheadline)
                            .foregroundStyle(change >= 0 ? .green : .red)
                    }
                }
            }
            Spacer()
            Text(stock.sector)
                .font(.caption)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.2))
                .foregroundStyle(Color.accentColor)
                .clipShape(Capsule())
        }
        .padding()
    }

    // MARK: - Zaman Dilimi Seçici

    private var timeframePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Timeframe.allCases) { tf in
                    Button(tf.displayName) { vm.switchTimeframe(tf) }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(vm.selectedTimeframe == tf ? Color.accentColor : Color(.systemGray5))
                        .foregroundStyle(vm.selectedTimeframe == tf ? .white : .primary)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Göstergeler Paneli

    private var indicatorsPanel: some View {
        Group {
            if let ind = vm.indicators {
                VStack(spacing: 1) {
                    indicatorRow("RSI (14)",        value: String(format: "%.1f", ind.rsi),
                                 highlight: ind.rsi < 30 ? .green : ind.rsi > 70 ? .red : nil)
                    indicatorRow("MACD Hist.",      value: String(format: "%.4f", ind.macdHistogram),
                                 highlight: ind.macdHistogram > 0 ? .green : .red)
                    indicatorRow("EMA 9",           value: String(format: "%.2f", ind.ema9))
                    indicatorRow("EMA 21",          value: String(format: "%.2f", ind.ema21))
                    indicatorRow("EMA 50",          value: String(format: "%.2f", ind.ema50))
                    indicatorRow("BB Üst",          value: String(format: "%.2f", ind.bbUpper))
                    indicatorRow("BB Alt",          value: String(format: "%.2f", ind.bbLower))
                    indicatorRow("Ort. Hacim (20)", value: formatVolume(ind.avgVolume20))
                }
                .padding(.horizontal)
                .padding(.top, 4)
            }
        }
    }

    private func indicatorRow(_ label: String, value: String, highlight: Color? = nil) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
                .foregroundStyle(highlight ?? .primary)
        }
        .font(.subheadline)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.vertical, 1)
    }

    private func formatVolume(_ v: Double) -> String {
        if v >= 1_000_000 { return String(format: "%.1fM", v / 1_000_000) }
        if v >= 1_000     { return String(format: "%.0fK", v / 1_000) }
        return String(format: "%.0f", v)
    }
}
