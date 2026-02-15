# 🔐 API Keys Kurulum Rehberi

Bu dosya, Google Maps API key'lerinizi güvenli bir şekilde nasıl ekleyeceğinizi açıklar.

## ⚠️ ÖNEMLİ
Bu API key dosyaları **GİTİGNORE**'a eklenmiştir ve GitHub'a yüklenmeyecektir!

---

## 📱 Android için API Key Ekleme

1. **`android/local.properties`** dosyasını açın
2. Dosyanın sonundaki şu satırı bulun:
   ```properties
   google.maps.api.key=YOUR_ANDROID_API_KEY_HERE
   ```
3. `YOUR_ANDROID_API_KEY_HERE` yerine **Android API Key**'inizi yazın:
   ```properties
   google.maps.api.key=AIzaSyC...your_actual_key...xyz
   ```

### Android'de Nasıl Çalışır?
- API key `android/local.properties` dosyasında saklanır
- `build.gradle.kts` dosyası bunu okur ve `AndroidManifest.xml`'e aktarır
- `local.properties` dosyası `.gitignore`'da olduğu için GitHub'a gitmez

---

## 🍎 iOS için API Key Ekleme

1. **`ios/Flutter/Secrets.xcconfig`** dosyasını açın
2. Şu satırı bulun:
   ```
   GOOGLE_MAPS_API_KEY = YOUR_IOS_API_KEY_HERE
   ```
3. `YOUR_IOS_API_KEY_HERE` yerine **iOS API Key**'inizi yazın:
   ```
   GOOGLE_MAPS_API_KEY = AIzaSyC...your_actual_key...xyz
   ```

### iOS'ta Nasıl Çalışır?
- API key `ios/Flutter/Secrets.xcconfig` dosyasında saklanır
- `Debug.xcconfig` ve `Release.xcconfig` bunu import eder
- `Info.plist` dosyası bu değişkeni okur
- `AppDelegate.swift` runtime'da bu değeri kullanır
- `Secrets.xcconfig` dosyası `.gitignore`'da olduğu için GitHub'a gitmez

---

## 🚀 Kurulum Sonrası

API key'leri ekledikten sonra şu komutları çalıştırın:

```bash
# iOS için pod kurulumu
cd ios && pod install && cd ..

# Temiz build
flutter clean
flutter pub get

# Uygulamayı çalıştır
flutter run
```

---

## 👥 Takım Arkadaşlarınız İçin

Yeni bir geliştirici projeye katıldığında:

1. **iOS için**: `ios/Flutter/Secrets.xcconfig.example` dosyasını kopyalayıp `Secrets.xcconfig` olarak kaydedin ve kendi key'inizi ekleyin
2. **Android için**: `android/local.properties` dosyasının sonuna kendi key'inizi ekleyin

---

## ✅ Güvenlik Kontrolleri

Şu dosyaların `.gitignore`'da olduğundan emin olun:
- ✅ `/android/local.properties`
- ✅ `/ios/Flutter/Secrets.xcconfig`

Şu dosyalar GitHub'a gidebilir (örnek dosyalar):
- ✅ `/ios/Flutter/Secrets.xcconfig.example`

---

## 🆘 Sorun Giderme

### Harita Görünmüyor (Android)
1. `android/local.properties` dosyasında API key doğru mu?
2. Google Cloud Console'da Android API'si etkin mi?
3. Package name doğru mu? (`com.example.city_project`)
4. SHA-1 fingerprint eklediniz mi?

### Harita Görünmüyor (iOS)
1. `ios/Flutter/Secrets.xcconfig` dosyasında API key doğru mu?
2. Pod kurulumu yaptınız mı? (`cd ios && pod install`)
3. Google Cloud Console'da iOS API'si etkin mi?
4. Bundle ID doğru mu?

### API Key Kontrolü
```bash
# Android
cat android/local.properties | grep "google.maps"

# iOS
cat ios/Flutter/Secrets.xcconfig | grep "GOOGLE_MAPS"
```

