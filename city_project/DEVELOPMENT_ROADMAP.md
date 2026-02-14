# 🚀 CityPulse - Geliştirme Yol Haritası

**Proje:** Belediye Sosyal Ağı ve Çözüm Platformu  
**Versiyon:** 1.0 (MVP - Hackathon Sürümü)  
**Tarih:** 14 Şubat 2026  
**Teknoloji:** Flutter + Firebase (Auth, Firestore, Storage) + Google Maps API

---

## 📊 Mevcut Durum Analizi

### ✅ Tamamlanmış Özellikler

1. **Firebase Entegrasyonu**
   - ✅ Firebase Authentication (Email/Password)
   - ✅ Cloud Firestore (Veritabanı)
   - ✅ Firebase Storage (Görsel yükleme)
   - ✅ Google Sign-In entegrasyonu

2. **Temel Kullanıcı Özellikleri**
   - ✅ Kayıt olma / Giriş yapma
   - ✅ Profil görüntüleme
   - ✅ Kullanıcı modeli (id, fullName, email, role, score, city)

3. **Konum Servisleri**
   - ✅ GPS ile otomatik konum alma
   - ✅ Geocoding (Koordinat → İl/İlçe/Mahalle)
   - ✅ Manuel konum seçimi
   - ✅ Google Maps entegrasyonu

4. **Rapor Yönetimi (Temel)**
   - ✅ Harita üzerinden rapor oluşturma
   - ✅ Manuel (haritasız) rapor oluşturma
   - ✅ Fotoğraf yükleme (imageUrlBefore)
   - ✅ ReportModel (kategori, durum, koordinat, açıklama)
   - ✅ Raporları listeleme (Home, MyReports, NearbyReports)
   - ✅ Rapor detay sayfası
   - ✅ Custom marker ikonları (pending, approved, resolved, fake)

5. **UI/UX**
   - ✅ Tema yönetimi (Light/Dark mode)
   - ✅ Bottom Navigation Bar
   - ✅ Go Router ile sayfa yönlendirme
   - ✅ Provider state management

---

## 🔴 EKSİK ÖZELLİKLER ve GELİŞTİRİLECEK ALANLAR

### 1️⃣ **ÖNCELIK 1: Belediye Yetkilisi (Municipality) Özellikleri**

#### 🎯 Problem:
- Şu anda `role` field'ı var ama sadece UI'da gösteriliyor
- Belediye yetkilisi için özel yetkiler ve arayüz yok
- Çözüm fotoğrafı (Before/After) yükleme özelliği eksik

#### ✨ Çözüm:
**1.1. Firestore Kullanıcı Koleksiyonu Güncellemesi**
```
users/ (collection)
  └── {userId}/
      ├── fullName: string
      ├── email: string
      ├── role: string ("citizen" | "municipality" | "admin")
      ├── score: number
      ├── cityId: string (belediye için önemli)
      ├── city: string (İstanbul)
      ├── district: string (Kadıköy)
      ├── districts: array<string> (Belediye yetkilisi için: ["Kadıköy", "Maltepe"])
      ├── createdAt: timestamp
```

**1.2. Role Bazlı Navigasyon**
- Citizen: Home → Nearby → Messages → Profile
- Municipality: Municipality Dashboard → Reports Management → Profile

**1.3. Belediye Dashboard Ekranı** (`MunicipalityDashboardView`)
- Sorumlu olunan mahallelerdeki raporları listeleme
- Durum filtreleri (Pending, Approved, Resolved)
- Kategori filtreleri
- Harita görünümü
- Tablo görünümü (DataTable)

**1.4. Rapor Çözme Özelliği** (`ResolveReportView`)
- Sadece Municipality rolü erişebilir
- "Çözüldü Olarak İşaretle" butonu
- Çözüm fotoğrafı yükleme (imageUrlAfter)
- Çözüm notu ekleme
- Status'u "resolved" olarak güncelleme
- resolvedAt timestamp'i ekleme

---

### 2️⃣ **ÖNCELIK 2: Smart Clustering (Akıllı Gruplama) Algoritması**

#### 🎯 Problem:
- Aynı yerde onlarca rapor açılabilir → Belediye iş yükü artar
- supportCount field'ı var ama kullanılmıyor
- Haversine formülü ile yakındaki raporları kontrol etme yok

#### ✨ Çözüm:
**2.1. Clustering Servisi Oluştur** (`lib/core/services/clustering_service.dart`)

