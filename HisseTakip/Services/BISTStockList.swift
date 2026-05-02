import Foundation

enum BISTStockList {

    static let all: [Stock] = [

        // MARK: - Bankacılık
        Stock(id: "AKBNK.IS", symbol: "AKBNK", name: "Akbank",               sector: "Bankacılık"),
        Stock(id: "GARAN.IS", symbol: "GARAN", name: "Garanti BBVA",         sector: "Bankacılık"),
        Stock(id: "HALKB.IS", symbol: "HALKB", name: "Halkbank",             sector: "Bankacılık"),
        Stock(id: "ISCTR.IS", symbol: "ISCTR", name: "İş Bankası C",         sector: "Bankacılık"),
        Stock(id: "VAKBN.IS", symbol: "VAKBN", name: "Vakıfbank",            sector: "Bankacılık"),
        Stock(id: "YKBNK.IS", symbol: "YKBNK", name: "Yapı Kredi",          sector: "Bankacılık"),
        Stock(id: "QNBFB.IS", symbol: "QNBFB", name: "QNB Finansbank",      sector: "Bankacılık"),
        Stock(id: "ALBRK.IS", symbol: "ALBRK", name: "Albaraka Türk",        sector: "Bankacılık"),
        Stock(id: "TSKB.IS",  symbol: "TSKB",  name: "TSKB",                sector: "Bankacılık"),
        Stock(id: "SKBNK.IS", symbol: "SKBNK", name: "Şekerbank",           sector: "Bankacılık"),
        Stock(id: "ICBCT.IS", symbol: "ICBCT", name: "ICBC Turkey",          sector: "Bankacılık"),
        Stock(id: "BURCE.IS", symbol: "BURCE", name: "Burgan Bank",          sector: "Bankacılık"),
        Stock(id: "ISBTR.IS", symbol: "ISBTR", name: "İş Bankası B",         sector: "Bankacılık"),
        Stock(id: "KUOTK.IS", symbol: "KUOTK", name: "Kuveyt Türk",         sector: "Bankacılık"),

        // MARK: - Holding
        Stock(id: "KCHOL.IS", symbol: "KCHOL", name: "Koç Holding",          sector: "Holding"),
        Stock(id: "SAHOL.IS", symbol: "SAHOL", name: "Sabancı Holding",      sector: "Holding"),
        Stock(id: "DOHOL.IS", symbol: "DOHOL", name: "Doğan Holding",        sector: "Holding"),
        Stock(id: "GLYHO.IS", symbol: "GLYHO", name: "Global Yatırım H.",   sector: "Holding"),
        Stock(id: "YAZIC.IS", symbol: "YAZIC", name: "Yazıcılar Holding",    sector: "Holding"),
        Stock(id: "TKFEN.IS", symbol: "TKFEN", name: "Tekfen Holding",       sector: "Holding"),
        Stock(id: "AGHOL.IS", symbol: "AGHOL", name: "AG Anadolu Grubu",    sector: "Holding"),
        Stock(id: "ALARK.IS", symbol: "ALARK", name: "Alarko Holding",       sector: "Holding"),
        Stock(id: "BERA.IS",  symbol: "BERA",  name: "Bera Holding",         sector: "Holding"),
        Stock(id: "GOZDE.IS", symbol: "GOZDE", name: "Gözde Girişim",       sector: "Holding"),
        Stock(id: "NTHOL.IS", symbol: "NTHOL", name: "Net Holding",          sector: "Holding"),
        Stock(id: "POLHO.IS", symbol: "POLHO", name: "Polisan Holding",      sector: "Holding"),
        Stock(id: "ITTFK.IS", symbol: "ITTFK", name: "İttifak Holding",     sector: "Holding"),
        Stock(id: "IHLAS.IS", symbol: "IHLAS", name: "İhlas Holding",        sector: "Holding"),
        Stock(id: "KTLEV.IS", symbol: "KTLEV", name: "KT Levent",            sector: "Holding"),

        // MARK: - Havacılık & Ulaşım
        Stock(id: "THYAO.IS", symbol: "THYAO", name: "Türk Hava Yolları",   sector: "Havacılık"),
        Stock(id: "PGSUS.IS", symbol: "PGSUS", name: "Pegasus",              sector: "Havacılık"),
        Stock(id: "TAVHL.IS", symbol: "TAVHL", name: "TAV Havalimanları",   sector: "Havacılık"),
        Stock(id: "HAVAS.IS", symbol: "HAVAS", name: "Havaş",               sector: "Havacılık"),
        Stock(id: "CLEBI.IS", symbol: "CLEBI", name: "Çelebi Havacılık",    sector: "Havacılık"),
        Stock(id: "UCAK.IS",  symbol: "UCAK",  name: "Uçak Servisi",        sector: "Havacılık"),

        // MARK: - Savunma & Teknoloji
        Stock(id: "ASELS.IS", symbol: "ASELS", name: "Aselsan",              sector: "Savunma"),
        Stock(id: "KATMR.IS", symbol: "KATMR", name: "Katmerciler",          sector: "Savunma"),
        Stock(id: "LOGO.IS",  symbol: "LOGO",  name: "Logo Yazılım",         sector: "Teknoloji"),
        Stock(id: "ALCTL.IS", symbol: "ALCTL", name: "Alcatel Lucent",       sector: "Teknoloji"),
        Stock(id: "NETAS.IS", symbol: "NETAS", name: "Netaş",               sector: "Teknoloji"),
        Stock(id: "INDES.IS", symbol: "INDES", name: "İndeks Bilgisayar",   sector: "Teknoloji"),
        Stock(id: "KAREL.IS", symbol: "KAREL", name: "Karel Elektronik",     sector: "Teknoloji"),
        Stock(id: "LINK.IS",  symbol: "LINK",  name: "Link Bilgisayar",      sector: "Teknoloji"),
        Stock(id: "VBTYZ.IS", symbol: "VBTYZ", name: "VBT Yazılım",         sector: "Teknoloji"),
        Stock(id: "ESCOM.IS", symbol: "ESCOM", name: "Escort Teknoloji",     sector: "Teknoloji"),
        Stock(id: "DGATE.IS", symbol: "DGATE", name: "Datagate",             sector: "Teknoloji"),
        Stock(id: "PRKME.IS", symbol: "PRKME", name: "Park Elektrik",        sector: "Teknoloji"),
        Stock(id: "KRONT.IS", symbol: "KRONT", name: "Kronos",               sector: "Teknoloji"),
        Stock(id: "MIATK.IS", symbol: "MIATK", name: "Mia Teknoloji",        sector: "Teknoloji"),
        Stock(id: "BORSK.IS", symbol: "BORSK", name: "Borska",               sector: "Teknoloji"),
        Stock(id: "OBASE.IS", symbol: "OBASE", name: "Obase Bilgisayar",     sector: "Teknoloji"),

        // MARK: - Enerji
        Stock(id: "TUPRS.IS", symbol: "TUPRS", name: "Tüpraş",              sector: "Enerji"),
        Stock(id: "AKSEN.IS", symbol: "AKSEN", name: "Aksa Enerji",          sector: "Enerji"),
        Stock(id: "ZOREN.IS", symbol: "ZOREN", name: "Zorlu Enerji",         sector: "Enerji"),
        Stock(id: "ODAS.IS",  symbol: "ODAS",  name: "Odaş Elektrik",       sector: "Enerji"),
        Stock(id: "AYEN.IS",  symbol: "AYEN",  name: "Ayen Enerji",          sector: "Enerji"),
        Stock(id: "ONRYT.IS", symbol: "ONRYT", name: "Onur Enerji",          sector: "Enerji"),
        Stock(id: "ORGE.IS",  symbol: "ORGE",  name: "Orge Enerji",          sector: "Enerji"),
        Stock(id: "AKENR.IS", symbol: "AKENR", name: "Ak Enerji",            sector: "Enerji"),
        Stock(id: "BIOEN.IS", symbol: "BIOEN", name: "Bio Enerji",           sector: "Enerji"),
        Stock(id: "GWIND.IS", symbol: "GWIND", name: "Galata Wind",          sector: "Enerji"),
        Stock(id: "EUPWR.IS", symbol: "EUPWR", name: "European Power",       sector: "Enerji"),
        Stock(id: "NATEN.IS", symbol: "NATEN", name: "Naturel Enerji",       sector: "Enerji"),
        Stock(id: "TUREX.IS", symbol: "TUREX", name: "Türkerler Enerji",    sector: "Enerji"),
        Stock(id: "KCAER.IS", symbol: "KCAER", name: "KC Enerji",            sector: "Enerji"),
        Stock(id: "SMRTG.IS", symbol: "SMRTG", name: "Smart Güneş",         sector: "Enerji"),
        Stock(id: "AYGAZ.IS", symbol: "AYGAZ", name: "Aygaz",               sector: "Enerji"),
        Stock(id: "PETKM.IS", symbol: "PETKM", name: "Petkim",               sector: "Enerji"),
        Stock(id: "IEDAS.IS", symbol: "IEDAS", name: "İED AŞ",              sector: "Enerji"),
        Stock(id: "ALFAS.IS", symbol: "ALFAS", name: "Alfa Solar",           sector: "Enerji"),
        Stock(id: "SANKO.IS", symbol: "SANKO", name: "Sanko Güneş",         sector: "Enerji"),

        // MARK: - Petrokimya & Kimya
        Stock(id: "AKSA.IS",  symbol: "AKSA",  name: "Aksa Akrilik",         sector: "Kimya"),
        Stock(id: "SASA.IS",  symbol: "SASA",  name: "Sasa Polyester",       sector: "Kimya"),
        Stock(id: "GUBRF.IS", symbol: "GUBRF", name: "Gübre Fabrikaları",    sector: "Kimya"),
        Stock(id: "ALKIM.IS", symbol: "ALKIM", name: "Alkim Kimya",          sector: "Kimya"),
        Stock(id: "HEKTS.IS", symbol: "HEKTS", name: "Hektaş",              sector: "Kimya"),
        Stock(id: "EGGUB.IS", symbol: "EGGUB", name: "Ege Gübre",           sector: "Kimya"),
        Stock(id: "EPLAS.IS", symbol: "EPLAS", name: "Ege Plastik",          sector: "Kimya"),
        Stock(id: "BAGFS.IS", symbol: "BAGFS", name: "Bağfaş",              sector: "Kimya"),
        Stock(id: "CANTE.IS", symbol: "CANTE", name: "Can Tarım",            sector: "Kimya"),
        Stock(id: "EGEEN.IS", symbol: "EGEEN", name: "Ege Endüstri",        sector: "Kimya"),
        Stock(id: "KLMSN.IS", symbol: "KLMSN", name: "Klimasan",             sector: "Kimya"),

        // MARK: - İlaç & Sağlık
        Stock(id: "ECILC.IS", symbol: "ECILC", name: "Eczacıbaşı İlaç",    sector: "İlaç"),
        Stock(id: "ECZYT.IS", symbol: "ECZYT", name: "Eczacıbaşı Yatırım", sector: "İlaç"),
        Stock(id: "SELEC.IS", symbol: "SELEC", name: "Selçuk Ecza",         sector: "İlaç"),
        Stock(id: "DEVA.IS",  symbol: "DEVA",  name: "Deva Holding",         sector: "İlaç"),
        Stock(id: "RTALB.IS", symbol: "RTALB", name: "Rotor Alüminyum",     sector: "İlaç"),
        Stock(id: "MPARK.IS", symbol: "MPARK", name: "MLP Care",             sector: "Sağlık"),

        // MARK: - Otomotiv & Lastik
        Stock(id: "FROTO.IS", symbol: "FROTO", name: "Ford Otosan",          sector: "Otomotiv"),
        Stock(id: "TOASO.IS", symbol: "TOASO", name: "Tofaş",               sector: "Otomotiv"),
        Stock(id: "TTRAK.IS", symbol: "TTRAK", name: "Türk Traktör",        sector: "Otomotiv"),
        Stock(id: "OTKAR.IS", symbol: "OTKAR", name: "Otokar",               sector: "Otomotiv"),
        Stock(id: "DOAS.IS",  symbol: "DOAS",  name: "Doğuş Otomotiv",      sector: "Otomotiv"),
        Stock(id: "ASUZU.IS", symbol: "ASUZU", name: "Anadolu Isuzu",       sector: "Otomotiv"),
        Stock(id: "KARSN.IS", symbol: "KARSN", name: "Karsan",               sector: "Otomotiv"),
        Stock(id: "BRYAT.IS", symbol: "BRYAT", name: "Borusan Otomotiv",    sector: "Otomotiv"),
        Stock(id: "MUTLU.IS", symbol: "MUTLU", name: "Mutlu Akü",           sector: "Otomotiv"),
        Stock(id: "JANTS.IS", symbol: "JANTS", name: "Jantsa Jant",         sector: "Otomotiv"),
        Stock(id: "BRISA.IS", symbol: "BRISA", name: "Brisa",               sector: "Lastik"),
        Stock(id: "GOODY.IS", symbol: "GOODY", name: "Goodyear",             sector: "Lastik"),

        // MARK: - Beyaz Eşya & Elektronik
        Stock(id: "ARCLK.IS", symbol: "ARCLK", name: "Arçelik",             sector: "Beyaz Eşya"),
        Stock(id: "VESTL.IS", symbol: "VESTL", name: "Vestel",               sector: "Elektronik"),
        Stock(id: "VESBE.IS", symbol: "VESBE", name: "Vestel Beyaz Eşya",  sector: "Beyaz Eşya"),
        Stock(id: "IHEVA.IS", symbol: "IHEVA", name: "İhlas Ev Aletleri",   sector: "Beyaz Eşya"),

        // MARK: - Demir-Çelik & Metal
        Stock(id: "EREGL.IS", symbol: "EREGL", name: "Ereğli Demir Çelik", sector: "Demir-Çelik"),
        Stock(id: "KRDMD.IS", symbol: "KRDMD", name: "Kardemir D",          sector: "Demir-Çelik"),
        Stock(id: "KRDMB.IS", symbol: "KRDMB", name: "Kardemir B",          sector: "Demir-Çelik"),
        Stock(id: "IZMDC.IS", symbol: "IZMDC", name: "İzmir Demir Çelik",  sector: "Demir-Çelik"),
        Stock(id: "BRSAN.IS", symbol: "BRSAN", name: "Borusan Mannesmann",  sector: "Metal"),
        Stock(id: "CELHA.IS", symbol: "CELHA", name: "Çelik Halat",        sector: "Metal"),
        Stock(id: "SARKY.IS", symbol: "SARKY", name: "Sarkuysan",           sector: "Metal"),
        Stock(id: "EMKEL.IS", symbol: "EMKEL", name: "Emek Elektrik",       sector: "Metal"),
        Stock(id: "PARSN.IS", symbol: "PARSN", name: "Parsan",              sector: "Metal"),
        Stock(id: "DITAS.IS", symbol: "DITAS", name: "Ditaş",              sector: "Metal"),
        Stock(id: "CEMAS.IS", symbol: "CEMAS", name: "Çemaş Döküm",        sector: "Metal"),
        Stock(id: "PRKAB.IS", symbol: "PRKAB", name: "Türk Prysmian Kablo", sector: "Metal"),

        // MARK: - Cam & Seramik
        Stock(id: "SISE.IS",  symbol: "SISE",  name: "Şişe Cam",           sector: "Cam"),
        Stock(id: "TRKCM.IS", symbol: "TRKCM", name: "Trakya Cam",          sector: "Cam"),
        Stock(id: "ANACM.IS", symbol: "ANACM", name: "Anadolu Cam",         sector: "Cam"),

        // MARK: - Çimento & İnşaat Malz.
        Stock(id: "CIMSA.IS", symbol: "CIMSA", name: "Çimsa",              sector: "Çimento"),
        Stock(id: "AKCNS.IS", symbol: "AKCNS", name: "Akçansa",            sector: "Çimento"),
        Stock(id: "ADANA.IS", symbol: "ADANA", name: "Adana Çimento A",    sector: "Çimento"),
        Stock(id: "ADNAC.IS", symbol: "ADNAC", name: "Adana Çimento C",    sector: "Çimento"),
        Stock(id: "GOLTS.IS", symbol: "GOLTS", name: "Göltaş Çimento",    sector: "Çimento"),
        Stock(id: "BOLUC.IS", symbol: "BOLUC", name: "Bolu Çimento",       sector: "Çimento"),
        Stock(id: "BSOKE.IS", symbol: "BSOKE", name: "Batısöke Çimento",  sector: "Çimento"),
        Stock(id: "MRDIN.IS", symbol: "MRDIN", name: "Mardin Çimento",     sector: "Çimento"),
        Stock(id: "NUHCM.IS", symbol: "NUHCM", name: "Nuh Çimento",       sector: "Çimento"),
        Stock(id: "UNYEC.IS", symbol: "UNYEC", name: "Ünye Çimento",      sector: "Çimento"),
        Stock(id: "BTCIM.IS", symbol: "BTCIM", name: "Batı Çimento",      sector: "Çimento"),
        Stock(id: "AFKUR.IS", symbol: "AFKUR", name: "Afyon Çimento",     sector: "Çimento"),
        Stock(id: "KONYA.IS", symbol: "KONYA", name: "Konya Çimento",     sector: "Çimento"),
        Stock(id: "BUCIM.IS", symbol: "BUCIM", name: "Bursa Çimento",     sector: "Çimento"),
        Stock(id: "OYAKC.IS", symbol: "OYAKC", name: "Oyak Çimento",      sector: "Çimento"),
        Stock(id: "ASLAN.IS", symbol: "ASLAN", name: "Aslan Çimento",     sector: "Çimento"),
        Stock(id: "EGPRO.IS", symbol: "EGPRO", name: "Ege Profil",        sector: "Çimento"),
        Stock(id: "IZOCM.IS", symbol: "IZOCM", name: "İzocam",            sector: "İnşaat"),

        // MARK: - GYO & İnşaat
        Stock(id: "EKGYO.IS", symbol: "EKGYO", name: "Emlak Konut GYO",   sector: "GYO"),
        Stock(id: "ISGYO.IS", symbol: "ISGYO", name: "İş GYO",            sector: "GYO"),
        Stock(id: "TRGYO.IS", symbol: "TRGYO", name: "Torunlar GYO",      sector: "GYO"),
        Stock(id: "SNGYO.IS", symbol: "SNGYO", name: "Sinpaş GYO",        sector: "GYO"),
        Stock(id: "HLGYO.IS", symbol: "HLGYO", name: "Halk GYO",          sector: "GYO"),
        Stock(id: "VAKGYO.IS",symbol: "VAKGYO",name: "Vakıf GYO",         sector: "GYO"),
        Stock(id: "SRVGY.IS", symbol: "SRVGY", name: "Servet GYO",        sector: "GYO"),
        Stock(id: "OZGYO.IS", symbol: "OZGYO", name: "Özderici GYO",      sector: "GYO"),
        Stock(id: "MSGYO.IS", symbol: "MSGYO", name: "Martı GYO",         sector: "GYO"),
        Stock(id: "NUGYO.IS", symbol: "NUGYO", name: "Nurol GYO",         sector: "GYO"),
        Stock(id: "PEKGY.IS", symbol: "PEKGY", name: "Peker GYO",         sector: "GYO"),
        Stock(id: "AGYO.IS",  symbol: "AGYO",  name: "Atakule GYO",       sector: "GYO"),
        Stock(id: "ATAGY.IS", symbol: "ATAGY", name: "Ata GYO",           sector: "GYO"),
        Stock(id: "ALGYO.IS", symbol: "ALGYO", name: "Alarko GYO",        sector: "GYO"),
        Stock(id: "AKSGY.IS", symbol: "AKSGY", name: "Akiş GYO",          sector: "GYO"),
        Stock(id: "IHLGM.IS", symbol: "IHLGM", name: "İhlas Gayrimenkul", sector: "GYO"),
        Stock(id: "DNISI.IS", symbol: "DNISI", name: "Deniz GYO",         sector: "GYO"),
        Stock(id: "ENKAI.IS", symbol: "ENKAI", name: "Enka İnşaat",       sector: "İnşaat"),
        Stock(id: "DOGUB.IS", symbol: "DOGUB", name: "Doğuş İnşaat",     sector: "İnşaat"),

        // MARK: - Perakende
        Stock(id: "BIMAS.IS", symbol: "BIMAS", name: "BİM Mağazaları",    sector: "Perakende"),
        Stock(id: "MGROS.IS", symbol: "MGROS", name: "Migros",             sector: "Perakende"),
        Stock(id: "SOKM.IS",  symbol: "SOKM",  name: "Şok Marketler",     sector: "Perakende"),
        Stock(id: "BIZIM.IS", symbol: "BIZIM", name: "Bizim Toptan",       sector: "Perakende"),
        Stock(id: "MAVI.IS",  symbol: "MAVI",  name: "Mavi Giyim",        sector: "Perakende"),
        Stock(id: "BOYP.IS",  symbol: "BOYP",  name: "Boyner Perakende",  sector: "Perakende"),
        Stock(id: "VAKKO.IS", symbol: "VAKKO", name: "Vakko Tekstil",      sector: "Perakende"),
        Stock(id: "DESA.IS",  symbol: "DESA",  name: "Desa Deri",          sector: "Perakende"),
        Stock(id: "TKNSA.IS", symbol: "TKNSA", name: "Teknosa",            sector: "Perakende"),

        // MARK: - Gıda & İçecek
        Stock(id: "ULKER.IS", symbol: "ULKER", name: "Ülker Bisküvi",     sector: "Gıda"),
        Stock(id: "TATGD.IS", symbol: "TATGD", name: "Tat Gıda",          sector: "Gıda"),
        Stock(id: "AEFES.IS", symbol: "AEFES", name: "Anadolu Efes",      sector: "Gıda"),
        Stock(id: "CCOLA.IS", symbol: "CCOLA", name: "Coca-Cola İçecek",  sector: "Gıda"),
        Stock(id: "KRVGD.IS", symbol: "KRVGD", name: "Kervan Gıda",       sector: "Gıda"),
        Stock(id: "PNSUT.IS", symbol: "PNSUT", name: "Pınar Süt",         sector: "Gıda"),
        Stock(id: "KERVT.IS", symbol: "KERVT", name: "Kervansaray Tatl.", sector: "Gıda"),
        Stock(id: "TUKAS.IS", symbol: "TUKAS", name: "Tukaş",             sector: "Gıda"),
        Stock(id: "BANVT.IS", symbol: "BANVT", name: "Banvit",            sector: "Gıda"),
        Stock(id: "SELGT.IS", symbol: "SELGT", name: "Selçuk Gıda",      sector: "Gıda"),
        Stock(id: "TBORG.IS", symbol: "TBORG", name: "Türk Tuborg",       sector: "Gıda"),
        Stock(id: "KNFRT.IS", symbol: "KNFRT", name: "Konfrut",           sector: "Gıda"),
        Stock(id: "DARDL.IS", symbol: "DARDL", name: "Dardanel",          sector: "Gıda"),
        Stock(id: "ERSU.IS",  symbol: "ERSU",  name: "Ersu Meyve",        sector: "Gıda"),
        Stock(id: "KENT.IS",  symbol: "KENT",  name: "Kent Gıda",         sector: "Gıda"),
        Stock(id: "PETUN.IS", symbol: "PETUN", name: "Pınar Et ve Un",   sector: "Gıda"),

        // MARK: - Tekstil
        Stock(id: "KORDS.IS", symbol: "KORDS", name: "Kordsa",            sector: "Tekstil"),
        Stock(id: "ARSAN.IS", symbol: "ARSAN", name: "Arsan Tekstil",     sector: "Tekstil"),
        Stock(id: "BOSSA.IS", symbol: "BOSSA", name: "Bossa",             sector: "Tekstil"),
        Stock(id: "SKTAS.IS", symbol: "SKTAS", name: "Söktaş",           sector: "Tekstil"),
        Stock(id: "YATAS.IS", symbol: "YATAS", name: "Yataş",            sector: "Tekstil"),
        Stock(id: "YUNSA.IS", symbol: "YUNSA", name: "Yünsa",            sector: "Tekstil"),
        Stock(id: "LUKSK.IS", symbol: "LUKSK", name: "Lüks Kadife",      sector: "Tekstil"),
        Stock(id: "FLAP.IS",  symbol: "FLAP",  name: "Flap Kongre",       sector: "Tekstil"),
        Stock(id: "KAPLM.IS", symbol: "KAPLM", name: "Kaplamin Ambalaj", sector: "Tekstil"),

        // MARK: - Telekomünikasyon
        Stock(id: "TCELL.IS", symbol: "TCELL", name: "Turkcell",          sector: "Telekomünikasyon"),
        Stock(id: "TTKOM.IS", symbol: "TTKOM", name: "Türk Telekom",     sector: "Telekomünikasyon"),

        // MARK: - Sigorta & Finans
        Stock(id: "AKGRT.IS", symbol: "AKGRT", name: "Aksigorta",        sector: "Sigorta"),
        Stock(id: "ANHYT.IS", symbol: "ANHYT", name: "Anadolu Hayat",    sector: "Sigorta"),
        Stock(id: "RAYSG.IS", symbol: "RAYSG", name: "Ray Sigorta",      sector: "Sigorta"),
        Stock(id: "ANSGR.IS", symbol: "ANSGR", name: "Anadolu Sigorta",  sector: "Sigorta"),
        Stock(id: "GUSGR.IS", symbol: "GUSGR", name: "Güneş Sigorta",   sector: "Sigorta"),
        Stock(id: "TURSG.IS", symbol: "TURSG", name: "Türk Sigorta",     sector: "Sigorta"),
        Stock(id: "ISFIN.IS", symbol: "ISFIN", name: "İş Finansal Kiralama", sector: "Finans"),
        Stock(id: "GARFA.IS", symbol: "GARFA", name: "Garanti Faktoring", sector: "Finans"),
        Stock(id: "LIDER.IS", symbol: "LIDER", name: "Lider Faktoring",   sector: "Finans"),
        Stock(id: "ISYAT.IS", symbol: "ISYAT", name: "İş Yatırım",       sector: "Finans"),
        Stock(id: "ATLAS.IS", symbol: "ATLAS", name: "Atlas Menkul",      sector: "Finans"),

        // MARK: - Turizm & Otel
        Stock(id: "MAALT.IS", symbol: "MAALT", name: "Marmaris Altınyunus", sector: "Turizm"),
        Stock(id: "NTTUR.IS", symbol: "NTTUR", name: "Net Turizm",         sector: "Turizm"),
        Stock(id: "METUR.IS", symbol: "METUR", name: "Metemtur",           sector: "Turizm"),
        Stock(id: "PKENT.IS", symbol: "PKENT", name: "Petrokent Turizm",   sector: "Turizm"),
        Stock(id: "FVORI.IS", symbol: "FVORI", name: "Favori Dinlenme",    sector: "Turizm"),

        // MARK: - Madencilik
        Stock(id: "KOZAL.IS", symbol: "KOZAL", name: "Koza Altın",        sector: "Madencilik"),
        Stock(id: "KOZAA.IS", symbol: "KOZAA", name: "Koza Madencilik A", sector: "Madencilik"),
        Stock(id: "IPEKE.IS", symbol: "IPEKE", name: "İpek Doğal Enerji", sector: "Madencilik"),
        Stock(id: "MNKAY.IS", symbol: "MNKAY", name: "Minkay",            sector: "Madencilik"),

        // MARK: - Medya & Spor
        Stock(id: "BJKAS.IS", symbol: "BJKAS", name: "Beşiktaş",         sector: "Spor"),
        Stock(id: "FENER.IS", symbol: "FENER", name: "Fenerbahçe",       sector: "Spor"),
        Stock(id: "GSRAY.IS", symbol: "GSRAY", name: "Galatasaray",       sector: "Spor"),
        Stock(id: "TSPOR.IS", symbol: "TSPOR", name: "Trabzonspor",       sector: "Spor"),
        Stock(id: "HURGZ.IS", symbol: "HURGZ", name: "Hürriyet",         sector: "Medya"),
        Stock(id: "IHYAY.IS", symbol: "IHYAY", name: "İhlas Yayın",      sector: "Medya"),

        // MARK: - Elektrik & Kablo
        Stock(id: "PNLSN.IS", symbol: "PNLSN", name: "Panelsan",         sector: "Elektrik"),

        // MARK: - Tarım
        Stock(id: "ALYAG.IS", symbol: "ALYAG", name: "Alaçatı Yağ",       sector: "Tarım"),
        Stock(id: "OYLUM.IS", symbol: "OYLUM", name: "Oylum Sınai Yatırım", sector: "Tarım"),
        Stock(id: "YYLGD.IS", symbol: "YYLGD", name: "Yayla Agro Gıda",   sector: "Tarım"),

        // MARK: - Ek Sanayi & Üretim
        Stock(id: "ADEL.IS",  symbol: "ADEL",  name: "Adel Kalemcilik",      sector: "Sanayi"),
        Stock(id: "MAKIM.IS", symbol: "MAKIM", name: "Makine Takım End.",    sector: "Sanayi"),
        Stock(id: "MEGMT.IS", symbol: "MEGMT", name: "Megmetal Makina",      sector: "Sanayi"),
        Stock(id: "SAMAT.IS", symbol: "SAMAT", name: "Samat Makina",         sector: "Sanayi"),
        Stock(id: "GEREL.IS", symbol: "GEREL", name: "Gersan Elektrik",      sector: "Sanayi"),
        Stock(id: "OSMEN.IS", symbol: "OSMEN", name: "Osman Endüstri",       sector: "Sanayi"),
        Stock(id: "OSTIM.IS", symbol: "OSTIM", name: "Ostim Endüstriyel",   sector: "Sanayi"),
        Stock(id: "ACSEL.IS", symbol: "ACSEL", name: "Acıselsan Kablo",      sector: "Sanayi"),
        Stock(id: "ERBOS.IS", symbol: "ERBOS", name: "Erbosan Erciyas Boru", sector: "Metal"),
        Stock(id: "GENTS.IS", symbol: "GENTS", name: "Gentaş Metal San.",    sector: "Metal"),
        Stock(id: "TMSN.IS",  symbol: "TMSN",  name: "Tomsan Kablo",         sector: "Metal"),
        Stock(id: "BRVAG.IS", symbol: "BRVAG", name: "Birvagas",             sector: "Metal"),
        Stock(id: "ALVES.IS", symbol: "ALVES", name: "Alves Elektromekanik", sector: "Metal"),
        Stock(id: "GEDZA.IS", symbol: "GEDZA", name: "Gediz Ambalaj",        sector: "Metal"),

        // MARK: - Ek Tekstil
        Stock(id: "EDIP.IS",  symbol: "EDIP",  name: "Edip İplik",           sector: "Tekstil"),
        Stock(id: "MNDRS.IS", symbol: "MNDRS", name: "Menderes Tekstil",     sector: "Tekstil"),
        Stock(id: "ROYAL.IS", symbol: "ROYAL", name: "Royal Halı",           sector: "Tekstil"),
        Stock(id: "SONS.IS",  symbol: "SONS",  name: "Sönmez Filament",      sector: "Tekstil"),
        Stock(id: "ASTER.IS", symbol: "ASTER", name: "Aster Tekstil",        sector: "Tekstil"),
        Stock(id: "DMSAS.IS", symbol: "DMSAS", name: "Demisaş Döküm",       sector: "Tekstil"),

        // MARK: - Ek Kimya & Boya
        Stock(id: "DYOBY.IS", symbol: "DYOBY", name: "DYO Boya",             sector: "Kimya"),
        Stock(id: "MRSHL.IS", symbol: "MRSHL", name: "Marshall Boya",        sector: "Kimya"),
        Stock(id: "PIMAS.IS", symbol: "PIMAS", name: "Pimas Plastik",        sector: "Kimya"),
        Stock(id: "ORCAY.IS", symbol: "ORCAY", name: "Orcay Organik",        sector: "Kimya"),
        Stock(id: "HUNER.IS", symbol: "HUNER", name: "Hüner Kimya",          sector: "Kimya"),

        // MARK: - Ek Enerji & Elektrik
        Stock(id: "ASTOR.IS", symbol: "ASTOR", name: "Astor Enerji",         sector: "Enerji"),
        Stock(id: "AYDEM.IS", symbol: "AYDEM", name: "Aydem Enerji",         sector: "Enerji"),
        Stock(id: "MANAS.IS", symbol: "MANAS", name: "Manas Enerji",         sector: "Enerji"),
        Stock(id: "GESAN.IS", symbol: "GESAN", name: "Gesan Enerji Sis.",    sector: "Enerji"),
        Stock(id: "MIPAZ.IS", symbol: "MIPAZ", name: "Mipaz Petrol",         sector: "Enerji"),
        Stock(id: "AKFYE.IS", symbol: "AKFYE", name: "Akfen Yenilenebilir",  sector: "Enerji"),
        Stock(id: "ULUSE.IS", symbol: "ULUSE", name: "Ulusoy Elektrik",      sector: "Elektrik"),
        Stock(id: "MAGEN.IS", symbol: "MAGEN", name: "Mavi Gök Enerji",      sector: "Enerji"),
        Stock(id: "SEYKM.IS", symbol: "SEYKM", name: "Seykum",               sector: "Enerji"),
        Stock(id: "EUREN.IS", symbol: "EUREN", name: "Euro Enerji",           sector: "Enerji"),
        Stock(id: "DENGE.IS", symbol: "DENGE", name: "Denge Enerji",          sector: "Enerji"),

        // MARK: - Ek Teknoloji & Bilişim
        Stock(id: "ARMDA.IS", symbol: "ARMDA", name: "Armada Bilgisayar",    sector: "Teknoloji"),
        Stock(id: "FONET.IS", symbol: "FONET", name: "Fonet Bilişim",        sector: "Teknoloji"),
        Stock(id: "FORTE.IS", symbol: "FORTE", name: "Forte Bilişim",        sector: "Teknoloji"),
        Stock(id: "INVEO.IS", symbol: "INVEO", name: "İnveo Portföy",        sector: "Teknoloji"),
        Stock(id: "KFEIN.IS", symbol: "KFEIN", name: "Kafein Yazılım",       sector: "Teknoloji"),
        Stock(id: "MTRKS.IS", symbol: "MTRKS", name: "Matreks Bilişim",      sector: "Teknoloji"),
        Stock(id: "PENTA.IS", symbol: "PENTA", name: "Penta Teknoloji",      sector: "Teknoloji"),
        Stock(id: "PKART.IS", symbol: "PKART", name: "Plastikkart",          sector: "Teknoloji"),
        Stock(id: "ARDYZ.IS", symbol: "ARDYZ", name: "Ardıç Yazılım",       sector: "Teknoloji"),
        Stock(id: "DESPC.IS", symbol: "DESPC", name: "Despec Bilgisayar",   sector: "Teknoloji"),
        Stock(id: "MOBTL.IS", symbol: "MOBTL", name: "Mobil Teknoloji",      sector: "Teknoloji"),
        Stock(id: "ARENA.IS", symbol: "ARENA", name: "Arena Bilgisayar",     sector: "Teknoloji"),

        // MARK: - Ek Sağlık
        Stock(id: "LKMNH.IS", symbol: "LKMNH", name: "Lokman Hekim",         sector: "Sağlık"),
        Stock(id: "GLBMD.IS", symbol: "GLBMD", name: "Global Medikal",       sector: "Sağlık"),
        Stock(id: "MEDTR.IS", symbol: "MEDTR", name: "Meditera Tıbbi",       sector: "Sağlık"),
        Stock(id: "BIGEN.IS", symbol: "BIGEN", name: "Bilim Ecza Deposu",   sector: "İlaç"),
        Stock(id: "ADESE.IS", symbol: "ADESE", name: "Adese Alışveriş",     sector: "Sağlık"),

        // MARK: - Ek Perakende & Gıda
        Stock(id: "METRO.IS", symbol: "METRO", name: "Metro Ticaret",        sector: "Perakende"),
        Stock(id: "KILER.IS", symbol: "KILER", name: "Kiler Alışveriş",     sector: "Perakende"),
        Stock(id: "KOFAZ.IS", symbol: "KOFAZ", name: "Kofaz Gıda",          sector: "Gıda"),
        Stock(id: "ARASE.IS", symbol: "ARASE", name: "Araş Gıda",           sector: "Gıda"),
        Stock(id: "OLMKS.IS", symbol: "OLMKS", name: "Olmuksa Int. Paper",  sector: "Gıda"),

        // MARK: - Ek GYO
        Stock(id: "AKFGY.IS", symbol: "AKFGY", name: "Akfen GYO",           sector: "GYO"),
        Stock(id: "AKMGY.IS", symbol: "AKMGY", name: "Akmerkez GYO",        sector: "GYO"),
        Stock(id: "MRGYO.IS", symbol: "MRGYO", name: "Merkez GYO",          sector: "GYO"),
        Stock(id: "RYGYO.IS", symbol: "RYGYO", name: "Rya GYO",             sector: "GYO"),
        Stock(id: "VEGYO.IS", symbol: "VEGYO", name: "Vega GYO",            sector: "GYO"),
        Stock(id: "ZRGYO.IS", symbol: "ZRGYO", name: "Ziraat GYO",          sector: "GYO"),
        Stock(id: "YKGYO.IS", symbol: "YKGYO", name: "Yapı Kredi GYO",     sector: "GYO"),
        Stock(id: "DZGYO.IS", symbol: "DZGYO", name: "Denizbank GYO",       sector: "GYO"),
        Stock(id: "OYGYO.IS", symbol: "OYGYO", name: "Oyaş GYO",            sector: "GYO"),
        Stock(id: "ESCAR.IS", symbol: "ESCAR", name: "Escort Hizmetleri",   sector: "İnşaat"),
        Stock(id: "YKONT.IS", symbol: "YKONT", name: "Yüksel Proje",        sector: "İnşaat"),
        Stock(id: "INTEM.IS", symbol: "INTEM", name: "İntema Yapı",          sector: "İnşaat"),
        Stock(id: "VARYA.IS", symbol: "VARYA", name: "Varyap",              sector: "İnşaat"),

        // MARK: - Ek Cam & Seramik
        Stock(id: "CANTR.IS", symbol: "CANTR", name: "Çanakkale Seramik",  sector: "Seramik"),
        Stock(id: "KTSKE.IS", symbol: "KTSKE", name: "Kütahya Seramik",    sector: "Seramik"),
        Stock(id: "EGSER.IS", symbol: "EGSER", name: "Ege Seramik",        sector: "Seramik"),
        Stock(id: "USAK.IS",  symbol: "USAK",  name: "Uşak Seramik",       sector: "Seramik"),
        Stock(id: "KBORU.IS", symbol: "KBORU", name: "Krone Boru",         sector: "Cam"),

        // MARK: - Ek Holding & Finans
        Stock(id: "GSDHO.IS", symbol: "GSDHO", name: "GSD Holding",         sector: "Holding"),
        Stock(id: "MARKA.IS", symbol: "MARKA", name: "Marka Yatırım Hld.",  sector: "Holding"),
        Stock(id: "HTTBT.IS", symbol: "HTTBT", name: "Hattat Holding",       sector: "Holding"),
        Stock(id: "KCFIN.IS", symbol: "KCFIN", name: "Koç Finansman",       sector: "Finans"),
        Stock(id: "SEKFK.IS", symbol: "SEKFK", name: "Şeker Faktoring",    sector: "Finans"),
        Stock(id: "QNBFL.IS", symbol: "QNBFL", name: "QNB Finansleasing",  sector: "Finans"),
        Stock(id: "VAKFN.IS", symbol: "VAKFN", name: "Vakıf Fin. Kiralama", sector: "Finans"),
        Stock(id: "YKFIN.IS", symbol: "YKFIN", name: "YKF Finansal Kir.",   sector: "Finans"),
        Stock(id: "TRILC.IS", symbol: "TRILC", name: "Türkiye İş Leasing", sector: "Finans"),
        Stock(id: "GEDIK.IS", symbol: "GEDIK", name: "Gedik Yatırım",       sector: "Finans"),
        Stock(id: "AGESA.IS", symbol: "AGESA", name: "AGesa Sigorta",        sector: "Sigorta"),

        // MARK: - Ek Turizm
        Stock(id: "MERIT.IS", symbol: "MERIT", name: "Merit Turizm",        sector: "Turizm"),
        Stock(id: "AYCES.IS", symbol: "AYCES", name: "Altınyunus Çeşme",   sector: "Turizm"),
        Stock(id: "CRFSA.IS", symbol: "CRFSA", name: "Carrefour SA",        sector: "Turizm"),
        Stock(id: "SEDEN.IS", symbol: "SEDEN", name: "Sedef Tersanesi",     sector: "Turizm"),

        // MARK: - Ek Madencilik
        Stock(id: "GMTAS.IS", symbol: "GMTAS", name: "Gümüştaş Madencilik", sector: "Madencilik"),
        Stock(id: "SELGD.IS", symbol: "SELGD", name: "Sel Girişim",         sector: "Madencilik"),

        // MARK: - Bankacılık (Ek)
        Stock(id: "ODEABANK.IS",  symbol: "ODEABANK",  name: "Odeabank",    sector: "Bankacılık"),
        Stock(id: "FIBABANKA.IS", symbol: "FIBABANKA", name: "Fibabanka",   sector: "Bankacılık"),

        // MARK: - Kağıt & Ambalaj
        Stock(id: "KARTN.IS", symbol: "KARTN", name: "Kartonsan",           sector: "Kağıt"),
        Stock(id: "BAKAB.IS", symbol: "BAKAB", name: "Bak Ambalaj",         sector: "Kağıt"),
        Stock(id: "TEZOL.IS", symbol: "TEZOL", name: "Tezol Kağıt",        sector: "Kağıt"),
        Stock(id: "SNPAM.IS", symbol: "SNPAM", name: "Şenpazar Ambalaj",   sector: "Kağıt"),

        // MARK: - Lojistik & Denizcilik
        Stock(id: "GSDDE.IS", symbol: "GSDDE", name: "GSD Denizcilik",      sector: "Denizcilik"),
        Stock(id: "SEDEF.IS", symbol: "SEDEF", name: "Sedef Tersanesi",     sector: "Denizcilik"),
        Stock(id: "ULASL.IS", symbol: "ULASL", name: "Ulaşlar Turizm",     sector: "Lojistik"),
        Stock(id: "AVTUR.IS", symbol: "AVTUR", name: "Avrasya Petrol",      sector: "Lojistik"),
        Stock(id: "KONTR.IS", symbol: "KONTR", name: "Kontrolmatik",        sector: "Lojistik"),
        Stock(id: "MEPET.IS", symbol: "MEPET", name: "Mepet Metro",         sector: "Lojistik"),

        // MARK: - Otomotiv (Ek)
        Stock(id: "RENTA.IS", symbol: "RENTA", name: "Rentaş",              sector: "Otomotiv"),

        // MARK: - Elektronik (Ek)
        Stock(id: "SIMGE.IS", symbol: "SIMGE", name: "Simge Reklam",        sector: "Elektronik"),
    ]

    // Geriye dönük uyumluluk
    static var bist100: [Stock] { all }
}
