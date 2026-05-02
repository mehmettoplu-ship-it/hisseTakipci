import SwiftUI
import UIKit

struct SignalListView: View {
    @EnvironmentObject private var vm: ScannerViewModel
    @State private var filterTimeframe: Timeframe?
    @State private var filterStrength: SignalStrength?

    var filtered: [Signal] {
        vm.sortedSignals.filter { s in
            (filterTimeframe == nil || s.timeframe == filterTimeframe) &&
            (filterStrength  == nil || s.strength  == filterStrength)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    emptyState
                } else {
                    List(filtered) { signal in
                        NavigationLink {
                            StockDetailView(stock: signal.stock)
                        } label: {
                            SignalCardView(signal: signal)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(.init(top: 6, leading: 14, bottom: 6, trailing: 14))
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                openTradingView(symbol: signal.stock.symbol)
                            } label: {
                                Label("TV", systemImage: "chart.xyaxis.line")
                            }
                            .tint(Color(red: 0.1, green: 0.47, blue: 0.95))

                            Button {
                                openFVT(symbol: signal.stock.symbol)
                            } label: {
                                Label("FVT", systemImage: "chart.bar.xaxis")
                            }
                            .tint(Color(red: 0.1, green: 0.6, blue: 0.35))
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                FavoritesManager.shared.toggle(signal.stock)
                            } label: {
                                let isFav = FavoritesManager.shared.isFavorite(signal.stock)
                                Label(isFav ? "Favoriden Çıkar" : "Favoriye Ekle",
                                      systemImage: isFav ? "star.slash" : "star.fill")
                            }
                            .tint(Color(red: 1.0, green: 0.65, blue: 0.0))
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Sinyaller")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { filterMenu }
            }
        }
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

    // MARK: - Boş Durum

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.blue.opacity(0.15), .purple.opacity(0.08)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 90, height: 90)
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 6) {
                Text("Henüz sinyal yok")
                    .font(.title3.weight(.bold))
                Text("Tarayıcı sekmesinden taramayı başlatın")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var filterMenu: some View {
        Menu {
            Section("Periyot") {
                Button("Tümü") { filterTimeframe = nil }
                ForEach(Timeframe.allCases) { tf in
                    Button(tf.displayName) { filterTimeframe = tf }
                }
            }
            Section("Güç") {
                Button("Tümü")    { filterStrength = nil }
                Button("Güçlü")  { filterStrength = .strong }
                Button("Orta")   { filterStrength = .moderate }
            }
        } label: {
            let active = filterTimeframe != nil || filterStrength != nil
            Image(systemName: active
                  ? "line.3.horizontal.decrease.circle.fill"
                  : "line.3.horizontal.decrease.circle")
            .foregroundStyle(active ? .blue : .secondary)
            .font(.system(size: 18))
        }
    }
}

// MARK: - Premium Sinyal Kartı

struct SignalCardView: View {
    let signal: Signal

    private var strengthColor: Color {
        switch signal.strength {
        case .strong:   return Color(red: 0.1, green: 0.85, blue: 0.55)
        case .moderate: return Color(red: 1.0, green: 0.62, blue: 0.0)
        case .weak:     return Color(.systemGray2)
        }
    }

    private var strengthGradient: [Color] {
        switch signal.strength {
        case .strong:   return [Color(red: 0.1, green: 0.85, blue: 0.55), Color(red: 0.0, green: 0.6, blue: 0.38)]
        case .moderate: return [Color(red: 1.0, green: 0.7, blue: 0.0), Color(red: 0.85, green: 0.4, blue: 0.0)]
        case .weak:     return [Color(.systemGray2), Color(.systemGray3)]
        }
    }

    private var isECHFT: Bool { signal.type == .ecHFTPro }
    private var isStrong: Bool { signal.strength == .strong }

    var body: some View {
        HStack(spacing: 0) {
            // Sol gradient güç çizgisi
            LinearGradient(colors: strengthGradient, startPoint: .top, endPoint: .bottom)
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 9) {
                // Üst satır
                HStack(spacing: 7) {
                    Text(signal.stock.symbol)
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(.primary)

                    if isECHFT {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 7, weight: .black))
                            Text("PRO")
                                .font(.system(size: 9, weight: .black))
                                .tracking(0.8)
                        }
                        .foregroundStyle(Color(red: 0.1, green: 0.05, blue: 0.0))
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(
                            LinearGradient(colors: [Color(red: 1.0, green: 0.85, blue: 0.15),
                                                    Color(red: 1.0, green: 0.55, blue: 0.0)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.4),
                                radius: 4, y: 2)
                    }

                    Text(signal.type.emoji + " " + signal.type.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(strengthColor)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(strengthColor.opacity(0.12))
                        .clipShape(Capsule())

                    Spacer()

                    Text(signal.timeframe.displayName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                }

                // Alt veri satırı
                HStack(spacing: 0) {
                    dataChip(label: "Fiyat", value: String(format: "%.2f ₺", signal.price))

                    if let dc = signal.dailyChangePercent {
                        chipDivider()
                        dataChip(
                            label: "Günlük",
                            value: String(format: "%+.2f%%", dc),
                            valueColor: dc >= 0
                                ? Color(red: 0.1, green: 0.85, blue: 0.55)
                                : Color(red: 1.0, green: 0.28, blue: 0.32)
                        )
                    }
                    if let rsi = signal.rsi {
                        chipDivider()
                        dataChip(label: "RSI",
                                 value: String(format: "%.0f", rsi),
                                 valueColor: rsi < 30
                                    ? Color(red: 0.1, green: 0.85, blue: 0.55)
                                    : rsi > 70 ? Color(red: 1.0, green: 0.28, blue: 0.32) : nil)
                    }
                    if let vr = signal.volumeRatio {
                        chipDivider()
                        dataChip(label: "Hacim",
                                 value: String(format: "%.1fx", vr),
                                 valueColor: vr >= 2
                                    ? Color(red: 0.1, green: 0.85, blue: 0.55) : nil)
                    }

                    Spacer()
                    Text(signal.timestamp, style: .time)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 13)
            .padding(.horizontal, 13)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isECHFT
                                ? LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.75, blue: 0.1).opacity(0.7),
                                             Color(red: 1.0, green: 0.45, blue: 0.0).opacity(0.2),
                                             .clear],
                                    startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(
                                    colors: [strengthColor.opacity(isStrong ? 0.5 : 0.2), .clear],
                                    startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: isStrong ? strengthColor.opacity(0.18) : Color.black.opacity(0.08),
            radius: isStrong ? 10 : 4,
            y: isStrong ? 4 : 2
        )
    }

    private func dataChip(label: String, value: String, valueColor: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(valueColor ?? .primary)
        }
    }

    private func chipDivider() -> some View {
        Rectangle()
            .fill(Color(.separator).opacity(0.5))
            .frame(width: 1, height: 20)
            .padding(.horizontal, 9)
    }
}
