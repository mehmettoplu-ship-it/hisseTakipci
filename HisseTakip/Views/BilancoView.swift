import SwiftUI
import UIKit

struct BilancoView: View {
    @EnvironmentObject private var scanner: ScannerViewModel
    @StateObject private var vm = BilancoViewModel()
    @State private var filterType: FinancialSignalType?

    private func openIsyatirim(symbol: String) {
        let url = URL(string: "https://www.isyatirim.com.tr/tr-tr/analiz/hisse/Sayfalar/sirket-karti.aspx?hisse=\(symbol)")!
        UIApplication.shared.open(url)
    }

    private func openKAP(symbol: String) {
        let url = URL(string: "https://www.kap.org.tr/tr/Bildirim/search?text=\(symbol)&type=FR")!
        UIApplication.shared.open(url)
    }

    private var filtered: [FinancialSignal] {
        guard let f = filterType else { return vm.signals }
        return vm.signals.filter { $0.type == f }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statsBar
                    .padding(.vertical, 12)
                Divider().opacity(0.4)

                Group {
                    if vm.isScanning {
                        scanningView
                    } else if vm.signals.isEmpty {
                        idleView
                    } else {
                        signalList
                    }
                }

                scanButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
            .navigationTitle("Bilanço Tarayıcı")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if let date = vm.lastScanDate {
                    ToolbarItem(placement: .topBarLeading) {
                        Text(date.formatted(.dateTime.day().month().hour().minute()))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                if !vm.signals.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) { filterMenu }
                }
            }
        }
    }

    // MARK: - İstatistik Çubuğu

    private var statsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                statBox(type: .turningProfitable,        label: "Kara\nGeçiş",       color: Color(red: 0.1,  green: 0.85, blue: 0.55))
                statDivider()
                statBox(type: .approachingProfit,        label: "Kâra\nYakın",       color: Color(red: 1.0,  green: 0.55, blue: 0.0))
                statDivider()
                statBox(type: .consecutiveLossReduction, label: "Sürekli\nİyileşme", color: Color(red: 0.3,  green: 0.7,  blue: 1.0))
                statDivider()
                statBox(type: .ebitTurnaround,           label: "FAVÖK\nToparlandı", color: Color(red: 0.6,  green: 0.85, blue: 0.3))
                statDivider()
                statBox(type: .lossReducing,             label: "Zarar\nAzalıyor",   color: Color(red: 0.2,  green: 0.6,  blue: 1.0))
                statDivider()
                statBox(type: .operatingLeverage,        label: "Op.\nKaldıraç",     color: Color(red: 0.0,  green: 0.75, blue: 0.85))
                statDivider()
                statBox(type: .profitConsistency,        label: "İstikrarlı\nKâr",   color: Color(red: 0.95, green: 0.35, blue: 0.6))
                statDivider()
                statBox(type: .profitGrowing,            label: "Kar\nBüyüyor",      color: Color(red: 1.0,  green: 0.72, blue: 0.0))
                statDivider()
                statBox(type: .revenueGrowing,           label: "Gelir\nArtışı",     color: Color(red: 0.7,  green: 0.3,  blue: 1.0))
            }
            .padding(.horizontal, 8)
        }
    }

    private func statDivider() -> some View {
        Divider().frame(height: 40).opacity(0.5)
    }

    private func statBox(type: FinancialSignalType, label: String, color: Color) -> some View {
        let count      = vm.signals.filter { $0.type == type }.count
        let isSelected = filterType == type
        return Button {
            filterType = (filterType == type) ? nil : type
        } label: {
            VStack(spacing: 3) {
                Text("\(count)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(count > 0 ? color : .secondary)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isSelected ? color : .secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(minWidth: 68)
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
            .background(isSelected ? color.opacity(0.15) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(count == 0)
    }

    // MARK: - Taranıyor

    private var scanningView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 5)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: vm.progress)
                    .stroke(
                        LinearGradient(colors: [Color(red: 0.1, green: 0.85, blue: 0.55),
                                                Color(red: 0.0, green: 0.6, blue: 0.38)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 100, height: 100)
                    .animation(.easeInOut(duration: 0.35), value: vm.progress)
                VStack(spacing: 0) {
                    Text("\(Int(vm.progress * 100))")
                        .font(.system(size: 22, weight: .black, design: .monospaced))
                    Text("%")
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                }
            }
            VStack(spacing: 6) {
                Text("\(vm.scannedCount) / \(vm.totalCount)")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                Text("bilanço analiz ediliyor…")
                    .font(.subheadline).foregroundStyle(.secondary)
                HStack(spacing: 16) {
                    Label("\(vm.dataFoundCount) veri bulundu", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Color(red: 0.1, green: 0.85, blue: 0.55))
                    if vm.fetchErrors > 0 {
                        Label("\(vm.fetchErrors) hata", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
                .font(.caption.weight(.medium))
                Text("Kaynak: İş Yatırım")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer()
        }
    }

    // MARK: - Boş Ekran

    private var idleView: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [Color(red: 0.1, green: 0.85, blue: 0.55).opacity(0.15), .clear],
                        center: .center, startRadius: 0, endRadius: 55))
                    .frame(width: 110, height: 110)
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.1, green: 0.85, blue: 0.55), .mint],
                            startPoint: .top, endPoint: .bottom))
            }
            VStack(spacing: 6) {
                if vm.hasScanned {
                    if vm.fetchErrors > 0 && vm.dataFoundCount == 0 {
                        Text("Veri Alınamadı")
                            .font(.title3.weight(.bold))
                        Text("İş Yatırım sunucusuna bağlanılamadı veya\nveri formatı beklenenden farklı")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Text("Hata: \(vm.fetchErrors) / \(vm.totalCount) hisse")
                            .font(.caption).foregroundStyle(.red.opacity(0.8))
                            .padding(.top, 2)
                    } else if vm.dataFoundCount > 0 {
                        Text("Sinyal Bulunamadı")
                            .font(.title3.weight(.bold))
                        Text("\(vm.dataFoundCount) şirketin bilanço verisi analiz edildi\nBelirlenen kriterleri karşılayan sinyal yok")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Bilanço Verisi Yok")
                            .font(.title3.weight(.bold))
                        Text("İş Yatırım'dan bilanço verisi alınamadı.\nBiraz sonra tekrar deneyin.")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    Text("Bilanço Taramasına Hazır")
                        .font(.title3.weight(.bold))
                    Text("Kara geçen, kâra yakın, FAVÖK toparlanmış\nveya sürekli iyileşen şirketleri bulur")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                Text("Kaynak: İş Yatırım")
                    .font(.caption2).foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            Spacer()
        }
    }

    // MARK: - Sinyal Listesi

    private var signalList: some View {
        List {
            if filterType == nil {
                scanSummaryRow
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init(top: 4, leading: 14, bottom: 2, trailing: 14))
            }
            ForEach(filtered) { sig in
                NavigationLink {
                    StockDetailView(stock: sig.stock)
                } label: {
                    FinancialSignalCard(signal: sig)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 6, leading: 14, bottom: 6, trailing: 14))
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button { openIsyatirim(symbol: sig.stock.symbol) } label: {
                        Label("İş Yatırım", systemImage: "building.columns.fill")
                    }
                    .tint(Color(red: 0.1, green: 0.6, blue: 0.35))
                    Button { openKAP(symbol: sig.stock.symbol) } label: {
                        Label("KAP", systemImage: "doc.text.fill")
                    }
                    .tint(Color(red: 0.15, green: 0.4, blue: 0.85))
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        FavoritesManager.shared.toggle(sig.stock)
                    } label: {
                        let isFav = FavoritesManager.shared.isFavorite(sig.stock)
                        Label(isFav ? "Favoriden Çıkar" : "Favoriye Ekle",
                              systemImage: isFav ? "star.slash" : "star.fill")
                    }
                    .tint(Color(red: 1.0, green: 0.65, blue: 0.0))
                }
            }
        }
        .listStyle(.plain)
    }

    private var scanSummaryRow: some View {
        HStack(spacing: 12) {
            summaryChip(value: "\(vm.totalCount)", label: "Tarandı", color: .secondary)
            summaryChip(value: "\(vm.dataFoundCount)", label: "Veri Bulundu",
                        color: Color(red: 0.1, green: 0.85, blue: 0.55))
            summaryChip(value: "\(vm.signals.count)", label: "Sinyal",
                        color: Color(red: 0.2, green: 0.5, blue: 1.0))
            if vm.fetchErrors > 0 {
                summaryChip(value: "\(vm.fetchErrors)", label: "Hata", color: .orange)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func summaryChip(value: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 9).padding(.vertical, 5)
        .background(color.opacity(0.08))
        .clipShape(Capsule())
    }

    // MARK: - Tara Butonu

    private var scanButton: some View {
        Button {
            if vm.isScanning {
                vm.cancelScan()
            } else {
                vm.startScan(stocks: scanner.stockList)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: vm.isScanning ? "stop.circle.fill" : "building.columns.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                Text(vm.isScanning ? "Taramayı Durdur" : "Tüm BIST Bilanço Tara")
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
                        LinearGradient(colors: [Color(red: 0.1, green: 0.75, blue: 0.45),
                                                Color(red: 0.0, green: 0.52, blue: 0.3)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    }
                }
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(
                color: vm.isScanning
                    ? Color.red.opacity(0.35)
                    : Color(red: 0.1, green: 0.75, blue: 0.45).opacity(0.4),
                radius: 12, y: 5
            )
        }
        .scaleEffect(vm.isScanning ? 0.98 : 1.0)
        .animation(.spring(response: 0.3), value: vm.isScanning)
    }

    // MARK: - Filtre Menüsü

    private var filterMenu: some View {
        Menu {
            Button("Tümü") { filterType = nil }
            ForEach(FinancialSignalType.allCases, id: \.self) { t in
                Button("\(t.emoji) \(t.rawValue)") { filterType = t }
            }
        } label: {
            let active = filterType != nil
            Image(systemName: active
                  ? "line.3.horizontal.decrease.circle.fill"
                  : "line.3.horizontal.decrease.circle")
            .foregroundStyle(active ? .green : .secondary)
            .font(.system(size: 18))
        }
    }
}

// MARK: - Finansal Sinyal Kartı

struct FinancialSignalCard: View {
    let signal: FinancialSignal

    private var typeColor: Color {
        switch signal.type {
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

    var body: some View {
        HStack(spacing: 0) {
            typeColor
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 8) {
                // Başlık
                HStack(spacing: 6) {
                    Text(signal.stock.symbol)
                        .font(.system(size: 16, weight: .black))
                    Text(signal.type.emoji + " " + signal.type.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(typeColor)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(typeColor.opacity(0.12))
                        .clipShape(Capsule())
                    Spacer()
                    Text(signal.period)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                }

                // Finansal veriler
                HStack(spacing: 0) {
                    financialChip(label: "Net Kar",
                                  value: formatMoney(signal.currentNetIncome),
                                  valueColor: signal.currentNetIncome >= 0
                                    ? Color(red: 0.1, green: 0.85, blue: 0.55)
                                    : Color(red: 1.0, green: 0.28, blue: 0.32))

                    cardDivider()

                    financialChip(label: "Değişim",
                                  value: String(format: "%+.0f%%", signal.netIncomeChangePercent),
                                  valueColor: signal.netIncomeChangePercent >= 0
                                    ? Color(red: 0.1, green: 0.85, blue: 0.55)
                                    : Color(red: 1.0, green: 0.28, blue: 0.32))

                    cardDivider()

                    financialChip(label: "Gelir",
                                  value: formatMoney(signal.currentRevenue),
                                  valueColor: nil)

                    if let yoy = signal.yoyNetIncomeChangePercent {
                        cardDivider()
                        financialChip(label: "YoY",
                                      value: String(format: "%+.0f%%", yoy),
                                      valueColor: yoy >= 0
                                        ? Color(red: 0.1, green: 0.85, blue: 0.55)
                                        : Color(red: 1.0, green: 0.28, blue: 0.32))
                    }
                    Spacer()
                }

                // Sinyal türüne özgü ek bilgi satırı
                extraInfoRow
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
                            LinearGradient(
                                colors: [typeColor.opacity(0.35), .clear],
                                startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1)
                )
        )
        .shadow(color: typeColor.opacity(0.12), radius: 8, y: 3)
    }

    @ViewBuilder
    private var extraInfoRow: some View {
        switch signal.type {

        case .approachingProfit:
            // Net marj yüzdesi + iyileşme okunun gösterimi
            let marginPct = signal.currentNetMargin * 100
            let improvPct = signal.netMarginImprovement * 100
            HStack(spacing: 6) {
                infoTag(
                    text: String(format: "Net Marj: %.1f%%", marginPct),
                    color: Color(red: 1.0, green: 0.55, blue: 0.0))
                infoTag(
                    text: String(format: "Marj %+.1f puan", improvPct),
                    color: improvPct >= 0
                        ? Color(red: 0.1, green: 0.85, blue: 0.55)
                        : Color(red: 1.0, green: 0.28, blue: 0.32))
                Spacer()
            }

        case .consecutiveLossReduction:
            // Kaç ardışık çeyrek iyileşme var
            HStack(spacing: 6) {
                infoTag(
                    text: "\(signal.consecutiveImprovements + 1) çeyrek sürekli iyileşme",
                    color: Color(red: 0.3, green: 0.7, blue: 1.0))
                if signal.consecutiveImprovements >= 2 {
                    infoTag(text: "Güçlü Trend", color: Color(red: 0.1, green: 0.85, blue: 0.55))
                }
                Spacer()
            }

        case .ebitTurnaround:
            let ebitMargin = signal.currentRevenue != 0
                ? signal.currentOperatingIncome / signal.currentRevenue * 100 : 0
            HStack(spacing: 6) {
                infoTag(
                    text: "FAVÖK: \(formatMoney(signal.currentOperatingIncome))",
                    color: Color(red: 0.6, green: 0.85, blue: 0.3))
                infoTag(
                    text: String(format: "FAVÖK Marjı: %.1f%%", ebitMargin),
                    color: Color(red: 0.6, green: 0.85, blue: 0.3))
                Spacer()
            }

        case .operatingLeverage:
            HStack(spacing: 6) {
                infoTag(
                    text: String(format: "Gelir %+.0f%%", signal.revenueChangePercent),
                    color: Color(red: 0.0, green: 0.75, blue: 0.85))
                infoTag(
                    text: String(format: "Faal. Kâr %+.0f%%", signal.operatingIncomeChangePercent),
                    color: Color(red: 0.0, green: 0.75, blue: 0.85))
                Spacer()
            }

        case .profitConsistency:
            HStack(spacing: 6) {
                infoTag(text: "4 çeyrek kârlı", color: Color(red: 0.95, green: 0.35, blue: 0.6))
                if let yoy = signal.yoyNetIncomeChangePercent {
                    infoTag(
                        text: String(format: "YoY %+.0f%%", yoy),
                        color: Color(red: 0.95, green: 0.35, blue: 0.6))
                }
                Spacer()
            }

        default:
            EmptyView()
        }
    }

    private func infoTag(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func financialChip(label: String, value: String, valueColor: Color?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(valueColor ?? .primary)
        }
    }

    private func cardDivider() -> some View {
        Rectangle()
            .fill(Color(.separator).opacity(0.5))
            .frame(width: 1, height: 20)
            .padding(.horizontal, 9)
    }

    private func formatMoney(_ v: Double) -> String {
        let abs = Swift.abs(v)
        let prefix = v < 0 ? "-" : ""
        if abs >= 1_000_000_000 { return "\(prefix)\(String(format: "%.1f", abs / 1_000_000_000))B₺" }
        if abs >= 1_000_000     { return "\(prefix)\(String(format: "%.0f", abs / 1_000_000))M₺" }
        if abs >= 1_000         { return "\(prefix)\(String(format: "%.0f", abs / 1_000))K₺" }
        return "\(prefix)\(String(format: "%.0f", abs))₺"
    }
}
