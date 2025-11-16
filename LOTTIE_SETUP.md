# Lottie Animations Setup Guide

## 📦 SPM Package Installation

### Adım 1: Lottie-ios Paketini Xcode'da Ekleyin

1. **Xcode'da projeyi açın**: `ZenFlow.xcodeproj`
2. **File > Add Package Dependencies** seçin
3. Arama kutusuna şu URL'yi girin:
   ```
   https://github.com/airbnb/lottie-ios
   ```
4. **Version**: Latest version (5.0.0+) seçin
5. **Add to Project**: "ZenFlow" seçin
6. **Add Package** butonuna tıklayın

### Adım 2: Yeni Dosyaları Xcode Projesine Ekleyin

Aşağıdaki dosyaları Xcode projesine manuel olarak eklemeniz gerekiyor:

#### 1. Animation JSON Dosyaları
Yeni oluşturulan `Resources/Animations/` klasörünü Xcode'a sürükleyin:
- `Resources/Animations/success.json` - Success checkmark animation
- `Resources/Animations/confetti.json` - Confetti burst animation
- `Resources/Animations/sparkle.json` - Sparkle glow animation
- `Resources/Animations/loading.json` - Zen lotus loading animation

**Önemli**: Dosyaları eklerken:
- ✅ "Copy items if needed" seçeneğini işaretleyin
- ✅ "Add to targets: ZenFlow" seçeneğini işaretleyin
- ✅ "Create groups" seçeneğini işaretleyin

#### 2. Swift Dosyaları
Aşağıdaki Swift dosyaları projeye eklenmiştir, Xcode'da görünmüyorsa manuel olarak ekleyin:

**Utilities:**
- `Utilities/LottieView.swift` - Lottie SwiftUI wrapper ve animation manager

**Views/Components:**
- `Views/Components/SessionCompleteView.swift` - Session complete modal with success animation
- `Views/Components/SplashScreenView.swift` - App launch splash screen

**Güncellenmiş Dosyalar:**
- `Views/BreathingView.swift` - Session complete animation entegrasyonu
- `Views/Components/BadgeUnlockAnimationView.swift` - Lottie confetti eklendi
- `Views/ZenGardenView.swift` - Sparkle animation eklendi
- `ZenFlowApp.swift` - Splash screen eklendi

### Adım 3: Build ve Test

1. **Clean Build Folder**: ⌘ + Shift + K
2. **Build**: ⌘ + B
3. **Run**: ⌘ + R

## ✨ Yeni Özellikler

### 1. Success Animation (Session Complete)
- **Lokasyon**: BreathingView
- **Tetikleyici**: Meditasyon seansı tamamlandığında (>= 1 dakika)
- **Animasyon**: 2 saniyelik checkmark success animation
- **Özellikler**: Auto-dismiss, haptic feedback

### 2. Badge Unlock Animation
- **Lokasyon**: BadgeUnlockAnimationView
- **Tetikleyici**: Yeni rozet kazanıldığında
- **Animasyon**: 3 saniyelik confetti burst + trophy animation
- **Özellikler**: Lottie + legacy particle effects combined

### 3. Tree Growth Animation
- **Lokasyon**: ZenGardenView
- **Tetikleyici**: Ağaç seviyesi atladığında
- **Animasyon**: 2.5 saniyelik sparkle/glow animation
- **Özellikler**: Overlay animation + tree scale/rotation

### 4. App Launch Loading
- **Lokasyon**: ZenFlowApp (Splash Screen)
- **Tetikleyici**: App launch
- **Animasyon**: 1.5 saniyelik zen lotus loading animation
- **Özellikler**: Fade in/out, auto-dismiss

## 🎯 Performance Optimizasyonları

### Caching Strategy
- **LRU Cache**: Maksimum 5 animasyon cache'lenir
- **Preloading**: Sık kullanılan animasyonlar app launch'ta preload edilir
- **Memory Management**: Uygulama background'a gittiğinde cache temizlenir

