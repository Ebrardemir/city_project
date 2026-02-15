## 🤖 AI-Destekli Fake İhbar Tespiti - Implementation Guide

### 📋 Özet

Bu özellik, yapay zeka (Google Cloud Vision API) kullanarak yüklenen fotoğrafları analiz eder ve aşağıdaki problematik vakaları otomatik olarak tespit eder:

- **Selfie**: Kullanıcının kendi fotoğrafı
- **Bulanık (Blur)**: Kalite düşük fotoğraflar
- **Karanlık (Darkness)**: Aydınlık yetersiz fotoğraflar
- **Ekran Görüntüsü**: Telefon/monitor ekranından alınmış fotoğraf
- **Çizim/Grafik**: Gerçek fotoğraf değil, çizim veya grafik
- **İç Mekan**: Yol kategorisinde iç mekan fotoğrafları (uyarı)

Tespit durumunda, rapor otomatik olarak **`fake`** veya **`flagged`** durumuna geçer ve Admin onayına gider.

---

## 🗂️ Oluşturulan/Güncellenmiş Dosyalar

### 1. **Core Services**

#### `lib/core/Services/ai_vision_service.dart` ✨ **YENİ**
- Google Cloud Vision API ile iletişim kurar
- Görüntü analizi yapar ve fake oranı hesaplar
- Tespit edilen labels (etiketler) döndürür
- Enum: `FakeDetectionReason`, `FakeDetectionResult`

**Kullanım:**
```dart
final visionService = AIVisionService(apiKey: 'YOUR_API_KEY');
final result = await visionService.analyzeImage(imageFile);

if (result.isFake) {
  print('Fake tespit: ${result.reason.label}');
  print('Güven: ${result.confidence * 100}%');
  print('Labels: ${result.detectedLabels}');
}
```

#### `lib/core/Services/api_keys_config.dart` ✨ **YENİ**
- API key'ler için merkezi konfigürasyon
- Firebase Remote Config integration noktası
- Environment variable desteği

---

### 2. **Home Feature - Model**

#### `lib/Features/Home/model/report_model.dart` 🔄 **GÜNCELLENDI**
- Yeni Enum: `FakeReportReason`
- ReportStatus'e `flagged` eklendi
- ReportModel'e AI detection fields:
  - `isFakeDetected: bool?`
  - `fakeReason: FakeReportReason?`
  - `fakeConfidence: double?`
  - `aiDetectedLabels: List<String>?`
  - `fakeDetectionTime: DateTime?`

```dart
// Örnek rapor
final report = ReportModel(
  // ... diğer fields ...
  status: ReportStatus.fake,
  isFakeDetected: true,
  fakeReason: FakeReportReason.selfie,
  fakeConfidence: 0.95,
  aiDetectedLabels: ['Face', 'Person', 'Selfie'],
);
```

---

### 3. **Home Feature - Service**

#### `lib/Features/Home/service/report_service.dart` 🔄 **GÜNCELLENDI**

**Constructor Değişikliği:**
```dart
// Eskisi
ReportService();

// Yenisi
ReportService({AIVisionService? aiVisionService})
```

**Yeni Metodlar:**

1. **`createReport()` - Güncellenmiş**
   - Rapor oluşturulurken AI analiz yapılır
   - Eğer fake tespit edilirse: `status = ReportStatus.fake`
   - Analiz sonuçları rapor'a kaydedilir
   - Analiz başarısız olsa bile rapor oluşturulur

2. **`getFakeFlaggedReports()`** ✨ **YENİ**
   - Admin paneli için fake/flagged raporları getirir
   - Güncel sıralama: fakeDetectionTime descending

3. **`adminReviewFakeReport()`** ✨ **YENİ**
   - Admin aksiyonu: Onay/Red
   - Rapor durumunu günceller

---

### 4. **CreateReport Feature - ViewModel**

#### `lib/Features/CreateReport/viewmodel/create_report_viewmodel.dart` 🔄 **GÜNCELLENDI**

**Yeni Fields:**
```dart
bool analyzingImage = false;
FakeDetectionResult? lastAnalysisResult;
bool? imageAnalysisWarning;
```

**Yeni Metodlar:**

1. **`setImagePath()`** - Güncellenmiş
   - Yeni resim seçilince önceki analiz temizlenir