```dart
class ClusteringService {
  // Haversine formülü ile mesafe hesaplama (metre cinsinden)
  double calculateDistance(
    double lat1, double lng1, 
    double lat2, double lng2
  ) {
    const R = 6371000; // Dünya yarıçapı (metre)
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
              cos(_degreesToRadians(lat1)) * 
              cos(_degreesToRadians(lat2)) *
              sin(dLng / 2) * sin(dLng / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Metre cinsinden
  }
  
  // Yakındaki benzer raporu kontrol et
  Future<String?> checkNearbyReport({
    required double latitude,
    required double longitude,
    required String category,
    double radiusMeters = 20.0,
  }) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reports')
        .where('category', isEqualTo: category)
        .where('status', whereIn: ['pending', 'approved'])
        .get();
    
    for (var doc in snapshot.docs) {
      final report = ReportModel.fromJson(doc.data());
      final distance = calculateDistance(
        latitude, longitude,
        report.latitude, report.longitude,
      );
      
      if (distance <= radiusMeters) {
        return doc.id; // Yakında benzer rapor bulundu
      }
    }
    
    return null; // Yeni rapor oluşturulabilir
  }
  
  // Mevcut rapora destek ekle
  Future<void> addSupport(String reportId, String userId) async {
    final docRef = FirebaseFirestore.instance
        .collection('reports')
        .doc(reportId);
    
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final supportedUserIds = List<String>.from(
        snapshot.data()?['supportedUserIds'] ?? []
      );
      
      if (!supportedUserIds.contains(userId)) {
        supportedUserIds.add(userId);
        transaction.update(docRef, {
          'supportCount': FieldValue.increment(1),
          'supportedUserIds': supportedUserIds,
        });
      }
    });
  }
}
```

**2.2. CreateReportViewModel'e entegre et**
- Rapor oluşturmadan önce `checkNearbyReport()` çağır
- Eğer yakında rapor varsa → "Bu sorun zaten bildirilmiş, desteğinizi ekledik" mesajı
- Yoksa → Yeni rapor oluştur

**2.3. Google Maps Clustering**
- `google_maps_cluster_manager` paketi ekle
- Harita üzerinde birbirine yakın pinleri tek bir marker ile göster
- Marker'a tıklayınca cluster'daki raporları listele

---

### 3️⃣ **ÖNCELIK 3: Before/After Özelliği**

#### 🎯 Problem:
- `before_after` paketi yüklü ama kullanılmıyor
- `imageUrlAfter` field'ı var ama UI'da gösterilmiyor

#### ✨ Çözüm:
**3.1. ReportDetailView Güncellemesi**

```dart
// Eğer status == resolved && imageUrlAfter != null
if (report.status == ReportStatus.resolved && 
    report.imageUrlAfter != null) {
  BeforeAfter(
    beforeImage: CachedNetworkImageProvider(report.imageUrlBefore!),
    afterImage: CachedNetworkImageProvider(report.imageUrlAfter!),
    thumbColor: Colors.white,
    thumbRadius: 20.0,
  )
} else {
  // Normal image widget
  CachedNetworkImage(imageUrl: report.imageUrlBefore!)
}
```

**3.2. Municipality Resolve UI**
- Belediye yetkilisi "Çözüldü" işaretlerken imageUrlAfter yükleyebilsin
- Preview özelliği: Before/After slider ile önizleme
- "Yayınla" butonu ile Firestore'a kaydet

---

### 4️⃣ **ÖNCELIK 4: Gamification (Oyunlaştırma) Sistemi**

#### 🎯 Problem:
- UserModel'de `score` field'ı var ama güncelleme yok
- Liderlik tablosu yok
- Kullanıcıları teşvik eden bir sistem yok

#### ✨ Çözüm:
**4.1. Puan Sistemi**
```
- Rapor oluşturma: +10 puan
- Rapor çözülünce (raporlayan): +25 puan
- Başka rapora destek verme: +5 puan
- Fake rapor (ceza): -20 puan
```

**4.2. Firestore Koleksiyonu**
```
gamificationLog/ (collection)
  └── {logId}/
      ├── userId: string
      ├── action: string ("create_report" | "support" | "resolved" | "fake")
      ├── points: number (+10, -20)
      ├── reportId: string
      ├── createdAt: timestamp
```

**4.3. Liderlik Tablosu** (`LeaderboardView`)
- Firebase Query: users koleksiyonunu score'a göre sırala (limit: 50)
- Kartlar: Sıralama, Avatar, İsim, Puan, Rozet
- Kullanıcının kendi sıralaması highlight

