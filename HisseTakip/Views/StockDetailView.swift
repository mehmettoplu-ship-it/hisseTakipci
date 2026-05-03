import SwiftUI
import UIKit

struct StockDetailView: View {
    let stock: Stock
    @StateObject private var vm: StockDetailViewModel
    @ObservedObject private var favorites = FavoritesManager.shared
    @Environment(\.dismiss) private var dismiss

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
                    financialSection
                        .padding(.top, 8)
                }
            }
        }
        .navigationTitle(stock.symbol)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Geri")
                            .font(.system(size: 16, weight: .regular))
                    }
                    .foregroundStyle(Color(red: 0.2, green: 0.5, blue: 1.0))
                }
            }
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
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                externalLinkButton(
                    title: "TradingView",
                    subtitle: "BIST:\(stock.symbol)",
                    icon: "chart.xyaxis.line",
                    color: Color(red: 0.1, green: 0.47, blue: 0.95)
                ) { openTradingView() }
                externalLinkButton(
                    title: "Finviz TR",
                    subtitle: "fvt.com.tr",
                    icon: "chart.bar.xaxis",
                    color: Color(red: 0.1, green: 0.6, blue: 0.35)
                ) { openFVT() }
            }
            externalLinkButton(
                title: "Fintables",
                subtitle: "fintables.com/sirketler/\(stock.symbol)",
                icon: "building.2.fill",
                color: Color(red: 0.55, green: 0.25, blue: 0.95)
            ) { openFintables() }
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

    // MARK: - Dış Bağlantılar

    private func openTradingView() {
        let encoded = "BIST%3A\(stock.symbol)"
        guard let url = URL(string: "https://www.tradingview.com/chart/?symbol=\(encoded)") else { return }
        UIApplication.shared.open(url)
    }

    private func openFVT() {
        guard let url = URL(string: "https://fvt.com.tr/hisseler/yerli/\(stock.symbol)") else { return }
        UIApplication.shared.open(url)
    }

    private func openFintables() {
        guard let url = URL(string: "https://fintables.com/sirketler/\(stock.symbol)") else { return }
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
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(change >= 0
                                ? Color(red: 0.1, green: 0.85, blue: 0.55)
                                : Color(red: 1.0, green: 0.28, blue: 0.32))
                    }
                }
            }
            Spacer()
            Text(stock.sector)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color(red: 0.2, green: 0.5, blue: 1.0).opacity(0.15))
                .foregroundStyle(Color(red: 0.2, green: 0.5, blue: 1.0))
                .clipShape(Capsule())
        }
        .padding()
    }

    // MARK: - Zaman Dilimi Seçici

    private var timeframePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Timeframe.allCases) { tf in
                    let selected = vm.selectedTimeframe == tf
                    Button(tf.displayName) { vm.switchTimeframe(tf) }
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(
                            selected
                                ? LinearGradient(
                                    colors: [Color(red: 0.2, green: 0.5, blue: 1.0),
                                             Color(red: 0.1, green: 0.3, blue: 0.9)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(
                                    colors: [Color(.tertiarySystemFill), Color(.tertiarySystemFill)],
                                    startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundStyle(selected ? .white : .secondary)
                        .clipShape(Capsule())
                        .shadow(color: selected
                            ? Color(red: 0.2, green: 0.5, blue: 1.0).opacity(0.35) : .clear,
                                radius: 6, y: 3)
                        .animation(.spring(response: 0.3), value: selected)
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

    // MARK: - Finansal Analiz Bölümü

    @ViewBuilder
    private var financialSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Başlık
            HStack {
                Label("Finansal Analiz", systemImage: "building.columns.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if vm.isLoadingFinancial {
                    ProgressView().scaleEffect(0.7)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)

            if let sig = vm.financialSignal {
                financialSignalBadge(sig)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
            }

            if !vm.statements.isEmpty {
                quarterlyTable
                    .padding(.horizontal)
            } else if !vm.isLoadingFinancial {
                HStack {
                    Image(systemName: "chart.bar.xaxis")
                        .foregroundStyle(.tertiary)
                    Text("Finansal veri bulunamadı")
                        .font(.caption).foregroundStyle(.tertiary)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemGray6).opacity(0.5))
    }

    private func financialSignalBadge(_ sig: FinancialSignal) -> some View {
        let color = signalColor(sig.type)
        return HStack(spacing: 10) {
            Text(sig.type.emoji)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(sig.type.rawValue)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)
                Text("Son dönem: \(sig.period) · Net Kâr: \(formatMoney(sig.currentNetIncome))")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            Text(String(format: "%+.0f%%", sig.netIncomeChangePercent))
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundStyle(sig.netIncomeChangePercent >= 0
                    ? Color(red: 0.1, green: 0.85, blue: 0.55) : .red)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(color.opacity(0.25), lineWidth: 1))
        )
    }

    private var quarterlyTable: some View {
        VStack(spacing: 1) {
            HStack(spacing: 0) {
                Text("Dönem").frame(width: 68, alignment: .leading)
                Text("Gelir").frame(maxWidth: .infinity, alignment: .trailing)
                Text("Net Kâr").frame(maxWidth: .infinity, alignment: .trailing)
                Text("Marj").frame(width: 54, alignment: .trailing)
            }
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            ForEach(Array(vm.statements.prefix(5).enumerated()), id: \.offset) { i, s in
                quarterlyRow(index: i, stmt: s)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }

    private func quarterlyRow(index i: Int, stmt s: QuarterlyStatement) -> some View {
        let netColor: Color = s.isProfit ? Color(red: 0.1, green: 0.85, blue: 0.55) : .red
        let marginColor: Color = s.isProfit ? .secondary : .red.opacity(0.8)
        let textStyle: Color = i == 0 ? .primary : .secondary
        return HStack(spacing: 0) {
            Text(s.periodLabel)
                .font(.system(size: 11, weight: i == 0 ? .bold : .regular, design: .monospaced))
                .foregroundStyle(textStyle)
                .frame(width: 68, alignment: .leading)
            Text(formatMoney(s.revenue))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(textStyle)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(formatMoney(s.netIncome))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(netColor)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(String(format: "%.1f%%", s.netMargin * 100))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(marginColor)
                .frame(width: 54, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(i == 0 ? Color(.systemBackground).opacity(0.6) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func signalColor(_ type: FinancialSignalType) -> Color {
        switch type {
        case .turningProfitable:        return Color(red: 0.1,  green: 0.85, blue: 0.55)
        case .approachingProfit:        return Color(red: 1.0,  green: 0.55, blue: 0.0)
        case .consecutiveLossReduction: return Color(red: 0.3,  green: 0.7,  blue: 1.0)
        case .ebitTurnaround:           return Color(red: 0.6,  green: 0.85, blue: 0.3)
        case .lossReducing:             return Color(red: 0.2,  green: 0.6,  blue: 1.0)
        case .operatingLeverage:        return Color(red: 0.0,  green: 0.75, blue: 0.85)
        case .profitConsistency:        return Color(red: 0.95, green: 0.35, blue: 0.6)
        case .profitGrowing:            return Color(red: 1.0,  green: 0.72, blue: 0.0)
        case .revenueGrowing:           return Color(red: 0.7,  green: 0.3,  blue: 1.0)
        }
    }

    private func formatMoney(_ v: Double) -> String {
        let a = Swift.abs(v); let p = v < 0 ? "-" : ""
        if a >= 1_000_000_000 { return "\(p)\(String(format: "%.1f", a / 1_000_000_000))B₺" }
        if a >= 1_000_000     { return "\(p)\(String(format: "%.0f", a / 1_000_000))M₺" }
        if a >= 1_000         { return "\(p)\(String(format: "%.0f", a / 1_000))K₺" }
        return "\(p)\(String(format: "%.0f", a))₺"
    }
}
