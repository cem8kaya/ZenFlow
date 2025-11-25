//
//  ZenWisdomLibrary.swift
//  ZenFlow
//
//  Created by Claude AI on 25.11.2025.
//  Copyright © 2025 ZenFlow. All rights reserved.
//
//  Zen öğretileri kütüphanesi ve kategori yönetimi
//  Offline çalışan, derin Zen felsefesi içeren hikmet kitaplığı
//

import Foundation

// MARK: - Zen Kategorileri
enum ZenCategory: String, CaseIterable {
    case mindfulness = "Şimdiki An"
    case impermanence = "Kalıcısızlık"
    case acceptance = "Kabul"
    case simplicity = "Sadelik"
    case beginner = "Başlangıç Zihni"
    case meditation = "Meditasyon"
    case breath = "Nefes"
    case nature = "Doğa"
    case silence = "Sessizlik"
    case balance = "Denge"
}

// MARK: - Zen Öğretisi Modeli
struct ZenTeaching: Identifiable, Codable {
    let id: UUID
    let category: String
    let title: String
    let content: String
    let quote: String?
    let author: String?
    let practicalAdvice: String

    init(id: UUID = UUID(), category: ZenCategory, title: String, content: String, quote: String? = nil, author: String? = nil, practicalAdvice: String) {
        self.id = id
        self.category = category.rawValue
        self.title = title
        self.content = content
        self.quote = quote
        self.author = author
        self.practicalAdvice = practicalAdvice
    }
}

// MARK: - Zen Hikmet Kütüphanesi
class ZenWisdomLibrary {
    static let shared = ZenWisdomLibrary()

    private var teachings: [ZenTeaching] = []

    private init() {
        loadTeachings()
    }

