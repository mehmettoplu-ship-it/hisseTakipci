import Foundation

enum SignalType: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }
    case resistanceBreakout = "Direnç Kırıldı"
    case oversoldReversal   = "RSI Dip Dönüşü"
    case emaBullishCross    = "EMA Altın Kesişim"
    case goldenCross        = "EMA Altın Haç"
    case bollingerBounce    = "Bollinger Dip Zıplama"
    case squeezeBounce      = "Sıkışma Patlaması"
    case rsiDivergence      = "RSI Boğa Diverjansı"
    case maStack            = "EMA Hizalanması"
    case breakoutRetest     = "Kırılma Geri Testi"
    case trendPullback      = "Trend Desteği"
    case smartMomentum      = "Akıllı Momentum"
    case candlePattern      = "Mum Formasyonu"
    case weeklyBreakout       = "52 Hafta Zirvesi"
    case vcpBreakout          = "VCP Kırılması"
    case descendingBreakout   = "Düşen Trend Kırılması"
    case ecHFT                = "EC HFT"

    var emoji: String {
        switch self {
        case .resistanceBreakout: return "🚀"
        case .oversoldReversal:   return "🔄"
        case .emaBullishCross:    return "⚡"
        case .goldenCross:        return "🌟"
        case .bollingerBounce:    return "🔻"
        case .squeezeBounce:      return "💥"
        case .rsiDivergence:      return "🔀"
        case .maStack:            return "📊"
        case .breakoutRetest:     return "🎯"
        case .trendPullback:      return "↩️"
        case .smartMomentum:      return "🧠"
        case .candlePattern:      return "🕯️"
        case .weeklyBreakout:       return "📈"
        case .vcpBreakout:          return "💎"
        case .descendingBreakout:   return "🔺"
        case .ecHFT:                return "🤖"
        }
    }

    var storageKey: String {
        switch self {
        case .resistanceBreakout: return "strategy_resistanceBreakout"
        case .oversoldReversal:   return "strategy_oversoldReversal"
        case .emaBullishCross:    return "strategy_emaBullishCross"
        case .goldenCross:        return "strategy_goldenCross"
        case .bollingerBounce:    return "strategy_bollingerBounce"
        case .squeezeBounce:      return "strategy_squeezeBounce"
        case .rsiDivergence:      return "strategy_rsiDivergence"
        case .maStack:            return "strategy_maStack"
        case .breakoutRetest:     return "strategy_breakoutRetest"
        case .trendPullback:      return "strategy_trendPullback"
        case .smartMomentum:      return "strategy_smartMomentum"
        case .candlePattern:      return "strategy_candlePattern"
        case .weeklyBreakout:       return "strategy_weeklyBreakout"
        case .vcpBreakout:          return "strategy_vcpBreakout"
        case .descendingBreakout:   return "strategy_descendingBreakout"
        case .ecHFT:                return "strategy_ecHFT"
        }
    }
}

// MARK: - Strateji Açıklamaları

extension SignalType {

