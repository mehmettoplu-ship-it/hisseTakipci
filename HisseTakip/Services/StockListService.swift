import Foundation

actor StockListService {
    static let shared = StockListService()

    private let cacheKey     = "dynamicStockList"
    private let cacheDateKey = "dynamicStockListDate"
    private let cacheTTL: TimeInterval = 24 * 3600

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpShouldSetCookies = true
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
            "Accept": "application/json",
            "Accept-Language": "en-US,en;q=0.9"
        ]
        return URLSession(configuration: config)
    }()

    private var didBootstrap = false

    // MARK: - Screener Body

    private func makeScreenerBody(offset: Int, size: Int) -> Data? {
        let body: [String: Any] = [
            "size": size,
            "offset": offset,
            "sortField": "ticker",
            "sortType": "ASC",
            "quoteType": "EQUITY",
            "query": [
                "operator": "EQ",
                "operands": ["region", "tr"]
            ],
            "userId": "",
            "userIdType": "guid"
        ]
        return try? JSONSerialization.data(withJSONObject: body)
    }

    // Ana metot: cache → Yahoo screener → static fallback
    func loadStocks() async -> [Stock] {
        if let cached = loadFromCache() { return cached }
        if let fresh = try? await fetchAll(), fresh.count > 100 {
            saveToCache(fresh)
            return fresh
        }
        return BISTStockList.all
    }

    func forceRefresh() async -> [Stock] {
        clearCache()
        return await loadStocks()
    }

    // MARK: - Bootstrap

    private func bootstrap() async {
        guard !didBootstrap else { return }
        didBootstrap = true
        let ua = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
        if let url = URL(string: "https://finance.yahoo.com") {
            var req = URLRequest(url: url)
            req.setValue(ua, forHTTPHeaderField: "User-Agent")
            req.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
            req.timeoutInterval = 10
            _ = try? await session.data(for: req)
        }
    }

    // MARK: - Fetch

    private func fetchAll() async throws -> [Stock] {
        await bootstrap()
        var all: [Stock] = []
        var offset = 0
        let pageSize = 250
        var consecutiveFailures = 0

        while offset < 1000 {
            do {
                let page = try await fetchPage(offset: offset, size: pageSize)
                guard !page.isEmpty else { break }
                all.append(contentsOf: page)
                if page.count < pageSize { break }
                offset += pageSize
                try? await Task.sleep(for: .milliseconds(500))
                consecutiveFailures = 0
            } catch {
                consecutiveFailures += 1
                if consecutiveFailures >= 2 { break }
                try? await Task.sleep(for: .seconds(1))
            }
        }

        // Yahoo Finance bazı hisseleri döndürmeyebilir — statik listedekilerle birleştir
        let apiIds = Set(all.map(\.id))
        let missing = BISTStockList.all.filter { !apiIds.contains($0.id) }
        return all + missing
    }

    private func fetchPage(offset: Int, size: Int) async throws -> [Stock] {
        guard let url = URL(string: "https://query1.finance.yahoo.com/v1/finance/screener"),
              let body = makeScreenerBody(offset: offset, size: size) else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("https://finance.yahoo.com", forHTTPHeaderField: "Referer")
        req.httpBody = body

        let (data, response) = try await session.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            return try await fetchPageV2(offset: offset, size: size)
        }
        if let decoded = try? JSONDecoder().decode(PredefinedScreenerResponse.self, from: data),
           let quotes = decoded.finance?.result?.first?.quotes, !quotes.isEmpty {
            return parseQuotes(quotes)
        }
        return try await fetchPageV2(offset: offset, size: size)
    }

    private func fetchPageV2(offset: Int, size: Int) async throws -> [Stock] {
        guard let url = URL(string: "https://query2.finance.yahoo.com/v1/finance/screener"),
              let body = makeScreenerBody(offset: offset, size: size) else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("https://finance.yahoo.com", forHTTPHeaderField: "Referer")
        req.httpBody = body

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(PredefinedScreenerResponse.self, from: data)
        return parseQuotes(decoded.finance?.result?.first?.quotes ?? [])
    }

    private func parseQuotes(_ quotes: [ScreenerQuote]) -> [Stock] {
        quotes.compactMap { q in
            guard q.symbol.hasSuffix(".IS") else { return nil }
            let sym  = String(q.symbol.dropLast(3))
            let name = q.shortName ?? q.longName ?? sym
            return Stock(id: q.symbol, symbol: sym, name: name, sector: mapSector(q.sector))
        }
    }

    // MARK: - Sektör Eşlemesi

    private func mapSector(_ s: String?) -> String {
        switch s {
        case "Financial Services":     return "Finans"
        case "Industrials":            return "Sanayi"
        case "Energy":                 return "Enerji"
        case "Basic Materials":        return "Hammadde"
        case "Technology":             return "Teknoloji"
        case "Consumer Cyclical":      return "Tüketim"
        case "Consumer Defensive":     return "Tüketim"
        case "Healthcare":             return "Sağlık"
        case "Communication Services": return "Telekomünikasyon"
        case "Utilities":              return "Kamu Hizmetleri"
        case "Real Estate":            return "GYO"
        default:                       return s ?? "Diğer"
        }
    }

    // MARK: - Cache

    private func loadFromCache() -> [Stock]? {
        guard
            let date   = UserDefaults.standard.object(forKey: cacheDateKey) as? Date,
            Date().timeIntervalSince(date) < cacheTTL,
            let data   = UserDefaults.standard.data(forKey: cacheKey),
            let stocks = try? JSONDecoder().decode([Stock].self, from: data),
            stocks.count > 100
        else { return nil }
        return stocks
    }

    private func saveToCache(_ stocks: [Stock]) {
        guard let data = try? JSONEncoder().encode(stocks) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
        UserDefaults.standard.set(Date(), forKey: cacheDateKey)
    }

    private func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheDateKey)
    }
}

// MARK: - Response Models

private struct PredefinedScreenerResponse: Decodable {
    let finance: ScreenerFinance?
}
private struct ScreenerFinance: Decodable {
    let result: [ScreenerResult]?
}
private struct ScreenerResult: Decodable {
    let quotes: [ScreenerQuote]?
}
private struct ScreenerQuote: Decodable {
    let symbol: String
    let shortName: String?
    let longName: String?
    let sector: String?
}