### Render Mode
- **Main Thread Rendering**: UI updates için optimize edilmiş
- **Background Pause**: Background'ta animasyonlar otomatik pause

## ♿ Accessibility Support

### Reduce Motion
Lottie animasyonları accessibility ayarlarına uyumludur:

1. **UIAccessibility.isReduceMotionEnabled**: Otomatik tespit
2. **UserDefaults Toggle**: `lottieAnimationsEnabled` key ile manuel kontrol
3. **Fallback**: Reduce motion aktif ise static son frame gösterilir

### Kullanıcı Ayarları
```swift
// Lottie animasyonlarını devre dışı bırakma
UserDefaults.standard.set(false, forKey: "lottieAnimationsEnabled")

// Lottie animasyonlarını etkinleştirme
UserDefaults.standard.set(true, forKey: "lottieAnimationsEnabled")
```

## 🔧 Troubleshooting

### "Cannot find 'Lottie' in scope" hatası
1. Lottie-ios paketinin düzgün yüklendiğinden emin olun
2. Xcode'u kapatıp tekrar açın
3. Clean Build Folder yapın (⌘ + Shift + K)
4. Derived Data'yı silin: `~/Library/Developer/Xcode/DerivedData`

### Animation JSON dosyaları bulunamıyor
1. JSON dosyalarının `Resources/Animations/` klasöründe olduğunu kontrol edin
2. Build Phases > Copy Bundle Resources içinde dosyaların listelendiğini kontrol edin
3. Gerekirse dosyaları tekrar projeye ekleyin (Copy items if needed ile)

### Animasyonlar çalışmıyor
1. `LottieAnimationManager.shared` başlatıldığından emin olun (ZenFlowApp.swift:36)
2. Console'da Lottie error mesajlarını kontrol edin
3. Reduce Motion ayarının kapalı olduğunu kontrol edin

## 📚 Daha Fazla Animasyon Ekleme

Yeni Lottie animasyonları eklemek için:

1. **JSON Dosyası**: `Resources/Animations/` klasörüne yeni JSON ekleyin
2. **Preload**: `LottieAnimationManager.swift:66` içine animasyon adını ekleyin
3. **View Oluştur**: `LottieView.swift` dosyasında yeni predefined view oluşturun:

```swift
struct MyCustomLottieView: View {
    var completion: (() -> Void)? = nil

    var body: some View {
        LottieView(
            animationName: "my-animation",
            loopMode: .playOnce,
            animationSpeed: 1.0,
            completion: completion
        )
        .frame(width: 300, height: 300)
    }
}
```

## 📖 LottieFiles Kaynakları

Premium animasyonlar için:
- [LottieFiles.com](https://lottiefiles.com/) - Ücretsiz ve premium Lottie animasyonları
- [Success Animations](https://lottiefiles.com/search?q=success&category=animations)
- [Confetti Animations](https://lottiefiles.com/search?q=confetti&category=animations)
- [Sparkle Animations](https://lottiefiles.com/search?q=sparkle&category=animations)

**Not**: Mevcut JSON dosyaları basit placeholder'dır. Production için LottieFiles'dan professional animasyonlar indirmeniz önerilir.

## ✅ Checklist

- [ ] Lottie-ios SPM paketi eklendi
- [ ] Resources/Animations/ klasörü Xcode'a eklendi
- [ ] Tüm JSON dosyaları Copy Bundle Resources'da
- [ ] Yeni Swift dosyaları projeye eklendi
- [ ] Build başarılı (⌘ + B)
- [ ] Tüm animasyonlar test edildi
- [ ] Reduce Motion accessibility testi yapıldı
- [ ] Memory profiling yapıldı (Instruments)

---

**Oluşturulma Tarihi**: 16 Kasım 2025
**Güncelleyen**: Claude AI
**Version**: 1.0.0