2. **`analyzeImage()`** ✨ **YENİ**
   - Seçilen resmi AI ile analiz eder
   - Fake tespit edilirse kullanıcıya uyarı gösterir
   - `imageAnalysisWarning` flag'ini set eder

**Kullanım:**
```dart
// Resim seçildikten sonra
await viewModel.analyzeImage();

if (viewModel.imageAnalysisWarning == true) {
  // Uyarı göster: "${lastAnalysisResult.reason.label}"
}
```

---

### 5. **Admin Feature - Widget**

#### `lib/Features/Admin/widgets/fake_report_review_widget.dart` ✨ **YENİ**
- Fake/Flagged raporları inceleme ekranı
- AI detection sonuçlarını gösterir
- Admin: Onay/Red karar verir
- Tespit edilen labels'ları gösterir

---

### 6. **Main App**

#### `lib/main.dart` 🔄 **GÜNCELLENDI**
```dart
// AIVisionService provider eklendi
if (googleCloudApiKey != null)
  Provider<AIVisionService>(
    create: (_) => AIVisionService(apiKey: googleCloudApiKey),
  ),

// ReportService'e AI service pass edilir
ReportService(aiVisionService: aiVisionService)
```

---

### 7. **Dependencies**

#### `pubspec.yaml` 🔄 **GÜNCELLENDI**
```yaml
dependencies:
  http: ^1.2.2
  google_cloud_vision_api: ^1.0.0  # Yeni
```

---

### 8. **Dokümantasyon**

#### `GOOGLE_VISION_API_SETUP.md` ✨ **YENİ**
- Google Cloud Console kurulum adımları
- API key oluşturma rehberi
- Dart kodunda entegrasyon talimatları
- Test komutları

---

## 🚀 Kullanım Akışı

### User Perspektifi

```
1. Kullanıcı rapor formunu açar
   ↓
2. Fotoğraf seçer
   ↓
3. [OPSİYONEL] "Fotoğrafı Kontrol Et" butonu tıklar
   ↓
4. AI Analiz başlar (Loading spinner)
   ↓
5a. Legitimate → "Fotoğraf onaylandı" mesajı ✅
   ↓
5b. Fake Tespit → "⚠️ Selfie tespit edildi (95% kesinlik)"
    Kullanıcı seçer:
    - "Yine de Gönder" → Admin inceleyecek
    - "Fotoğrafı Değiştir" → Yeni fotoğraf seçer
   ↓
6. Rapor gönderilir
   ↓
7a. Fake değilse → Status: "pending" → Admin hızlı onay
   ↓
7b. Fake ise → Status: "fake" → Admin'e özel inceleme kuyruğu
```

### Admin Perspektifi

```
1. Admin panelinde "Şüpheli İhbarlar" sekmesi açar
   ↓
2. Fake/Flagged raporların listesini görür
   ↓
3. Bir rapor seçer
   ↓
4. AI tarafından tespit edilen bilgileri inceler:
   - Neden: Selfie
   - Güven Seviyesi: 95%
   - Tespit edilen Labels: Face, Person, Selfie
   ↓
5. Admin karar verir:
   - "Onayla" → Status: pending → Normal onay flow'una gider
   - "Reddet" → Status: fake → Reject
```

---

## 🔧 Integration Checklist

### Backend Integration

- [ ] Google Cloud Console'da proje oluştur
- [ ] Vision API'yi etkinleştir
- [ ] API Key oluştur ve `.env` / `.xcconfig` / `local.properties`'e ekle
- [ ] `firebase_options.dart`'da API key tanımı yap (optional)
- [ ] `main.dart`'da `ApiKeysConfig.initializeApiKeys()` call et

### Database (Firestore)

- [ ] Report collection'ında indexing:
  ```
  - status (ascending)
  - fakeDetectionTime (descending) - YENI
  ```
- [ ] Mevcut raporlar'da migration script çalıştır (optional):
  ```dart
  // AI fields'ları null/false olarak initialize et
  isFakeDetected: null
  fakeReason: null
  fakeConfidence: null
  aiDetectedLabels: null
  fakeDetectionTime: null
  ```

### Frontend UI

- [ ] CreateReport sayfasında "Fotoğrafı Kontrol Et" butonu ekle
  - Tap → `await viewModel.analyzeImage()`
  - Loading göster
  - Sonuç göster

