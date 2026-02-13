# MacinCloud 1 Saat Checklist

Bu listeyi MacinCloud'a bağlanmadan ÖNCE oku ve hazırlan.
Süre sınırlı (1 saat), her dakika önemli.

---

## BAĞLANMADAN ÖNCE HAZIRLA (Windows'ta)

- [ ] GitHub'da repo oluştur ve kodu push et
- [ ] Apple Developer hesap bilgilerini not al:
  - Apple ID email
  - Team ID (developer.apple.com → Membership)
- [ ] App Store Connect API Key oluştur:
  - appstoreconnect.apple.com → Users → Integrations → Keys
  - Key ID ve Issuer ID not al
  - AuthKey.p8 dosyasını indir
- [ ] Bu checklist'i ekranda açık tut

---

## MacinCloud'da YAPILACAKLAR (60 dakika plan)

### Dakika 0-5: Hazırlık
- [ ] Terminal aç
- [ ] Xcode'un kurulu olduğunu kontrol et: `xcode-select -p`
- [ ] GitHub repo'nu clone et:
  ```bash
  cd ~/Desktop
  git clone https://github.com/KULLANICI/niyaz-pusulasi.git
  cd niyaz-pusulasi
  ```

### Dakika 5-15: Xcode Project Oluştur
- [ ] Xcode aç → File → New → Project
- [ ] iOS → App seç
- [ ] Ayarlar:
  - Product Name: `NiyazPusulasi`
  - Team: Kendi team'ini seç
  - Organization Identifier: `com.niyazpusulasi`
  - Bundle Identifier: `com.niyazpusulasi.app` (otomatik oluşur)
  - Interface: SwiftUI
  - Language: Swift
  - Storage: None
  - **Lokasyon: clone ettiğin klasörü seç**
- [ ] Proje oluşturulduktan sonra auto-generated ContentView.swift vb. SİL
  (bizim dosyalarımız zaten var)

### Dakika 15-20: Deployment Target & Signing
- [ ] Project Navigator → NiyazPusulasi (mavi ikon) tıkla
- [ ] TARGETS → NiyazPusulasi seç
- [ ] General tab:
  - Minimum Deployments: iOS 17.0
  - Display Name: Niyaz Pusulası
  - Bundle Identifier: com.niyazpusulasi.app
- [ ] Signing & Capabilities tab:
  - Team: Seç
  - "Automatically manage signing" işaretli olsun

### Dakika 20-25: Widget Extension Target Ekle
- [ ] File → New → Target
- [ ] iOS → Widget Extension seç
- [ ] Ayarlar:
  - Product Name: `NiyazPusulasWidget`
  - Bundle Identifier: `com.niyazpusulasi.app.widget` (otomatik)
  - "Include Live Activity" işaretleme
  - "Include Configuration App Intent" işaretleme
- [ ] Auto-generated widget dosyalarını SİL (bizimkiler var)
- [ ] Widget target'ın Deployment Target'ını iOS 17.0 yap

### Dakika 25-30: App Groups Capability
- [ ] Ana target (NiyazPusulasi) seç → Signing & Capabilities
- [ ] "+ Capability" → "App Groups" ekle
- [ ] `group.com.niyazpusulasi.shared` ekle
- [ ] Widget target'a da AYNI App Group'u ekle

### Dakika 30-35: SPM Dependencies Ekle
- [ ] File → Add Package Dependencies
- [ ] İlk paket:
  - URL: `https://github.com/batoulapps/adhan-swift.git`
  - Dependency Rule: Up to Next Major → 1.4.0
  - Add to Target: NiyazPusulasi
- [ ] İkinci paket:
  - URL: `https://github.com/RevenueCat/purchases-ios.git`
  - Dependency Rule: Up to Next Major → 5.0.0
  - Add to Target: NiyazPusulasi
  - "RevenueCat" library'yi seç

### Dakika 35-40: Dosyaları Target'lara Ekle
- [ ] Project Navigator'da NiyazPusulasi klasörünü seç
- [ ] Tüm .swift dosyalarının "Target Membership"inde NiyazPusulasi işaretli olsun
- [ ] NiyazPusulasWidget klasöründeki dosyaların target'ı NiyazPusulasWidget olsun
- [ ] NiyazPusulasTests klasöründeki dosyaların target'ı NiyazPusulasTests olsun
- [ ] CoreData model dosyasını (.xcdatamodeld) ana target'a ekle

### Dakika 40-45: Build Test Et
- [ ] Product → Build (Cmd+B)
- [ ] Hataları not al
- [ ] Varsa hızlıca düzelt (genellikle import veya target membership sorunları)

### Dakika 45-50: Simülatörde Çalıştır
- [ ] Simulator: iPhone 15 Pro seç
- [ ] Product → Run (Cmd+R)
- [ ] Uygulamanın açıldığını doğrula
- [ ] Temel navigasyonu test et (tab'lar arası geçiş)

### Dakika 50-55: Screenshot Al (Opsiyonel)
- [ ] Simülatör açıkken: File → New Screen Shot (veya Cmd+S)
- [ ] TodayView, RamadanView, HabitsView screenshot'ları al
- [ ] Screenshot'ları proje klasörüne kaydet

### Dakika 55-60: Push ve Temizlik
- [ ] Terminal'de:
  ```bash
  cd ~/Desktop/niyaz-pusulasi
  git add .
  git commit -m "Add Xcode project with targets, signing, and dependencies"
  git push origin main
  ```
- [ ] Push'un başarılı olduğunu doğrula
- [ ] MacinCloud'dan çıkış yap

---

## Build Hataları İçin Hızlı Çözümler

### "No such module 'Adhan'"
→ SPM package resolve bekle (sağ üstte loading göstergesi)
→ Product → Clean Build Folder → tekrar Build

### "No such module 'RevenueCat'"
→ Aynı çözüm (SPM resolve)

### "Multiple commands produce..."
→ Build Phases → Copy Bundle Resources → duplicate'leri sil

### Target membership hatası
→ Dosya seç → File Inspector (sağ panel) → Target Membership kontrol et

### App Group hatası
→ Signing & Capabilities → App Groups → doğru identifier kontrol et

### CoreData model bulunamıyor
→ .xcdatamodeld dosyasını Project Navigator'da doğru yere sürükle

---

## SONRA YAPILACAKLAR (MacinCloud'dan sonra, Windows'ta)

- [ ] GitHub'da .xcodeproj dosyasının push edildiğini kontrol et
- [ ] GitHub Actions workflow'un çalışıp çalışmadığını kontrol et
- [ ] RevenueCat API key'i PremiumManager.swift'e ekle
- [ ] GitHub Secrets ekle (ASC_KEY_ID, ASC_ISSUER_ID, vb.)
- [ ] App Store Connect'te app oluştur
- [ ] Abonelik ürünleri oluştur
- [ ] Gizlilik politikası URL'sini yayınla (GitHub Pages)
- [ ] İlk TestFlight build'i: `git tag v1.0.0 && git push origin v1.0.0`
