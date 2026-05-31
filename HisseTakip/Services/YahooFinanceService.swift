import Foundation

actor YahooFinanceService {
    static let shared = YahooFinanceService()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.httpCookieStorage    = HTTPCookieStorage.shared
        config.httpShouldSetCookies = true
        config.httpCookieAcceptPolicy = .always
        return URLSession(configuration: config)
    }()

    func fetchCandles(symbol: String, timeframe: Timeframe) async throws -> [Candle] {
        var lastError: Error = FetchError.badResponse
        for attempt in 0...2 {
            if attempt > 0 {
                // 429 rate-limit: 2s, 4s bekleme
                try? await Task.sleep(for: .seconds(Double(attempt) * 2))
            }
            do {
                return try await _fetchCandles(symbol: symbol, timeframe: timeframe)
            } catch FetchError.rateLimited {
                lastError = FetchError.rateLimited
                // bir sonraki attempt'e geç
            } catch {
                throw error  // kalıcı hata (404, noData): hemen fırlat
            }
        }
        throw lastError
    }

    private func _fetchCandles(symbol: String, timeframe: Timeframe) async throws -> [Candle] {
        let url = try buildURL(symbol: symbol, timeframe: timeframe)
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        let (data, response) = try await session.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse else { throw FetchError.badResponse }

        if http.statusCode == 429 || http.statusCode == 401 {
            throw FetchError.rateLimited
        }
        guard http.statusCode == 200 else {
            throw FetchError.badResponse
        }

        let raw = try JSONDecoder().decode(YahooResponse.self, from: data)
        guard let result = raw.chart.result?.first else { throw FetchError.noData }

        let candles = try parseCandles(result: result)

        if timeframe.aggregationFactor > 1 {
            return aggregate(candles: candles, factor: timeframe.aggregationFactor)
        }
        return candles
    }

    private func buildURL(symbol: String, timeframe: Timeframe) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host   = "query2.finance.yahoo.com"
        components.path   = "/v8/finance/chart/\(symbol)"
        components.queryItems = [
            URLQueryItem(name: "interval", value: timeframe.yahooInterval),
            URLQueryItem(name: "range",    value: timeframe.yahooRange),
        ]
        guard let url = components.url else { throw FetchError.badURL }
        return url
    }

    private func parseCandles(result: YahooResult) throws -> [Candle] {
        guard
            let timestamps = result.timestamp,
            let quote      = result.indicators.quote.first,
            let opens      = quote.open,
            let highs      = quote.high,
            let lows       = quote.low,
            let closes     = quote.close,
            let volumes    = quote.volume
        else { throw FetchError.noData }

        var candles: [Candle] = []
        for i in 0 ..< timestamps.count {
            guard
                let o = opens[i], let h = highs[i],
                let l = lows[i],  let c = closes[i]
            else { continue }
            let v = volumes[i] ?? 0
            candles.append(Candle(
                timestamp: Date(timeIntervalSince1970: TimeInterval(timestamps[i])),
                open: o, high: h, low: l, close: c, volume: v
            ))
        }
        return candles
    }

    // 4h için: ardışık `factor` tane 1h mumu birleştir
    private func aggregate(candles: [Candle], factor: Int) -> [Candle] {
        var result: [Candle] = []
        var i = 0
        while i + factor <= candles.count {
            let group = candles[i ..< i + factor]
            let agg = Candle(
                timestamp: group.first!.timestamp,
                open:      group.first!.open,
                high:      group.map(\.high).max()!,
                low:       group.map(\.low).min()!,
                close:     group.last!.close,
                volume:    group.map(\.volume).reduce(0, +)
            )
            result.append(agg)
            i += factor
        }
        return result
    }
}

// MARK: - Errors
enum FetchError: Error, LocalizedError {
    case badURL, badResponse, noData, rateLimited

    var errorDescription: String? {
        switch self {
        case .badURL:       return "Geçersiz URL"
        case .badResponse:  return "Sunucu yanıt vermedi"
        case .noData:       return "Veri bulunamadı"
        case .rateLimited:  return "İstek limiti aşıldı"
        }
    }
}

// MARK: - Response Models
private struct YahooResponse: Decodable {
    let chart: YahooChart
}
private struct YahooChart: Decodable {
    let result: [YahooResult]?
}
private struct YahooResult: Decodable {
    let timestamp: [Int]?
    let indicators: YahooIndicators
}
private struct YahooIndicators: Decodable {
    let quote: [YahooQuote]
}
private struct YahooQuote: Decodable {
    let open:   [Double?]?
    let high:   [Double?]?
    let low:    [Double?]?
    let close:  [Double?]?
    let volume: [Double?]?
}