    private func loadTeachings() {
        teachings = [
            // ŞİMDİKİ AN KATEGORİSİ
            ZenTeaching(
                category: .mindfulness,
                title: "Şimdiki Anın Gücü",
                content: """
                Zen'de geçmiş ve gelecek birer illüzyondur. Yalnızca şimdiki an gerçektir. \
                Her nefes, her adım, her an tam ve eksiksizdir. Geçmişin pişmanlıklarıyla ya da \
                geleceğin kaygılarıyla zihnimizi meşgul ettiğimizde, hayatın gerçekliğinden uzaklaşırız.

                Bir Zen ustası şöyle der: "Çay içerken sadece çay iç. Yürürken sadece yürü." \
                Bu sadelikte derin bir bilgelik gizlidir. Her eylemi tam bir dikkatle yapmak, \
                yaşamı bir meditasyon haline getirir.
                """,
                quote: "Yürürken sadece yürü, otururken sadece otur. Her ne yaparsan yap, sallanma.",
                author: "Zen Atasözü",
                practicalAdvice: "Bugün bir aktivite seç (yemek yeme, diş fırçalama, yürüyüş) ve onu tam bir dikkatle yap. Zihnin başka yerlere gittiğinde, nazikçe şimdiki ana geri getir."
            ),

            // KALICISIZLIK KATEGORİSİ
            ZenTeaching(
                category: .impermanence,
                title: "Kalıcısızlığı Kucaklamak",
                content: """
                Her şey değişir, hiçbir şey kalıcı değildir - bu Zen'in temel öğretilerinden biridir. \
                Çiçekler solar, mevsimler değişir, duygular gelip geçer. Bu gerçeği kabul etmek, \
                acının değil, özgürlüğün anahtarıdır.

                Kalıcısızlığa direnmek acıya yol açar. Değişimi doğal akışında kabul etmek ise huzuru getirir. \
                Japon'lar bu güzelliği 'mono no aware' (şeylerin geçiciliğine duyulan hüzün) olarak tanımlar.
                """,
                quote: "Düşünceler bulutlar gibidir - gelir, şeklini değiştirir ve geçer. Sen ise gökyüzüsün.",
                author: "Zen Öğretisi",
                practicalAdvice: "Bir düşünceyi ya da duyguyu gözlemle. Onu değiştirmeye çalışmadan sadece izle. Nasıl gelip gittiğini fark et. Sen onların gözlemcisisin, onların kendisi değil."
            ),

            // KABUL KATEGORİSİ
            ZenTeaching(
                category: .acceptance,
                title: "Gerçekliği Olduğu Gibi Görmek",
                content: """
                Zen'de 'suchness' (tathātā) kavramı, her şeyi olduğu gibi kabul etmektir. \
                Yargılamadan, değiştirmeye çalışmadan, sadece gözlemlemek. Yağmur yağıyorsa yağmur yağıyor, \
                güneş açıyorsa güneş açıyor.

                Çoğu acımız, gerçekliğin farklı olmasını istemekten kaynaklanır. "Böyle olmamalıydı", \
                "şöyle olsaydı daha iyi olurdu" gibi düşünceler zihnimizi bulandırır. Kabul, teslimiyettir. \
                Teslimiyet ise en büyük güçtür.
                """,
                quote: "Engel yol olur, yol engel olur.",
                author: "Zen Atasözü",
                practicalAdvice: "Bugün karşılaştığın zorlu bir durumda, önce derin bir nefes al. 'Bu şu an böyle' de. Kabul et. Sonra gerekirse hareket et. Kabul, hareketsizlik değildir - net görüştür."
            ),

            // SADELİK KATEGORİSİ
            ZenTeaching(
                category: .simplicity,
                title: "Sadelikte Mükemmellik",
                content: """
                Zen bahçeleri neden bu kadar etkileyicidir? Çünkü fazlalık yoktur. Her taş, her bitki, \
                her boşluk bir amaca hizmet eder. Sadelik, yoksulluk değildir - gereksizi atmaktır.

                Zihnimiz de aynı şekilde işler. Ne kadar çok düşünce, kaygı, arzu birikirse, o kadar karmaşık hale gelir. \
                Zen meditasyonu bu fazlalıkları silmek, zihnin doğal berraklığını ortaya çıkarmak içindir.
                """,
                quote: "Bilgelik başka bir şey eklemek değil, gereksizi çıkarmaktır.",
                author: "Zen Öğretisi",
                practicalAdvice: "Bugün bir alanı (fiziksel ya da zihinsel) sadeleştir. Gereksiz bir eşyayı at, ya da gereksiz bir endişeden vazgeç. Boşluğun getirdiği rahatlığı hisset."
            ),

            // BAŞLANGIÇ ZİHNİ KATEGORİSİ
            ZenTeaching(
                category: .beginner,
                title: "Başlangıç Zihninin Zenginliği",
                content: """
                Shunryu Suzuki'nin ünlü sözü: "Başlangıç zihninde birçok olasılık vardır, \
                uzman zihninde ise çok azdır." Bu, Zen'in kalbinde yatan bir öğretidir.

                Bildiğimizi sandığımız her şey, aslında zihnimizin özgürlüğünü kısıtlayan bir kalıptır. \
                Bir şeyi ilk kez yapan bir çocuğun merakını, şaşkınlığını hatırla. İşte o zihne ihtiyacımız var. \
                Her nefes yeni, her meditasyon ilk.
                """,
                quote: "Uzman zihninde çok az olasılık vardır, başlangıç zihninde sonsuz olasılık.",
                author: "Shunryu Suzuki",
                practicalAdvice: "Bugün sıradan bir şeyi ilk kez görüyormuşsun gibi incele. Bir ağaç yaprağı, ellerin, gökyüzü. Ne varsayımlar yapabilirsin? Ne merak uyandırır?"
            ),

            // MEDİTASYON KATEGORİSİ
            ZenTeaching(
                category: .meditation,
                title: "Oturuşta Uyanış - Zazen",
                content: """
                Zazen, Zen meditasyonunun kalbidir. 'Za' oturmak, 'zen' meditasyon demektir. \
                Ama Zazen bir teknik değil, bir duruştur, bir varoluş biçimidir.

                Zazen'de bir hedefe ulaşmaya çalışmayız. Aydınlanma aramayız. Sadece otururuz. \
                Shikantaza - "sadece oturmak". Bu paradoks, aslında en derin öğretidir: Hiçbir şey elde etmeye \
                çalışmadığında, her şeyi zaten elde etmişsin.
                """,
                quote: "Meditasyon amacınız yoksa, o zaten mükemmeldir.",
                author: "Dogen Zenji",
                practicalAdvice: "Meditasyonunda bugün hiçbir şey beklemeden otur. Rahatlamaya çalışma, konsantre olmaya çalışma. Sadece otur. Olduğun gibi ol."
            ),

            // NEFES KATEGORİSİ
            ZenTeaching(
                category: .breath,
                title: "Nefes - Hayatın Kapısı",
                content: """
                Nefes, hayatın en temel ritmidir. Doğumla başlar, ölümle son bulur. \
                Her nefeste bir hayat, her nefeste bir ölüm vardır. Nefes, şimdiki ana dönen köprüdür.

                Zen'de nefese dikkat etmek, zihnin en basit ama en derin uygulamasıdır. \
                Nefes düşünülemez, sadece yaşanır. Bu yüzden nefes meditasyonu, düşünce dünyasından \
                deneyim dünyasına geçişin kapısıdır.
                """,
                quote: "Nefes gider, nefes gelir. Bırak gitsin, bırak gelsin.",
                author: "Thich Nhat Hanh",
                practicalAdvice: "Şimdi üç derin nefes al. İlkini göğsünle, ikincisini karnınla, üçüncüsünü tüm bedenle al. Her nefeste hayatın mucizesini hisset."
            ),

            // DOĞA KATEGORİSİ
            ZenTeaching(
                category: .nature,
                title: "Doğanın Öğretileri",
                content: """
                Zen, doğadan ayrı değildir. Dağlar, nehirler, ağaçlar - hepsi Zen öğretmenleridir. \
                Bir çam ağacı hiçbir zaman gül olmaya çalışmaz. Bir kaya hiçbir zaman bulut olmayı istemez. \
                Her şey kendi doğasında mükemmeldir.

                İnsanlar ise sürekli başka bir şey olmaya çalışır. Bu, acının köküdür. \
                Doğaya bakarak, kendi doğamıza dönmeyi öğrenebiliriz.
                """,
                quote: "Bambu eğilir ama kırılmaz, çam dik durur ama zorlanmaz. Her biri kendi yolunda mükemmeldir.",
                author: "Zen Atasözü",
                practicalAdvice: "Bugün doğada bir şeyi dikkatle gözlemle. Bir ağaç, bir taş, gökyüzü. Ondan ne öğrenebilirsin? O nasıl var oluyor?"
            ),

            // SESSİZLİK KATEGORİSİ
            ZenTeaching(
                category: .silence,
                title: "Sessizliğin Sesi",
                content: """
                Zen'in en ünlü koanlarından biri: "Tek elin çırdağı sesi nasıldır?" \
                Bu soru mantıkla cevaplanamaz. Sadece sessizlikte, düşüncenin ötesinde anlaşılabilir.

                Sessizlik, sesin yokluğu değildir. Sessizlik, zihnin durulmuş halidir. \
                Bu sessizlikte her şey duyulur - kalbin atışı, nefes, hayatın kendisi. \
                Konuşma dışarıdadır, sessizlik içeridedir.
                """,
                quote: "Sessizlikte cevaplar vardır, gürültüde sadece yankılar.",
                author: "Zen Öğretisi",
                practicalAdvice: "Bugün 5 dakika tamamen sessiz kal. Konuşma, müzik dinleme, hiçbir ses çıkarma. Sessizliğin içinde ne duyuyorsun?"
            ),

            // DENGE KATEGORİSİ
            ZenTeaching(
                category: .balance,
                title: "İki Uç Arasında Orta Yol",
                content: """
                Buddha'nın öğrettiği orta yol, Zen'in de temelidir. Ne aşırı disiplin, ne de aşırı rahatlık. \
                Ne dünyadan kaçış, ne de dünyaya boğulma. Denge, statik bir nokta değil, dinamik bir danstır.

                Bir terazide olduğu gibi, sürekli ayarlama gerekir. Bazen bir tarafa ağırlık vermek, \
                bazen diğer tarafa. Ama her zaman merkeze dönme niyeti vardır. Bu niyet, \
                Zen yolculuğunun pusuladır.
                """,
                quote: "Çok gergin teller koparır, çok gevşek teller ses çıkarmaz. Orta gerilim müziği yaratır.",
                author: "Buddha",
                practicalAdvice: "Hayatında dengesiz hissettiğin bir alan var mı? Çok mu sıkısın, yoksa çok mu gevşek? Bugün küçük bir ayarlama yap - orta yola doğru."
            )
        ]
    }

