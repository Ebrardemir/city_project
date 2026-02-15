## 🤖 Google Cloud Vision API - Fake Report Detection Kurulum

Yapay zeka destekli sahte ihbar tespiti için Google Cloud Vision API gereklidir.

### 📋 Gerekli Adımlar

#### 1. Google Cloud Project Oluştur
```bash
1. Google Cloud Console'a git: https://console.cloud.google.com/
2. Yeni bir proje oluştur (veya mevcut projeyi kullan)
3. Proje adı: "CityProject-Vision" (örnek)
4. Create'i tıkla
```

#### 2. Vision API'yi Etkinleştir
```bash
1. Console'da "APIs & Services" > "Library" bölümüne git
2. "Vision API" ara
3. "Enable" butonuna tıkla
4. Etkinleştirilmesini bekle
```

#### 3. Servis Hesabı Oluştur
```bash
1. "APIs & Services" > "Credentials" bölümüne git
2. "Create Credentials" > "Service Account" seç
3. Bilgileri doldur:
   - Service account name: city-project-vision
   - Service account ID: city-project-vision
   - Description: AI Vision API for fake report detection
4. "Create and Continue" tıkla
```

#### 4. API Key'i Oluştur (REST API için)
```bash
# REST API kullanıyoruz (Server-side validation için ideal)

1. Credentials sayfasında "Create Credentials" > "API Key" seç
2. API Key oluşturulur
3. **ÖNEMLİ**: Bu key'i hemen yapıştır (bir sonraki adımda görmeyeceksin)
```

#### 5. API Key'i Projeye Ekle

**Option 1: Android**
```properties
# android/local.properties dosyasına ekle
google.cloud.vision.api.key=AIzaSyC...YOUR_API_KEY_HERE...xyz
```

**Option 2: iOS**
```
# ios/Flutter/Secrets.xcconfig dosyasına ekle
GOOGLE_CLOUD_VISION_API_KEY = AIzaSyC...YOUR_API_KEY_HERE...xyz
```

**Option 3: Firebase Remote Config (Production için - Önerilen)**
```
1. Firebase Console'da "Remote Config" sayfasına git
2. Yeni parameter ekle:
   - Parameter key: google_cloud_vision_api_key
   - Default value: API_KEY_HERE
3. Yayınla (Publish)
```

**Option 4: Environment Variable**
```bash
# .env dosyasına (flutter_dotenv kullanıyorsan)
GOOGLE_CLOUD_VISION_API_KEY=AIzaSyC...YOUR_API_KEY_HERE...xyz
```

#### 6. Kodda Kullan
```dart
// lib/main.dart
import 'package:city_project/core/Services/api_keys_config.dart';

void main() async {
  // API Keys'i initialize et
  await ApiKeysConfig.initializeApiKeys();
  
  // ...rest of the code
}
```

### 🔍 Fake Detection Algoritması

Yüklenen görüntüler aşağıdaki kriterlere göre analiz edilir:

#### ✅ Legitimate Report (Onaylanır)
- Açık ve net görüntü
- Gerçek mekanda çekilmiş fotoğraf
- Face/Selfie etiketi yok
- "Blur", "Darkness" minimum seviyede

#### ❌ Fake Report (Reddedilir - Status: `fake`)

1. **Selfie Tespiti**
   - Yüz tespit edilirse
   - "Selfie", "Person" etiketi varsa
   - Confidence: 0.95

2. **Bulanık Görüntü**
   - "Blur" etiketi tespit edilirse
   - Confidence: 0.85

3. **Karanlık/Düşük Kalite**
   - "Darkness", "Dark", "Night" etiketleri
   - Confidence: 0.80

4. **Ekran Görüntüsü**
   - "Screenshot", "Monitor" etiketi
   - Confidence: 0.90

5. **Çizim/Grafik**
   - "Drawing", "Sketch", "Art" etiketi
   - Confidence: 0.85

#### ⚠️ Flagged Report (Manuel Review - Status: `flagged`)
- İç mekan fotoğrafları (yol kategorisi için uyumsuz)
- Düşük confidence ama şüpheli

### 📊 Vision API Yanıtı Örneği

```json
{
  "responses": [
    {
      "labelAnnotations": [
        {
          "mid": "/m/0bt9lr",
          "description": "Road",
          "score": 0.95
        },
        {
          "mid": "/m/04gy_q",
          "description": "Pothole",
          "score": 0.87
        }
      ],
      "faceAnnotations": [], // Boşsa selfie değil
      "safeSearchAnnotation": {
        "adult": "VERY_UNLIKELY",
        "medical": "UNLIKELY",
        "violent": "VERY_UNLIKELY",
        "racy": "UNLIKELY"
      }
    }
  ]
}
```

### 🚀 Test Etme

```dart
// Quick Test
import 'package:city_project/core/Services/ai_vision_service.dart';

void testVision() async {
  final visionService = AIVisionService(
    apiKey: 'YOUR_API_KEY_HERE'
  );
  
  final file = File('/path/to/image.jpg');
  final result = await visionService.analyzeImage(file);
  
  print('Fake Detected: ${result.isFake}');
  print('Reason: ${result.reason.label}');
  print('Confidence: ${result.confidence}');
  print('Labels: ${result.detectedLabels}');
}
```

### 💰 Maliyet

- İlk 1000 request/ay: **Ücretsiz**
- Sonrası: $1.50 per 1000 requests
- Label Detection: $0.60 per 1000 requests
- Face Detection: $0.15 per 1000 requests

### ⚠️ Güvenlik Notları

1. **API Key'i Commit Etme**
   - `.gitignore`'da sakla
   - Public repository'de asla paylaşma

2. **Rate Limiting**
   - Production'da rate limit kontrol et
   - Backend validation yap

3. **User Privacy**
   - Uploaded images'ları hemen sil
   - Logging'de sensitive data sakla

4. **Error Handling**
   - API down olsa bile report oluşturulmalı (isFakeDetected = null)
   - User'a "API şu anda hazır değil" mesajı göster

### 🔗 Faydalı Linkler

- Vision API Docs: https://cloud.google.com/vision/docs
- Label Descriptions: https://cloud.google.com/vision/docs/labels
- Pricing: https://cloud.google.com/vision/pricing
- REST API Reference: https://cloud.google.com/vision/docs/reference/rest

### ✅ Checklist

- [ ] Google Cloud Project oluşturdum
- [ ] Vision API'yi etkinleştirdim
- [ ] Servis hesabı oluşturdum
- [ ] API Key oluşturdum
- [ ] API Key'i güvenli bir şekilde ekledim
- [ ] Android/iOS'ta test ettim
- [ ] Fake detection çalışıyor
- [ ] Admin panelinde flagged reports görünüyor
