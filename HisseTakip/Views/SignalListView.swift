import SwiftUI
import UIKit

struct SignalListView: View {
    @EnvironmentObject private var vm: ScannerViewModel
    @State private var groupMode: GroupMode = .sector
    @State private var filterTimeframe: Timeframe?
    @State private var filterStrength: SignalStrength?
    @State private var filterSector: String? = nil
    @State private var filterMaxBarsAgo: Int? = nil
    @State private var onlyHighScore = false

    private enum GroupMode: String, CaseIterable {
        case sector = "Sektör"
        case stock  = "Hisse"
    }

    // Filtrelenmiş sinyaller
    private var filtered: [Signal] {
        var base = vm.sortedSignals.filter { s in
            (filterTimeframe  == nil || s.timeframe == filterTimeframe) &&
            (filterStrength   == nil || s.strength  == filterStrength) &&
            (filterSector     == nil || s.stock.sector == filterSector) &&
            (filterMaxBarsAgo == nil || (s.barsAgo ?? 0) <= filterMaxBarsAgo!)
        }
        if onlyHighScore {
            let highIDs = Set(
                Dictionary(grouping: base, by: \.stock.id)
                    .filter { StockOpportunity.computeScore($0.value) >= 60 }
                    .keys
            )
            base = base.filter { highIDs.contains($0.stock.id) }
        }
        return base
    }

    // Hisse bazlı gruplar — fırsat skoruna göre sıralı
    private var stockGroups: [(stock: Stock, signals: [Signal])] {
        let order: [SignalStrength] = [.strong, .moderate, .weak]
        let grouped = Dictionary(grouping: filtered, by: \.stock)
        return grouped
            .map { (stock: $0.key, signals: $0.value.sorted {
                (order.firstIndex(of: $0.strength) ?? 2) < (order.firstIndex(of: $1.strength) ?? 2)
            }) }
            .sorted {
                StockOpportunity.computeScore($0.signals) > StockOpportunity.computeScore($1.signals)
            }
    }

