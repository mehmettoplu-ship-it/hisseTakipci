import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var scanner: ScannerViewModel
    @StateObject private var marketVM = MarketStatusViewModel()
    @AppStorage("autoScanIntervalMinutes") private var autoScanIntervalMinutes: Int = 15
    @Binding var selectedTab: Int
    @State private var now   = Date()
    @State private var pulse = false

    private let tickTimer  = Timer.publish(every: 10,  on: .main, in: .common).autoconnect()
    private let liveTimer  = Timer.publish(every: 60,  on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    bist100Card
                    statsGrid
                    recentSignalsSection
                    scanStatusCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 28)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Hisse Takip")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { marketVM.refresh() }
            .onReceive(tickTimer) { _ in now = Date() }
            .onReceive(liveTimer) { _ in marketVM.refresh() }
        }
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

            // Dekoratif ışık
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
            // Üst satır
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
                    Image(systemName: marketVM.isLoading ? "arrow.clockwise" : "arrow.clockwise")
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

            // Fiyat + değişim
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
                        highLowBadge("Y", value: s.dayHigh, color: .white.opacity(0.55))
                        highLowBadge("D", value: s.dayLow, color: .white.opacity(0.55))
                    }
                }
            }
            .padding(.horizontal, 20)

            // Sparkline
            if !marketVM.recentCandles.isEmpty {
                sparkline
                    .frame(height: 36)
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
            }

            Spacer(minLength: 4)

            // Alt cam çubuk
            HStack(spacing: 6) {
                conditionBadge(s.condition)
                if !s.isAboveEMA50 { smallBadge("EMA50 ↓") }
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
            let minV = closes.min() ?? 0
            let maxV = closes.max() ?? 1
            let range = maxV - minV
            let w = geo.size.width
            let h = geo.size.height
            let step = range > 0 ? range : 1

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

    // MARK: - İstatistik Grid

    private var statsGrid: some View {
        HStack(spacing: 12) {
            statCard(
                value: "\(scanner.signals.count)",
                label: "Toplam\nSinyal",
                icon: "chart.bar.fill",
                gradient: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.1, green: 0.3, blue: 0.85)],
                targetTab: 3
            )
            statCard(
                value: "\(scanner.strongSignalCount)",
                label: "Güçlü\nSinyal",
                icon: "bolt.fill",
                gradient: [Color(red: 0.1, green: 0.85, blue: 0.55), Color(red: 0.0, green: 0.6, blue: 0.38)],
                targetTab: 3
            )
            statCard(
                value: "\(scanner.signals.filter { $0.type == .ecHFTPro }.count)",
                label: "EC HFT\nPro",
                icon: "star.fill",
                gradient: [Color(red: 1.0, green: 0.75, blue: 0.0), Color(red: 0.9, green: 0.5, blue: 0.0)],
                targetTab: 3
            )
        }
    }

    private func statCard(value: String, label: String, icon: String, gradient: [Color], targetTab: Int) -> some View {
        Button { selectedTab = targetTab } label: {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 42, height: 42)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text(value)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                LinearGradient(colors: [gradient[0].opacity(0.4), .clear],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: gradient[0].opacity(0.18), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Son Sinyaller

    @ViewBuilder
    private var recentSignalsSection: some View {
        let top = Array(scanner.sortedSignals.prefix(4))
        if !top.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Son Güçlü Sinyaller", systemImage: "bolt.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button { selectedTab = 3 } label: {
                        HStack(spacing: 3) {
                            Text("Tümü")
                            Image(systemName: "chevron.right")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(red: 0.2, green: 0.5, blue: 1.0))
                    }
                }
                .padding(.horizontal, 4)

                ForEach(top) { signal in
                    Button { selectedTab = 3 } label: {
                        signalRow(signal)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func signalRow(_ signal: Signal) -> some View {
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

    // MARK: - Tarama Durumu

    private var scanStatusCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if scanner.isScanning {
                scanningContent
            } else {
                idleContent
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var scanningContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 15))
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse)
                Text("Taranıyor…")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(Int(scanner.progress * 100))%")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(.blue)
            }
            ProgressView(value: scanner.progress)
                .tint(.blue)
                .scaleEffect(x: 1, y: 1.4)
            Text("\(scanner.scannedCount) / \(scanner.stockList.count * scanner.selectedTimeframes.count) hisse tarandı")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var idleContent: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Son Tarama", systemImage: "clock.fill")
                        .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    if let date = scanner.lastScanDate {
                        Text(relativeLabel(for: date))
                            .font(.subheadline.weight(.bold))
                        Text(date.formatted(date: .numeric, time: .shortened))
                            .font(.system(size: 11, design: .monospaced)).foregroundStyle(.tertiary)
                    } else {
                        Text("Henüz yapılmadı")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            Divider()

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Sonraki Otomatik Tarama", systemImage: "timer")
                        .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Text(nextScanLabel)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(nextScanColor)
                }
                Spacer()
                if let remaining = remainingSeconds, remaining > 0 {
                    countdownRing(remaining: remaining)
                }
            }
        }
    }

    private func countdownRing(remaining: Double) -> some View {
        let total    = Double(autoScanIntervalMinutes * 60)
        let progress = 1.0 - (remaining / total)
        return ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 3.5)
                .frame(width: 40, height: 40)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(colors: [.blue, .cyan],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 40, height: 40)
                .animation(.linear(duration: 0.5), value: remaining)
            Text(remaining < 60 ? "\(Int(remaining))s" : "\(Int(remaining / 60))m")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private var remainingSeconds: Double? {
        guard let last = scanner.lastScanDate else { return nil }
        let r = last.addingTimeInterval(Double(autoScanIntervalMinutes * 60)).timeIntervalSince(now)
        return r > 0 ? r : 0
    }

    private var nextScanLabel: String {
        guard let r = remainingSeconds else { return "Tarama başlatıldığında" }
        if r <= 0 { return "Az sonra başlıyor…" }
        let m = Int(r) / 60; let s = Int(r) % 60
        return m > 0 ? "\(m) dk \(s) sn sonra" : "\(s) saniye sonra"
    }

    private var nextScanColor: Color {
        guard let r = remainingSeconds else { return .secondary }
        if r <= 60  { return .orange }
        if r <= 300 { return .primary }
        return .secondary
    }

    private func relativeLabel(for date: Date) -> String {
        let e = now.timeIntervalSince(date)
        if e < 60    { return "Az önce" }
        if e < 3600  { return "\(Int(e / 60)) dakika önce" }
        if e < 86400 { return "\(Int(e / 3600)) saat önce" }
        return "\(Int(e / 86400)) gün önce"
    }
}