**4.4. Rozetler (Badges)**
- 🥉 Bronz: 100 puan
- 🥈 Gümüş: 500 puan
- 🥇 Altın: 1000 puan
- 💎 Elmas: 5000 puan

---

### 5️⃣ **ÖNCELIK 5: Mahalle Bazlı Filtreleme ve Yönetim**

#### 🎯 Problem:
- Sadece il/ilçe var, mahalle bilgisi eksik
- Belediye yetkilisi için mahalle bazlı filtreleme yok

#### ✨ Çözüm:
**5.1. Firestore Raporlarına Mahalle Ekle**
```dart
// ReportModel'e ekle
final String? neighborhood; // Mahalle

// Geocoding'den al
final place = await _locationService.getAddressFromLatLng(lat, lng);
final neighborhood = place?.subLocality ?? place?.locality;
```

**5.2. Türkiye Mahalle Veritabanı**
- `lib/core/constants/tr_neighborhoods.dart`
- JSON formatında İl → İlçe → Mahalle hiyerarşisi
- Dropdown'larda kullanılacak

**5.3. Municipality Dashboard Filtreleri**
- İlçe seçimi (belediyenin sorumlu olduğu ilçeler)
- Mahalle seçimi (seçilen ilçeye bağlı)
- Kategori filtresi
- Durum filtresi
- Tarih aralığı filtresi

---

### 6️⃣ **ÖNCELIK 6: AI Destekli Fake Rapor Tespiti**

#### 🎯 Problem:
- Kullanıcılar gereksiz veya sahte raporlar açabilir
- Manuel kontrol çok zaman alıyor

#### ✨ Çözüm:
**6.1. Google Cloud Vision API Entegrasyonu**

```dart
class FakeDetectionService {
  Future<bool> analyzeImage(String imageUrl) async {
    // Google Cloud Vision API'ye istek at
    final response = await http.post(
      Uri.parse('https://vision.googleapis.com/v1/images:annotate'),
      headers: {'Authorization': 'Bearer $apiKey'},
      body: json.encode({
        'requests': [{
          'image': {'source': {'imageUri': imageUrl}},
          'features': [
            {'type': 'LABEL_DETECTION'},
            {'type': 'SAFE_SEARCH_DETECTION'},
            {'type': 'IMAGE_PROPERTIES'}
          ]
        }]
      }),
    );
    
    final data = json.decode(response.body);
    final labels = data['responses'][0]['labelAnnotations'];
    
    // Şüpheli etiketleri kontrol et
    final suspiciousLabels = ['selfie', 'person', 'indoor', 'darkness', 'blur'];
    for (var label in labels) {
      if (suspiciousLabels.contains(label['description'].toLowerCase())) {
        return true; // Fake olabilir
      }
    }
    
    return false; // Güvenli görünüyor
  }
}
```

**6.2. Rapor Oluşturma Sırasında Kontrol**
- Fotoğraf yüklendikten sonra Vision API'ye gönder
- Eğer şüpheli ise → Status otomatik "fake" olarak işaretle
- Admin onayına düşsün

**6.3. Admin Panel** (`AdminDashboardView`)
- Fake olarak işaretlenmiş raporları listele
- Manuel onaylama/reddetme
- Kullanıcıya ceza puanı verme

---

### 7️⃣ **ÖNCELIK 7: Bildirimler ve Gerçek Zamanlı Güncellemeler**

#### 🎯 Problem:
- Kullanıcı, raporunun çözüldüğünü bilmiyor
- Belediye, yeni raporlardan haberdar olmuyor

#### ✨ Çözüm:
**7.1. Firebase Cloud Messaging (FCM)**
- `firebase_messaging` paketi ekle
- Push notification izinleri al
- FCM token'ı Firestore'da sakla

**7.2. Bildirim Senaryoları**
```
- Kullanıcının raporu onaylandığında → "Raporunuz belediye tarafından onaylandı!"
- Rapor çözüldüğünde → "Raporunuz çözüldü! 🎉 Before/After görseli eklenmiş."
- Desteklediğiniz rapor çözüldüğünde → "Desteklediğiniz sorun çözüldü!"
- Belediyeye yeni rapor düştüğünde → "Yeni ihbar: Kadıköy/Caferağa - Çöp sorunu"
```

