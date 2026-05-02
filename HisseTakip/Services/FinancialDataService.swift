import Foundation

// İş Yatırım (isyatirim.com.tr) MaliTablo endpoint'i kullanılır.
// Yahoo Finance'e göre çok daha güncel ve kapsamlı BIST veri kaynağı.
actor FinancialDataService {
    static let shared = FinancialDataService()

    private let baseURL = "https://www.isyatirim.com.tr/_layouts/15/IsYatirim.Website/Common/Data.aspx/MaliTablo"

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.httpAdditionalHeaders = [
            "User-Agent":      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
            "Accept":          "application/json, text/plain, */*",
            "Accept-Language": "tr-TR,tr;q=0.9,en;q=0.8"
        ]
        return URLSession(configuration: config)
    }()

    // MARK: - Ana Metot

    func fetchQuarterlyStatements(symbol: String) async throws -> [QuarterlyStatement] {
        let periods = recentQuarters(count: 4)

        // XI_29: Standart TMS (çoğu sanayi şirketi)
        // UFRS:  TFRS (holdingler, büyük şirketler)
        // UFRS_K: Bankalar, sigorta şirketleri
        for group in ["XI_29", "UFRS", "UFRS_K"] {
            if let stmts = try? await fetch(symbol: symbol, periods: periods, group: group),
               !stmts.isEmpty {
                return stmts
            }
        }
        return []
    }

    // MARK: - İstek

    private func fetch(
        symbol: String,
        periods: [(year: Int, period: Int)],
        group: String
    ) async throws -> [QuarterlyStatement] {

        var components = URLComponents(string: baseURL)!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "companyCode",    value: symbol),
            URLQueryItem(name: "exchange",       value: "TRY"),
            URLQueryItem(name: "financialGroup", value: group)
        ]
        for (i, p) in periods.prefix(4).enumerated() {
            let n = i + 1
            items.append(URLQueryItem(name: "year\(n)",   value: "\(p.year)"))
            items.append(URLQueryItem(name: "period\(n)", value: "\(p.period)"))
        }
        components.queryItems = items

        guard let url = components.url else { throw FetchError.badURL }
        var req = URLRequest(url: url)
        req.setValue("https://www.isyatirim.com.tr", forHTTPHeaderField: "Referer")

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw FetchError.badResponse
        }

        let stmts = parse(data: data, periods: periods)
        return stmts
    }

    // MARK: - JSON Çözümleme

    private func parse(
        data: Data,
        periods: [(year: Int, period: Int)]
    ) -> [QuarterlyStatement] {

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let rows = json["value"] as? [[String: Any]],
            !rows.isEmpty
        else { return [] }

        // --- Satır eşleştirme yardımcısı ---
        func firstRow(trKeywords: [String], engKeywords: [String], trExclude: [String] = []) -> [String: Any]? {
            rows.first { row in
                let tr  = (row["itemDescTr"]  as? String ?? "").lowercased()
                let eng = (row["itemDescEng"] as? String ?? "").lowercased()
                let matchTr  = trKeywords.contains  { tr.contains($0)  }
                let matchEng = engKeywords.contains { eng.contains($0) }
                let excluded = trExclude.contains   { tr.contains($0)  }
                return (matchTr || matchEng) && !excluded
            }
        }

        // Gelir (Satışlar / Hasılat)
        let revRow = firstRow(
            trKeywords:  ["satışlar", "hasılat", "net satış", "brüt satış"],
            engKeywords: ["revenue", "net sales", "sales"],
            trExclude:   ["maliyet", "gider", "iade"]
        )

        // Faaliyet Kârı
        let opRow = firstRow(
            trKeywords:  ["faaliyet kâr", "faaliyet kar", "esas faaliyet"],
            engKeywords: ["operating profit", "operating income", "ebit"]
        )

        // Net Dönem Kârı
        let niRow = firstRow(
            trKeywords:  ["net dönem k", "dönem kâr", "dönem kar", "net dönem"],
            engKeywords: ["net income", "net profit", "period profit", "net period"]
        )

        // En az bir temel satır zorunlu
        guard revRow != nil || niRow != nil else { return [] }

        var stmts: [QuarterlyStatement] = []

        for p in periods {
            let colKey = "\(p.year)/\(p.period)"

            func val(_ row: [String: Any]?) -> Double {
                guard let row else { return 0 }
                if let v = row[colKey] as? Double { return v }
                if let v = row[colKey] as? Int    { return Double(v) }
                return 0
            }

            let rev = val(revRow)
            let ni  = val(niRow)
            let op  = val(opRow)

            guard rev != 0 || ni != 0 else { continue }   // bu çeyrek verisi yok

            // Dönem sonu tarihi (3 → Mart 31, 6 → Haz 30, 9 → Eyl 30, 12 → Ara 31)
            var dc = DateComponents()
            dc.year  = p.year
            dc.month = p.period
            dc.day   = p.period == 12 ? 31 : 30
            let date = Calendar.current.date(from: dc) ?? Date()

            stmts.append(QuarterlyStatement(
                date: date, revenue: rev,
                netIncome: ni, operatingIncome: op
            ))
        }

        return stmts.sorted { $0.date > $1.date }
    }

    // MARK: - Çeyrek Hesaplama

    private func recentQuarters(count: Int) -> [(year: Int, period: Int)] {
        let cal   = Calendar.current
        let now   = Date()
        let month = cal.component(.month, from: now)
        let year  = cal.component(.year,  from: now)

        // Şirketler çeyrek bitiminden ~2 ay sonra bildiri verir
        let (latestPeriod, latestYear): (Int, Int)
        if      month <= 2  { (latestPeriod, latestYear) = (9,  year - 1) }  // Oca-Şub → Q3 geçen yıl
        else if month <= 4  { (latestPeriod, latestYear) = (12, year - 1) }  // Mar-Nis → Q4 geçen yıl
        else if month <= 7  { (latestPeriod, latestYear) = (3,  year)     }  // May-Tem → Q1 bu yıl
        else if month <= 10 { (latestPeriod, latestYear) = (6,  year)     }  // Ağu-Eki → Q2 bu yıl
        else                { (latestPeriod, latestYear) = (9,  year)     }  // Kas-Ara → Q3 bu yıl

        var result: [(Int, Int)] = []
        var p = latestPeriod
        var y = latestYear

        for _ in 0..<count {
            result.append((y, p))
            if p == 3 { p = 12; y -= 1 } else { p -= 3 }
        }
        return result
    }
}