    // Sektör bazlı gruplar — sektördeki en yüksek hisse skoruna göre sıralı
    private var sectorGroups: [(sector: String, stocks: [(stock: Stock, signals: [Signal])])] {
        let bySector = Dictionary(grouping: stockGroups, by: { $0.stock.sector })
        return bySector.map { sector, stocks in (sector: sector, stocks: stocks) }
            .sorted { l, r in
                let ls = l.stocks.map { StockOpportunity.computeScore($0.signals) }.max() ?? 0
                let rs = r.stocks.map { StockOpportunity.computeScore($0.signals) }.max() ?? 0
                return ls > rs
            }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                controlsRow
                if filterTimeframe != nil || filterStrength != nil || filterSector != nil || filterMaxBarsAgo != nil {
                    activeFiltersRow
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Divider().opacity(0.4)

                if vm.signals.isEmpty {
                    emptyState
                } else if filtered.isEmpty {
                    noResultState
                } else if groupMode == .sector {
                    sectorList
                } else {
                    stockList
                }
            }
            .navigationTitle("Sinyaller")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { filterMenu }
            }
        }
    }

    // MARK: - Üst Kontroller

    private var controlsRow: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(GroupMode.allCases, id: \.self) { mode in
                    let sel = groupMode == mode
                    Button { groupMode = mode } label: {
                        Text(mode.rawValue)
                            .font(.system(size: 13, weight: .bold))
                            .padding(.vertical, 9)
                            .frame(maxWidth: .infinity)
                            .background(
                                sel
                                    ? LinearGradient(
                                        colors: [Color(red: 0.2, green: 0.5, blue: 1.0),
                                                 Color(red: 0.1, green: 0.3, blue: 0.9)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(
                                        colors: [Color(.tertiarySystemFill), Color(.tertiarySystemFill)],
                                        startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundStyle(sel ? .white : .secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: sel ? Color(red: 0.2, green: 0.5, blue: 1.0).opacity(0.35) : .clear,
                                    radius: 6, y: 3)
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.3), value: sel)
                }
            }

            Spacer()

            Text("\(stockGroups.count) hisse")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            Button {
                withAnimation(.spring(response: 0.3)) { onlyHighScore.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 9, weight: .semibold))
                    Text("A+B")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(onlyHighScore ? .white : Color(red: 1.0, green: 0.75, blue: 0.0))
                .padding(.horizontal, 10).padding(.vertical, 7)
                .background(
                    onlyHighScore
                        ? Color(red: 1.0, green: 0.75, blue: 0.0)
                        : Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.1)
                )
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .animation(.spring(response: 0.3), value: onlyHighScore)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var activeFiltersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                if let tf = filterTimeframe {
                    activeFilterChip(label: tf.displayName, systemImage: "calendar") {
                        withAnimation(.spring(response: 0.3)) { filterTimeframe = nil }
                    }
                }
                if let fs = filterStrength {
                    activeFilterChip(label: strengthLabel(fs), systemImage: "bolt.fill") {
                        withAnimation(.spring(response: 0.3)) { filterStrength = nil }
                    }
                }
                if let sec = filterSector {
                    activeFilterChip(label: sec, systemImage: "building.2") {
                        withAnimation(.spring(response: 0.3)) { filterSector = nil }
                    }
                }
                if let ba = filterMaxBarsAgo {
                    activeFilterChip(label: "≤\(ba) bar", systemImage: "clock") {
                        withAnimation(.spring(response: 0.3)) { filterMaxBarsAgo = nil }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
        }
        .background(Color(.tertiarySystemBackground).opacity(0.6))
    }

    private func activeFilterChip(label: String, systemImage: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 9, weight: .semibold))
            Text(label)
                .font(.system(size: 12, weight: .semibold))
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(Color(red: 0.2, green: 0.5, blue: 1.0))
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Color(red: 0.2, green: 0.5, blue: 1.0).opacity(0.1))
        .overlay(Capsule().strokeBorder(Color(red: 0.2, green: 0.5, blue: 1.0).opacity(0.3), lineWidth: 1))
        .clipShape(Capsule())
    }

    private func strengthLabel(_ s: SignalStrength) -> String {
        switch s {
        case .strong:   return "Güçlü"
        case .moderate: return "Orta"
        case .weak:     return "Zayıf"
        }
    }

    // MARK: - Sektör Listesi

    private var sectorList: some View {
        List {
            ForEach(sectorGroups, id: \.sector) { group in
                Section {
                    ForEach(group.stocks, id: \.stock.id) { item in
                        stockRow(item)
                    }
                } header: {
                    sectorHeader(group)
                }
            }
        }
        .listStyle(.plain)
    }

    private func sectorHeader(_ group: (sector: String, stocks: [(stock: Stock, signals: [Signal])])) -> some View {
        let totalSignals = group.stocks.flatMap(\.signals).count
        let strongCount  = group.stocks.flatMap(\.signals).filter { $0.strength == .strong }.count
        return HStack(spacing: 8) {
            Text(group.sector)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.primary)
            Spacer()
            if strongCount > 0 {
                Text("\(strongCount) güçlü")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color(red: 0.1, green: 0.85, blue: 0.55))
                    .clipShape(Capsule())
            }
            Text("\(totalSignals) sinyal")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color(.tertiarySystemBackground))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
        .listRowInsets(.init(top: 8, leading: 14, bottom: 2, trailing: 14))
    }

    // MARK: - Hisse Listesi

    private var stockList: some View {
        List {
            ForEach(stockGroups, id: \.stock.id) { item in
                stockRow(item)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Ortak satır + swipe

    @ViewBuilder
    private func stockRow(_ item: (stock: Stock, signals: [Signal])) -> some View {
        let score = StockOpportunity.computeScore(item.signals)
        NavigationLink { StockDetailView(stock: item.stock) } label: {
            StockSignalGroupCard(stock: item.stock, signals: item.signals, score: score)
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(.init(top: 5, leading: 14, bottom: 5, trailing: 14))
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

    private var noResultState: some View {
        VStack(spacing: 12) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Filtreyle eşleşen sinyal yok")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Filtre Menüsü

    private var filterMenu: some View {
        let active = filterTimeframe != nil || filterStrength != nil || filterSector != nil || filterMaxBarsAgo != nil
        let availableSectors = Array(Set(vm.sortedSignals.map(\.stock.sector))).sorted()
        return Menu {
            Section("Periyot") {
                Button { filterTimeframe = nil } label: {
                    Label("Tümü", systemImage: filterTimeframe == nil ? "checkmark" : "")
                }
                ForEach(Timeframe.allCases) { tf in
                    Button { filterTimeframe = tf } label: {
                        Label(tf.displayName,
                              systemImage: filterTimeframe == tf ? "checkmark" : "")
                    }
                }
            }
            Section("Sinyal Gücü") {
                Button { filterStrength = nil } label: {
                    Label("Tümü", systemImage: filterStrength == nil ? "checkmark" : "")
                }
                Button { filterStrength = .strong } label: {
                    Label("Güçlü", systemImage: filterStrength == .strong ? "checkmark" : "")
                }
                Button { filterStrength = .moderate } label: {
                    Label("Orta", systemImage: filterStrength == .moderate ? "checkmark" : "")
                }
            }
            Section("Sektör") {
                Button { filterSector = nil } label: {
                    Label("Tümü", systemImage: filterSector == nil ? "checkmark" : "")
                }
                ForEach(availableSectors, id: \.self) { sec in
                    Button { filterSector = sec } label: {
                        Label(sec, systemImage: filterSector == sec ? "checkmark" : "")
                    }
                }
            }
            Section("Tazelik") {
                Button { filterMaxBarsAgo = nil } label: {
                    Label("Tümü", systemImage: filterMaxBarsAgo == nil ? "checkmark" : "")
                }
                Button { filterMaxBarsAgo = 0 } label: {
                    Label("Taze (0 bar)", systemImage: filterMaxBarsAgo == 0 ? "checkmark" : "")
                }
                Button { filterMaxBarsAgo = 3 } label: {
                    Label("≤ 3 bar", systemImage: filterMaxBarsAgo == 3 ? "checkmark" : "")
                }
                Button { filterMaxBarsAgo = 7 } label: {
                    Label("≤ 7 bar", systemImage: filterMaxBarsAgo == 7 ? "checkmark" : "")
                }
            }
        } label: {
            Image(systemName: active
                  ? "line.3.horizontal.decrease.circle.fill"
                  : "line.3.horizontal.decrease.circle")
            .foregroundStyle(active ? .blue : .secondary)
            .font(.system(size: 18))
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
}

// MARK: - Hisse Sinyal Grup Kartı

private struct StockSignalGroupCard: View {
    let stock: Stock
    let signals: [Signal]
    let score: Int

    @State private var expandedIDs: Set<UUID> = []

    private var topStrength: SignalStrength {
        if signals.contains(where: { $0.strength == .strong })   { return .strong }
        if signals.contains(where: { $0.strength == .moderate }) { return .moderate }
        return .weak
    }
    private var accentColor: Color { strengthColor(topStrength) }
    private var scoreColor: Color  { StockOpportunity.gradeColor(for: score) }

    var body: some View {
        HStack(spacing: 0) {
            LinearGradient(colors: [accentColor, accentColor.opacity(0.3)],
                           startPoint: .top, endPoint: .bottom)
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 10) {
                // Üst: avatar + sembol + sektör + fiyat
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
                        HStack(spacing: 4) {
                            Text(stock.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Text("·")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(stock.sector)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Fırsat Skoru badge
                    VStack(spacing: 1) {
                        Text(StockOpportunity.grade(for: score))
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(scoreColor)
                        Text("\(score)")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(scoreColor.opacity(0.75))
                    }
                    .frame(width: 34, height: 34)
                    .background(scoreColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .strokeBorder(scoreColor.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 9))

                    if let first = signals.first {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.2f ₺", first.price))
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                            if let dc = first.dailyChangePercent {
                                Text(String(format: "%+.2f%%", dc))
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(dc >= 0
                                        ? Color(red: 0.1, green: 0.85, blue: 0.55)
                                        : Color(red: 1.0, green: 0.28, blue: 0.32))
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background((dc >= 0
                                        ? Color(red: 0.1, green: 0.85, blue: 0.55)
                                        : Color(red: 1.0, green: 0.28, blue: 0.32)).opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Sinyal satırları (detaylı)
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(signals) { signal in
                        signalDetailRow(signal)
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
            color: topStrength == .strong ? accentColor.opacity(0.18) : .black.opacity(0.07),
            radius: topStrength == .strong ? 10 : 4,
            y: topStrength == .strong ? 4 : 2
        )
    }

    private func signalDetailRow(_ signal: Signal) -> some View {
        let sc = strengthColor(signal.strength)
        let isExpanded = expandedIDs.contains(signal.id)
        return VStack(alignment: .leading, spacing: 5) {
            // Sinyal adı + periyot + güç
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
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(Capsule())
                Circle()
                    .fill(sc)
                    .frame(width: 7, height: 7)
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        if isExpanded { expandedIDs.remove(signal.id) }
                        else          { expandedIDs.insert(signal.id) }
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            // RSI + Hacim + Sinyal Yaşı
            HStack(spacing: 8) {
                if let rsi = signal.rsi {
                    metricBadge(label: "RSI",
                                value: String(format: "%.0f", rsi),
                                color: rsi > 60 ? Color(red: 0.1, green: 0.85, blue: 0.55)
                                     : rsi < 40 ? .orange : .secondary)
                }
                if let vr = signal.volumeRatio {
                    metricBadge(label: "Hacim",
                                value: String(format: "%.1fx", vr),
                                color: vr >= 3 ? Color(red: 0.2, green: 0.5, blue: 1.0)
                                     : vr >= 1.5 ? .orange : .secondary)
                }
                if let ba = signal.barsAgo {
                    ageBadge(barsAgo: ba, runup: signal.signalRunup ?? 0)
                }
                Spacer()
            }
            // Açıklama (genişletilince)
            if isExpanded {
                VStack(alignment: .leading, spacing: 3) {
                    Text(signal.type.shortDescription)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(Array(signal.type.conditionsList.enumerated()), id: \.offset) { _, cond in
                        HStack(alignment: .top, spacing: 5) {
                            Text("•")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(sc)
                            Text(cond)
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(sc.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func metricBadge(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(Color(.tertiarySystemBackground))
        .clipShape(Capsule())
    }

    private func ageBadge(barsAgo: Int, runup: Double) -> some View {
        let text: String
        let col: Color
        if barsAgo == 0 {
            text = "Taze"; col = Color(red: 0.1, green: 0.85, blue: 0.55)
        } else if runup >= 5 {
            text = "\(barsAgo)b | +\(String(format: "%.1f", runup))%"
            col  = Color(red: 1.0, green: 0.28, blue: 0.32)
        } else if runup >= 2 {
            text = "\(barsAgo)b | +\(String(format: "%.1f", runup))%"
            col  = Color(red: 1.0, green: 0.62, blue: 0.0)
        } else {
            text = "\(barsAgo)b önce"; col = Color(.secondaryLabel)
        }
        return HStack(spacing: 3) {
            Image(systemName: "clock")
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(col)
            Text(text)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(col)
        }
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(col.opacity(0.1))
        .overlay(Capsule().strokeBorder(col.opacity(0.3), lineWidth: 0.5))
        .clipShape(Capsule())
    }

    private func strengthColor(_ s: SignalStrength) -> Color {
        switch s {
        case .strong:   return Color(red: 0.1, green: 0.85, blue: 0.55)
        case .moderate: return Color(red: 1.0, green: 0.62, blue: 0.0)
        case .weak:     return Color(.systemGray2)
        }
    }
}

// MARK: - Tekil Sinyal Kartı

struct SignalCardView: View {
    let signal: Signal

    private var strengthColor: Color {
        switch signal.strength {
        case .strong:   return Color(red: 0.1, green: 0.85, blue: 0.55)
        case .moderate: return Color(red: 1.0, green: 0.62, blue: 0.0)
        case .weak:     return Color(.systemGray2)
        }
    }

    private var isStrong: Bool { signal.strength == .strong }

    var body: some View {
        HStack(spacing: 0) {
            strengthColor
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 7) {
                    Text(signal.stock.symbol)
                        .font(.system(size: 17, weight: .black))
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
                        dataChip(label: "Günlük",
                                 value: String(format: "%+.2f%%", dc),
                                 valueColor: dc >= 0
                                    ? Color(red: 0.1, green: 0.85, blue: 0.55)
                                    : Color(red: 1.0, green: 0.28, blue: 0.32))
                    }
                    if let rsi = signal.rsi {
                        chipDivider()
                        dataChip(label: "RSI", value: String(format: "%.0f", rsi),
                                 valueColor: rsi < 30 ? Color(red: 0.1, green: 0.85, blue: 0.55)
                                           : rsi > 70 ? Color(red: 1.0, green: 0.28, blue: 0.32) : nil)
                    }
                    if let vr = signal.volumeRatio {
                        chipDivider()
                        dataChip(label: "Hacim", value: String(format: "%.1fx", vr),
                                 valueColor: vr >= 2 ? Color(red: 0.1, green: 0.85, blue: 0.55) : nil)
                    }
                    if let ba = signal.barsAgo {
                        chipDivider()
                        dataChip(label: "Yaş",
                                 value: ageLabel(barsAgo: ba, runup: signal.signalRunup ?? 0),
                                 valueColor: ageColor(runup: signal.signalRunup ?? 0, barsAgo: ba))
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
                        .strokeBorder(strengthColor.opacity(isStrong ? 0.4 : 0.15), lineWidth: 1)
                )
        )
        .shadow(color: isStrong ? strengthColor.opacity(0.18) : .black.opacity(0.08),
                radius: isStrong ? 10 : 4, y: isStrong ? 4 : 2)
    }

    private func dataChip(label: String, value: String, valueColor: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 9, weight: .medium)).foregroundStyle(.tertiary)
            Text(value).font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(valueColor ?? .primary)
        }
    }

    private func chipDivider() -> some View {
        Rectangle().fill(Color(.separator).opacity(0.5))
            .frame(width: 1, height: 20).padding(.horizontal, 9)
    }

    private func ageLabel(barsAgo: Int, runup: Double) -> String {
        if barsAgo == 0 { return "Taze" }
        if runup >= 2   { return "\(barsAgo)b|+\(String(format: "%.1f", runup))%" }
        return "\(barsAgo)b önce"
    }

    private func ageColor(runup: Double, barsAgo: Int) -> Color {
        if barsAgo == 0 { return Color(red: 0.1, green: 0.85, blue: 0.55) }
        if runup >= 5   { return Color(red: 1.0, green: 0.28, blue: 0.32) }
        if runup >= 2   { return Color(red: 1.0, green: 0.62, blue: 0.0) }
        return .secondary
    }
}
