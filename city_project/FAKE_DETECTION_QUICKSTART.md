## ⚡ Fake Detection - Quick Start (5 dakika)

### 1️⃣ Google Cloud API Key Oluştur (2 dakika)

```bash
1. https://console.cloud.google.com/ aç
2. Yeni proje oluştur: "CityProject"
3. APIs & Services > Library > "Vision API" ara > Enable
4. Credentials > Create API Key
5. API Key'i kopyala: AIzaSyC...xyz
```

### 2️⃣ API Key'i Ekle (1 dakika)

**Windows/Android:**
```properties
# android/local.properties
google.cloud.vision.api.key=AIzaSyC...xyz
```

**macOS/iOS:**
```
# ios/Flutter/Secrets.xcconfig
GOOGLE_CLOUD_VISION_API_KEY = AIzaSyC...xyz
```

### 3️⃣ Kodu Ekle (1 dakika)

```dart
// lib/main.dart
import 'package:city_project/core/services/ai_vision_service.dart';

// TODO: Bu satırı kaldır
// const String? googleCloudApiKey = null;

// Bunun yerine koy:
const String? googleCloudApiKey = 'AIzaSyC...xyz'; // Veya env'den oku
```

### 4️⃣ Test Et (1 dakika)

```bash
flutter clean
flutter pub get
flutter run

# App'te:
1. + Rapor Oluştur
2. Selfie/Bulanık resim seç
3. "Fotoğrafı Kontrol Et" tap
4. Result göster ✨
```

---

## 🎯 Neler Oldu?

✅ **AI Fake Detection kuruldu**
✅ **ReportModel updated** - AI fields eklendi
✅ **ReportService** - Fake detection entegre
✅ **CreateReportViewModel** - Image analysis metodu
✅ **Admin review widget** - Şüpheli raporları göster

---

## 📋 Fake Detection Mantığı

```
Image Upload
    ↓
Google Vision API
    ↓
Tespit et: Selfie? Blur? Darkness? Screenshot? Drawing?
    ↓
YES → Status = "fake" → Admin Queue
NO  → Status = "pending" → Normal flow
    ↓
Admin: Onayla / Reddet
```

---

## 🔍 Test Örnekleri

### Fake Olarak Tespit Edilecek:
- Ayna selfie (Face tespit)
- Çok bulanık fotoğraf
- Gece çekilmiş (karanlık)
- Telefon ekranı
- Çizim/Grafik

### Legitimate Olarak Geçecek:
- Açık, net yol fotoğrafı
- Gündüz çekilmiş
- Gerçek mekan
- Yüz yok

---

## 🐛 Sorun?

```dart
// API Key yok? → AIVisionService null
// Rapor yine de oluşturulur (isFakeDetected = null)

// API error? → Graceful fallback
// Rapor oluşturulur (isFakeDetected = null)

// Image download failed? → Skip analysis
// Rapor oluşturulur

// Fake positive (yanlış tespit)? → Admin "Onayla"
// Status pending olur, normal flow
```

---

## ✨ Sonraki İyileştirmeler

- [ ] Local image optimization (compress)
- [ ] Batch processing (multiple images)
- [ ] Caching (aynı image tekrar analiz etme)
- [ ] Custom models (domain-specific)
- [ ] Offline mode (cache results)
- [ ] User feedback loop (Admin verdicts → ML improvement)

---

**Başarı! Fake Detection hazır 🚀**