    var shortDescription: String {
        switch self {
        case .resistanceBreakout: return "20 günlük zirveyi güçlü hacimle kıran hisseleri tespit eder."
        case .oversoldReversal:   return "RSI 30 altından dönen, boğa mumu + hacim + MACD üçlü teyidiyle dip dönüşlerini yakalar."
        case .emaBullishCross:    return "EMA9'un EMA21'i yukarı kesmesiyle tetiklenen kısa vadeli momentum dönüşü."
        case .goldenCross:        return "EMA21'in EMA50'yi yukarı kesmesi — orta vadeli trend değişikliğinin en güvenilir işareti."
        case .bollingerBounce:    return "Bollinger alt bandına dokunan ve boğa mumu ile dönen hisseleri tespit eder."
        case .squeezeBounce:      return "Düşük volatilite sıkışmasının ardından Bollinger orta bandını kıran patlamaları yakalar."
        case .rsiDivergence:      return "Fiyat yeni dip yaparken RSI'nın daha yüksek dip yapmasını (gizli güç) tespit eder."
        case .maStack:            return "EMA9 > EMA21 > EMA50 mükemmel hizalamasında olan ve yükselen hisseleri tespit eder."
        case .breakoutRetest:     return "Kırılan direnç seviyesini destek olarak test eden ve dönen hisseleri tespit eder."
        case .trendPullback:      return "Yükselen trendde EMA21 veya EMA50 desteğine çekilen ve dönen hisseleri tespit eder."
        case .smartMomentum:      return "5 bağımsız sistemin hepsinin aynı anda boğa sinyali verdiği anları yakalar. En seçici strateji."
        case .candlePattern:      return "Destek bölgesinde oluşan Hammer (Çekiç) veya Bullish Engulfing (Boğa Yutma) formasyonunu tespit eder."
        case .weeklyBreakout:     return "52 haftalık (1 yıllık) en yüksek seviyeyi hacim onayıyla kıran hisseleri tespit eder. Kurumsal yatırımcıların en çok izlediği direnç seviyesi."
        case .vcpBreakout:          return "Sıkışma + hacim kuruması + patlama: Minervini'nin VCP (Volatility Contraction Pattern) stratejisi. En kaliteli, en nadir sinyal."
        case .descendingBreakout:   return "Son 30 mumda oluşan alçalan direnç çizgisini hacim ve MACD onayıyla yukarı kıran hisseleri tespit eder. Ayı trendinin erken sona erme sinyali."
        case .ecHFT:                return "SuperTrend boğa yönünde + EMA hızlı > EMA yavaş + fiyat > EMA yavaş üçlü onayıyla momentum kırılmalarını yakalar. Tüm parametreler ayarlanabilir."
        }
    }

