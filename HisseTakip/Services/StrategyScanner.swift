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
        let price         = lastCandle.close
        let prevCloses    = candles.dropLast().map(\.close)
        let prevClosesArr = Array(prevCloses)
        let allCloses     = candles.map(\.close)

        // Pre-computed prev-candle EMA values — reused by strategies 3, 4, 8, 11
        let prevEma9Last  = TechnicalAnalysis.ema(values: prevClosesArr, period: 9).last  ?? 0
        let prevEma21Last = TechnicalAnalysis.ema(values: prevClosesArr, period: 21).last ?? 0
        let prevEma50Last = TechnicalAnalysis.ema(values: prevClosesArr, period: 50).last ?? 0
        let volRatio   = lastCandle.volume / max(ind.avgVolume20, 1)
        let confluence = TechnicalAnalysis.confluenceScore(candles: candles, ind: ind, price: price)
        let dailyChange: Double? = prevCandle.close > 0
            ? (price - prevCandle.close) / prevCandle.close * 100 : nil

        // ─────────────────────────────────────────────────────────────────
        // 1. DİRENÇ KIRILMASI
        // 20 günlük zirvenin %0.5 üzerinde kırılma + güçlü hacim
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.resistanceBreakout) {
            let high20 = candles.suffix(21).dropLast().map(\.high).max() ?? 0
            if price > high20 * 1.005,
               volRatio >= 2.0,
               ind.rsi > 42, ind.rsi < 68,
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
        // RSI 28 altından yukarı döner + MACD histogramı negatiften pozitife geçer
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.oversoldReversal) {
            let prevRSI = TechnicalAnalysis.rsi(closes: prevClosesArr)
            if prevRSI < 28, ind.rsi >= 28, confluence >= 2 {
                let (_, _, prevHist) = TechnicalAnalysis.macd(closes: prevClosesArr)
                let macdConfirmed = (prevHist.last ?? 0) < 0 && ind.macdHistogram > 0
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
        // 3. EMA ALTIN KESİŞİM (EMA9 > EMA21)
        // Kısa vadeli momentum dönüşü — fiyat EMA50 üzerinde olmalı
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.emaBullishCross) {
            let emaCrossed = prevEma9Last < prevEma21Last && ind.ema9 > ind.ema21
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

        // ─────────────────────────────────────────────────────────────────
        // 4. EMA ALTIN HAÇ (EMA21 > EMA50)
        // Orta vadeli trend dönüşü — EMA9/21'den çok daha güvenilir
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.goldenCross) {
            let freshCross = prevEma21Last <= prevEma50Last && ind.ema21 > ind.ema50
            if freshCross,
               price > ind.ema21,
               ind.rsi > 45, ind.rsi < 72,
               lastCandle.volume >= ind.avgVolume20,
               confluence >= 2 {
                signals.append(make(
                    stock: stock, type: .goldenCross,
                    strength: volRatio >= 1.5 && ind.rsi > 52 ? .strong : .moderate,
                    timeframe: timeframe, price: price, ind: ind,
                    volRatio: volRatio, dailyChange: dailyChange
                ))
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 5. BOLLİNGER DİP ZIPLAMASI
        // Alt banda değen önceki mum + boğa mumu kapanışı + RSI aşırı satım
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.bollingerBounce) {
            let candleRange    = lastCandle.high - lastCandle.low
            let closeInUpperHalf = candleRange > 0 &&
                (lastCandle.close - lastCandle.low) / candleRange > 0.5
            if prevCandle.low <= ind.bbLower,
               lastCandle.close > ind.bbLower,
               ind.rsi < 38,
               closeInUpperHalf,
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
        // 6. SIKIŞMA PATLAMASI
        // ATR normal seviyenin %65'ine iner (düşük volatilite) → BB orta bandı
        // yukarı kırar + hacim artar. Patlamadan önce sessizlik kalıbı.
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.squeezeBounce) {
            let shortATR = TechnicalAnalysis.atrArray(candles: Array(candles.suffix(20)), period: 10).last ?? 0
            let baseATR  = TechnicalAnalysis.atrArray(candles: Array(candles.suffix(40)), period: 20).last ?? 0
            let squeezed   = baseATR > 0 && shortATR < baseATR * 0.65
            let breakingUp = price > ind.bbMiddle && lastCandle.close > lastCandle.open
            let volOk      = lastCandle.volume > ind.avgVolume20 * 1.2
            let rsiOk      = ind.rsi > 45 && ind.rsi < 68

            if squeezed && breakingUp && volOk && rsiOk && confluence >= 2 {
                signals.append(make(
                    stock: stock, type: .squeezeBounce,
                    strength: volRatio >= 2.0 ? .strong : .moderate,
                    timeframe: timeframe, price: price, ind: ind,
                    volRatio: volRatio, dailyChange: dailyChange
                ))
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 7. RSI BOĞA DİVERJANSI
        // Fiyat daha düşük dip yaparken RSI daha yüksek dip — 5+ puan fark
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
        // EMA9 > EMA21 > EMA50 + fiyat EMA9 üzerinde + RSI momentum bölgesi
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.maStack) {
            let aligned    = ind.ema9 > ind.ema21 && ind.ema21 > ind.ema50
            let priceAbove = price > ind.ema9
            let volOk      = lastCandle.volume >= ind.avgVolume20 * 0.8
            let rsiOk      = ind.rsi > 50 && ind.rsi < 72

            if aligned && priceAbove && volOk && rsiOk {
                if ind.ema9 > prevEma9Last {
                    let freshCross = prevEma21Last <= prevEma50Last && ind.ema21 > ind.ema50
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
        // Direnç kırıldı → destek oldu → toparlanıyor — en güvenilir giriş kalıbı
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.breakoutRetest), candles.count >= 25 {
            let breakoutWindow  = candles[(candles.count - 25)..<(candles.count - 10)]
            let resistanceLevel = breakoutWindow.map(\.high).max() ?? 0
            let breakoutCandles = candles.suffix(10).dropLast(1)
            let breakoutOccurred = breakoutCandles.contains {
                $0.close > resistanceLevel * 1.002
            }
            let inRetestZone = price >= resistanceLevel * 0.985 &&
                               price <= resistanceLevel * 1.025
            let retestVol    = lastCandle.volume < ind.avgVolume20 * 1.5
            let bullishCandle = lastCandle.close > lastCandle.open

            if breakoutOccurred && inRetestZone && retestVol && bullishCandle,
               ind.rsi > 45, ind.rsi < 65,
               confluence >= 2 {
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
        // 10. TREND DESTEĞİ
        // Yükselen trendde EMA21 veya EMA50'ye çekilme + boğa mumu onayı
        // Trend takipçileri için en doğal giriş noktası
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.trendPullback) {
            let inUptrend  = ind.ema9 > ind.ema21 && ind.ema21 > ind.ema50
            let ema21Touch = price >= ind.ema21 * 0.985 && price <= ind.ema21 * 1.015
            let ema50Touch = price >= ind.ema50 * 0.985 && price <= ind.ema50 * 1.015
            let bullCandle = lastCandle.close > lastCandle.open &&
                             (lastCandle.close - lastCandle.open) / lastCandle.open > 0.003
            let volOk = lastCandle.volume >= ind.avgVolume20 * 0.8

            if inUptrend && (ema21Touch || ema50Touch) && bullCandle && volOk,
               ind.rsi > 38, ind.rsi < 60,
               confluence >= 2 {
                let isStrong = ema50Touch && volRatio >= 1.3 && ind.rsi > 42
                signals.append(make(
                    stock: stock, type: .trendPullback,
                    strength: isStrong ? .strong : .moderate,
                    timeframe: timeframe, price: price, ind: ind,
                    volRatio: volRatio, dailyChange: dailyChange
                ))
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 11. AKILLI MOMENTUM
        // 5 bağımsız koşulun tamamı doğru: SuperTrend + EMA + RSI + MACD + Hacim
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.smartMomentum) {
            let (_, stDirs) = TechnicalAnalysis.supertrend(
                candles: candles, multiplier: 2.0, period: 14)

            let c1_supertrend = stDirs.last == 1
            let c2_emaAlign   = ind.ema9 > ind.ema21 && ind.ema21 > ind.ema50
            let c3_rsi        = ind.rsi > 52 && ind.rsi < 68
            let c4_macd       = ind.macdLine > 0 && ind.macdHistogram > 0
            let c5_volume     = lastCandle.volume > ind.avgVolume20 * 1.2

            let conditionCount = [c1_supertrend, c2_emaAlign, c3_rsi, c4_macd, c5_volume]
                .filter { $0 }.count

            if conditionCount == 5 {
                let prevDir  = stDirs.count >= 2 ? stDirs[stDirs.count - 2] : 0
                let freshSignal = (prevDir == -1 && stDirs.last == 1) ||
                                  (prevEma9Last < ind.ema9 * 0.998)
                let isStrong = freshSignal && volRatio >= 1.5

                signals.append(make(
                    stock: stock, type: .smartMomentum,
                    strength: isStrong ? .strong : .moderate,
                    timeframe: timeframe, price: price, ind: ind,
                    volRatio: volRatio, dailyChange: dailyChange
                ))
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 12. MUM FORMASYONU
        // Hammer (Çekiç) veya Bullish Engulfing — destek bölgesinde oluşmalı
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.candlePattern) {
            let range = lastCandle.high - lastCandle.low

            if range > 0 {
                let lowerShadow = min(lastCandle.open, lastCandle.close) - lastCandle.low
                let upperShadow = lastCandle.high - max(lastCandle.open, lastCandle.close)
                let bodyRatio   = abs(lastCandle.close - lastCandle.open) / range
                let body        = abs(lastCandle.close - lastCandle.open)

                // Hammer: uzun alt gölge, küçük gövde, küçük üst gölge
                let isHammer = lowerShadow / range > 0.55 &&
                               bodyRatio < 0.30 &&
                               upperShadow / range < 0.20 &&
                               ind.rsi < 52

                // Bullish Engulfing: önceki kırmızı mumu tamamen yutan yeşil mum
                let prevBody     = abs(prevCandle.close - prevCandle.open)
                let prevBearish  = prevCandle.close < prevCandle.open
                let currBullish  = lastCandle.close > lastCandle.open
                let engulfs      = lastCandle.open  <= prevCandle.close &&
                                   lastCandle.close >= prevCandle.open
                let isEngulfing  = prevBearish && currBullish && engulfs &&
                                   body > prevBody * 1.1 &&
                                   ind.rsi < 58

                if (isHammer || isEngulfing) && confluence >= 2 {
                    let nearEMA = price >= ind.ema21 * 0.97 || price >= ind.ema50 * 0.97
                    let nearBB  = lastCandle.low <= ind.bbLower * 1.03

                    if nearEMA || nearBB {
                        let isStrong: Bool
                        if isEngulfing {
                            isStrong = body > prevBody * 2.0 && volRatio >= 1.5
                        } else {
                            isStrong = lowerShadow / range > 0.70 &&
                                       (nearBB || abs(price - ind.ema50) / ind.ema50 < 0.015)
                        }
                        signals.append(make(
                            stock: stock, type: .candlePattern,
                            strength: isStrong ? .strong : .moderate,
                            timeframe: timeframe, price: price, ind: ind,
                            volRatio: volRatio, dailyChange: dailyChange
                        ))
                    }
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 13. 52 HAFTA ZİRVESİ KIRILMASI
        // Bir yıllık en yüksek seviyeyi hacim onaylı kıran hisseler
        // Kurumsal yatırımcıların izlediği Stage 2 kırılma kalıbı
        // ─────────────────────────────────────────────────────────────────
        let weeklyBreakoutMin = timeframe == .weekly ? 54 : 200
        if enabledStrategies.contains(.weeklyBreakout), candles.count >= weeklyBreakoutMin {
            // Günlük: 251 gün ≈ 1 yıl | Haftalık: 53 hafta ≈ 1 yıl
            let lookback = timeframe == .weekly ? 53 : 251
            let yearHigh = candles.suffix(lookback).dropLast().map(\.high).max() ?? 0
            if yearHigh > 0,
               price > yearHigh * 1.002,
               lastCandle.volume > ind.avgVolume20 * 1.5,
               ind.rsi > 55, ind.rsi < 78,
               price > ind.ema21,
               price > ind.ema50 {
                signals.append(make(
                    stock: stock, type: .weeklyBreakout,
                    strength: volRatio >= 2.0 && ind.rsi > 60 ? .strong : .moderate,
                    timeframe: timeframe, price: price, ind: ind,
                    volRatio: volRatio, dailyChange: dailyChange
                ))
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 14. VCP KIRILMASI (Volatility Contraction Pattern)
        // Sıkışma + hacim kuruması + 3x patlama — Minervini metodolojisi
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.vcpBreakout), candles.count >= 30 {
            let shortATR = TechnicalAnalysis.atrArray(candles: Array(candles.suffix(20)), period: 10).last ?? 0
            let baseATR  = TechnicalAnalysis.atrArray(candles: Array(candles.suffix(40)), period: 20).last ?? 0
            let atrContracted = baseATR > 0 && shortATR < baseATR * 0.65

            let recent5AvgVol = candles.suffix(6).dropLast().map(\.volume).reduce(0, +) / 5
            let volumeDriedUp = recent5AvgVol < ind.avgVolume20 * 0.70

            let prior20High = candles.suffix(21).dropLast().map(\.high).max() ?? 0
            let breakingOut = price > prior20High * 1.002

            let explosionVol = lastCandle.volume > ind.avgVolume20 * 3.0
            let inUptrend    = price > ind.ema21 && price > ind.ema50
            let rsiOk        = ind.rsi > 52 && ind.rsi < 75
            let macdOk       = ind.macdHistogram > 0

            if atrContracted && volumeDriedUp && breakingOut && explosionVol
               && inUptrend && rsiOk && macdOk && confluence >= 3 {
                signals.append(make(
                    stock: stock, type: .vcpBreakout,
                    strength: volRatio >= 4.0 && ind.rsi > 62 ? .strong : .moderate,
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
