import SwiftUI
import UIKit

struct SignalListView: View {
    @EnvironmentObject private var vm: ScannerViewModel
    @State private var filterTimeframe: Timeframe?
    @State private var filterStrength: SignalStrength?
    @State private var showSingleSignals = false

    private var stockGroups: [(stock: Stock, signals: [Signal])] {
        let strengthOrder: [SignalStrength] = [.strong, .moderate, .weak]
        let base = vm.sortedSignals.filter { s in
            (filterTimeframe == nil || s.timeframe == filterTimeframe) &&
            (filterStrength  == nil || s.strength  == filterStrength)
        }
        let grouped = Dictionary(grouping: base, by: \.stock)
        return grouped
            .map { (stock: $0.key, signals: $0.value.sorted {
                let li = strengthOrder.firstIndex(of: $0.strength) ?? 2
                let ri = strengthOrder.firstIndex(of: $1.strength) ?? 2
                return li < ri
            }) }
            .filter { showSingleSignals || $0.signals.count >= 2 }
            .sorted { l, r in
                if l.signals.count != r.signals.count { return l.signals.count > r.signals.count }
                let ls = l.signals.contains { $0.strength == .strong }
                let rs = r.signals.contains { $0.strength == .strong }
                return ls && !rs
            }
    }

    var body: some View {
        NavigationStack {
            Group {
                if vm.signals.isEmpty {
                    emptyState
                } else if stockGroups.isEmpty {
                    noMultiSignalState
                } else {
                    List {
                        ForEach(stockGroups, id: \.stock.id) { item in
                            NavigationLink {
                                StockDetailView(stock: item.stock)
                            } label: {
                                StockSignalGroupCard(stock: item.stock, signals: item.signals)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(.init(top: 6, leading: 14, bottom: 6, trailing: 14))
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button { openTradingView(symbol: item.stock.symbol) } label: {
                                    Label("TV", systemImage: "chart.xyaxis.line")
                                }
                                .tint(Color(red: 0.1, green: 0.47, blue: 0.95))
                                Button { openFVT(symbol: item.stock.symbol) } label: {
                                    Label("FVT", systemImage: "chart.bar.xaxis")
                                }
                                .tint(Color(red: 0.1, green: 0.6, blue: 0.35))
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    FavoritesManager.shared.toggle(item.stock)
                                } label: {
                                    let isFav = FavoritesManager.shared.isFavorite(item.stock)
                                    Label(isFav ? "Favoriden Çıkar" : "Favoriye Ekle",
                                          systemImage: isFav ? "star.slash" : "star.fill")
                                }
                                .tint(Color(red: 1.0, green: 0.65, blue: 0.0))
                            }
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

    // MARK: - Boş Durumlar

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue.opacity(0.15), .purple.opacity(0.08)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
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

    private var noMultiSignalState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.2, green: 0.5, blue: 1.0).opacity(0.1))
                    .frame(width: 90, height: 90)
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 8) {
                Text("\(vm.signals.count) sinyal bulundu")
                    .font(.title3.weight(.bold))
                Text("Birden fazla sinyal veren hisse bulunamadı.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button {
                    showSingleSignals = true
                } label: {
                    Text("Tüm sinyalleri göster")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(red: 0.2, green: 0.5, blue: 1.0))
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Filtre Menüsü

    private var filterMenu: some View {
        Menu {
            Section("Periyot") {
                Button("Tümü") { filterTimeframe = nil }
                ForEach(Timeframe.allCases) { tf in
                    Button(tf.displayName) { filterTimeframe = tf }
                }
            }
            Section("Güç") {
                Button("Tümü")   { filterStrength = nil }
                Button("Güçlü") { filterStrength = .strong }
                Button("Orta")  { filterStrength = .moderate }
            }
            Section {
                Button {
                    showSingleSignals.toggle()
                } label: {
                    Label(
                        showSingleSignals ? "Sadece çoklu sinyaller" : "Tüm sinyalleri göster",
                        systemImage: showSingleSignals ? "line.3.horizontal.decrease" : "list.bullet"
                    )
                }
            }
        } label: {
            let active = filterTimeframe != nil || filterStrength != nil || showSingleSignals
            Image(systemName: active
                  ? "line.3.horizontal.decrease.circle.fill"
                  : "line.3.horizontal.decrease.circle")
            .foregroundStyle(active ? .blue : .secondary)
            .font(.system(size: 18))
        }
    }
}

// MARK: - Hisse Sinyal Grup Kartı

private struct StockSignalGroupCard: View {
    let stock: Stock
    let signals: [Signal]

    private var topStrength: SignalStrength {
        if signals.contains(where: { $0.strength == .strong })   { return .strong }
        if signals.contains(where: { $0.strength == .moderate }) { return .moderate }
        return .weak
    }

    private var accentColor: Color { strengthColor(topStrength) }

    var body: some View {
        HStack(spacing: 0) {
            LinearGradient(colors: [accentColor, accentColor.opacity(0.3)],
                           startPoint: .top, endPoint: .bottom)
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 10) {
                // Üst satır: avatar + sembol + sayaç + fiyat
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.55)],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 40, height: 40)
                        Text(String(stock.symbol.prefix(2)))
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(stock.symbol)
                                .font(.system(size: 16, weight: .black))
                            Text("\(signals.count) sinyal")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7).padding(.vertical, 3)
                                .background(accentColor)
                                .clipShape(Capsule())
                        }
                        Text(stock.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    if let first = signals.first {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.2f ₺", first.price))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                            if let dc = first.dailyChangePercent {
                                Text(String(format: "%+.2f%%", dc))
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(dc >= 0
                                        ? Color(red: 0.1, green: 0.85, blue: 0.55)
                                        : Color(red: 1.0, green: 0.28, blue: 0.32))
                            }
                        }
                    }
                }

                // Sinyal satırları
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(signals) { signal in
                        HStack(spacing: 6) {
                            Text(signal.type.emoji)
                                .font(.system(size: 13))
                            Text(signal.type.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Spacer()
                            Text(signal.timeframe.displayName)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                            Circle()
                                .fill(strengthColor(signal.strength))
                                .frame(width: 7, height: 7)
                        }
                        .padding(.horizontal, 8).padding(.vertical, 5)
                        .background(strengthColor(signal.strength).opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            accentColor.opacity(topStrength == .strong ? 0.4 : 0.15),
                            lineWidth: 1)
                )
        )
        .shadow(
            color: topStrength == .strong
                ? accentColor.opacity(0.18) : .black.opacity(0.07),
            radius: topStrength == .strong ? 10 : 4,
            y: topStrength == .strong ? 4 : 2
        )
    }

    private func strengthColor(_ s: SignalStrength) -> Color {
        switch s {
        case .strong:   return Color(red: 0.1, green: 0.85, blue: 0.55)
        case .moderate: return Color(red: 1.0, green: 0.62, blue: 0.0)
        case .weak:     return Color(.systemGray2)
        }
    }
}

// MARK: - Tekil Sinyal Kartı (StrategySignalSheet için hâlâ kullanılıyor)

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

    private var isSmartMomentum: Bool { signal.type == .smartMomentum }
    private var isStrong: Bool { signal.strength == .strong }

    var body: some View {
        HStack(spacing: 0) {
            LinearGradient(colors: strengthGradient, startPoint: .top, endPoint: .bottom)
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 7) {
                    Text(signal.stock.symbol)
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(.primary)

                    if isSmartMomentum {
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
                            isSmartMomentum
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