    var conditionsList: [String] {
        switch self {
        case .resistanceBreakout:
            return ["Fiyat 20 günlük zirveden %0.5+ yüksekte kapandı",
                    "Hacim 20 günlük ortalamanın 2x+ üzerinde",
                    "RSI 42–68 arasında (aşırı alım yok)",
                    "Confluence skoru ≥ 2/5"]
        case .oversoldReversal:
            return ["Önceki mumda RSI 30'un altında (aşırı satım bölgesi)",
                    "Son mumda RSI tekrar 30'un üzerine çıktı (dönüş başladı)",
                    "MACD histogramı: önceki mumda negatif, son mumda pozitif",
                    "Dönüş günü boğa mumu: kapanış > açılış (alıcılar hakim)",
                    "Hacim ≥ ortalama × 0.7 (minimum katılım var)",
                    "Fiyat EMA50'nin en az %72'si üzerinde (serbest düşüş değil)",
                    "Confluence skoru ≥ 2/5"]
        case .emaBullishCross:
            return ["Önceki mumda EMA9 < EMA21, son mumda EMA9 > EMA21 (taze kesişim)",
                    "Fiyat EMA50'nin üzerinde (ana trend yukarı)",
                    "RSI 45'in üzerinde",
                    "Hacim ≥ ortalama × 0.9"]
        case .goldenCross:
            return ["Önceki mumda EMA21 ≤ EMA50, son mumda EMA21 > EMA50 (taze kesişim)",
                    "Fiyat EMA21'in üzerinde",
                    "RSI 45–72 arasında",
                    "Hacim ≥ 20 günlük ortalama"]
        case .bollingerBounce:
            return ["Önceki mumun düşüğü Bollinger alt bandında veya altında",
                    "Son mum alt bandın üzerinde kapandı (içe döndü)",
                    "RSI 38'in altında (aşırı satım bölgesi)",
                    "Son mum günün üst yarısında kapandı (güçlü boğa mumu)"]
        case .squeezeBounce:
            return ["Kısa vadeli ATR uzun vadeli ATR'nin %65'inden düşük (sıkışma tespit edildi)",
                    "Fiyat Bollinger orta bandını (20 günlük SMA) yukarı kırdı",
                    "Son mum boğa mumu (kapanış > açılış)",
                    "Hacim 1.2x+, RSI 45–68 arasında"]
        case .rsiDivergence:
            return ["Son 50 mum içinde iki dip noktası tespit edildi",
                    "İkinci (yakın) dip birinciden daha düşük (fiyat yeni dip yaptı)",
                    "İkinci dipte RSI birinciden en az 5 puan yüksek (gizli güç)",
                    "İkinci dipte RSI 52'nin altında",
                    "Min. 50 mum verisi gerekli"]
        case .maStack:
            return ["EMA9 > EMA21 > EMA50 (üçlü boğa hizalanması)",
                    "Fiyat EMA9'un üzerinde",
                    "RSI 50–72 arasında (momentum bölgesi)",
                    "Hacim ≥ ortalama × 0.8",
                    "EMA9 bir önceki mumdan yüksek (ivme var)"]
        case .breakoutRetest:
            return ["Son 10–25 mumda direnç kırılması gerçekleşti (kapanış %0.2+ üstünde)",
                    "Mevcut fiyat eski direnç bölgesinde (±%1.5–2.5 bant içinde)",
                    "Geri çekilmede hacim ortalama × 1.5'ten az (sağlıklı konsolidasyon)",
                    "Son mum boğa mumu, RSI 45–65 arasında"]
        case .trendPullback:
            return ["EMA9 > EMA21 > EMA50 (yükselen trend aktif)",
                    "Fiyat EMA21 ±%1.5 veya EMA50 ±%1.5 bandında (desteğe çekilme)",
                    "Son mum boğa mumu (gövde > %0.3)",
                    "Hacim ≥ ortalama × 0.8, RSI 38–60 arasında"]
        case .smartMomentum:
            return ["SuperTrend (2.0 çarpan, 14 periyot) → boğa yönünde",
                    "EMA9 > EMA21 > EMA50 (üçlü hizalanma)",
                    "RSI 52–68 arasında (momentum bölgesi)",
                    "MACD çizgisi > 0 VE histogram > 0 (sıfır üstünde ivme)",
                    "Hacim 1.2x+ (para girişi var)",
                    "⚠️ 5 koşulun TAMAMI sağlanmalı, 4 yetmez"]
        case .candlePattern:
            return ["Hammer: Alt gölge > toplam aralığın %55'i, gövde < %30, üst gölge < %20",
                    "Bullish Engulfing: Önceki kırmızı mumu tamamen yutan yeşil mum",
                    "Her iki formasyon için RSI < 52 (aşırı alım yok)",
                    "Fiyat EMA21/EMA50 desteği yakınında VEYA Bollinger alt bandı yakınında",
                    "Confluence skoru ≥ 2/5"]
        case .weeklyBreakout:
            return ["Son 250 mumun (1 yıl) en yüksek seviyesinin %0.2+ üzerinde kapanış",
                    "Hacim 20 günlük ortalamanın 1.5 katından fazla",
                    "RSI 55–78 arasında (güçlü momentum, aşırı alım yok)",
                    "Fiyat EMA21 ve EMA50 üzerinde (ana trend yukarı)",
                    "En az 250 mum veri gerekli"]
        case .vcpBreakout:
            return ["ATR sıkışması: kısa ATR, uzun ATR'nin %65'inden düşük",
                    "Hacim kuruması: son 5 bar ort. hacim < genel ort. × 0.70",
                    "Fiyat son 20 mumun en yüksek seviyesini kırdı (taze breakout)",
                    "Patlama hacmi: bugünkü hacim > 20 günlük ort. × 3.0",
                    "Fiyat EMA21 VE EMA50 üzerinde (sağlam uptrend)",
                    "RSI 52–75 arası, MACD histogramı pozitif",
                    "Confluence skoru ≥ 3/5 (diğer stratejilerden daha katı)"]
        case .descendingBreakout:
            return ["Son 30 mumda en az 2 azalan pivot yüksek tespit edildi (alçalan direnç çizgisi)",
                    "Pivot yüksekler arası fark ≥ %1 (gerçek düşüş trendi)",
                    "Fiyat hesaplanan trendline'ın %0.5+ üzerinde kapandı",
                    "Önceki mum trendline altındaydı (taze kırılma — eski değil)",
                    "Hacim ≥ ortalama × 1.3 (kırılma hacim onaylı)",
                    "RSI 35–62 arası (toparlanıyor, aşırı alım yok)",
                    "MACD pozitif veya yükseliyor, Confluence ≥ 2/5"]
        case .ecHFT:
            return ["SuperTrend (ATR periyodu ve çarpan Ayarlar'dan değiştirilebilir) → boğa yönünde",
                    "Fiyat EMA Yavaş (varsayılan 17) üzerinde",
                    "EMA Hızlı (varsayılan 2) > EMA Yavaş: kısa vadeli momentum pozitif",
                    "Taze sinyal: SuperTrend yeni boğaya döndü VEYA EMA hızlı yavazı yukarı kesti",
                    "Hacim filtresi etkinse: hacim > ortalama × 1.2 (para girişi var)",
                    "Parametreler: ATR periyodu, çarpan, EMA hızlı/yavaş, hacim filtresi, stop %, breakeven %"]
        }
    }

