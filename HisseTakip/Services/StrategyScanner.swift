import Foundation

enum StrategyScanner {

    static func scan(
        stock: Stock,
        candles: [Candle],
        timeframe: Timeframe,
        enabledStrategies: Set<SignalType> = Set(SignalType.allCases)
    ) -> [Signal] {
        guard let ind = TechnicalAnalysis.calculate(candles: candles),
              let lastCandle = candles.last,
              let prevCandle = candles.dropLast().last
        else { return [] }

        var signals: [Signal] = []
        let price      = lastCandle.close
        let prevCloses = candles.dropLast().map(\.close)
        let allCloses  = candles.map(\.close)
        let volRatio   = lastCandle.volume / max(ind.avgVolume20, 1)
        let confluence = TechnicalAnalysis.confluenceScore(candles: candles, ind: ind, price: price)
        let dailyChange: Double? = prevCandle.close > 0
            ? (price - prevCandle.close) / prevCandle.close * 100 : nil

        // ─────────────────────────────────────────────────────────────────
        // 1. DİRENÇ KIRILMASI
        // Yükseltilmiş filtre: hacim 2x+, RSI 42-68, confluence >= 2
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.resistanceBreakout) {
            let high20 = candles.suffix(21).dropLast().map(\.high).max() ?? 0
            if price > high20 * 1.005,        // en az %0.5 üstünde kırılma
               volRatio >= 2.0,               // güçlü hacim (1.5→2.0)
               ind.rsi > 42, ind.rsi < 68,   // aşırı alım yok
               confluence >= 2 {
                signals.append(make(
                    stock: stock, type: .resistanceBreakout,
                    strength: volRatio >= 3.0 ? .strong : .moderate,
                    timeframe: timeframe, price: price, ind: ind,
                    volRatio: volRatio, dailyChange: dailyChange
                ))
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 2. RSI DİP DÖNÜŞÜ
        // Daha derin aşırı satım (28), MACD onayı zorunlu, confluence >= 2
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.oversoldReversal) {
            let prevRSI = TechnicalAnalysis.rsi(closes: Array(prevCloses))
            if prevRSI < 28, ind.rsi >= 28,   // 30→28: daha derin dip
               confluence >= 2 {
                let (_, _, prevHist) = TechnicalAnalysis.macd(closes: Array(prevCloses))
                let macdConfirmed = (prevHist.last ?? 0) < 0 && ind.macdHistogram > 0
                // MACD onayı olmadan sinyal üretme
                if macdConfirmed {
                    signals.append(make(
                        stock: stock, type: .oversoldReversal,
                        strength: ind.rsi < 24 ? .strong : .moderate,
                        timeframe: timeframe, price: price, ind: ind,
                        dailyChange: dailyChange
                    ))
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 3. MACD ALTIN KESİŞİM
        // Sıfır çizgisi altında kesişim + hacim onayı + RSI momentumu
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.macdBullishCross) {
            let (macdL, macdS, _) = TechnicalAnalysis.macd(closes: allCloses)
            if macdL.count >= 2, macdS.count >= 2 {
                let prevML = macdL[macdL.count - 2], prevMS = macdS[macdS.count - 2]
                let crossedUp = prevML < prevMS && ind.macdLine > ind.macdSignal
                if crossedUp,
                   ind.macdLine < 0,         // sıfır altında daha güvenilir
                   ind.rsi > 42, ind.rsi < 65,
                   lastCandle.volume >= ind.avgVolume20 * 0.9,
                   confluence >= 2 {
                    signals.append(make(
                        stock: stock, type: .macdBullishCross,
                        strength: ind.macdHistogram > 0 && volRatio >= 1.5 ? .strong : .moderate,
                        timeframe: timeframe, price: price, ind: ind,
                        dailyChange: dailyChange
                    ))
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 4. EMA ALTIN KESİŞİM (EMA9 > EMA21)
        // Hacim onayı eklendi + RSI > 45, confluence >= 2
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.emaBullishCross) {
            let prevEma9Arr  = TechnicalAnalysis.ema(values: Array(prevCloses), period: 9)
            let prevEma21Arr = TechnicalAnalysis.ema(values: Array(prevCloses), period: 21)
            if let pe9 = prevEma9Arr.last, let pe21 = prevEma21Arr.last {
                let emaCrossed = pe9 < pe21 && ind.ema9 > ind.ema21
                if emaCrossed,
                   price > ind.ema50,
                   ind.rsi > 45,
                   lastCandle.volume >= ind.avgVolume20 * 0.9,
                   confluence >= 2 {
                    signals.append(make(
                        stock: stock, type: .emaBullishCross,
                        strength: volRatio >= 1.5 && ind.rsi > 52 ? .strong : .moderate,
                        timeframe: timeframe, price: price, ind: ind,
                        dailyChange: dailyChange
                    ))
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 5. BOLLİNGER DİP ZIPLAMASI
        // RSI daha düşük eşik (38), mum alt yarıda açılıp üst yarıda kapanmış
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.bollingerBounce) {
            let candleRange = lastCandle.high - lastCandle.low
            let closeInUpperHalf = candleRange > 0 &&
                (lastCandle.close - lastCandle.low) / candleRange > 0.5
            if prevCandle.low <= ind.bbLower,
               lastCandle.close > ind.bbLower,
               ind.rsi < 38,                  // 45→38: daha gerçekçi aşırı satım
               closeInUpperHalf,              // boğa mumu: üst yarıda kapanış
               confluence >= 2 {
                signals.append(make(
                    stock: stock, type: .bollingerBounce,
                    strength: ind.rsi < 30 ? .strong : .moderate,
                    timeframe: timeframe, price: price, ind: ind,
                    dailyChange: dailyChange
                ))
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 6. EC HFT PRO — değişmedi, zaten katı filtreler içeriyor
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.ecHFTPro) {
            let ud     = UserDefaults.standard
            let stMult = { let v = ud.double(forKey: "echft_multiplier");  return v > 0 ? v : 1.5 }()
            let stPer  = { let v = ud.integer(forKey: "echft_period");     return v > 0 ? v : 10  }()
            let emaS   = { let v = ud.integer(forKey: "echft_emaShort");   return v > 0 ? v : 2   }()
            let emaL   = { let v = ud.integer(forKey: "echft_emaLong");    return v > 0 ? v : 17  }()

            let (_, stDirs) = TechnicalAnalysis.supertrend(candles: candles, multiplier: stMult, period: stPer)
            let emaShortArr = TechnicalAnalysis.ema(values: allCloses, period: emaS)
            let emaLongArr  = TechnicalAnalysis.ema(values: allCloses, period: emaL)

            if stDirs.count >= 2,
               let eSh = emaShortArr.last, let eLo = emaLongArr.last {
                let lastDir = stDirs[stDirs.count - 1]
                let prevDir = stDirs[stDirs.count - 2]
                let stBull  = lastDir == 1
                let emaBull = eSh > eLo && price > eLo
                let volOk   = lastCandle.volume > ind.avgVolume20

                if stBull && emaBull && volOk {
                    let prevESh = TechnicalAnalysis.ema(values: Array(prevCloses), period: emaS).last ?? 0
                    let prevELo = TechnicalAnalysis.ema(values: Array(prevCloses), period: emaL).last ?? 0
                    let freshST  = prevDir == -1 && lastDir == 1
                    let freshEMA = prevESh <= prevELo && eSh > eLo
                    let isStrong = (freshST || freshEMA) && volRatio >= 1.5
                    signals.append(make(
                        stock: stock, type: .ecHFTPro,
                        strength: isStrong ? .strong : .moderate,
                        timeframe: timeframe, price: price, ind: ind,
                        volRatio: volRatio, dailyChange: dailyChange
                    ))
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 7. RSI BOĞA DİVERJANSI
        // Fiyat daha düşük dip yaparken RSI daha yüksek dip — eşik 5 puana yükseltildi
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.rsiDivergence), candles.count >= 50 {
            let earlierStart = candles.count - 35
            let earlierEnd   = candles.count - 16
            let recentStart  = candles.count - 15

            var earlierMinIdx = earlierStart
            for i in (earlierStart + 1)...earlierEnd {
                if candles[i].close < candles[earlierMinIdx].close { earlierMinIdx = i }
            }
            var recentMinIdx = recentStart
            for i in (recentStart + 1)..<(candles.count - 1) {
                if candles[i].close < candles[recentMinIdx].close { recentMinIdx = i }
            }

            let earlierMinPrice = candles[earlierMinIdx].close
            let recentMinPrice  = candles[recentMinIdx].close

            if recentMinPrice < earlierMinPrice * 0.998,
               price < recentMinPrice * 1.05 {
                let earlierRSI = TechnicalAnalysis.rsi(closes: Array(allCloses.prefix(earlierMinIdx + 1)))
                let recentRSI  = TechnicalAnalysis.rsi(closes: Array(allCloses.prefix(recentMinIdx + 1)))

                // Eşik 3→5 puan: daha az ama daha güvenilir diverjans
                if recentRSI > earlierRSI + 5.0, recentRSI < 52 {
                    let mag = recentRSI - earlierRSI
                    signals.append(make(
                        stock: stock, type: .rsiDivergence,
                        strength: mag >= 12 ? .strong : .moderate,
                        timeframe: timeframe, price: price, ind: ind,
                        dailyChange: dailyChange
                    ))
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 8. EMA HİZALANMASI (MA Stack)
        // RSI eşiği 45→50, taze kesişim veya 2x hacim zorunlu
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.maStack) {
            let aligned    = ind.ema9 > ind.ema21 && ind.ema21 > ind.ema50
            let priceAbove = price > ind.ema9
            let volOk      = lastCandle.volume >= ind.avgVolume20 * 0.8
            let rsiOk      = ind.rsi > 50 && ind.rsi < 72  // 45→50

            if aligned && priceAbove && volOk && rsiOk {
                let prevEma9  = TechnicalAnalysis.ema(values: Array(prevCloses), period: 9).last  ?? 0
                let prevEma21 = TechnicalAnalysis.ema(values: Array(prevCloses), period: 21).last ?? 0
                let prevEma50 = TechnicalAnalysis.ema(values: Array(prevCloses), period: 50).last ?? 0

                if ind.ema9 > prevEma9 {
                    let freshCross = prevEma21 <= prevEma50 && ind.ema21 > ind.ema50
                    let isStrong   = freshCross || (volRatio >= 2.0 && ind.rsi > 55)
                    signals.append(make(
                        stock: stock, type: .maStack,
                        strength: isStrong ? .strong : .moderate,
                        timeframe: timeframe, price: price, ind: ind,
                        volRatio: volRatio, dailyChange: dailyChange
                    ))
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 9. KIRILMA GERİ TESTİ
        // Direnç kırıldı → geri çekilme → destek oldu → toparlanma
        // En güvenilir giriş kalıplarından biri
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.breakoutRetest), candles.count >= 25 {
            // Son 15 mumdan önceki 10 mumun en yüksek kapanışı = kırılan direnç
            let breakoutWindow = candles[(candles.count - 25)..<(candles.count - 10)]
            let resistanceLevel = breakoutWindow.map(\.high).max() ?? 0

            // Kırılma: son 10 mum içinde direnç üstüne kapanmış mum var mı?
            let breakoutCandles = candles.suffix(10).dropLast(1)
            let breakoutOccurred = breakoutCandles.contains {
                $0.close > resistanceLevel * 1.002   // en az %0.2 üstünde kapanış
            }

            // Şu anki mum geri test bölgesinde mi? (direnç ±2%)
            let inRetestZone = price >= resistanceLevel * 0.985 &&
                               price <= resistanceLevel * 1.025

            // Hacim: geri testte hacim azalmış olmalı (sağlıklı konsolidasyon)
            let retestVol = lastCandle.volume < ind.avgVolume20 * 1.5

            // Boğa mumu: kapanış açılışın üstünde
            let bullishCandle = lastCandle.close > lastCandle.open

            if breakoutOccurred && inRetestZone && retestVol && bullishCandle,
               ind.rsi > 45, ind.rsi < 65,
               confluence >= 2 {
                // Güçlü sinyal: EMA50 üstünde ve önceki kırılmada yüksek hacim vardı
                let breakoutHadVolume = breakoutCandles.contains {
                    $0.volume > ind.avgVolume20 * 1.8
                }
                signals.append(make(
                    stock: stock, type: .breakoutRetest,
                    strength: breakoutHadVolume && price > ind.ema50 ? .strong : .moderate,
                    timeframe: timeframe, price: price, ind: ind,
                    volRatio: volRatio, dailyChange: dailyChange
                ))
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 10. AKILLI MOMENTUM
        // 5 bağımsız koşulun tamamı aynı anda doğru — çok az sinyal, yüksek kalite
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.smartMomentum) {
            let (_, stDirs) = TechnicalAnalysis.supertrend(
                candles: candles, multiplier: 2.0, period: 14)

            let c1_supertrend = stDirs.last == 1               // SuperTrend boğa
            let c2_emaAlign   = ind.ema9 > ind.ema21 &&
                                ind.ema21 > ind.ema50          // EMA hizalanma
            let c3_rsi        = ind.rsi > 52 && ind.rsi < 68  // RSI momentum bölgesi
            let c4_macd       = ind.macdLine > 0 &&
                                ind.macdHistogram > 0          // MACD sıfır üstünde
            let c5_volume     = lastCandle.volume > ind.avgVolume20 * 1.2 // hacim onayı

            let conditionCount = [c1_supertrend, c2_emaAlign, c3_rsi, c4_macd, c5_volume]
                .filter { $0 }.count

            // Tüm 5 koşul doğru olmalı — 4 tanesi yeterli değil
            if conditionCount == 5 {
                let prevEma9 = TechnicalAnalysis.ema(values: Array(prevCloses), period: 9).last ?? 0
                let prevDir  = stDirs.count >= 2 ? stDirs[stDirs.count - 2] : 0
                // Güçlü: SuperTrend yeni döndü VEYA hacim 2x+
                let freshSignal = (prevDir == -1 && stDirs.last == 1) ||
                                  (prevEma9 < ind.ema9 * 0.998)
                let isStrong = freshSignal && volRatio >= 1.5

                signals.append(make(
                    stock: stock, type: .smartMomentum,
                    strength: isStrong ? .strong : .moderate,
                    timeframe: timeframe, price: price, ind: ind,
                    volRatio: volRatio, dailyChange: dailyChange
                ))
            }
        }

        return signals
    }

    private static func make(
        stock: Stock, type: SignalType, strength: SignalStrength,
        timeframe: Timeframe, price: Double, ind: TechnicalIndicators,
        volRatio: Double? = nil, dailyChange: Double? = nil
    ) -> Signal {
        Signal(
            id: UUID(), stock: stock, type: type, strength: strength,
            timeframe: timeframe, price: price, timestamp: Date(),
            rsi: ind.rsi, macdHistogram: ind.macdHistogram,
            volumeRatio: volRatio, dailyChangePercent: dailyChange
        )
    }
}
