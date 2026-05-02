import Foundation

// Yahoo Finance quoteSummary — crumb token ile BIST hisseleri için çeyreklik gelir tablosu
actor FinancialDataService {
    static let shared = FinancialDataService()

    private var cachedCrumb: String?
    private var crumbFetchedAt: Date?
    private var didBootstrap = false

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.httpCookieStorage    = HTTPCookieStorage.shared
        config.httpShouldSetCookies  = true
        config.httpCookieAcceptPolicy = .always
        config.httpAdditionalHeaders = [
            "User-Agent":      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
            "Accept":          "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9"
        ]
        return URLSession(configuration: config)
    }()

    // MARK: - Ana Metot

    func fetchQuarterlyStatements(symbol: String) async throws -> [QuarterlyStatement] {
        let yahooSymbol = symbol.hasSuffix(".IS") ? symbol : "\(symbol).IS"
        let crumb = try await getOrFetchCrumb()
        let stmts = try await fetchSummary(symbol: yahooSymbol, crumb: crumb)
        return stmts
    }

    private func fetchSummary(symbol: String, crumb: String) async throws -> [QuarterlyStatement] {
        guard let url = URL(string: "https://query1.finance.yahoo.com/v10/finance/quoteSummary/\(symbol)?modules=incomeStatementHistoryQuarterly&crumb=\(crumb)") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.setValue("https://finance.yahoo.com", forHTTPHeaderField: "Referer")
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode == 401 || http.statusCode == 403 {
            // Crumb bayatlamış — bir kez yenile
            cachedCrumb = nil
            let fresh = try await getOrFetchCrumb()
            guard let retryURL = URL(string: "https://query1.finance.yahoo.com/v10/finance/quoteSummary/\(symbol)?modules=incomeStatementHistoryQuarterly&crumb=\(fresh)") else {
                throw URLError(.badURL)
            }
            var retryReq = URLRequest(url: retryURL)
            retryReq.setValue("https://finance.yahoo.com", forHTTPHeaderField: "Referer")
            let (retryData, retryResp) = try await session.data(for: retryReq)
            guard (retryResp as? HTTPURLResponse)?.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            return parseYahoo(retryData)
        }
        guard http.statusCode == 200 else { throw URLError(.badServerResponse) }
        return parseYahoo(data)
    }

    // MARK: - Crumb

    private func getOrFetchCrumb() async throws -> String {
        // 30 dakika geçerliyse cache'den kullan
        if let c = cachedCrumb,
           let fetched = crumbFetchedAt,
           Date().timeIntervalSince(fetched) < 1800 {
            return c
        }
        // Önce finance.yahoo.com ana sayfasını ziyaret et — GDPR consent cookie (A3) buradan geliyor
        // Sadece API endpoint'i ısıtmak bu cookie'yi set etmiyor, crumb 401 döndürüyor
        if !didBootstrap {
            didBootstrap = true
            let ua = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
            if let homeURL = URL(string: "https://finance.yahoo.com") {
                var homeReq = URLRequest(url: homeURL)
                homeReq.setValue(ua, forHTTPHeaderField: "User-Agent")
                homeReq.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
                homeReq.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
                homeReq.timeoutInterval = 12
                _ = try? await session.data(for: homeReq)
            }
            if let warmURL = URL(string: "https://query2.finance.yahoo.com/v8/finance/chart/THYAO.IS?interval=1d&range=5d") {
                var warmReq = URLRequest(url: warmURL)
                warmReq.setValue(ua, forHTTPHeaderField: "User-Agent")
                warmReq.setValue("https://finance.yahoo.com", forHTTPHeaderField: "Referer")
                warmReq.timeoutInterval = 10
                _ = try? await session.data(for: warmReq)
            }
        }
        guard let url = URL(string: "https://query1.finance.yahoo.com/v1/test/getcrumb") else {
            throw URLError(.badURL)
        }
        var crumbRequest = URLRequest(url: url)
        crumbRequest.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
            forHTTPHeaderField: "User-Agent")
        crumbRequest.setValue("https://finance.yahoo.com", forHTTPHeaderField: "Referer")
        crumbRequest.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        let (data, response) = try await session.data(for: crumbRequest)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
              let raw = String(data: data, encoding: .utf8)
        else {
            throw URLError(.cannotParseResponse)
        }
        let crumbStr = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // Geçerli crumb: kısa alfanümerik dize (HTML veya JSON değil)
        guard !crumbStr.isEmpty,
              !crumbStr.hasPrefix("<"),
              !crumbStr.hasPrefix("{"),
              crumbStr.count < 30
        else {
            throw URLError(.cannotParseResponse)
        }
        cachedCrumb    = crumbStr
        crumbFetchedAt = Date()
        return crumbStr
    }

    // MARK: - JSON Parse

    private func parseYahoo(_ data: Data) -> [QuarterlyStatement] {
        guard
            let json  = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let qSum  = json["quoteSummary"] as? [String: Any],
            let res   = (qSum["result"] as? [[String: Any]])?.first,
            let hist  = res["incomeStatementHistoryQuarterly"] as? [String: Any],
            let stmts = hist["incomeStatementHistory"] as? [[String: Any]]
        else { return [] }

        return stmts.compactMap { s -> QuarterlyStatement? in
            guard let ts = (s["endDate"] as? [String: Any])?["raw"] as? Int else { return nil }
            let date = Date(timeIntervalSince1970: TimeInterval(ts))
            func raw(_ key: String) -> Double {
                (s[key] as? [String: Any])?["raw"] as? Double ?? 0
            }
            return QuarterlyStatement(
                date: date,
                revenue: raw("totalRevenue"),
                netIncome: raw("netIncome"),
                operatingIncome: raw("ebit")
            )
        }
        .sorted { $0.date > $1.date }
    }
}