**7.3. Firestore Realtime Updates**
```dart
FirebaseFirestore.instance
    .collection('reports')
    .where('userId', isEqualTo: currentUser.uid)
    .snapshots()
    .listen((snapshot) {
      // UI'ı otomatik güncelle
    });
```

---

### 8️⃣ **ÖNCELIK 8: İstatistikler ve Analitik**

#### 🎯 Problem:
- Kullanıcılar ve belediyeler veri görmüyor
- Kaç rapor, hangi kategoriler, çözüm oranı?

#### ✨ Çözüm:
**8.1. Kullanıcı İstatistikleri** (ProfileView'e ekle)
```
- Toplam Rapor Sayısı: 12
- Çözülen Raporlar: 8
- Bekleyen: 4
- Çözüm Oranı: %66.7
- En Çok Kullandığı Kategori: Çöp
- Toplam Puan: 340
```

**8.2. Belediye Dashboard İstatistikleri**
```
- Toplam Açık Rapor: 47
- Bugün Çözülen: 5
- Ortalama Çözüm Süresi: 3 gün
- En Çok Rapor Alan Mahalle: Caferağa
- Kategori Dağılımı: Pie Chart (Chart.js veya fl_chart)
```

**8.3. Charts (fl_chart paketi)**
- Aylık rapor trendi (Line Chart)
- Kategori dağılımı (Pie Chart)
- Mahalle bazlı heat map

---

### 9️⃣ **ÖNCELIK 9: Performans ve Optimizasyon**

#### 🔧 Yapılacaklar:
**9.1. Görsel Yönetimi**
- ✅ `cached_network_image` paketi ekle (cache mekanizması)
- Firebase Storage'a yüklerken thumbnail oluştur (Cloud Function)
- Haritada thumbnail, detayda full resolution

**9.2. Firestore Indexing**
- Sık kullanılan sorgular için composite index oluştur
```
reports:
  - city ASC, status ASC, createdAt DESC
  - district ASC, category ASC, status ASC
```

**9.3. Pagination (Sayfalama)**
- Raporları 20'şer 20'şer yükle
- "Daha Fazla Yükle" butonu
- Firestore `limit()` ve `startAfter()` kullan

**9.4. Lazy Loading**
- Harita üzerinde sadece görünür alandaki markerları yükle
- Zoom level'a göre marker yoğunluğu ayarla

---

### 🔟 **ÖNCELIK 10: Güvenlik ve Validasyon**

#### 🔒 Yapılacaklar:
**10.1. Firestore Security Rules**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users Collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Reports Collection
    match /reports/{reportId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null 
                    && request.resource.data.userId == request.auth.uid;
      allow update: if request.auth != null && (
        request.auth.uid == resource.data.userId || // Kendi raporu
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'municipality' || // Belediye
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' // Admin
      );
      allow delete: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

**10.2. Input Validasyonu**
- Email formatı kontrolü
- Şifre güçlü mü? (min 8 karakter, büyük/küçük harf, sayı)
- Açıklama alanı (min 10, max 500 karakter)
- Fotoğraf boyutu (max 5MB)
- Koordinat validasyonu (Türkiye sınırları içinde mi?)

**10.3. Rate Limiting**
- Bir kullanıcı günde en fazla 10 rapor açabilir
- 5 dakikada 1 rapor (spam önleme)

---

## 📅 ADIM ADIM GELİŞTİRME PLANI

### 🚀 Faz 1: Temel Özellikler (1-2 Gün)
- [ ] **1.1** - Belediye Dashboard ekranı oluştur
- [ ] **1.2** - Municipality Dashboard View (rapor listesi)
- [ ] **1.3** - Role bazlı bottom navigation (citizen vs municipality)
- [ ] **1.4** - Rapor çözme UI'ı (imageUrlAfter yükleme)
- [ ] **1.5** - Before/After slider entegrasyonu

### 🔥 Faz 2: Smart Clustering (1 Gün)
- [ ] **2.1** - ClusteringService oluştur (Haversine formülü)
- [ ] **2.2** - CreateReport'a entegre et (yakın rapor kontrolü)
- [ ] **2.3** - Google Maps Clustering (google_maps_cluster_manager)
- [ ] **2.4** - Support butonu ve sayaç UI'ı

### 🎮 Faz 3: Gamification (1 Gün)
- [ ] **3.1** - Puan sistemi backend mantığı
- [ ] **3.2** - GamificationLog koleksiyonu
- [ ] **3.3** - Liderlik tablosu ekranı
- [ ] **3.4** - Rozet sistemi ve profil rozetleri

### 🏘️ Faz 4: Mahalle Yönetimi (0.5 Gün)
- [ ] **4.1** - Mahalle field'ı ekle (ReportModel)
- [ ] **4.2** - tr_neighborhoods.dart dosyası (il/ilçe/mahalle hiyerarşisi)
- [ ] **4.3** - Municipality dashboard filtreleri

### 🤖 Faz 5: AI Fake Detection (1 Gün)
- [ ] **5.1** - Google Cloud Vision API anahtarı al
- [ ] **5.2** - FakeDetectionService oluştur
- [ ] **5.3** - CreateReport'a entegre et
- [ ] **5.4** - Admin panel (fake rapor yönetimi)

### 🔔 Faz 6: Bildirimler (1 Gün)
- [ ] **6.1** - Firebase Cloud Messaging setup
- [ ] **6.2** - FCM token yönetimi
- [ ] **6.3** - Cloud Functions (rapor durumu değiştiğinde bildirim)
- [ ] **6.4** - Notification UI (InAppNotification widget)

### 📊 Faz 7: İstatistikler (0.5 Gün)
- [ ] **7.1** - Profil istatistikleri (card'lar)
- [ ] **7.2** - Municipality dashboard stats
- [ ] **7.3** - fl_chart entegrasyonu (pie, line chart)

### ⚡ Faz 8: Optimizasyon (1 Gün)
- [ ] **8.1** - cached_network_image entegrasyonu
- [ ] **8.2** - Firestore composite index'ler oluştur
- [ ] **8.3** - Pagination (lazy loading)
- [ ] **8.4** - Map markers lazy loading

### 🔒 Faz 9: Güvenlik (0.5 Gün)
- [ ] **9.1** - Firestore Security Rules yazma ve test etme
- [ ] **9.2** - Input validasyonları (form validators)
- [ ] **9.3** - Rate limiting (günlük rapor limiti)
- [ ] **9.4** - Error handling iyileştirmesi

### 🎨 Faz 10: UI/UX İyileştirmeleri (1 Gün)
- [ ] **10.1** - Loading states (Shimmer effect)
- [ ] **10.2** - Empty states (hiç rapor yoksa)
- [ ] **10.3** - Error states (hata mesajları)
- [ ] **10.4** - Animasyonlar (Hero, SlideTransition)
- [ ] **10.5** - Responsive design (tablet support)

---

## 🛠️ EKLENMESİ GEREKEN PAKETLER

```yaml
dependencies:
  # Mevcut paketler korunacak...
  
  # Clustering
  google_maps_cluster_manager: ^3.0.0+1
  
  # Image Caching
  cached_network_image: ^3.3.1
  
  # Charts
  fl_chart: ^0.69.2
  
  # Notifications
  firebase_messaging: ^15.1.5
  flutter_local_notifications: ^18.0.1
  
  # HTTP (Vision API için)
  http: ^1.2.2
  
  # Utilities
  intl: ^0.19.0 # Tarih formatlama
  timeago: ^3.7.0 # "2 saat önce" formatı
  shimmer: ^3.0.0 # Loading animation
  lottie: ^3.2.1 # Animasyonlar
```

---

## 🗂️ YENİ DOSYA YAPISI

```
lib/
├── Features/
│   ├── Municipality/              # YENİ MODÜL
│   │   ├── view/
│   │   │   ├── municipality_dashboard_view.dart
│   │   │   ├── resolve_report_view.dart
│   │   │   └── municipality_reports_list.dart
│   │   ├── viewmodel/
│   │   │   ├── municipality_viewmodel.dart
│   │   │   └── resolve_report_viewmodel.dart
│   │   ├── service/
│   │   │   └── municipality_service.dart
│   │   └── widgets/
│   │       ├── municipality_stats_card.dart
│   │       ├── report_action_buttons.dart
│   │       └── before_after_uploader.dart
│   │
│   ├── Admin/                     # YENİ MODÜL
│   │   ├── view/
│   │   │   ├── admin_dashboard_view.dart
│   │   │   └── fake_reports_view.dart
│   │   ├── viewmodel/
│   │   │   └── admin_viewmodel.dart
│   │   └── service/
│   │       └── admin_service.dart
│   │
│   ├── Leaderboard/               # YENİ MODÜL
│   │   ├── view/
│   │   │   └── leaderboard_view.dart
│   │   ├── viewmodel/
│   │   │   └── leaderboard_viewmodel.dart
│   │   ├── service/
│   │   │   └── leaderboard_service.dart
│   │   ├── model/
│   │   │   └── leaderboard_user.dart
│   │   └── widgets/
│   │       ├── leaderboard_card.dart
│   │       └── badge_widget.dart
│   │
│   └── Statistics/                # YENİ MODÜL
│       ├── view/
│       │   └── statistics_view.dart
│       ├── viewmodel/
│       │   └── statistics_viewmodel.dart
│       └── widgets/
│           ├── stats_card.dart
│           ├── pie_chart_widget.dart
│           └── line_chart_widget.dart
│
├── core/
│   ├── services/
│   │   ├── clustering_service.dart         # YENİ
│   │   ├── fake_detection_service.dart     # YENİ
│   │   ├── gamification_service.dart       # YENİ
│   │   ├── notification_service.dart       # YENİ
│   │   ├── analytics_service.dart          # YENİ
│   │   └── cache_service.dart              # YENİ
│   │
│   ├── constants/
│   │   ├── tr_neighborhoods.dart           # YENİ - Mahalle veritabanı
│   │   └── gamification_rules.dart         # YENİ - Puan kuralları
│   │
│   ├── utils/
│   │   ├── validators.dart                 # YENİ - Input validasyonları
│   │   ├── date_formatter.dart             # YENİ
│   │   └── distance_calculator.dart        # YENİ - Haversine
│   │
│   └── widgets/
│       ├── loading_shimmer.dart            # YENİ
│       ├── empty_state.dart                # YENİ
│       ├── error_state.dart                # YENİ
│       └── badge_icon.dart                 # YENİ
```

---

## 🎯 MVP İÇİN ÖNCELİK SIRALAMASI (Hackathon için)

Eğer zaman kısıtlı ise, bu sırayla ilerleyin:

### 🏆 Olmazsa Olmaz (Must Have) - 3 Gün
1. ✅ Belediye Dashboard + Rapor Çözme (Before/After)
2. ✅ Smart Clustering (Haversine + supportCount)
3. ✅ Gamification (Puan + Liderlik Tablosu)

### ⭐ Çok İyi Olur (Should Have) - 2 Gün
4. Mahalle yönetimi ve filtreleme
5. İstatistikler ve grafikler
6. Firebase Cloud Messaging (bildirimler)

### 💫 Artı Puan (Nice to Have) - 1-2 Gün
7. AI Fake Detection
8. Admin Panel
9. Performans optimizasyonları
10. UI/UX İyileştirmeleri

---

## 🔍 TEST SENARYOLARI

### Manuel Test Checklist
- [ ] Yeni kullanıcı kaydı (Citizen)
- [ ] Yeni kullanıcı kaydı (Municipality - @belediye.bel.tr email'i)
- [ ] Konum izni verme/vermeme senaryoları
- [ ] Harita üzerinden rapor oluşturma
- [ ] Aynı noktaya 2. rapor açmaya çalışma (clustering testi)
- [ ] Başka rapora destek verme
- [ ] Belediye olarak rapor çözme (before/after yükleme)
- [ ] Liderlik tablosunu görüntüleme
- [ ] Harita zoom/pan performance testi
- [ ] Offline durumda davranış

---

## 📞 EK KAYNAKLAR

### API Anahtarları
- [ ] Google Maps API Key (Android + iOS)
- [ ] Google Cloud Vision API Key (Fake Detection)
- [ ] Firebase Project Setup

### Dokümantasyonlar
- [Firebase Flutter Setup](https://firebase.google.com/docs/flutter/setup)
- [Google Maps Flutter Plugin](https://pub.dev/packages/google_maps_flutter)
- [Google Cloud Vision API](https://cloud.google.com/vision/docs)
- [Before/After Package](https://pub.dev/packages/before_after)

---

## 💡 SONRAKİ ADIMLAR

Bu dokümanı tamamladıktan sonra:
1. Her bir faz için ayrı branch oluşturun (git)
2. Her özellik tamamlandıkça test edin
3. Firebase Console'dan Firestore verilerini manuel kontrol edin
4. Gerçek cihazda test edin (iOS Simulator konum sorunlu olabilir)

---

**📌 NOT:** Bu plan hackathon için optimize edilmiştir. Üretim ortamı için ek güvenlik testleri, load testing ve UX araştırması gereklidir.

**🚀 Başarılar! Sorularınız için bana ulaşabilirsiniz.**