- [ ] Admin panelinde "Şüpheli İhbarlar" tab'ı ekle
  - `ReportService.getFakeFlaggedReports()` call et
  - `FakeReportReviewWidget` göster

- [ ] ReportDetail sayfasında AI detection info göster (optional)
  ```dart
  if (report.isFakeDetected != null)
    _buildAIDetectionInfo(report)
  ```

### Error Handling

- [ ] API key missing → Graceful fallback (Analiz yapma, ama rapor oluştur)
- [ ] API rate limit → Retry with exponential backoff
- [ ] Image download failed → Analiz skip et, rapor devam et
- [ ] API timeout → 30 saniye limit, fallback

### Testing

- [ ] Test selfie image → Fake tespit et
- [ ] Test blur image → Fake tespit et
- [ ] Test normal road image → Legitimate sonuç
- [ ] Test API key invalid → Graceful error
- [ ] Test network error → Fallback

---

## 📊 Database Schema

```json
// Firestore: reports/{id}
{
  "id": "report_123",
  "userId": "user_456",
  "status": "fake",  // pending | approved | resolved | fake | flagged
  "category": "road",
  
  // ... diğer fields ...
  
  // AI Detection Fields (YENİ)
  "isFakeDetected": true,
  "fakeReason": "selfie",
  "fakeConfidence": 0.95,
  "aiDetectedLabels": ["Face", "Person", "Selfie"],
  "fakeDetectionTime": Timestamp.now(),
  
  // Admin Review (optional)
  "adminReviewNotes": "User kendi fotoğrafını yüklemiş",
  "adminReviewedAt": Timestamp.now(),
  "adminReviewedBy": "admin_789"
}
```

---

## 🔐 Güvenlik & Privacy

1. **API Key Protection**
   - `.gitignore`'da sakla
   - Firebase Secret Manager / Remote Config kullan
   - Production ortamı ayrı key

2. **Image Processing**
   - Temp file'ları hemen sil
   - Logging'de sensitive data log etme
   - GDPR compliance: User tarafından silinebilir

3. **Rate Limiting**
   - Per-user analysis limit koy
   - Spam detection (ör: 5+ analiz/saat = flag)
   - Backend'de double-check

4. **Admin Access**
   - Sadece admin role fake reports görebilir
   - Audit log: Kim ne aksiyonu aldı
   - Review history

---

## 📈 Performance Optimization

1. **Image Processing**
   - Max image size: 4MB
   - Compress before sending
   - Client-side: Local image optimization

2. **API Calls**
   - Batch processing: Multiple reports in one call (optional)
   - Caching: Aynı image hash'ı 2x analiz etme
   - Queue: Offpeak hours'ta batch process

3. **UI/UX**
   - Loading state optimistic
   - Timeout after 30 sec
   - Background processing ile non-blocking

---

## 🚨 Monitoring & Alerting

1. **Metrics**
   - False positive rate (User "Yine de gönder" seçerse, Admin onayla)
   - False negative rate (Admin fake bulup bizim kaçırdık)
   - API success rate
   - Avg analysis time

2. **Alerts**
   - API key expired
   - High false positive rate > 20%
   - API quota exceeded
   - Unusual pattern (ör: 80% report fake)

---

## 📚 Referanslar

- [Google Cloud Vision API Docs](https://cloud.google.com/vision/docs)
- [Label Detection Guide](https://cloud.google.com/vision/docs/labels)
- [REST API Reference](https://cloud.google.com/vision/docs/reference/rest)
- [Pricing](https://cloud.google.com/vision/pricing)

---

## ✅ Sonraki Adımlar

1. **Google Cloud Console'da kurulum yap** (GOOGLE_VISION_API_SETUP.md)
2. **API Key'i app'e ekle**
3. **Fake detection UI'ını CreateReport sayfasında integrate et**
4. **Admin review UI'ını Admin panelinde ekle**
5. **Firebase Firestore indexing set et**
6. **Test et**: Selfie upload → Fake tespit → Admin gözden geçir
7. **Deploy et**: Staging → Production

---

**Son Güncelleme:** 15 Şubat 2026
**Durum:** ✅ Implementation Tamamlandı - Hazır Entegrasyon
