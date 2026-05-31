import SwiftUI

struct PortfolioView: View {
    @StateObject private var pm = PortfolioManager.shared

    var body: some View {
        NavigationStack {
            Group {
                if pm.positions.isEmpty {
                    emptyState
                } else {
                    positionList
                }
            }
            .navigationTitle("Portföy")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Özet Başlık

    private var summaryHeader: some View {
        let hasLive = pm.positions.contains { $0.currentPrice != nil }
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                summaryBox(
                    title: "Maliyet",
                    value: formatMoney(pm.totalCost),
                    color: .secondary
                )
                Divider().frame(height: 40).opacity(0.5)
                summaryBox(
                    title: "Güncel Değer",
                    value: hasLive ? formatMoney(pm.totalValue) : "—",
                    color: .primary
                )
                Divider().frame(height: 40).opacity(0.5)
                summaryBox(
                    title: "Kâr / Zarar",
                    value: hasLive ? String(format: "%+.1f%%", pm.totalPLPercent) : "—",
                    color: hasLive ? (pm.totalPL >= 0
                        ? Color(red: 0.1, green: 0.85, blue: 0.55)
                        : Color(red: 1.0, green: 0.28, blue: 0.32)) : .secondary
                )
            }
            .padding(.vertical, 12)
            Divider().opacity(0.4)
        }
    }