    // MARK: - Public Methods

    /// Kategoriye göre rastgele öğreti al
    func getTeaching(for category: ZenCategory) -> ZenTeaching? {
        return teachings.filter { $0.category == category.rawValue }.randomElement()
    }

    /// Tamamen rastgele bir öğreti al
    func getRandomTeaching() -> ZenTeaching {
        return teachings.randomElement() ?? teachings[0]
    }

    /// Kullanıcı bağlamına göre uygun öğreti al
    func getTeachingForContext(sessionCount: Int, lastSessionDate: Date?, currentMood: String?) -> ZenTeaching {
        // Başlangıç kullanıcıları için
        if sessionCount < 5 {
            return getTeaching(for: .beginner) ?? getRandomTeaching()
        }

        // Düzenli kullanıcılar için nefes odaklı
        if let lastDate = lastSessionDate, Calendar.current.isDateInToday(lastDate) {
            return getTeaching(for: .breath) ?? getRandomTeaching()
        }

        // Genel rotasyon
        return getRandomTeaching()
    }

    /// Tüm kategorileri al
    func getAllCategories() -> [ZenCategory] {
        return ZenCategory.allCases
    }

    /// Kategori için ikon adı
    func iconForCategory(_ category: ZenCategory) -> String {
        switch category {
        case .mindfulness: return "brain.head.profile"
        case .impermanence: return "leaf"
        case .acceptance: return "hand.raised.fill"
        case .simplicity: return "circle"
        case .beginner: return "sparkles"
        case .meditation: return "figure.mind.and.body"
        case .breath: return "wind"
        case .nature: return "tree"
        case .silence: return "speaker.slash.fill"
        case .balance: return "scale.3d"
        }
    }

    /// Kategori için renk
    func colorForCategory(_ category: ZenCategory) -> String {
        switch category {
        case .mindfulness: return "purple"
        case .impermanence: return "orange"
        case .acceptance: return "blue"
        case .simplicity: return "gray"
        case .beginner: return "yellow"
        case .meditation: return "indigo"
        case .breath: return "cyan"
        case .nature: return "green"
        case .silence: return "mint"
        case .balance: return "pink"
        }
    }
}
