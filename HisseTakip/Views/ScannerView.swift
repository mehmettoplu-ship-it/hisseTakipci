import SwiftUI

struct ScannerView: View {
    @EnvironmentObject private var vm: ScannerViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedStrategy: SignalType? = nil
    @State private var showFailedSheet = false
    @State private var backgroundedDuringScan = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                timeframeSelector
                Divider().opacity(0.4)
                statsRow
                    .padding(.vertical, 14)
                Divider().opacity(0.4)
                Spacer()
                if vm.isScanning {
                    scanningView
                } else if !vm.signals.isEmpty {
                    resultsView
                } else {
                    idleView
                }
                Spacer()
                scanButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
            .navigationTitle("Tarayıcı")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let date = vm.lastScanDate {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(date.formatted(.dateTime.hour().minute()))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .sheet(item: $selectedStrategy) { type in
                StrategySignalSheet(type: type)
                    .environmentObject(vm)
            }
            .sheet(isPresented: $showFailedSheet) {
                FailedStocksSheet()
                    .environmentObject(vm)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background && vm.isScanning { backgroundedDuringScan = true }
                if newPhase == .active && !vm.isScanning   { backgroundedDuringScan = false }
            }
        }
    }

    // MARK: - Zaman Dilimi Seçici

    private var timeframeSelector: some View {
        HStack(spacing: 8) {
            ForEach(Timeframe.allCases) { tf in
                let selected = vm.selectedTimeframes.contains(tf)
                Button {
                    if selected && vm.selectedTimeframes.count > 1 {
                        vm.selectedTimeframes.remove(tf)
                    } else {
                        vm.selectedTimeframes.insert(tf)
                    }
                } label: {
                    Text(tf.displayName)
                        .font(.system(size: 13, weight: .bold))
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity)
                        .background(
                            selected
                                ? LinearGradient(colors: [Color(red: 0.2, green: 0.5, blue: 1.0),
                                                          Color(red: 0.1, green: 0.3, blue: 0.9)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color(.tertiarySystemFill), Color(.tertiarySystemFill)],
                                                 startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundStyle(selected ? .white : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: selected ? Color(red: 0.2, green: 0.5, blue: 1.0).opacity(0.35) : .clear,
                                radius: 6, y: 3)
                }
                .animation(.spring(response: 0.3), value: selected)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - İstatistik Satırı

    private var statsRow: some View {
        HStack(spacing: 0) {
            statBox(value: "\(vm.signals.count)",
                    label: "Toplam",
                    icon: "chart.bar.fill",
                    color: Color(red: 0.2, green: 0.5, blue: 1.0))
            Divider().frame(height: 40).opacity(0.5)
            statBox(value: "\(vm.strongSignalCount)",
                    label: "Güçlü",
                    icon: "bolt.fill",
                    color: Color(red: 0.1, green: 0.85, blue: 0.55))
            Divider().frame(height: 40).opacity(0.5)
            statBox(value: "\(Set(vm.signals.map(\.stock)).count)",
                    label: "Hisse",
                    icon: "person.crop.circle.fill",
                    color: Color(red: 0.7, green: 0.35, blue: 1.0))
        }
    }

    private func statBox(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
            }
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Taranıyor

    private var scanningView: some View {
        VStack(spacing: 20) {
            // Arka plan göstergesi
            if backgroundedDuringScan {
                HStack(spacing: 6) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 10))
                    Text("Arka planda devam ediyor")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color(.tertiarySystemBackground))
                .clipShape(Capsule())
                .transition(.scale.combined(with: .opacity))
            }

            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 5)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: vm.progress)
                    .stroke(
                        LinearGradient(colors: [Color(red: 0.2, green: 0.5, blue: 1.0),
                                                Color(red: 0.4, green: 0.8, blue: 1.0)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 100, height: 100)
                    .animation(.easeInOut(duration: 0.35), value: vm.progress)
                    .shadow(color: Color(red: 0.2, green: 0.5, blue: 1.0).opacity(0.4), radius: 6)

                VStack(spacing: 0) {
                    Text("\(Int(vm.progress * 100))")
                        .font(.system(size: 22, weight: .black, design: .monospaced))
                    Text("%")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 8) {
                Text("\(vm.scannedCount) / \(vm.stockList.count * vm.selectedTimeframes.count)")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)

                if let sym = vm.currentSymbol {
                    HStack(spacing: 6) {
                        ProgressView().scaleEffect(0.7)
                        Text(sym)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .transition(.opacity)
                    }
                    .animation(.easeInOut(duration: 0.2), value: sym)
                } else {
                    Text("hisse analiz ediliyor…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Canlı sinyal sayacı
                if vm.liveSignalCount > 0 {
                    HStack(spacing: 5) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(red: 0.1, green: 0.85, blue: 0.55))
                        Text("\(vm.liveSignalCount) sinyal bulundu")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(red: 0.1, green: 0.85, blue: 0.55))
                            .contentTransition(.numericText())
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color(red: 0.1, green: 0.85, blue: 0.55).opacity(0.1))
                    .clipShape(Capsule())
                    .animation(.spring(response: 0.4), value: vm.liveSignalCount)
                }

                if vm.fetchErrors > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.caption2)
                        Text("\(vm.fetchErrors) hisse verisi alınamadı").font(.caption)
                    }
                    .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.1))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color(red: 1.0, green: 0.45, blue: 0.1).opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .animation(.spring(response: 0.4), value: backgroundedDuringScan)
    }

    // MARK: - Sonuçlar

    private var resultsView: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [Color(red: 0.1, green: 0.85, blue: 0.55).opacity(0.15), .clear],
                        center: .center, startRadius: 0, endRadius: 55))
                    .frame(width: 110, height: 110)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(LinearGradient(
                        colors: [Color(red: 0.1, green: 0.85, blue: 0.55), .mint],
                        startPoint: .top, endPoint: .bottom))
            }

            VStack(spacing: 6) {
                Text("\(vm.signals.count) sinyal bulundu")
                    .font(.title3.weight(.bold))
                HStack(spacing: 8) {
                    if let dur = vm.scanDuration {
                        Label(durationLabel(dur), systemImage: "timer")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    if vm.fetchErrors > 0 {
                        Button {
                            showFailedSheet = true
                        } label: {
                            Label("\(vm.fetchErrors) hata", systemImage: "exclamationmark.triangle.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.1))
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Color(red: 1.0, green: 0.45, blue: 0.1).opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            strategyBreakdown

            Text("Sinyaller sekmesinden inceleyin")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
    }

    private var strategyBreakdown: some View {
        let grouped = Dictionary(grouping: vm.signals, by: \.type)
        let sorted  = grouped.sorted { $0.value.count > $1.value.count }.prefix(6)

        return LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
            spacing: 8
        ) {
            ForEach(sorted, id: \.key) { type, sigs in
                let color = typeColor(type)
                Button { selectedStrategy = type } label: {
                    VStack(spacing: 4) {
                        Text("\(sigs.count)")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(color)
                        Text(type.emoji)
                            .font(.system(size: 14))
                        Text(shortName(type))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(color.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(color.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func typeColor(_ type: SignalType) -> Color {
        switch type {
        case .resistanceBreakout: return Color(red: 0.2,  green: 0.5,  blue: 1.0)
        case .oversoldReversal:   return Color(red: 0.1,  green: 0.85, blue: 0.55)
        case .emaBullishCross:    return Color(red: 1.0,  green: 0.72, blue: 0.0)
        case .goldenCross:        return Color(red: 1.0,  green: 0.82, blue: 0.1)
        case .bollingerBounce:    return Color(red: 0.3,  green: 0.7,  blue: 1.0)
        case .squeezeBounce:      return Color(red: 0.6,  green: 0.85, blue: 0.3)
        case .rsiDivergence:      return Color(red: 0.7,  green: 0.3,  blue: 1.0)
        case .maStack:            return Color(red: 0.0,  green: 0.75, blue: 0.85)
        case .breakoutRetest:     return Color(red: 1.0,  green: 0.55, blue: 0.0)
        case .trendPullback:      return Color(red: 0.95, green: 0.35, blue: 0.6)
        case .smartMomentum:      return Color(red: 1.0,  green: 0.85, blue: 0.15)
        case .candlePattern:      return Color(red: 0.4,  green: 0.8,  blue: 1.0)
        case .weeklyBreakout:       return Color(red: 0.1,  green: 0.85, blue: 0.55)
        case .vcpBreakout:          return Color(red: 0.85, green: 0.7,  blue: 0.1)
        case .descendingBreakout:   return Color(red: 1.0,  green: 0.45, blue: 0.2)
        }
    }

    // MARK: - Boş Ekran

    private var idleView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [Color(red: 0.2, green: 0.5, blue: 1.0).opacity(0.15), .clear],
                        center: .center, startRadius: 0, endRadius: 55))
                    .frame(width: 110, height: 110)
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(LinearGradient(
                        colors: [Color(red: 0.2, green: 0.5, blue: 1.0), .cyan],
                        startPoint: .top, endPoint: .bottom))
            }

            VStack(spacing: 6) {
                Text("Taramaya Hazır")
                    .font(.title3.weight(.bold))
                Text("\(vm.stockList.count) hisse, \(vm.selectedTimeframes.count) zaman dilimi")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Tara / İptal Butonu

    private var scanButton: some View {
        Button {
            if vm.isScanning { vm.cancelScan() } else { vm.startScan() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: vm.isScanning ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                Text(vm.isScanning ? "Taramayı Durdur" : "Tüm BIST'i Tara")
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                Group {
                    if vm.isScanning {
                        LinearGradient(colors: [Color(red: 0.9, green: 0.15, blue: 0.15),
                                                Color(red: 0.75, green: 0.08, blue: 0.08)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    } else {
                        LinearGradient(colors: [Color(red: 0.2, green: 0.5, blue: 1.0),
                                                Color(red: 0.08, green: 0.28, blue: 0.95)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    }
                }
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(
                color: vm.isScanning
                    ? Color.red.opacity(0.35)
                    : Color(red: 0.2, green: 0.5, blue: 1.0).opacity(0.4),
                radius: 12, y: 5
            )
        }
        .scaleEffect(vm.isScanning ? 0.98 : 1.0)
        .animation(.spring(response: 0.3), value: vm.isScanning)
    }

    // MARK: - Yardımcılar

    private func durationLabel(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return mins > 0 ? "\(mins)dk \(secs)s" : "\(secs)s"
    }

    private func shortName(_ type: SignalType) -> String {
        switch type {
        case .resistanceBreakout: return "Direnç\nKırılması"
        case .oversoldReversal:   return "RSI\nDip"
        case .emaBullishCross:    return "EMA\nKesiş."
        case .goldenCross:        return "Altın\nHaç"
        case .bollingerBounce:    return "Bollinger\nZıplama"
        case .squeezeBounce:      return "Sıkışma\nPatl."
        case .rsiDivergence:      return "RSI\nDiverj."
        case .maStack:            return "MA\nHizal."
        case .breakoutRetest:     return "Geri\nTest"
        case .trendPullback:      return "Trend\nDestek"
        case .smartMomentum:      return "Akıllı\nMoment."
        case .candlePattern:      return "Mum\nFormas."
        case .weeklyBreakout:       return "52H\nZirve"
        case .vcpBreakout:          return "VCP\nKırılma"
        case .descendingBreakout:   return "Düşen\nKırılım"
        }
    }
}

// MARK: - Strateji Sinyal Sheet

private struct StrategySignalSheet: View {
    let type: SignalType
    @EnvironmentObject var vm: ScannerViewModel
    @Environment(\.dismiss) private var dismiss

    private var signals: [Signal] {
        vm.sortedSignals.filter { $0.type == type }
    }

    var body: some View {
        NavigationStack {
            Group {
                if signals.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Bu strateji için sinyal yok")
                            .font(.title3.weight(.bold))
                        Text("Son taramada \(type.rawValue) sinyali bulunamadı.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(signals) { signal in
                        NavigationLink {
                            StockDetailView(stock: signal.stock)
                        } label: {
                            SignalCardView(signal: signal)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(.init(top: 6, leading: 14, bottom: 6, trailing: 14))
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(type.emoji + " " + type.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Hatalı Hisseler Sheet

private struct FailedStocksSheet: View {
    @EnvironmentObject var vm: ScannerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if vm.failedStocks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color(red: 0.1, green: 0.85, blue: 0.55))
                        Text("Hata yok")
                            .font(.title3.weight(.bold))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section {
                            ForEach(vm.failedStocks) { item in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(red: 1.0, green: 0.45, blue: 0.1).opacity(0.15))
                                            .frame(width: 38, height: 38)
                                        Text(String(item.stock.symbol.prefix(2)))
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.1))
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.stock.symbol)
                                            .font(.system(size: 14, weight: .bold))
                                        Text(item.stock.name)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Text(item.timeframe.displayName)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Color(.tertiarySystemFill))
                                        .clipShape(Capsule())
                                }
                                .padding(.vertical, 4)
                            }
                        } header: {
                            Text("Veri alınamayan hisseler (\(vm.failedStocks.count))")
                                .font(.caption.weight(.semibold))
                        } footer: {
                            Text("Bu hisseler için Yahoo Finance'e bağlanırken ağ hatası oluştu. Bir sonraki taramada tekrar denenecek.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Hata Raporu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
