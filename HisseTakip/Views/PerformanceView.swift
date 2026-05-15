import SwiftUI

struct PerformanceView: View {
    @ObservedObject private var history = SignalHistoryManager.shared
    @State private var showHistory = false

    var body: some View {
        NavigationStack {
            List {
                overallSection
                strategySection
            }
            .listStyle(.plain)
            .navigationTitle("Performans")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
            .sheet(isPresented: $showHistory) {
                SignalHistorySheet()
            }
        }
    }

    // MARK: - Özet Kartı

    @ViewBuilder
    private var overallSection: some View {
        Section {
            let stats = history.overallStats
            if history.records.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("Henüz sinyal geçmişi yok")
                        .font(.subheadline.weight(.semibold))
                    Text("Tarayıcı sekmesinden bir tarama başlatın.\nHer tarama otomatik olarak kaydedilir.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                HStack(spacing: 10) {
                    summaryCard(
                        value: "\(history.records.count)",
                        label: "Sinyal",
                        icon: "bolt.fill",
                        color: Color(red: 0.2, green: 0.5, blue: 1.0)
                    )
                    summaryCard(
                        value: stats.evaluatedCount > 0
                            ? String(format: "%.0f%%", stats.hitRate) : "—",
                        label: "Hit Rate",
                        icon: "checkmark.circle.fill",
                        color: hitRateColor(stats.hitRate, hasData: stats.evaluatedCount > 0)
                    )
                    summaryCard(
                        value: stats.avgReturn.map { String(format: "%+.1f%%", $0) } ?? "—",
                        label: "Ort. Getiri",
                        icon: "chart.line.uptrend.xyaxis",
                        color: returnColor(stats.avgReturn)
                    )
                }
                .padding(.vertical, 4)
                if stats.evaluatedCount > 0 {
                    HStack(spacing: 16) {
                        pill(
                            value: "\(stats.hitCount)",
                            label: "+%3 kâr",
                            color: Color(red: 0.1, green: 0.85, blue: 0.55)
                        )
                        pill(
                            value: "\(stats.neutralCount)",
                            label: "Nötr",
                            color: .secondary
                        )
                        pill(
                            value: "\(stats.lossCount)",
                            label: "-%5 zarar",
                            color: Color(red: 1.0, green: 0.28, blue: 0.32)
                        )
                    }
                    .padding(.top, 4)
                }
            }
        } header: {
            Text("SON 30 GÜN ÖZET")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func summaryCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func pill(value: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Strateji Sıralaması

    @ViewBuilder
    private var strategySection: some View {
        let rows = SignalType.allCases
            .map { (type: $0, stats: history.stats(for: $0)) }
            .filter { $0.stats.signalCount > 0 }
            .sorted {
                if $0.stats.evaluatedCount > 0 && $1.stats.evaluatedCount > 0 {
                    return $0.stats.hitRate > $1.stats.hitRate
                }
                return $0.stats.signalCount > $1.stats.signalCount
            }

        if !rows.isEmpty {
            Section {
                ForEach(rows, id: \.type) { item in
                    strategyRow(type: item.type, stats: item.stats)
                }
            } header: {
                Text("STRATEJİ SIRALAMASI — EN İYİ HIT RATE'DEN")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            } footer: {
                Text("Hit: fiyat sinyal noktasından +%3 geçti  •  Zarar: -%5 geçti")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func strategyRow(type: SignalType, stats: StrategyStats) -> some View {
        let hasData = stats.evaluatedCount > 0
        let hrc     = hitRateColor(stats.hitRate, hasData: hasData)

        return HStack(spacing: 12) {
            Text(type.emoji).font(.system(size: 22))

            VStack(alignment: .leading, spacing: 3) {
                Text(type.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Text("\(stats.signalCount) sinyal" + (hasData ? "  •  \(stats.evaluatedCount) takipte" : ""))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if hasData {
                VStack(alignment: .trailing, spacing: 3) {
                    Text(String(format: "%.0f%%", stats.hitRate))
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(hrc)
                    if let avg = stats.avgReturn {
                        Text(String(format: "%+.1f%%", avg))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(avg > 0
                                ? Color(red: 0.1, green: 0.85, blue: 0.55)
                                : Color(red: 1.0, green: 0.28, blue: 0.32))
                    }
                }
            } else {
                Text("Bekleniyor")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Renk Yardımcıları

    private func hitRateColor(_ rate: Double, hasData: Bool) -> Color {
        guard hasData else { return .secondary }
        if rate >= 60 { return Color(red: 0.1, green: 0.85, blue: 0.55) }
        if rate >= 40 { return Color(red: 1.0, green: 0.62, blue: 0.0) }
        return Color(red: 1.0, green: 0.28, blue: 0.32)
    }

    private func returnColor(_ value: Double?) -> Color {
        guard let v = value else { return .secondary }
        if v >= 2  { return Color(red: 0.1, green: 0.85, blue: 0.55) }
        if v >= 0  { return Color(red: 1.0, green: 0.62, blue: 0.0) }
        return Color(red: 1.0, green: 0.28, blue: 0.32)
    }
}

// MARK: - Sinyal Geçmişi Sheet

private struct SignalHistorySheet: View {
    @ObservedObject private var history = SignalHistoryManager.shared
    @Environment(\.dismiss) private var dismiss

    private var sorted: [SignalRecord] {
        history.records.sorted { $0.signalDate > $1.signalDate }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sorted.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Geçmiş boş")
                            .font(.title3.weight(.bold))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(sorted) { record in
                        recordRow(record)
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Sinyal Geçmişi (\(sorted.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func recordRow(_ record: SignalRecord) -> some View {
        let rp      = record.returnPercent
        let rpColor: Color = {
            guard let rp else { return .secondary }
            if rp >= 3  { return Color(red: 0.1, green: 0.85, blue: 0.55) }
            if rp <= -5 { return Color(red: 1.0, green: 0.28, blue: 0.32) }
            return Color(red: 1.0, green: 0.62, blue: 0.0)
        }()

        return HStack(spacing: 10) {
            Text(record.strategyType.emoji).font(.system(size: 20))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(record.stockSymbol)
                        .font(.system(size: 14, weight: .black))
                    Text(record.strategyType.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 4) {
                    Text(String(format: "%.2f ₺", record.signalPrice))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                    if let lsp = record.lastSeenPrice {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 8))
                            .foregroundStyle(.tertiary)
                        Text(String(format: "%.2f ₺", lsp))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                if let rp {
                    Text(String(format: "%+.1f%%", rp))
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundStyle(rpColor)
                } else {
                    Text("Takipte")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                }
                Text(record.daysSinceSignal == 0 ? "Bugün" : "\(record.daysSinceSignal)g önce")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Text(record.timeframe.displayName)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