    private func summaryBox(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Pozisyon Listesi

    private var positionList: some View {
        List {
            Section {
                summaryHeader
                    .listRowInsets(.init())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            ForEach(pm.positions) { position in
                positionRow(position)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init(top: 5, leading: 14, bottom: 5, trailing: 14))
            }
            .onDelete { idx in
                idx.forEach { pm.remove(pm.positions[$0]) }
            }
        }
        .listStyle(.plain)
        .toolbar {
            EditButton()
        }
    }

    private func positionRow(_ p: Position) -> some View {
        let plColor: Color = {
            guard let pct = p.profitLossPercent else { return .secondary }
            return pct >= 0
                ? Color(red: 0.1, green: 0.85, blue: 0.55)
                : Color(red: 1.0, green: 0.28, blue: 0.32)
        }()

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(plColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(String(p.stockSymbol.prefix(2)))
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(plColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(p.stockSymbol)
                        .font(.system(size: 15, weight: .black))
                    Text(p.stockSector)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                }
                Text(p.stockName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(String(format: "%.0f lot", p.quantity))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text("Alış: \(String(format: "%.2f ₺", p.buyPrice))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                    if let cur = p.currentPrice {
                        Text("Güncel: \(String(format: "%.2f ₺", cur))")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                if let pct = p.profitLossPercent {
                    Text(String(format: "%+.2f%%", pct))
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundStyle(plColor)
                    if let pl = p.profitLoss {
                        Text(formatMoney(pl))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(plColor.opacity(0.75))
                    }
                } else {
                    Text(formatMoney(p.cost))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.primary)
                    Text("Maliyet")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(plColor.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Boş Durum

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.2, green: 0.5, blue: 1.0).opacity(0.1))
                    .frame(width: 90, height: 90)
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color(red: 0.2, green: 0.5, blue: 1.0).opacity(0.6))
            }
            VStack(spacing: 8) {
                Text("Portföy Boş")
                    .font(.title3.weight(.bold))
                Text("Hisse detay sayfasından\npozisyon ekleyebilirsin.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Yardımcı

    private func formatMoney(_ v: Double) -> String {
        let a = abs(v); let p = v < 0 ? "-" : (v > 0 ? "+" : "")
        if a >= 1_000_000 { return "\(p)\(String(format: "%.1f", a / 1_000_000))M₺" }
        if a >= 1_000     { return "\(p)\(String(format: "%.1f", a / 1_000))K₺" }
        return "\(p)\(String(format: "%.0f", a))₺"
    }
}

// MARK: - Pozisyon Ekleme Sheet

struct AddPositionSheet: View {
    let stock: Stock
    @Environment(\.dismiss) private var dismiss
    @State private var buyPriceText = ""
    @State private var quantityText = ""
    @State private var buyDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Hisse") {
                    HStack {
                        Text(stock.symbol).font(.headline)
                        Spacer()
                        Text(stock.name).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                Section("İşlem Detayları") {
                    HStack {
                        Text("Alış Fiyatı (₺)")
                        Spacer()
                        TextField("0.00", text: $buyPriceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 120)
                    }
                    HStack {
                        Text("Lot Sayısı")
                        Spacer()
                        TextField("0", text: $quantityText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 120)
                    }
                    DatePicker("Alış Tarihi", selection: $buyDate, displayedComponents: .date)
                }
                if let price = Double(buyPriceText.replacingOccurrences(of: ",", with: ".")),
                   let qty = Double(quantityText.replacingOccurrences(of: ",", with: ".")),
                   price > 0, qty > 0 {
                    Section("Özet") {
                        HStack {
                            Text("Toplam Maliyet")
                            Spacer()
                            Text(String(format: "%.2f ₺", price * qty))
                                .font(.system(.body, design: .monospaced))
                                .bold()
                        }
                    }
                }
            }
            .navigationTitle("Pozisyon Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kaydet") { save() }
                        .font(.system(size: 15, weight: .semibold))
                        .disabled(!isValid)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var isValid: Bool {
        guard let p = Double(buyPriceText.replacingOccurrences(of: ",", with: ".")),
              let q = Double(quantityText.replacingOccurrences(of: ",", with: "."))
        else { return false }
        return p > 0 && q > 0
    }

    private func save() {
        guard let p = Double(buyPriceText.replacingOccurrences(of: ",", with: ".")),
              let q = Double(quantityText.replacingOccurrences(of: ",", with: "."))
        else { return }
        PortfolioManager.shared.add(stock: stock, buyPrice: p, quantity: q, buyDate: buyDate)
        dismiss()
    }
}

// MARK: - Alarm Ekleme Sheet

struct AddAlarmSheet: View {
    let stock: Stock
    let currentPrice: Double?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var am = PriceAlarmManager.shared
    @State private var targetPriceText = ""
    @State private var direction: PriceAlarm.Direction = .above

    var body: some View {
        NavigationStack {
            Form {
                Section("Hisse") {
                    HStack {
                        Text(stock.symbol).font(.headline)
                        Spacer()
                        if let cur = currentPrice {
                            Text(String(format: "%.2f ₺", cur))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Alarm Koşulu") {
                    Picker("Yön", selection: $direction) {
                        ForEach(PriceAlarm.Direction.allCases, id: \.self) { d in
                            Text(d.rawValue).tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                    HStack {
                        Text("Hedef Fiyat (₺)")
                        Spacer()
                        TextField("0.00", text: $targetPriceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 120)
                    }
                }
                if !am.activeAlarms(for: stock.symbol).isEmpty {
                    Section("Mevcut Alarmlar") {
                        ForEach(am.activeAlarms(for: stock.symbol)) { alarm in
                            HStack {
                                Image(systemName: alarm.direction == .above ? "arrow.up" : "arrow.down")
                                    .font(.caption)
                                    .foregroundStyle(alarm.direction == .above ? .green : .red)
                                Text(alarm.direction.rawValue)
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.2f ₺", alarm.targetPrice))
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { idx in
                            idx.forEach { am.remove(am.activeAlarms(for: stock.symbol)[$0]) }
                        }
                    }
                }
            }
            .navigationTitle("Fiyat Alarmı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Ekle") { addAlarm() }
                        .font(.system(size: 15, weight: .semibold))
                        .disabled(!isValid)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var isValid: Bool {
        guard let p = Double(targetPriceText.replacingOccurrences(of: ",", with: ".")) else { return false }
        return p > 0
    }

    private func addAlarm() {
        guard let p = Double(targetPriceText.replacingOccurrences(of: ",", with: ".")) else { return }
        am.add(stockSymbol: stock.symbol, stockName: stock.name, targetPrice: p, direction: direction)
        targetPriceText = ""
    }
}
