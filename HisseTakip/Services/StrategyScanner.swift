import Foundation

enum StrategyScanner {

    static func scan(
        stock: Stock,
        candles: [Candle],
        timeframe: Timeframe,
        enabledStrategies: Set<SignalType> = Set(SignalType.allCases)
    ) -> [Signal] {
        let minVol = Double(UserDefaults.standard.integer(forKey: "minAvgVolume"))
        guard let ind = TechnicalAnalysis.calculate(candles: candles),
              let lastCandle = candles.last,
              let prevCandle = candles.dropLast().last,
              ind.avgVolume20 >= max(1, minVol)
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
        let fullEma9Arr  = TechnicalAnalysis.ema(values: allCloses, period: 9)
        let fullEma21Arr = TechnicalAnalysis.ema(values: allCloses, period: 21)
        let fullEma50Arr = TechnicalAnalysis.ema(values: allCloses, period: 50)
        let (_, _, fullHistArr) = TechnicalAnalysis.macd(closes: allCloses)
        let lastIdx = candles.count - 1
        // During market hours the current daily bar is incomplete — use previous complete bar for volume checks
        let isIncompleteBar = Calendar.current.isDateInToday(lastCandle.timestamp)
        let volCandle       = isIncompleteBar ? prevCandle : lastCandle
        let volRatio        = volCandle.volume / max(ind.avgVolume20, 1)
        let confluence = TechnicalAnalysis.confluenceScore(candles: candles, ind: ind, price: price)
        let dailyChange: Double? = prevCandle.close > 0
            ? (price - prevCandle.close) / prevCandle.close * 100 : nil

        // ── Sinyal yaşı yardımcıları ───────────────────────────────────
        // Her strateji için "k bar önce de geçerliydi mi?" kontrolü
        func conditionStillHeld(type: SignalType, kBarsAgo k: Int) -> Bool {
            guard k > 0 && k <= lastIdx else { return false }
            let idx = lastIdx - k
            let c   = candles[idx]
            switch type {
            case .resistanceBreakout:
                let s = max(0, idx - 20)
                guard s < idx else { return false }
                let h20 = candles[s..<idx].map(\.high).max() ?? 0
                return h20 > 0 && c.close > h20 * 1.005
            case .emaBullishCross:
                let e9i = fullEma9Arr.count - 1 - k
                let e21i = fullEma21Arr.count - 1 - k
                guard e9i >= 0 && e21i >= 0 else { return false }
                return fullEma9Arr[e9i] > fullEma21Arr[e21i]
            case .goldenCross:
                let e21i = fullEma21Arr.count - 1 - k
                let e50i = fullEma50Arr.count - 1 - k
                guard e21i >= 0 && e50i >= 0 else { return false }
                return fullEma21Arr[e21i] > fullEma50Arr[e50i]
            case .maStack:
                let e9i = fullEma9Arr.count - 1 - k
                let e21i = fullEma21Arr.count - 1 - k
                let e50i = fullEma50Arr.count - 1 - k
                guard e9i >= 0 && e21i >= 0 && e50i >= 0 else { return false }
                return fullEma9Arr[e9i] > fullEma21Arr[e21i] && fullEma21Arr[e21i] > fullEma50Arr[e50i]
            case .weeklyBreakout:
                let s = max(0, idx - 252)
                guard s < idx else { return false }
                let h52 = candles[s..<idx].map(\.high).max() ?? 0
                return h52 > 0 && c.close > h52
            case .macdBullish:
                let hi  = fullHistArr.count - 1 - k
                let e9i = fullEma9Arr.count  - 1 - k
                let e21i = fullEma21Arr.count - 1 - k
                guard hi >= 0 && e9i >= 0 && e21i >= 0 else { return false }
                return fullHistArr[hi] > 0
                    && c.close > fullEma21Arr[e21i]
                    && fullEma9Arr[e9i] > fullEma21Arr[e21i]
            case .ichimokuBullish:
                guard idx >= 77 else { return false }
                guard let ichi = TechnicalAnalysis.ichimoku(candles: Array(candles.prefix(idx + 1)))
                else { return false }
                return c.close > max(ichi.senkouA, ichi.senkouB) && ichi.tenkan > ichi.kijun
            case .trendPullback:
                let e9i  = fullEma9Arr.count  - 1 - k
                let e21i = fullEma21Arr.count - 1 - k
                let e50i = fullEma50Arr.count - 1 - k
                guard e9i >= 0 && e21i >= 0 && e50i >= 0 else { return false }
                return fullEma9Arr[e9i] > fullEma21Arr[e21i] && fullEma21Arr[e21i] > fullEma50Arr[e50i]
            case .smartMomentum:
                let e9i  = fullEma9Arr.count  - 1 - k
                let e21i = fullEma21Arr.count - 1 - k
                let e50i = fullEma50Arr.count - 1 - k
                let hi   = fullHistArr.count  - 1 - k
                guard e9i >= 0 && e21i >= 0 && e50i >= 0 && hi >= 0 else { return false }
                return fullEma9Arr[e9i] > fullEma21Arr[e21i]
                    && fullEma21Arr[e21i] > fullEma50Arr[e50i]
                    && fullHistArr[hi] > 0
            case .bollingerBounce:
                let e21i = fullEma21Arr.count - 1 - k
                guard e21i >= 0 else { return false }
                return c.close > fullEma21Arr[e21i] * 0.97
            case .squeezeBounce:
                let e21i = fullEma21Arr.count - 1 - k
                let hi   = fullHistArr.count  - 1 - k
                guard e21i >= 0 && hi >= 0 else { return false }
                return c.close > fullEma21Arr[e21i] && fullHistArr[hi] > 0
            case .breakoutRetest:
                let e21i = fullEma21Arr.count - 1 - k
                let e50i = fullEma50Arr.count - 1 - k
                guard e21i >= 0 && e50i >= 0 else { return false }
                return c.close > fullEma21Arr[e21i] && fullEma21Arr[e21i] > fullEma50Arr[e50i]
            case .candlePattern:
                let e21i = fullEma21Arr.count - 1 - k
                guard e21i >= 0 else { return false }
                return c.close > fullEma21Arr[e21i] * 0.98
            case .vcpBreakout:
                let e9i  = fullEma9Arr.count  - 1 - k
                let e50i = fullEma50Arr.count - 1 - k
                guard e9i >= 0 && e50i >= 0 else { return false }
                return fullEma9Arr[e9i] > fullEma50Arr[e50i]
            case .descendingBreakout:
                let hi = fullHistArr.count - 1 - k
                guard hi >= 0 else { return false }
                return fullHistArr[hi] > 0
            case .ecHFT:
                let e9i  = fullEma9Arr.count  - 1 - k
                let e21i = fullEma21Arr.count - 1 - k
                guard e9i >= 0 && e21i >= 0 else { return false }
                return fullEma9Arr[e9i] > fullEma21Arr[e21i]
            case .titanBreakout:
                let e9i  = fullEma9Arr.count  - 1 - k
                let e21i = fullEma21Arr.count - 1 - k
                let e50i = fullEma50Arr.count - 1 - k
                let hi   = fullHistArr.count  - 1 - k
                guard e9i >= 0 && e21i >= 0 && e50i >= 0 && hi >= 0 else { return false }
                return fullEma9Arr[e9i] > fullEma21Arr[e21i]
                    && fullEma21Arr[e21i] > fullEma50Arr[e50i]
                    && fullHistArr[hi] > 0
            case .oversoldReversal:
                let e50i = fullEma50Arr.count - 1 - k
                let hi   = fullHistArr.count  - 1 - k
                guard e50i >= 0 && hi >= 0 else { return false }
                return c.close > fullEma50Arr[e50i] * 0.85 && fullHistArr[hi] > 0
            case .rsiDivergence:
                let e21i = fullEma21Arr.count - 1 - k
                guard e21i >= 0 else { return false }
                return c.close > fullEma21Arr[e21i] * 0.95
            case .sma50Pullback:
                guard allCloses.count > idx + 1 && idx >= 49 else { return false }
                let pastSma50 = Array(allCloses.prefix(idx + 1)).suffix(50).reduce(0,+) / 50.0
                return pastSma50 > 0 && c.close >= pastSma50 * 0.985
            default:
                return false
            }
        }

        func signalAge(for type: SignalType) -> (barsAgo: Int, runup: Double) {
            var firstBar = lastIdx
            for k in 1...min(15, lastIdx) {
                if conditionStillHeld(type: type, kBarsAgo: k) { firstBar = lastIdx - k } else { break }
            }
            let tp = candles[firstBar].close
            return (barsAgo: lastIdx - firstBar, runup: tp > 0 ? (price - tp) / tp * 100.0 : 0.0)
        }

        func makeS(_ type: SignalType, _ strength: SignalStrength) -> Signal {
            let (ba, ru) = signalAge(for: type)
            return make(stock: stock, type: type, strength: strength, timeframe: timeframe,
                        price: price, ind: ind, volRatio: volRatio, dailyChange: dailyChange,
                        barsAgo: ba, signalRunup: ru)
        }

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
                signals.append(makeS(.resistanceBreakout, volRatio >= 3.0 ? .strong : .moderate))
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 2. RSI DİP DÖNÜŞÜ
        // RSI 28 altından yukarı döner + MACD histogramı negatiften pozitife geçer
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.oversoldReversal) {
            let prevRSI = TechnicalAnalysis.rsi(closes: prevClosesArr)
            if prevRSI < 30, ind.rsi >= 30, confluence >= 2 {
                let (_, _, prevHist) = TechnicalAnalysis.macd(closes: prevClosesArr)
                let macdConfirmed = (prevHist.last ?? 0) < 0 && ind.macdHistogram > 0
                let bullishDay    = lastCandle.close > lastCandle.open           // dönüş günü yeşil mum
                let volumeOk      = volCandle.volume >= ind.avgVolume20 * 0.7    // minimum hacim katılımı
                let notFreefall   = price >= ind.ema50 * 0.72                   // kopuk trend değil
                if macdConfirmed && bullishDay && volumeOk && notFreefall {
                    let isStrong = prevRSI < 24 && volRatio >= 1.2
                    signals.append(makeS(.oversoldReversal, isStrong ? .strong : .moderate))
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
               volCandle.volume >= ind.avgVolume20 * 0.9,
               confluence >= 2 {
                signals.append(makeS(.emaBullishCross, volRatio >= 1.5 && ind.rsi > 52 ? .strong : .moderate))
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
               volCandle.volume >= ind.avgVolume20,
               confluence >= 2 {
                signals.append(makeS(.goldenCross, volRatio >= 1.5 && ind.rsi > 52 ? .strong : .moderate))
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
                signals.append(makeS(.bollingerBounce, ind.rsi < 30 ? .strong : .moderate))
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
            let volOk      = volCandle.volume > ind.avgVolume20 * 1.2
            let rsiOk      = ind.rsi > 45 && ind.rsi < 68

            if squeezed && breakingUp && volOk && rsiOk && confluence >= 2 {
                signals.append(makeS(.squeezeBounce, volRatio >= 2.0 ? .strong : .moderate))
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
                    signals.append(makeS(.rsiDivergence, mag >= 12 ? .strong : .moderate))
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
            let volOk      = volCandle.volume >= ind.avgVolume20 * 0.8
            let rsiOk      = ind.rsi > 50 && ind.rsi < 72

            if aligned && priceAbove && volOk && rsiOk && confluence >= 2 {
                if ind.ema9 > prevEma9Last {
                    let freshCross = prevEma21Last <= prevEma50Last && ind.ema21 > ind.ema50
                    let isStrong   = freshCross || (volRatio >= 2.0 && ind.rsi > 55)
                    signals.append(makeS(.maStack, isStrong ? .strong : .moderate))
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
            let retestVol    = volCandle.volume < ind.avgVolume20 * 1.5
            let bullishCandle = lastCandle.close > lastCandle.open

            if breakoutOccurred && inRetestZone && retestVol && bullishCandle,
               ind.rsi > 45, ind.rsi < 65,
               confluence >= 2 {
                let breakoutHadVolume = breakoutCandles.contains {
                    $0.volume > ind.avgVolume20 * 1.8
                }
                signals.append(makeS(.breakoutRetest, breakoutHadVolume && price > ind.ema50 ? .strong : .moderate))
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
            let volOk = volCandle.volume >= ind.avgVolume20 * 0.8

            if inUptrend && (ema21Touch || ema50Touch) && bullCandle && volOk,
               ind.rsi > 38, ind.rsi < 60,
               confluence >= 2 {
                let isStrong = ema50Touch && volRatio >= 1.3 && ind.rsi > 42
                signals.append(makeS(.trendPullback, isStrong ? .strong : .moderate))
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
            let c5_volume     = volCandle.volume > ind.avgVolume20 * 1.2

            let conditionCount = [c1_supertrend, c2_emaAlign, c3_rsi, c4_macd, c5_volume]
                .filter { $0 }.count

            if conditionCount == 5 {
                let prevDir  = stDirs.count >= 2 ? stDirs[stDirs.count - 2] : 0
                let freshSignal = (prevDir == -1 && stDirs.last == 1) ||
                                  (prevEma9Last < ind.ema9 * 0.998)
                let isStrong = freshSignal && volRatio >= 1.5

                signals.append(makeS(.smartMomentum, isStrong ? .strong : .moderate))
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
                        signals.append(makeS(.candlePattern, isStrong ? .strong : .moderate))
                    }
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 13. 52 HAFTA ZİRVESİ KIRILMASI
        // Bir yıllık en yüksek seviyeyi hacim onaylı kıran hisseler
        // Kurumsal yatırımcıların izlediği Stage 2 kırılma kalıbı
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.weeklyBreakout), candles.count >= 200 {
            let lookback = 251
            let yearHigh = candles.suffix(lookback).dropLast().map(\.high).max() ?? 0
            if yearHigh > 0,
               price > yearHigh * 1.002,
               volCandle.volume > ind.avgVolume20 * 1.5,
               ind.rsi > 55, ind.rsi < 78,
               price > ind.ema21,
               price > ind.ema50 {
                signals.append(makeS(.weeklyBreakout, volRatio >= 2.0 && ind.rsi > 60 ? .strong : .moderate))
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 14. VCP KIRILMASI (Volatility Contraction Pattern)
        // Sıkışma + hacim kuruması + 3x patlama — Minervini metodolojisi
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.vcpBreakout), candles.count >= 30 {
            // Bugünkü patlayan mumu hariç tutarak sıkışma dönemini ölç
            let contractCandles = Array(candles.suffix(21).dropLast())
            let shortATR = TechnicalAnalysis.atrArray(candles: Array(contractCandles.suffix(20)), period: 10).last ?? 0
            let baseATR  = TechnicalAnalysis.atrArray(candles: Array(candles.suffix(41).dropLast()), period: 20).last ?? 0
            let atrContracted = baseATR > 0 && shortATR < baseATR * 0.65

            let recent5AvgVol = candles.suffix(6).dropLast().map(\.volume).reduce(0, +) / 5
            let volumeDriedUp = recent5AvgVol < ind.avgVolume20 * 0.70

            let prior20High = candles.suffix(21).dropLast().map(\.high).max() ?? 0
            let breakingOut = price > prior20High * 1.002

            let explosionVol = volCandle.volume > ind.avgVolume20 * 3.0
            let inUptrend    = price > ind.ema21 && price > ind.ema50
            let rsiOk        = ind.rsi > 52 && ind.rsi < 75
            let macdOk       = ind.macdHistogram > 0

            if atrContracted && volumeDriedUp && breakingOut && explosionVol
               && inUptrend && rsiOk && macdOk && confluence >= 3 {
                signals.append(makeS(.vcpBreakout, volRatio >= 4.0 && ind.rsi > 62 ? .strong : .moderate))
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 15. DÜŞEN TREND KIRILMASI
        // Son 30 mumda oluşan alçalan direnç çizgisini hacim onaylı kırar
        // Ayı trendinin sona erdiğinin erken sinyali — taze kırılma anını yakalar
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.descendingBreakout), candles.count >= 35 {
            // Bugünkü (muhtemelen açık) bar hariç son 30 mum üzerinde çalış
            let lookback = Array(candles.dropLast().suffix(30))

            // Pivot yüksek: her iki yanındaki 2 bardan daha yüksek olan tepe
            var pivotHighs: [(idx: Int, high: Double)] = []
            for i in 2..<(lookback.count - 2) {
                let h = lookback[i].high
                if h > lookback[i-1].high && h > lookback[i-2].high &&
                   h > lookback[i+1].high && h > lookback[i+2].high {
                    pivotHighs.append((idx: i, high: h))
                }
            }

            if pivotHighs.count >= 2 {
                let h1 = pivotHighs[pivotHighs.count - 2]   // önceki pivot
                let h2 = pivotHighs[pivotHighs.count - 1]   // son pivot

                // Gerçek alçalan trend: son pivot öncekinden en az %1 düşük
                // ve pivotlar arası en az 5 bar mesafe var
                if h1.high > h2.high * 1.01 && (h2.idx - h1.idx) >= 5 {
                    // Trendline eğimi ve bugünkü projeksiyonu hesapla
                    let slope        = (h2.high - h1.high) / Double(h2.idx - h1.idx)
                    let barsAfterH2  = lookback.count - h2.idx   // h2'den bugüne kaç bar geçti
                    let trendlineNow = h2.high + slope * Double(barsAfterH2)

                    if trendlineNow > 0 {
                        // Önceki bar trendline altındaydı (taze kırılma, eski değil)
                        let prevTrendline = h2.high + slope * Double(barsAfterH2 - 1)
                        let freshBreakout = prevCandle.close <= prevTrendline * 1.01

                        let breakingAbove = price > trendlineNow * 1.005     // %0.5+ üzerinde kırılma
                        let volOk         = volCandle.volume >= ind.avgVolume20 * 1.3
                        let rsiOk         = ind.rsi > 35 && ind.rsi < 62
                        let macdOk        = ind.macdHistogram > 0 || ind.macdLine > ind.macdSignal

                        if freshBreakout && breakingAbove && volOk && rsiOk && macdOk && confluence >= 2 {
                            let isStrong = volRatio >= 2.0 && ind.rsi > 42 && ind.macdHistogram > 0
                            signals.append(makeS(.descendingBreakout, isStrong ? .strong : .moderate))
                        }
                    }
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 16. EC HFT (Kişisel Strateji)
        // SuperTrend boğa + EMA hızlı > EMA yavaş + fiyat > EMA yavaş
        // Parametreler Ayarlar ekranından değiştirilebilir
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.ecHFT) {
            let p    = { let v = UserDefaults.standard.integer(forKey: "ecHFT_atrPeriod"); return v > 0 ? v : 10 }()
            let m    = { let v = UserDefaults.standard.double(forKey: "ecHFT_multiplier"); return v > 0 ? v : 1.5 }()
            let fast = { let v = UserDefaults.standard.integer(forKey: "ecHFT_emaFast");   return v > 0 ? v : 2  }()
            let slow = { let v = UserDefaults.standard.integer(forKey: "ecHFT_emaSlow");   return v > 0 ? v : 17 }()
            let volMult = { let v = UserDefaults.standard.double(forKey: "ecHFT_volMultiplier"); return v > 0 ? v : 1.5 }()
            let useVol  = UserDefaults.standard.object(forKey: "ecHFT_volFilter") == nil
                ? true : UserDefaults.standard.bool(forKey: "ecHFT_volFilter")

            let (_, stDirs)  = TechnicalAnalysis.supertrend(candles: candles, multiplier: m, period: p)
            let emaFastVals  = TechnicalAnalysis.ema(values: allCloses, period: fast)
            let emaSlowVals  = TechnicalAnalysis.ema(values: allCloses, period: slow)

            if let emaFastVal = emaFastVals.last,
               let emaSlowVal = emaSlowVals.last,
               let stDir = stDirs.last {

                let stBullish      = stDir == 1
                let priceAboveSlow = price > emaSlowVal
                let fastAboveSlow  = emaFastVal > emaSlowVal

                // Hacim artışı: ortalamanın volMult katından fazla VE önceki bardan yüksek
                let prevVolBar    = isIncompleteBar ? candles.dropLast(2).last : prevCandle
                let volAboveAvg   = volCandle.volume >= ind.avgVolume20 * volMult
                let volIncreasing = prevVolBar.map { volCandle.volume > $0.volume } ?? true
                let volOk         = !useVol || (volAboveAvg && volIncreasing)

                let prevStDir  = stDirs.count >= 2 ? stDirs[stDirs.count - 2] : 0
                let prevFast   = TechnicalAnalysis.ema(values: prevClosesArr, period: fast).last ?? 0
                let prevSlow   = TechnicalAnalysis.ema(values: prevClosesArr, period: slow).last ?? 0
                let freshST    = prevStDir != 1 && stBullish
                let freshCross = prevFast <= prevSlow && fastAboveSlow

                if stBullish && priceAboveSlow && fastAboveSlow && volOk && (freshST || freshCross) {
                    let isStrong = freshST && freshCross && volRatio >= 1.5
                    signals.append(makeS(.ecHFT, isStrong ? .strong : .moderate))
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 19. TİTAN KIRILIMI — 7 Koşulun Tamamı
        // En nadir, en güçlü kurulum. 6 koşul yetmez, 7 gerekir.
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.titanBreakout) {
            let high20 = candles.suffix(21).dropLast().map(\.high).max() ?? 0

            // ① Taze kırılma
            let breakout = price > high20 * 1.005

            // ② Kurumsal hacim
            let heavyVolume = volRatio >= 2.5

            // ③ EMA tam hizalama
            let emaAligned = ind.ema9 > ind.ema21 && ind.ema21 > ind.ema50

            // ④ MACD pozitif VE önceki bardan yüksek (ivme artıyor)
            let (_, _, prevHistArr) = TechnicalAnalysis.macd(closes: prevClosesArr)
            let prevHist = prevHistArr.last ?? 0
            let macdAccel = ind.macdHistogram > 0 && ind.macdHistogram > prevHist

            // ⑤ RSI tatlı nokta: momentum var ama aşırı alım değil
            let rsiSweet = ind.rsi >= 50 && ind.rsi <= 68

            // ⑥ Güçlü mum kapanışı — günün üst %40'ında
            let range = lastCandle.high - lastCandle.low
            let strongClose = range > 0 && (lastCandle.close - lastCandle.low) / range > 0.60

            // ⑦ Confluence ≥ 3
            let confluenceOk = confluence >= 3

            // 7 koşulun tamamı
            if breakout && heavyVolume && emaAligned && macdAccel && rsiSweet && strongClose && confluenceOk {
                let isStrong = volRatio >= 3.5 && ind.rsi > 55 && confluence >= 4
                signals.append(makeS(.titanBreakout, isStrong ? .strong : .moderate))
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 17. MACD BOĞA KESİŞİMİ — Günlük & 4 Saatlik İçin Optimize Edildi
        //
        // Yalnızca GERÇEK crossover: histogram negatiften pozitife geçti
        // "About to give" kaldırıldı — choppy piyasada çok gürültü üretiyordu
        //
        // Kalite filtresi — 4 ek koşul:
        //   ① Sürdürülmüş negatif: crossover'dan önce en az 4 ardışık negatif bar
        //      (choppy 1-2 bar dip'ten sahte crossover'ları eliyor)
        //   ② EMA21 trendi: fiyat EMA21'in üstünde (boğa bağlamı)
        //   ③ EMA9 > EMA21: kısa vadeli momentum yukarı
        //   ④ Histogram büyüklüğü: ilk pozitif bar anlamlı derinlikte
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.macdBullish) {
            if fullHistArr.count >= 6 {
                let h0 = fullHistArr[fullHistArr.count - 1]
                let h1 = fullHistArr[fullHistArr.count - 2]
                let h2 = fullHistArr[fullHistArr.count - 3]
                let h3 = fullHistArr[fullHistArr.count - 4]
                let h4 = fullHistArr[fullHistArr.count - 5]

                // ① Gerçek crossover — h1 negatif, h0 pozitife geçti
                let crossover = h0 > 0 && h1 < 0

                // ② Sürdürülmüş negatif histogram: h1, h2, h3, h4 hepsi < 0
                //    Gerçek satış dönemi sonrası crossover; 1-2 bar dip'ten sahte değil
                let sustainedNeg = h1 < 0 && h2 < 0 && h3 < 0 && h4 < 0

                // ③ Histogram anlamlı büyüklükte pozitife geçti (gürültü değil)
                //    İlk yeşil bar, son kırmızı barın mutlak değerinin en az %20'si kadar
                let histMomentum = h0 > abs(h1) * 0.2

                // ④ Trend bağlamı: fiyat EMA21 üzerinde, EMA9 > EMA21 (kısa trend yukarı)
                let trendContext = price > ind.ema21 && ind.ema9 > ind.ema21

                // ⑤ RSI tatlı nokta: momentum var ama aşırı alım değil
                let rsiOk = ind.rsi > 42 && ind.rsi < 65

                // ⑥ Hacim onayı — en az ortalama (gürültülü hacimde crossover güvenilmez)
                let volOk = volCandle.volume >= ind.avgVolume20 * 1.0

                if crossover && sustainedNeg && histMomentum && trendContext && rsiOk && volOk {
                    // Güçlü: hacim 1.5x+, RSI 50+, histogram belirgin (fiyatın ‰1'i üstü)
                    let isStrong = volRatio >= 1.5 && ind.rsi > 50 && h0 > price * 0.001
                    signals.append(makeS(.macdBullish, isStrong ? .strong : .moderate))
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 18. ICHİMOKU BULUT ÜSTÜ
        // Fiyat bulut üstü + Tenkan > Kijun + Yeşil bulut + Chikou doğrulaması
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.ichimokuBullish),
           let ichi = TechnicalAnalysis.ichimoku(candles: candles) {

            let cloudTop         = max(ichi.senkouA, ichi.senkouB)
            let aboveCloud       = price > cloudTop
            let tenkanAboveKijun = ichi.tenkan > ichi.kijun
            let greenCloud       = ichi.senkouA > ichi.senkouB
            let rsiOk            = ind.rsi > 42 && ind.rsi < 72
            let volOk            = volCandle.volume >= ind.avgVolume20 * 0.8

            if aboveCloud && tenkanAboveKijun && volOk {
                let isStrong = greenCloud && ichi.chikouAbove && rsiOk && ind.rsi > 50
                signals.append(makeS(.ichimokuBullish, isStrong ? .strong : .moderate))
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // 20. SMA50 ÇEKİLME & KIRILMA
        // Setup A — Çekilme: hareket başlamış hissenin 50G SMA'ya düşük hacimli dönüşü
        // Setup B — Kırılma: uzunca altında kalan hissenin güçlü hacimle SMA50'yi geçmesi
        // ─────────────────────────────────────────────────────────────────
        if enabledStrategies.contains(.sma50Pullback), candles.count >= 60 {
            let sma50 = allCloses.suffix(50).reduce(0,+) / 50.0
            let prevSma50 = prevClosesArr.count >= 50
                ? prevClosesArr.suffix(50).reduce(0,+) / 50.0 : 0.0
            let olderSma50 = Array(allCloses.dropLast(10)).suffix(50).reduce(0,+) / 50.0
            let sma50Rising = sma50 > olderSma50

            if sma50 > 0 && sma50Rising {
                // ── Setup A: Çekilme ──
                let nearSma50   = price >= sma50 * 0.985 && price <= sma50 * 1.02
                let wasAboveSma = prevCandle.close > prevSma50 * 1.01
                let pullbackVol = volCandle.volume < ind.avgVolume20 * 1.2
                let bullishBar  = lastCandle.close > lastCandle.open
                let rsiPullback = ind.rsi > 38 && ind.rsi < 58

                if nearSma50 && wasAboveSma && pullbackVol && bullishBar && rsiPullback && confluence >= 2 {
                    let isStrong = price <= sma50 * 1.008 && ind.rsi > 42
                    signals.append(makeS(.sma50Pullback, isStrong ? .strong : .moderate))
                }
                // ── Setup B: Kırılma ──
                else {
                    let crossedAbove = prevCandle.close <= prevSma50 * 1.005 && price > sma50 * 1.005
                    let breakoutVol  = volCandle.volume >= ind.avgVolume20 * 1.5
                    let rsiBreakout  = ind.rsi > 45 && ind.rsi < 68

                    if crossedAbove && breakoutVol && rsiBreakout && confluence >= 2 {
                        let isStrong = volRatio >= 2.0 && ind.rsi > 52
                        signals.append(makeS(.sma50Pullback, isStrong ? .strong : .moderate))
                    }
                }
            }
        }

        return signals
    }

    private static func make(
        stock: Stock, type: SignalType, strength: SignalStrength,
        timeframe: Timeframe, price: Double, ind: TechnicalIndicators,
        volRatio: Double? = nil, dailyChange: Double? = nil,
        barsAgo: Int? = nil, signalRunup: Double? = nil
    ) -> Signal {
        Signal(
            id: UUID(), stock: stock, type: type, strength: strength,
            timeframe: timeframe, price: price, timestamp: Date(),
            rsi: ind.rsi, macdHistogram: ind.macdHistogram,
            volumeRatio: volRatio, dailyChangePercent: dailyChange,
            barsAgo: barsAgo, signalRunup: signalRunup
        )
    }
}
