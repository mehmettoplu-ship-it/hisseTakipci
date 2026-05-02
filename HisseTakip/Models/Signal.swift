import Foundation

enum SignalType: String, Codable, CaseIterable {
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
        }
    }
}

// MARK: - Strateji Açıklamaları

extension SignalType {

    var shortDescription: String {
        switch self {
        case .resistanceBreakout: return "20 günlük zirveyi güçlü hacimle kıran hisseleri tespit eder."
        case .oversoldReversal:   return "RSI 28 altından dönen ve MACD'nin de teyit ettiği dipleri yakalar."
        case .emaBullishCross:    return "EMA9'un EMA21'i yukarı kesmesiyle tetiklenen kısa vadeli momentum dönüşü."
        case .goldenCross:        return "EMA21'in EMA50'yi yukarı kesmesi — orta vadeli trend değişikliğinin en güvenilir işareti."
        case .bollingerBounce:    return "Bollinger alt bandına dokunan ve boğa mumu ile dönen hisseleri tespit eder."
        case .squeezeBounce:      return "Düşük volatilite sıkışmasının ardından Bollinger orta bandını kıran patlamaları yakalar."
        case .rsiDivergence:      return "Fiyat yeni dip yaparken RSI'nın daha yüksek dip yapmasını (gizli güç) tespit eder."
        case .maStack:            return "EMA9 > EMA21 > EMA50 mükemmel hizalamasında olan ve yükselen hisseleri tespit eder."
        case .breakoutRetest:     return "Kırılan direnç seviyesini destek olarak test eden ve dönen hisseleri tespit eder."
        case .trendPullback:      return "Yükselen trendde EMA21 veya EMA50 desteğine çekilen ve dönen hisseleri tespit eder."
        case .smartMomentum:      return "5 bağımsız sistemin hepsinin aynı anda boğa sinyali verdiği anları yakalar. En seçici strateji."
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
            return ["Önceki mumda RSI 28'in altında (derin aşırı satım)",
                    "Son mumda RSI tekrar 28'in üzerine çıktı (dönüş)",
                    "MACD histogramı: önceki mumda negatif, son mumda pozitif",
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
        }
    }

    var strategyLogic: String {
        switch self {
        case .resistanceBreakout:
            return "Direnç kırılması gerçekse yüksek hacimle desteklenir. Düşük hacimli kırılmalar genellikle başarısız olup geri döner. 2x hacim şartı sahte kırılmaları filtreler, RSI üst sınırı ise aşırı alınmış hisseleri dışarıda bırakır."
        case .oversoldReversal:
            return "Tek başına RSI'nın 30 altına girmesi yeterli değildir — hisse daha da düşebilir. Bu strateji RSI dönüşünü VE MACD teyidini birden bekler. İki bağımsız göstergenin aynı anda dönüş sinyali vermesi güvenilirliği önemli ölçüde artırır."
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
        }
    }

    var strongSignalCriteria: String {
        switch self {
        case .resistanceBreakout: return "Hacim 3x veya daha fazlaysa Güçlü, 2–3x arası Orta."
        case .oversoldReversal:   return "RSI 24'ün altından döndüyse Güçlü (çok derin dip), 28'den döndüyse Orta."
        case .emaBullishCross:    return "Hacim 1.5x+ VE RSI 52 üzerindeyse Güçlü, aksi halde Orta."
        case .goldenCross:        return "Hacim 1.5x+ VE RSI 52 üzerindeyse Güçlü, aksi halde Orta."
        case .bollingerBounce:    return "RSI 30'un altındaysa Güçlü (çok derin aşırı satım), 30–38 arası Orta."
        case .squeezeBounce:      return "Hacim 2x veya daha fazlaysa Güçlü, 1.2–2x arası Orta."
        case .rsiDivergence:      return "RSI farkı 12+ puan ise Güçlü, 5–11 puan arası Orta."
        case .maStack:            return "Taze EMA21/50 kesişimi VEYA (Hacim 2x+ VE RSI 55+) → Güçlü."
        case .breakoutRetest:     return "Orijinal kırılmada yüksek hacim (1.8x+) VE fiyat EMA50 üzerindeyse Güçlü."
        case .trendPullback:      return "EMA50'ye dokunuş VE Hacim 1.3x+ VE RSI 42+ → Güçlü. EMA21'e dokunuş → Orta."
        case .smartMomentum:      return "SuperTrend yeni döndü veya EMA9 hızlanıyor VE Hacim 1.5x+ → Güçlü."
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
