import Foundation

// İş Yatırım (isyatirim.com.tr) MaliTablo endpoint'i kullanılır.
// Yahoo Finance'e göre çok daha güncel ve kapsamlı BIST veri kaynağı.
actor FinancialDataService {
    static let shared = FinancialDataService()

    private let baseURL = "https://www.isyatirim.com.tr/_layouts/15/IsYatirim.Website/Common/Data.aspx/MaliTablo"

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.httpAdditionalHeaders = [
            "User-Agent":      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
            "Accept":          "application/json, text/plain, */*",
            "Accept-Language": "tr-TR,tr;q=0.9,en;q=0.8"
        ]
        return URLSession(configuration: config)
    }()

    // MARK: - Ana Metot

    func fetchQuarterlyStatements(symbol: String) async throws -> [QuarterlyStatement] {
        let allPeriods  = recentQuarters(count: 5)
        let mainPeriods = Array(allPeriods.prefix(4))
        let yoyPeriod   = allPeriods[4]     // Aynı çeyreğin bir yıl öncesi (YoY için)

        // XI_29: Standart TMS (çoğu sanayi/ticaret şirketi)
        // UFRS:  TFRS konsolide (büyük şirketler, holdingler)
        // UFRS_K: Bankalar ve sigorta şirketleri
        for group in ["XI_29", "UFRS", "UFRS_K"] {
            guard let stmts = try? await fetch(symbol: symbol, periods: mainPeriods, group: group),
                  !stmts.isEmpty else { continue }
            // YoY çeyreği ayrı istekle çek — API max 4 dönem destekliyor
            let yoyStmts = try? await fetch(symbol: symbol, periods: [yoyPeriod], group: group)
            return stmts + (yoyStmts ?? [])
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

        return parse(data: data, periods: periods)
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

        // Satır eşleştirme — trKeywords veya engKeywords içerip trExclude içermeyen ilk satır
        func firstRow(trKeywords: [String], engKeywords: [String], trExclude: [String] = []) -> [String: Any]? {
            rows.first { row in
                let tr  = (row["itemDescTr"]  as? String ?? "").lowercased()
                let eng = (row["itemDescEng"] as? String ?? "").lowercased()
                let hit      = trKeywords.contains  { tr.contains($0)  } ||
                               engKeywords.contains { eng.contains($0) }
                let excluded = trExclude.contains   { tr.contains($0)  }
                return hit && !excluded
            }
        }

        // ── Gelir (Revenue) ──────────────────────────────────────────────────
        // XI_29: "Satış Gelirleri" (3C) | UFRS: "Hasılat"
        let revRow = firstRow(
            trKeywords:  ["satış gelir", "net satış", "brüt satış", "hasılat"],
            engKeywords: ["net sales", "revenue", "sales revenue"],
            trExclude:   ["maliyet", "pazarlama", "iade", "gider", "brüt kar", "brüt kâr"]
        )

        // ── Faaliyet Kârı (Operating Income) ────────────────────────────────
        // XI_29: "FAALİYET KARI (ZARARI)" (3DF) | UFRS: "Esas Faaliyet Kârı"
        let opRow = firstRow(
            trKeywords:  ["faaliyet kar", "faaliyet kâr", "esas faaliyet"],
            engKeywords: ["operating profit", "operating income", "operating profits"]
        )

        // ── Net Dönem Kârı (Net Income) ──────────────────────────────────────
        // XI_29: "DÖNEM KARI/ZARARI" (3J/3L)
        // UFRS:  "Dönem Net Kârı (Zararı)" veya "Ana Ortaklık Payları"
        let niRow = firstRow(
            trKeywords:  ["dönem kari", "dönem kâri", "dönem kar/", "dönem kâr/",
                          "net dönem k", "dönem net k"],
            engKeywords: ["net profit after tax", "profit from continuing",
                          "net income", "period profit", "net period"]
        )

        guard revRow != nil || niRow != nil else { return [] }

        var stmts: [QuarterlyStatement] = []

        for (i, p) in periods.enumerated() {
            // Kolon anahtarı: API sırasıyla value1, value2, value3, value4 döndürür
            let colKey = "value\(i + 1)"

            func val(_ row: [String: Any]?) -> Double {
                guard let row else { return 0 }
                // API bazen number, bazen string gönderir
                if let v = row[colKey] as? Double { return v }
                if let v = row[colKey] as? Int    { return Double(v) }
                if let s = row[colKey] as? String,
                   let v = Double(s.replacingOccurrences(of: ",", with: ".")) { return v }
                return 0
            }

            let rev = val(revRow)
            let ni  = val(niRow)
            let op  = val(opRow)

            guard rev != 0 || ni != 0 else { continue }   // bu çeyreğe veri yok

            // Dönem sonu tarihi (3→Mart31, 6→Haz30, 9→Eyl30, 12→Ara31)
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

        // Şirketler çeyrek bitiminden ~2 ay sonra KAP'a bildirir
        let latestPeriod: Int
        let latestYear:   Int
        if      month <= 2  { latestPeriod = 9;  latestYear = year - 1 }  // Oca-Şub → Q3 geçen yıl
        else if month <= 4  { latestPeriod = 12; latestYear = year - 1 }  // Mar-Nis → Q4 geçen yıl
        else if month <= 7  { latestPeriod = 3;  latestYear = year     }  // May-Tem → Q1 bu yıl
        else if month <= 10 { latestPeriod = 6;  latestYear = year     }  // Ağu-Eki → Q2 bu yıl
        else                { latestPeriod = 9;  latestYear = year     }  // Kas-Ara → Q3 bu yıl

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
