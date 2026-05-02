import Foundation

struct TechnicalIndicators {
    let rsi: Double
    let macdLine: Double
    let macdSignal: Double
    let macdHistogram: Double
    let ema9: Double
    let ema21: Double
    let ema50: Double
    let bbUpper: Double
    let bbMiddle: Double
    let bbLower: Double
    let avgVolume20: Double
}

enum TechnicalAnalysis {

    // MARK: - RSI (14 periyot)
    static func rsi(closes: [Double], period: Int = 14) -> Double {
        guard closes.count > period else { return 50 }
        var gains = 0.0, losses = 0.0
        for i in (closes.count - period) ..< closes.count {
            let diff = closes[i] - closes[i - 1]
            if diff > 0 { gains  += diff }
            else        { losses -= diff }
        }
        let avgGain = gains  / Double(period)
        let avgLoss = losses / Double(period)
        guard avgLoss > 0 else { return 100 }
        let rs = avgGain / avgLoss
        return 100 - (100 / (1 + rs))
    }

    // MARK: - EMA
    static func ema(values: [Double], period: Int) -> [Double] {
        guard values.count >= period else { return [] }
        let k = 2.0 / Double(period + 1)
        var result: [Double] = []
        let sma = values[0 ..< period].reduce(0, +) / Double(period)
        result.append(sma)
        for i in period ..< values.count {
            result.append(values[i] * k + result.last! * (1 - k))
        }
        return result
    }

    // MARK: - MACD (12/26/9)
    static func macd(closes: [Double]) -> (line: [Double], signal: [Double], histogram: [Double]) {
        let ema12 = ema(values: closes, period: 12)
        let ema26 = ema(values: closes, period: 26)
        guard ema12.count >= ema26.count else { return ([], [], []) }
        let offset = ema12.count - ema26.count
        let macdLine = zip(ema12.dropFirst(offset), ema26).map { $0 - $1 }
        let signal   = ema(values: macdLine, period: 9)
        let histOffset = macdLine.count - signal.count
        let histogram = zip(macdLine.dropFirst(histOffset), signal).map { $0 - $1 }
        return (macdLine, signal, histogram)
    }

    // MARK: - Bollinger Bantları (20 periyot, 2 std)
    static func bollingerBands(closes: [Double], period: Int = 20, multiplier: Double = 2.0)
        -> (upper: Double, middle: Double, lower: Double)
    {
        guard closes.count >= period else { return (0, 0, 0) }
        let slice = Array(closes.suffix(period))
        let mean  = slice.reduce(0, +) / Double(period)
        let variance = slice.map { pow($0 - mean, 2) }.reduce(0, +) / Double(period)
        let std   = sqrt(variance)
        return (mean + multiplier * std, mean, mean - multiplier * std)
    }

    // MARK: - ATR dizisi (her mum için)
    static func atrArray(candles: [Candle], period: Int = 14) -> [Double] {
        guard candles.count > 1 else { return [candles.first.map { $0.high - $0.low } ?? 0] }
        var tr = [Double](repeating: 0, count: candles.count)
        tr[0] = candles[0].high - candles[0].low
        for i in 1 ..< candles.count {
            tr[i] = max(
                candles[i].high - candles[i].low,
                abs(candles[i].high - candles[i-1].close),
                abs(candles[i].low  - candles[i-1].close)
            )
        }
        var atr = [Double](repeating: 0, count: candles.count)
        let init_ = min(period, candles.count)
        atr[init_ - 1] = tr[0 ..< init_].reduce(0, +) / Double(init_)
        for i in init_ ..< candles.count {
            atr[i] = (atr[i-1] * Double(period - 1) + tr[i]) / Double(period)
        }
        return atr
    }

    // MARK: - SuperTrend — direction: 1=boğa, -1=ayı
    static func supertrend(candles: [Candle], multiplier: Double = 1.5, period: Int = 10)
        -> (values: [Double], directions: [Int])
    {
        guard candles.count > period else { return ([], []) }
        let atrVals = atrArray(candles: candles, period: period)
        var upper = [Double](repeating: 0, count: candles.count)
        var lower = [Double](repeating: 0, count: candles.count)
        var st    = [Double](repeating: 0, count: candles.count)
        var dir   = [Int](repeating: -1, count: candles.count)

        for i in 0 ..< candles.count {
            let hl2   = (candles[i].high + candles[i].low) / 2.0
            let bUp   = hl2 + multiplier * atrVals[i]
            let bDown = hl2 - multiplier * atrVals[i]
            if i == 0 {
                upper[i] = bUp;  lower[i] = bDown
                dir[i]   = -1;   st[i]    = upper[i]
            } else {
                upper[i] = (bUp   < upper[i-1] || candles[i-1].close > upper[i-1]) ? bUp   : upper[i-1]
                lower[i] = (bDown > lower[i-1] || candles[i-1].close < lower[i-1]) ? bDown : lower[i-1]
                if dir[i-1] == -1 {
                    dir[i] = candles[i].close > upper[i] ?  1 : -1
                } else {
                    dir[i] = candles[i].close < lower[i] ? -1 :  1
                }
                st[i] = dir[i] == 1 ? lower[i] : upper[i]
            }
        }
        return (st, dir)
    }

    // MARK: - Confluence Skoru (0-5)
    // Birden fazla bağımsız faktörün aynı anda doğrulanması — yüksek skor = kaliteli sinyal
    static func confluenceScore(candles: [Candle], ind: TechnicalIndicators, price: Double) -> Int {
        guard let last = candles.last else { return 0 }
        var score = 0
        if ind.rsi > 40 && ind.rsi < 68 { score += 1 }           // RSI sağlıklı aralıkta
        if price > ind.ema50            { score += 1 }           // Ana trend yukarı
        if ind.macdHistogram > 0        { score += 1 }           // MACD momentumu pozitif
        if last.volume > ind.avgVolume20 { score += 1 }          // Hacim ortalamanın üstünde
        let sma10 = candles.suffix(10).map(\.close).reduce(0,+) / 10.0
        if price > sma10                { score += 1 }           // Kısa vadeli trend yukarı
        return score
    }

    // MARK: - Ortalama Hacim
    static func averageVolume(candles: [Candle], period: Int = 20) -> Double {
        let slice = candles.suffix(period).map(\.volume)
        guard !slice.isEmpty else { return 0 }
        return slice.reduce(0, +) / Double(slice.count)
    }

    // MARK: - Tüm göstergeleri hesapla
    static func calculate(candles: [Candle]) -> TechnicalIndicators? {
        guard candles.count >= 50 else { return nil }
        let closes  = candles.map(\.close)
        let rsiVal  = rsi(closes: closes)
        let (macdLine, macdSig, macdHist) = macd(closes: closes)
        let ema9Arr  = ema(values: closes, period: 9)
        let ema21Arr = ema(values: closes, period: 21)
        let ema50Arr = ema(values: closes, period: 50)
        let bb       = bollingerBands(closes: closes)
        let avgVol   = averageVolume(candles: candles)

        guard let e9  = ema9Arr.last,
              let e21 = ema21Arr.last,
              let e50 = ema50Arr.last,
              let ml  = macdLine.last,
              let ms  = macdSig.last,
              let mh  = macdHist.last
        else { return nil }

        return TechnicalIndicators(
            rsi:           rsiVal,
            macdLine:      ml,
            macdSignal:    ms,
            macdHistogram: mh,
            ema9:          e9,
            ema21:         e21,
            ema50:         e50,
            bbUpper:       bb.upper,
            bbMiddle:      bb.middle,
            bbLower:       bb.lower,
            avgVolume20:   avgVol
        )
    }
}
