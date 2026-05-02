import SwiftUI

struct StockSearchView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject private var scanner: ScannerViewModel
    @State private var query         = ""
    @State private var recentIDs: [String] = []
    @FocusState private var focused: Bool

    private let recentKey = "recentSearchIDs"

    private var results: [Stock] {
        guard query.count >= 1 else { return [] }
        let q = query.uppercased().trimmingCharacters(in: .whitespaces)
        return scanner.stockList.filter {
            $0.symbol.hasPrefix(q) ||
            $0.name.localizedCaseInsensitiveContains(query)
        }
        .sorted { a, b in
            let aExact = a.symbol == q
            let bExact = b.symbol == q
            if aExact != bExact { return aExact }
            let aPrefix = a.symbol.hasPrefix(q)
            let bPrefix = b.symbol.hasPrefix(q)
            if aPrefix != bPrefix { return aPrefix }
            return a.symbol < b.symbol
        }
        .prefix(20)
        .map { $0 }
    }

    private var recentStocks: [Stock] {
        recentIDs.compactMap { id in
            scanner.stockList.first { $0.id == id }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                Divider().opacity(0.4)

                Group {
                    if query.isEmpty {
                        emptyState
                    } else if results.isEmpty {
                        notFound
                    } else {
                        resultsList
                    }
                }
            }
            .navigationTitle("Hisse Analiz")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        focused = false
                        selectedTab = 0
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Ana Sayfa")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(Color(red: 0.2, green: 0.5, blue: 1.0))
                    }
                }
            }
            .onAppear { loadRecents() }
        }
    }

    // MARK: - Arama Çubuğu

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(focused ? Color(red: 0.2, green: 0.5, blue: 1.0) : .secondary)
                .animation(.easeInOut(duration: 0.2), value: focused)

            TextField("THYAO, ADEL, BIMAS…", text: $query)
                .font(.system(size: 16, weight: .medium))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .focused($focused)
                .submitLabel(.search)

            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            focused
                                ? Color(red: 0.2, green: 0.5, blue: 1.0).opacity(0.5)
                                : Color.clear,
                            lineWidth: 1.5)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: focused)
    }

    // MARK: - Boş Durum

    private var emptyState: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !recentStocks.isEmpty {
                    recentSection
                }
                suggestionsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Son Aramalar", systemImage: "clock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Temizle") { clearRecents() }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red.opacity(0.7))
            }
            .padding(.horizontal, 2)

            FlowLayout(spacing: 8) {
                ForEach(recentStocks) { stock in
                    NavigationLink(destination: stockDetail(stock)) {
                        recentChip(stock)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded { addRecent(stock) })
                }
            }
        }
    }

    private func recentChip(_ stock: Stock) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "clock")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            Text(stock.symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Önerilenler", systemImage: "star.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 2)

            let suggestions = suggestedStocks
            VStack(spacing: 6) {
                ForEach(suggestions) { stock in
                    NavigationLink(destination: stockDetail(stock)) {
                        suggestionRow(stock)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded { addRecent(stock) })
                }
            }
        }
    }

    private func suggestionRow(_ stock: Stock) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(accentColor(stock.sector).opacity(0.15))
                    .frame(width: 36, height: 36)
                Text(String(stock.symbol.prefix(2)))
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(accentColor(stock.sector))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.symbol)
                    .font(.system(size: 14, weight: .bold))
                Text(stock.name)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(stock.sector)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(Color(.tertiarySystemFill))
                .clipShape(Capsule())
            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Sonuçlar

    private var resultsList: some View {
        List(results) { stock in
            NavigationLink(destination: stockDetail(stock)) {
                resultRow(stock)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(.init(top: 4, leading: 16, bottom: 4, trailing: 16))
            .simultaneousGesture(TapGesture().onEnded { addRecent(stock) })
        }
        .listStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: results.map(\.id))
    }

    private func resultRow(_ stock: Stock) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(accentColor(stock.sector).opacity(0.15))
                    .frame(width: 40, height: 40)
                Text(String(stock.symbol.prefix(2)))
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(accentColor(stock.sector))
            }
            VStack(alignment: .leading, spacing: 3) {
                highlightedText(stock.symbol, query: query.uppercased())
                Text(stock.name)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(stock.sector)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Bulunamadı

    private var notFound: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            VStack(spacing: 6) {
                Text("\"\(query.uppercased())\" bulunamadı")
                    .font(.title3.weight(.bold))
                Text("Sembolü veya şirket adını kontrol edin.\nÖrnek: THYAO, ADEL, BIMAS")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Yardımcılar

    private func stockDetail(_ stock: Stock) -> some View {
        StockDetailView(stock: stock)
    }

    private var suggestedStocks: [Stock] {
        let popular = ["THYAO", "ASELS", "BIMAS", "SAHOL", "TUPRS", "SISE", "EREGL", "KCHOL"]
        return popular.compactMap { sym in
            scanner.stockList.first { $0.symbol == sym }
        }
    }

    private func accentColor(_ sector: String) -> Color {
        switch sector {
        case "Finans":          return Color(red: 0.2, green: 0.5, blue: 1.0)
        case "Sanayi":          return Color(red: 0.9, green: 0.5, blue: 0.0)
        case "Enerji":          return Color(red: 0.1, green: 0.75, blue: 0.45)
        case "Teknoloji":       return Color(red: 0.6, green: 0.3, blue: 1.0)
        case "Tüketim":         return Color(red: 1.0, green: 0.72, blue: 0.0)
        case "Sağlık":          return Color(red: 0.95, green: 0.35, blue: 0.6)
        case "GYO":             return Color(red: 0.3, green: 0.7,  blue: 1.0)
        case "Hammadde":        return Color(red: 0.7, green: 0.55, blue: 0.3)
        case "Telekomünikasyon": return Color(red: 0.0, green: 0.75, blue: 0.85)
        default:                return Color(.systemGray2)
        }
    }

    // MARK: - Recent Searches

    private func addRecent(_ stock: Stock) {
        var ids = recentIDs.filter { $0 != stock.id }
        ids.insert(stock.id, at: 0)
        recentIDs = Array(ids.prefix(8))
        UserDefaults.standard.set(recentIDs, forKey: recentKey)
    }

    private func loadRecents() {
        recentIDs = UserDefaults.standard.stringArray(forKey: recentKey) ?? []
    }

    private func clearRecents() {
        recentIDs = []
        UserDefaults.standard.removeObject(forKey: recentKey)
    }

    // Eşleşen kısmı vurgulayan Text bileşeni
    @ViewBuilder
    private func highlightedText(_ text: String, query: String) -> some View {
        if let range = text.range(of: query, options: .caseInsensitive) {
            let before = String(text[text.startIndex..<range.lowerBound])
            let match  = String(text[range])
            let after  = String(text[range.upperBound...])
            (Text(before)
             + Text(match)
                .foregroundColor(Color(red: 0.2, green: 0.5, blue: 1.0))
                .bold()
             + Text(after))
            .font(.system(size: 15, weight: .bold))
        } else {
            Text(text).font(.system(size: 15, weight: .bold))
        }
    }
}

// MARK: - FlowLayout (chip wrap)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > width, x > 0 { y += rowHeight + spacing; x = 0; rowHeight = 0 }
            rowHeight = max(rowHeight, s.height)
            x += s.width + spacing
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing; x = bounds.minX; rowHeight = 0
            }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            rowHeight = max(rowHeight, s.height)
            x += s.width + spacing
        }
    }
}
