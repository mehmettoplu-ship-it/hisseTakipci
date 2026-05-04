import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var scanner: ScannerViewModel
    @ObservedObject  private var favorites = FavoritesManager.shared
    @StateObject     private var marketVM  = MarketStatusViewModel()
    @Binding var selectedTab: Int
    @State private var now   = Date()
    @State private var pulse = false

    private let tickTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    private let liveTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private struct SectorSummary: Identifiable {
        let sector: String
        let signalCount: Int
        let strongCount: Int
        let avgChange: Double?
        let avgVolRatio: Double?
        var id: String { sector }

        var score: Double {
            let changeBonus = avgChange.map { max($0, 0) * 0.5 } ?? 0
            let volBonus    = avgVolRatio.map { max($0 - 1.0, 0) * 0.4 } ?? 0
            return Double(strongCount) * 3 + Double(signalCount) + changeBonus + volBonus
        }
    }

    private var sectorSummaries: [SectorSummary] {
        guard !scanner.signals.isEmpty else { return [] }
        let grouped = Dictionary(grouping: scanner.signals, by: \.stock.sector)
        return grouped.map { sector, sigs in
            let strongCount = sigs.filter { $0.strength == .strong }.count
            let changes     = sigs.compactMap(\.dailyChangePercent)
            let avgChange   = changes.isEmpty ? nil : changes.reduce(0, +) / Double(changes.count)
            let vols        = sigs.compactMap(\.volumeRatio)
            let avgVol      = vols.isEmpty ? nil : vols.reduce(0, +) / Double(vols.count)
            return SectorSummary(sector: sector, signalCount: sigs.count,
                                 strongCount: strongCount, avgChange: avgChange, avgVolRatio: avgVol)
        }
        .sorted { $0.score > $1.score }
    }

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
            ScrollView {
                VStack(spacing: 22) {
                    bist100Card
                    quickStats
                    favoritesSection
                    sectorRotationSection
                    recentSignalsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Hisse Takip")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let date = scanner.lastScanDate {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(relativeLabel(for: date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .onAppear { marketVM.refresh() }
            .onReceive(tickTimer) { _ in now = Date() }
            .onReceive(liveTimer) { _ in marketVM.refresh() }
        }
    }

    // MARK: - Quick Stats

    private var quickStats: some View {
        HStack(spacing: 10) {
            miniStat(
                value: "\(scanner.signals.count)",
                label: "Sinyal",
                icon: "chart.bar.fill",
                color: Color(red: 0.2, green: 0.5, blue: 1.0),
                tab: 3
            )
            miniStat(
                value: "\(scanner.strongSignalCount)",
                label: "Güçlü",
                icon: "bolt.fill",
                color: Color(red: 0.1, green: 0.85, blue: 0.55),
                tab: 3
            )
            miniStat(
                value: "\(favoriteStocks.count)",
                label: "Favori",
                icon: "star.fill",
                color: Color(red: 1.0, green: 0.75, blue: 0.0),
                tab: 5
            )
        }
    }

    private func miniStat(value: String, label: String, icon: String, color: Color, tab: Int) -> some View {
        Button { selectedTab = tab } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 1) {
                    Text(value)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Favoriler

    @ViewBuilder
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Favoriler", icon: "star.fill", tab: 5)

            if favoriteStocks.isEmpty {
                Button { selectedTab = 5 } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "star.badge.plus")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                        Text("Favori hisse ekleyin")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .buttonStyle(.plain)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(favoriteStocks) { stock in
                            NavigationLink {
                                StockDetailView(stock: stock)
                            } label: {
                                favoriteChip(stock)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 1)
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func favoriteChip(_ stock: Stock) -> some View {
        let signals   = scanner.signals.filter { $0.stock.id == stock.id }
        let hasStrong = signals.contains { $0.strength == .strong }
        let dotColor: Color = hasStrong
            ? Color(red: 0.1, green: 0.85, blue: 0.55)
            : .orange

        return VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(red: 1.0, green: 0.72, blue: 0.0),
                                     Color(red: 0.85, green: 0.38, blue: 0.0)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 32, height: 32)
                    Text(String(stock.symbol.prefix(2)))
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.white)
                }
                Spacer()
                if !signals.isEmpty {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 7, height: 7)
                        .padding(.top, 3)
                }
            }
            Text(stock.symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.primary)
            Text(stock.sector)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(width: 112)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            signals.isEmpty
                                ? Color.white.opacity(0.05)
                                : dotColor.opacity(0.25),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - Son Sinyaller

    @ViewBuilder
    private var recentSignalsSection: some View {
        let top = Array(scanner.sortedSignals.prefix(5))
        let stockCounts = Dictionary(grouping: scanner.signals, by: \.stock.id).mapValues(\.count)
        if !top.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader(title: "Son Sinyaller", icon: "bolt.fill", tab: 3)
                ForEach(top) { signal in
                    NavigationLink {
                        StockDetailView(stock: signal.stock)
                    } label: {
                        signalRow(signal, multiCount: stockCounts[signal.stock.id] ?? 1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Sektör Rotasyonu

    @ViewBuilder
    private var sectorRotationSection: some View {
        let summaries = sectorSummaries
        if !summaries.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Sektör Rotasyonu", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Sinyal bazlı")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 4)

                VStack(spacing: 6) {
                    ForEach(Array(summaries.prefix(6))) { s in
                        sectorRow(s, rank: (summaries.firstIndex { $0.id == s.id } ?? 0) + 1)
                    }
                }
            }
        }
    }

    private func sectorRow(_ s: SectorSummary, rank: Int) -> some View {
        let change     = s.avgChange ?? 0
        let changeUp   = change >= 0
        let changeColor: Color = changeUp
            ? Color(red: 0.1, green: 0.85, blue: 0.55)
            : Color(red: 1.0, green: 0.28, blue: 0.32)
        let volRatio   = s.avgVolRatio ?? 1.0
        let volBarMax  = 3.0
        let volFill    = min(volRatio / volBarMax, 1.0)
        let volColor: Color = volRatio >= 2.0
            ? Color(red: 0.2, green: 0.5, blue: 1.0)
            : volRatio >= 1.3 ? .orange : Color(.systemGray4)

        return HStack(spacing: 10) {
            // Sıra
            Text("\(rank)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: 14)

            // Sektör adı
            Text(s.sector)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Sinyal badge
            HStack(spacing: 3) {
                if s.strongCount > 0 {
                    Text("\(s.strongCount)💪")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(red: 0.1, green: 0.85, blue: 0.55))
                }
                Text("\(s.signalCount)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                Image(systemName: "bell.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }

            // Hacim çubuğu
            VStack(alignment: .trailing, spacing: 2) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.systemGray5))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(volColor)
                            .frame(width: geo.size.width * CGFloat(volFill), height: 4)
                    }
                }
                .frame(width: 44, height: 4)
                Text(String(format: "%.1fx", volRatio))
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(volColor)
            }
            .frame(width: 44)

            // Değişim %
            if s.avgChange != nil {
                Text(String(format: "%+.1f%%", change))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(changeColor)
                    .frame(width: 52, alignment: .trailing)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            rank == 1
                                ? Color(red: 0.2, green: 0.5, blue: 1.0).opacity(0.25)
                                : Color.clear,
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, icon: String, tab: Int) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Button { selectedTab = tab } label: {
                HStack(spacing: 3) {
                    Text("Tümü")
                    Image(systemName: "chevron.right")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(red: 0.2, green: 0.5, blue: 1.0))
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Signal Row

    private func signalRow(_ signal: Signal, multiCount: Int) -> some View {
        let strengthColor: Color = signal.strength == .strong
            ? Color(red: 0.1, green: 0.85, blue: 0.55)
            : signal.strength == .moderate ? .orange : .gray

        return HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(strengthColor)
                .frame(width: 4, height: 38)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(signal.stock.symbol)
                        .font(.system(size: 14, weight: .black))
                    if multiCount >= 2 {
                        Text("\(multiCount) sinyal")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(strengthColor)
                            .clipShape(Capsule())
                    }
                    Text(signal.type.emoji + " " + signal.type.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text("\(signal.timeframe.displayName) · \(String(format: "%.2f ₺", signal.price))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let chg = signal.dailyChangePercent {
                Text(String(format: "%+.1f%%", chg))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(chg >= 0
                        ? Color(red: 0.1, green: 0.85, blue: 0.55) : .red)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background((chg >= 0
                        ? Color(red: 0.1, green: 0.85, blue: 0.55) : Color.red)
                        .opacity(0.12))
                    .clipShape(Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(strengthColor.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - BIST 100 Hero Card

    @ViewBuilder
    private var bist100Card: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(
                    colors: cardColors(marketVM.status?.condition),
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(height: 210)

            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 180, height: 180).blur(radius: 35)
                .offset(x: 110, y: -70).allowsHitTesting(false)
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 110, height: 110).blur(radius: 22)
                .offset(x: -100, y: 45).allowsHitTesting(false)

            if marketVM.isLoading && marketVM.status == nil {
                HStack(spacing: 10) {
                    ProgressView().tint(.white)
                    Text("Piyasa verisi yükleniyor…")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.8))
                }
                .frame(height: 210)
            } else if let s = marketVM.status {
                bist100Content(s)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "wifi.slash").font(.title2)
                        .foregroundStyle(.white.opacity(0.6))
                    Text("Veri alınamadı")
                        .foregroundStyle(.white.opacity(0.8)).font(.subheadline)
                    Button("Tekrar Dene") { marketVM.refresh() }
                        .font(.caption.weight(.semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 6)
                        .background(.white.opacity(0.18)).clipShape(Capsule())
                }
                .frame(height: 210)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: cardColors(marketVM.status?.condition).first?.opacity(0.4) ?? .clear,
                radius: 28, x: 0, y: 12)
    }

    private func bist100Content(_ s: MarketStatus) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 7, height: 7)
                        .opacity(pulse ? 0.35 : 1.0)
                        .animation(.easeInOut(duration: 1.1).repeatForever(), value: pulse)
                        .onAppear { pulse = true }
                    Text("BIST 100")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.75))
                        .tracking(1.5)
                    Text("CANLI")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                }
                Spacer()
                Button { marketVM.refresh() } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(marketVM.isLoading ? 0.3 : 0.7))
                        .rotationEffect(.degrees(marketVM.isLoading ? 360 : 0))
                        .animation(marketVM.isLoading
                            ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default,
                                   value: marketVM.isLoading)
                        .frame(width: 30, height: 30)
                        .background(.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .disabled(marketVM.isLoading)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 14) {
                Text(s.price.formatted(.number.precision(.fractionLength(0))))
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 3) {
                        Image(systemName: s.changePercent >= 0
                              ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                            .font(.system(size: 10))
                        Text(String(format: "%+.2f%%", s.changePercent))
                            .font(.system(size: 17, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(.white.opacity(0.18))
                    .clipShape(Capsule())

                    HStack(spacing: 8) {
                        highLowBadge("Y", value: s.dayHigh,  color: .white.opacity(0.55))
                        highLowBadge("D", value: s.dayLow,   color: .white.opacity(0.55))
                    }
                }
            }
            .padding(.horizontal, 20)

            if !marketVM.recentCandles.isEmpty {
                sparkline
                    .frame(height: 36)
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
            }

            Spacer(minLength: 4)

            HStack(spacing: 6) {
                conditionBadge(s.condition)
                if !s.isAboveEMA50  { smallBadge("EMA50 ↓") }
                if s.isBelowSupport { smallBadge("Destek ↓") }
                Spacer()
                HStack(spacing: 3) {
                    Circle().fill(.white.opacity(0.5)).frame(width: 5, height: 5)
                    Text(s.updatedAt, style: .time)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
            .background(.ultraThinMaterial.opacity(0.45))
        }
        .frame(height: 210)
    }

    private func highLowBadge(_ label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(color)
            Text(value.formatted(.number.precision(.fractionLength(0))))
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(color)
        }
    }

    @ViewBuilder
    private var sparkline: some View {
        let closes = marketVM.recentCandles.map(\.close)
        let isUp   = (closes.last ?? 0) >= (closes.first ?? 0)
        GeometryReader { geo in
            let minV  = closes.min() ?? 0
            let maxV  = closes.max() ?? 1
            let range = maxV - minV
            let w     = geo.size.width
            let h     = geo.size.height
            let step  = range > 0 ? range : 1

            Path { path in
                for (i, v) in closes.enumerated() {
                    let x = w * CGFloat(i) / CGFloat(max(closes.count - 1, 1))
                    let y = h - h * CGFloat((v - minV) / step)
                    i == 0 ? path.move(to: CGPoint(x: x, y: y))
                           : path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(
                LinearGradient(
                    colors: [.white.opacity(isUp ? 0.9 : 0.6), .white.opacity(0.3)],
                    startPoint: .leading, endPoint: .trailing),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
            )
        }
    }

    private func conditionBadge(_ c: MarketCondition) -> some View {
        HStack(spacing: 4) {
            Image(systemName: c.systemImage).font(.system(size: 10, weight: .semibold))
            Text(c.label).font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9).padding(.vertical, 4)
        .background(.white.opacity(0.18))
        .clipShape(Capsule())
    }

    private func smallBadge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(.white.opacity(0.12))
            .clipShape(Capsule())
    }

    private func cardColors(_ c: MarketCondition?) -> [Color] {
        switch c {
        case .strongBull: return [Color(red: 0.0,  green: 0.72, blue: 0.44), Color(red: 0.0, green: 0.38, blue: 0.24)]
        case .bull:       return [Color(red: 0.05, green: 0.62, blue: 0.38), Color(red: 0.0, green: 0.38, blue: 0.22)]
        case .bear:       return [Color(red: 0.85, green: 0.42, blue: 0.0),  Color(red: 0.52, green: 0.22, blue: 0.0)]
        case .strongBear: return [Color(red: 0.85, green: 0.12, blue: 0.18), Color(red: 0.48, green: 0.06, blue: 0.1)]
        default:          return [Color(red: 0.14, green: 0.28, blue: 0.78), Color(red: 0.08, green: 0.14, blue: 0.52)]
        }
    }

    // MARK: - Helpers

    private func relativeLabel(for date: Date) -> String {
        let e = now.timeIntervalSince(date)
        if e < 60    { return "Az önce" }
        if e < 3600  { return "\(Int(e / 60)) dk önce" }
        if e < 86400 { return "\(Int(e / 3600)) saat önce" }
        return "\(Int(e / 86400)) gün önce"
    }
}
