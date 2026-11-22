# MyZenFlow Widget + Live Activity — kurulum rehberi

Bu klasördeki dosyalar **henüz Xcode projesine bağlı değil.** Widget eklentisi (extension) yeni bir
Xcode target'ı ve bir App Group gerektiriyor; bunlar `project.pbxproj`'u elle düzenlemeden
güvenle yapılamıyor. Uygulama tarafı hazır: veri köprüsü, Live Activity yöneticisi ve tüm
bağlantılar ana projede duruyor ve extension eklenene kadar zararsızca hiçbir şey yapmıyor.

> Geçmişte bir widget eklenip kaldırılmıştı (`widget removal` commit'i). Bu sefer App Group
> kimliği **kendi bundle ID'ne** göre ayarlı: `group.com.oqza.MyZenFlowApp`.

## 1. App Group'u kaydet (bir kez)

Xcode → **ZenFlow** target → *Signing & Capabilities* → **+ Capability → App Groups** →
`group.com.oqza.MyZenFlowApp` ekle. (Xcode "Automatically manage signing" açıksa grubu kendisi
developer hesabında oluşturur.) Başka bir isim kullanırsan `ZenFlow/Shared/WidgetSnapshot.swift`
içindeki `appGroupIdentifier` değerini de aynı yap.

## 2. Widget Extension target'ını oluştur

1. **File → New → Target… → Widget Extension**
2. Product Name: `ZenFlowWidget`
3. **Include Live Activity**: işaretli · **Include Configuration App Intent**: işaretsiz
4. Bundle ID `com.oqza.MyZenFlowApp.ZenFlowWidget` olmalı, Deployment Target **iOS 17.0**.
5. "Activate scheme?" sorusuna *Cancel* de (ana scheme'de kalmak daha rahat).

## 3. Dosyaları bağla

1. Xcode'un oluşturduğu şablon `.swift` dosyalarını sil (Move to Trash).
2. Bu klasördeki üç `.swift` dosyasını ve `Localizable.xcstrings`'i `ZenFlowWidget` grubuna sürükle.
   *Target Membership*: yalnızca **ZenFlowWidgetExtension**.
3. Ortak iki dosyayı **iki target'a da** üye yap (dosyayı seç → sağ panel → *Target Membership*):
   - `ZenFlow/Shared/WidgetSnapshot.swift`
   - `ZenFlow/Shared/ZenSessionActivityAttributes.swift`

   Hem **ZenFlow** hem **ZenFlowWidgetExtension** kutusu işaretli olmalı.

## 4. Extension'a App Group ver

**ZenFlowWidgetExtension** target → *Signing & Capabilities* → **+ Capability → App Groups** →
aynı `group.com.oqza.MyZenFlowApp` grubunu işaretle.

## 5. Live Activity'yi aç

**ZenFlow** (ana uygulama) target → *Build Settings* → **Active Compilation Conditions** →
hem Debug hem Release satırına `ZENFLOW_LIVE_ACTIVITIES` ekle.
(`NSSupportsLiveActivities` zaten ana `Info.plist`'te var.)

Bu bayrak olmadan `SessionLiveActivityManager` hiçbir şey yapmaz; yani extension'ı ekleyene kadar
kimse boş bir Live Activity görmez.

## 6. Dene

- Gerçek cihazda veya simülatörde bir meditasyon seansı yap, ardından ana ekrana uzun bas →
  **+** → *MyZenFlow* → "Zen Progress" widget'ını ekle (küçük/orta). Kilit ekranı widget'ları için
  kilit ekranını düzenle.
- Nefes, Odaklan veya Sessiz Meditasyon seansı başlatıp uygulamadan çık: kilit ekranında ve
  (destekleyen cihazda) Dynamic Island'da geri sayım görünmeli. Dokununca ilgili sekme açılır.
- Widget'a dokununca `zenflow://breathing` açılır (URL şeması `Info.plist`'te kayıtlı).

## Sorun giderme

| Belirti | Çözüm |
|---|---|
| Widget hep sıfırları gösteriyor | App Group iki target'ta da aynı mı? Uygulamayı bir kez açıp seans kaydettin mi? |
| `Cannot find 'WidgetSnapshot' in scope` | Ortak dosyalar extension target'ına üye değil (3. adım) |
| Extension'da actor isolation hataları | Extension target → Build Settings → *Default Actor Isolation* = **nonisolated** |
| Live Activity başlamıyor | Ayarlar → MyZenFlow → *Canlı Etkinlikler* açık mı? `ZENFLOW_LIVE_ACTIVITIES` eklendi mi? |
| Siri/Kısayol çalışmıyor | Uygulamayı bir kez çalıştır; Kısayollar uygulamasında MyZenFlow kısayolları görünmeli |

## App Store notu

Widget ve Live Activity için App Store Connect'te ayrı bir adım yok. Yeni capability'ler
(App Groups) provisioning profilinde otomatik gelir. Ek olarak `UIBackgroundModes: audio`
(uyku modu için) zaten eklendi.