    var strategyLogic: String {
        switch self {
        case .resistanceBreakout:
            return "Direnç kırılması gerçekse yüksek hacimle desteklenir. Düşük hacimli kırılmalar genellikle başarısız olup geri döner. 2x hacim şartı sahte kırılmaları filtreler, RSI üst sınırı ise aşırı alınmış hisseleri dışarıda bırakır."
        case .oversoldReversal:
            return "Tek başına RSI'nın 30 altına girmesi yeterli değildir — hisse daha da düşebilir. Bu strateji RSI dönüşünü, MACD teyidini, boğa mumunu ve minimum hacim katılımını birden bekler. Dönüş gününün yeşil kapanması alıcıların sahaya çıktığını, EMA50 mesafe filtresi ise kopuk bir trendin değil düzeltilebilir bir aşırı satımın sinyali olduğunu garanti eder."
        case .emaBullishCross:
            return "EMA9/21 kesişimi kısa vadeli momentumun döndüğünü gösterir. Fiyatın EMA50 üzerinde olması şartı, bu kesişimin yükselen ana trend içinde gerçekleştiğini teyit eder. Trende karşı kesişimler çok daha az güvenilirdir."
        case .goldenCross:
            return "Klasik 'Altın Haç' formasyonu. EMA9/21 kesişimine göre çok daha yavaş gerçekleşir, bu yüzden gürültü azdır. Orta-uzun vadeli trend değişikliklerini işaret eder. Ters yöndeki 'Ölüm Haçı' (EMA21 aşağı kesiyor) bu strateji tarafından aranmaz."
        case .bollingerBounce:
            return "Bollinger alt bandı fiyatın istatistiksel normdan uzaklaştığını gösterir. Üç şartın birden sağlanması gerekir: alt banda dokunmak, güçlü boğa mumu oluşmak ve RSI'nın aşırı satım bölgesinde olmak. Tek başına herhangi biri yeterli değildir."
        case .squeezeBounce:
            return "Piyasalar dönemsel olarak 'nefes alır': yüksek volatilitenin ardından düşük volatilite (sıkışma) gelir ve sıkışmanın ardından yeni bir büyük hareket başlar. ATR ile ölçülen sıkışma 'yay gerilmesi', kırılma ise 'yayın fırlatılması'dır."
        case .rsiDivergence:
            return "Fiyat aşağı giderken RSI'nın aşağı gitmemesi satış baskısının 'yorulduğunu' gösterir — alıcılar giderek güçleniyor. Bu 'gizli güç' sinyali genellikle düşüşlerin sonunda ortaya çıkar ve trend dönüşünden önce gelir."
        case .maStack:
            return "Üç farklı vadeli EMA'nın aynı yönde (yukarı) olması sürdürülebilir bir trendin göstergesidir. Bu 'mükemmel boğa dizilimi' kalıbı güçlü yükselişlerde karakteristik olarak görülür ve trend devam ederken alım fırsatı sunar."
        case .breakoutRetest:
            return "'Direnç kırılır, destek olur.' Teknik analizin temel prensibi. Kırılma anında girmek risklidir (sahte kırılma olabilir). İdeal giriş, eski direncin destek gibi davranmasının teyit edildiği geri test noktasıdır."
        case .trendPullback:
            return "Trend devam ederken her EMA desteğine çekilme potansiyel giriş noktasıdır. EMA50'ye çekilme daha derin olduğundan daha güçlü bir fırsat sayılır. Boğa mumu şartı desteğin tuttuğunu ve alıcıların devreye girdiğini teyit eder."
        case .smartMomentum:
            return "SuperTrend, EMA dizilimi, RSI, MACD ve hacim — 5 bağımsız sistem, farklı matematiksel yaklaşımlar. Hepsinin aynı anda 'al' demesi rastlantı değildir. Sinyal üretimi çok seyrektir ama kalitesi çok yüksektir."
        case .candlePattern:
            return "Mum formasyonları fiyatın anlık hikayesini anlatır: alıcılar mı satıcılar mı galip geldi? Hammer'da uzun alt gölge 'satıcılar baskı yaptı ama alıcılar geri aldı' demektir. Bullish Engulfing'de büyük yeşil mumun kırmızıyı tamamen yutması ani güç değişimini gösterir. İkisi de destek bölgesinde gerçekleşirse anlam kazanır."
        case .weeklyBreakout:
            return "52 haftalık zirve yalnızca teknik bir seviye değil, psikolojik bir engel. Bir yıldır bu seviyenin üzerine çıkamayan hisse aniden büyük hacimle geçiyorsa kurumsal alıcılar devreye girmiş demektir. Mark Minervini ve IBD (Investor's Business Daily) bu formasyonu 'Stage 2 Breakout' olarak tanımlar ve tarihin en büyük rallilerinin büyük çoğunluğu bu kalıpla başlamıştır."
        case .vcpBreakout:
            return "Minervini'nin VCP metodolojisi: her sıkışma dönemi kurumların sessizce birikim yaptığı zamandır. Hacim kuruyorsa satıcılar tükeniyor demektir. Sıkışmanın ardından 3x+ hacimli patlama = akıllı para alımı. Bu kombinasyonun sinyali çok nadiren tetiklenir ama tetiklendiğinde harekete geçmeye değer."
        case .descendingBreakout:
            return "Düşen trendde her mum bir öncekinin zirvesini geçemez — bu 'alçalan direnç' çizgisi oluşturur. Fiyat bu çizgiyi hacimle geçtiğinde satıcıların tükendiğini ve alıcıların kontrolü devraldığını gösterir. RSI'nın 35+ olması bazı alıcıların zaten harekete geçtiğini, MACD teyidi ise momentumun döndüğünü teyit eder. Bu strateji ayı trendinin erken kırıldığı anı yakalar."
        case .ecHFT:
            return "TradingView'de kişisel olarak kullanılan 'EC HFT Full Pro' stratejisinin Swift uyarlaması. SuperTrend trend yönünü belirler (boğa/ayı), EMA hızlı/yavaş kesişimi kısa vadeli momentumu teyit eder, hacim filtresi ise kurumsal girişin varlığını doğrular. Üç koşulun aynı anda sağlanması gereksiz gürültüyü filtreler. Taze sinyal şartı (yeni dönüş veya taze kesişim) eski sinyallerin tekrar tetiklenmesini önler. Tüm parametreler Ayarlar ekranından kişiselleştirilebilir."
        }
    }

    var strongSignalCriteria: String {
        switch self {
        case .resistanceBreakout: return "Hacim 3x veya daha fazlaysa Güçlü, 2–3x arası Orta."
        case .oversoldReversal:   return "RSI 24'ün altından döndü VE hacim 1.2x+ ise Güçlü. Aksi halde Orta."
        case .emaBullishCross:    return "Hacim 1.5x+ VE RSI 52 üzerindeyse Güçlü, aksi halde Orta."
        case .goldenCross:        return "Hacim 1.5x+ VE RSI 52 üzerindeyse Güçlü, aksi halde Orta."
        case .bollingerBounce:    return "RSI 30'un altındaysa Güçlü (çok derin aşırı satım), 30–38 arası Orta."
        case .squeezeBounce:      return "Hacim 2x veya daha fazlaysa Güçlü, 1.2–2x arası Orta."
        case .rsiDivergence:      return "RSI farkı 12+ puan ise Güçlü, 5–11 puan arası Orta."
        case .maStack:            return "Taze EMA21/50 kesişimi VEYA (Hacim 2x+ VE RSI 55+) → Güçlü."
        case .breakoutRetest:     return "Orijinal kırılmada yüksek hacim (1.8x+) VE fiyat EMA50 üzerindeyse Güçlü."
        case .trendPullback:      return "EMA50'ye dokunuş VE Hacim 1.3x+ VE RSI 42+ → Güçlü. EMA21'e dokunuş → Orta."
        case .smartMomentum:      return "SuperTrend yeni döndü veya EMA9 hızlanıyor VE Hacim 1.5x+ → Güçlü."
        case .candlePattern:      return "Bullish Engulfing ve mum gövdesi önceki mumun 2x+ büyüklüğünde VE Hacim 1.5x+ → Güçlü. Hammer ve alt gölge > 3x gövde VE EMA50 yakınında → Güçlü."
        case .weeklyBreakout:     return "Hacim 2x+ VE RSI 60+ → Güçlü. 1.5–2x hacim ve RSI 55–60 → Orta."
        case .vcpBreakout:          return "Hacim 4x+ VE RSI 62+ → Güçlü. 3–4x hacim arası → Orta."
        case .descendingBreakout:   return "Hacim 2x+ VE RSI 42+ VE MACD histogramı pozitif → Güçlü. Aksi halde Orta."
        case .ecHFT:                return "SuperTrend yeni döndü VE EMA kesişimi aynı anda gerçekleşti VE hacim 1.5x+ → Güçlü. Aksi halde → Orta."
        }
    }

    var firingFrequency: String {
        switch self {
        case .resistanceBreakout: return "Seyrek"
        case .oversoldReversal:   return "Orta Sıklıkta"
        case .emaBullishCross:    return "Orta Sıklıkta"
        case .goldenCross:        return "Seyrek"
        case .bollingerBounce:    return "Orta Sıklıkta"
        case .squeezeBounce:      return "Seyrek"
        case .rsiDivergence:      return "Seyrek"
        case .maStack:            return "Orta Sıklıkta"
        case .breakoutRetest:     return "Seyrek"
        case .trendPullback:      return "Orta Sıklıkta"
        case .smartMomentum:      return "Seyrek"
        case .candlePattern:      return "Orta Sıklıkta"
        case .weeklyBreakout:     return "Seyrek"
        case .vcpBreakout:          return "Çok Seyrek"
        case .descendingBreakout:   return "Orta Sıklıkta"
        case .ecHFT:                return "Orta Sıklıkta"
        }
    }
}

enum SignalStrength: String, Codable {
    case strong   = "Güçlü"
    case moderate = "Orta"
    case weak     = "Zayıf"

    var color: String {
        switch self {
        case .strong:   return "green"
        case .moderate: return "orange"
        case .weak:     return "gray"
        }
    }
}

struct Signal: Identifiable, Codable {
    let id: UUID
    let stock: Stock
    let type: SignalType
    let strength: SignalStrength
    let timeframe: Timeframe
    let price: Double
    let timestamp: Date
    let rsi: Double?
    let macdHistogram: Double?
    let volumeRatio: Double?
    let dailyChangePercent: Double?

    var notificationTitle: String {
        "\(stock.symbol) — \(type.rawValue) (\(timeframe.displayName))"
    }

    var notificationBody: String {
        var parts: [String] = ["Fiyat: \(String(format: "%.2f", price)) ₺"]
        if let rsi { parts.append("RSI: \(String(format: "%.1f", rsi))") }
        if let vr = volumeRatio { parts.append("Hacim: \(String(format: "%.1f", vr))x") }
        return parts.joined(separator: " | ")
    }
}
