# 🚀 HIZLI BAŞLANGIÇ REHBERİ - 1. Gün İçin

## 📋 Bu Dokümanın Amacı
Hackathon'da hız kazanmak için ilk günde mutlaka tamamlanması gereken özellikleri adım adım uygulayacağız.

---

## ⚡ İLK GÜN PLANI (6-8 Saat)

### ✅ SAAT 1-2: Belediye Yetkilisi Altyapısı

#### Adım 1.1: Firestore Users Koleksiyonu Güncelleme
Mevcut kullanıcı modelinize ek alanlar ekleyin:

**`lib/Features/Login/model/user_model.dart`** güncelleme:
```dart
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role; // "citizen" | "municipality" | "admin"
  final int score;
  final String? city;
  final String? district;
  final List<String> districts; // Belediye için sorumlu ilçeler
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.score = 0,
    this.city,
    this.district,
    this.districts = const [],
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'citizen',
      score: data['score'] ?? 0,
      city: data['city'],
      district: data['district'],
      districts: List<String>.from(data['districts'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
      'role': role,
      'score': score,
      'city': city,
      'district': district,
      'districts': districts,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
```

#### Adım 1.2: Kayıt Sırasında Rol Belirleme
**`lib/Features/Login/view_model/register_viewmodel.dart`** güncelleme:

```dart
Future<void> register() async {
  // Email kontrolü ile rol belirleme
  String role = 'citizen';
  List<String> districts = [];
  
  // Eğer email @belediye.bel.tr ile bitiyorsa
  if (emailController.text.toLowerCase().endsWith('@belediye.bel.tr')) {
    role = 'municipality';
    // Belediye için sorumlu ilçeleri belirle (örnek)
    districts = ['Kadıköy', 'Maltepe']; // Gerçek uygulamada form'dan alınacak
  }
  
  final userCredential = await _auth.createUserWithEmailAndPassword(
    email: emailController.text.trim(),
    password: passwordController.text.trim(),
  );
  
  // Firestore'a kullanıcı bilgilerini kaydet
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userCredential.user!.uid)
      .set({
    'fullName': fullNameController.text.trim(),
    'email': emailController.text.trim(),
    'role': role,
    'score': 0,
    'city': null,
    'district': null,
    'districts': districts,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
```

#### Adım 1.3: Role Bazlı Yönlendirme
**`lib/core/router/app_router.dart`** güncelleme:

```dart
redirect: (context, state) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    // Giriş yapmamışsa login'e yönlendir
    if (state.matchedLocation != '/login' && 
        state.matchedLocation != '/register') {
      return '/login';
    }
    return null;
  }
  
  // Kullanıcı rolünü al
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  
  final role = userDoc.data()?['role'] ?? 'citizen';
  
  // Login/Register sayfalarındaysa ana sayfaya yönlendir
  if (state.matchedLocation == '/login' || 
      state.matchedLocation == '/register') {
    return role == 'municipality' ? '/municipality-dashboard' : '/home';
  }
  
  return null;
},
```

---

### ✅ SAAT 2-4: Belediye Dashboard Ekranı

#### Adım 2.1: Yeni Modül Oluşturma
Dosyalar:
- `lib/Features/Municipality/view/municipality_dashboard_view.dart`
- `lib/Features/Municipality/viewmodel/municipality_viewmodel.dart`
- `lib/Features/Municipality/service/municipality_service.dart`

#### Adım 2.2: Municipality Service
**`lib/Features/Municipality/service/municipality_service.dart`**:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Home/model/report_model.dart';

class MunicipalityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Belediye için raporları getir (ilçe bazlı)
  Future<List<ReportModel>> getReportsForMunicipality({
    required List<String> districts,
    ReportStatus? statusFilter,
    ReportCategory? categoryFilter,
  }) async {
    Query query = _firestore.collection('reports');
    
    // İlçe filtresi
    if (districts.isNotEmpty) {
      query = query.where('district', whereIn: districts);
    }
    
    // Durum filtresi
    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.value);
    }
    
    // Kategori filtresi
    if (categoryFilter != null) {
      query = query.where('category', isEqualTo: categoryFilter.value);
    }
    
    // Sıralama
    query = query.orderBy('createdAt', descending: true).limit(50);
    
    final snapshot = await query.get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return ReportModel.fromJson(data);
    }).toList();
  }
  
  // Raporu çözüldü olarak işaretle
  Future<bool> resolveReport({
    required String reportId,
    required String imageUrlAfter,
    String? resolutionNote,
  }) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'status': 'resolved',
        'imageUrlAfter': imageUrlAfter,
        'resolutionNote': resolutionNote,
        'resolvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('❌ Rapor çözülemedi: $e');
      return false;
    }
  }
  
  // İstatistikler
  Future<Map<String, int>> getStatistics(List<String> districts) async {
    final snapshot = await _firestore
        .collection('reports')
        .where('district', whereIn: districts)
        .get();
    
    int total = snapshot.docs.length;
    int pending = 0;
    int resolved = 0;
    
    for (var doc in snapshot.docs) {
      final status = doc.data()['status'];
      if (status == 'pending') pending++;
      if (status == 'resolved') resolved++;
    }
    
    return {
      'total': total,
      'pending': pending,
      'resolved': resolved,
    };
  }
}
```

#### Adım 2.3: Municipality Dashboard View
**`lib/Features/Municipality/view/municipality_dashboard_view.dart`**:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/municipality_viewmodel.dart';
import '../../Home/model/report_model.dart';
import 'resolve_report_view.dart';

class MunicipalityDashboardView extends StatefulWidget {
  const MunicipalityDashboardView({super.key});

  @override
  State<MunicipalityDashboardView> createState() => _MunicipalityDashboardViewState();
}

class _MunicipalityDashboardViewState extends State<MunicipalityDashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MunicipalityViewModel>().loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Belediye Yönetim Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Consumer<MunicipalityViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return Column(
            children: [
              // İstatistik Kartları
              _buildStatsSection(viewModel),
              
              // Rapor Listesi
              Expanded(
                child: viewModel.reports.isEmpty
                    ? const Center(child: Text('Henüz rapor yok'))
                    : ListView.builder(
                        itemCount: viewModel.reports.length,
                        itemBuilder: (context, index) {
                          final report = viewModel.reports[index];
                          return _buildReportCard(context, report);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildStatsSection(MunicipalityViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              title: 'Toplam',
              value: viewModel.stats['total']?.toString() ?? '0',
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              title: 'Bekleyen',
              value: viewModel.stats['pending']?.toString() ?? '0',
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              title: 'Çözülen',
              value: viewModel.stats['resolved']?.toString() ?? '0',
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReportCard(BuildContext context, ReportModel report) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(report.status),
          child: Icon(
            _getCategoryIcon(report.category),
            color: Colors.white,
          ),
        ),
        title: Text(report.category.label),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(report.district),
            Text(
              report.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: report.status == ReportStatus.pending
            ? ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResolveReportView(report: report),
                    ),
                  );
                },
                child: const Text('Çöz'),
              )
            : Chip(
                label: Text(report.status.label),
                backgroundColor: _getStatusColor(report.status),
              ),
        onTap: () {
          // Rapor detayına git
        },
      ),
    );
  }
  
  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.approved:
        return Colors.blue;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.fake:
        return Colors.red;
    }
  }
  
  IconData _getCategoryIcon(ReportCategory category) {
    switch (category) {
      case ReportCategory.road:
        return Icons.road_outlined;
      case ReportCategory.park:
        return Icons.park;
      case ReportCategory.water:
        return Icons.water_drop;
      case ReportCategory.garbage:
        return Icons.delete;
      case ReportCategory.lighting:
        return Icons.lightbulb;
      case ReportCategory.other:
        return Icons.more_horiz;
    }
  }
  
  void _showFilterSheet(BuildContext context) {
    // Filtre bottom sheet'i göster
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### ✅ SAAT 4-6: Rapor Çözme ve Before/After

#### Adım 3.1: Resolve Report View
**`lib/Features/Municipality/view/resolve_report_view.dart`**:

```dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../Home/model/report_model.dart';
import '../service/municipality_service.dart';

class ResolveReportView extends StatefulWidget {
  final ReportModel report;
  
  const ResolveReportView({super.key, required this.report});

  @override
  State<ResolveReportView> createState() => _ResolveReportViewState();
}

class _ResolveReportViewState extends State<ResolveReportView> {
  final MunicipalityService _service = MunicipalityService();
  final TextEditingController _noteController = TextEditingController();
  
  File? _selectedImage;
  bool _isUploading = false;
  
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }
  
  Future<void> _submitResolution() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen çözüm fotoğrafı yükleyin')),
      );
      return;
    }
    
    setState(() => _isUploading = true);
    
    try {
      // 1. Fotoğrafı Firebase Storage'a yükle
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('reports')
          .child('after')
          .child('${widget.report.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await storageRef.putFile(_selectedImage!);
      final imageUrl = await storageRef.getDownloadURL();
      
      // 2. Raporu güncelle
      final success = await _service.resolveReport(
        reportId: widget.report.id,
        imageUrlAfter: imageUrl,
        resolutionNote: _noteController.text.trim(),
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rapor başarıyla çözüldü! ✅')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporu Çöz'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rapor bilgisi
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.report.category.label,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.report.description),
                    const SizedBox(height: 8),
                    Text('📍 ${widget.report.district}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Öncesi fotoğrafı
            const Text(
              'Öncesi:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (widget.report.imageUrlBefore != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.report.imageUrlBefore!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Çözüm fotoğrafı yükleme
            const Text(
              'Çözüm Fotoğrafı:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Fotoğraf Çek'),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Çözüm notu
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Çözüm Notu (Opsiyonel)',
                border: OutlineInputBorder(),
                hintText: 'Yapılan işlemi açıklayın...',
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Gönder butonu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitResolution,
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Raporu Çözüldü Olarak İşaretle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### Adım 3.2: ReportDetailView'de Before/After Gösterimi
**`lib/Features/ReportDetail/view/report_detail_view.dart`** güncelleme:

```dart
// Mevcut dosyaya ekle
import 'package:before_after/before_after.dart';

// Image widget'ının yerine:
Widget _buildImage() {
  if (widget.report.status == ReportStatus.resolved && 
      widget.report.imageUrlAfter != null) {
    // Before/After slider göster
    return SizedBox(
      height: 300,
      child: BeforeAfter(
        beforeImage: NetworkImage(widget.report.imageUrlBefore!),
        afterImage: NetworkImage(widget.report.imageUrlAfter!),
        imageHeight: 300,
        thumbColor: Colors.white,
        thumbRadius: 24,
        overlayColor: Colors.black54,
      ),
    );
  } else {
    // Sadece öncesi fotoğrafı
    return widget.report.imageUrlBefore != null
        ? Image.network(
            widget.report.imageUrlBefore!,
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
          )
        : const SizedBox();
  }
}
```

---

### ✅ SAAT 6-8: Smart Clustering

#### Adım 4.1: Clustering Service
**`lib/core/services/clustering_service.dart`**:

```dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Features/Home/model/report_model.dart';

class ClusteringService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Haversine formülü ile mesafe hesaplama (metre)
  double calculateDistance(
    double lat1, double lng1, 
    double lat2, double lng2,
  ) {
    const R = 6371000.0; // Dünya yarıçapı (metre)
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
              cos(_degreesToRadians(lat1)) * 
              cos(_degreesToRadians(lat2)) *
              sin(dLng / 2) * sin(dLng / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return R * c;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }
  
  // Yakındaki benzer raporu kontrol et
  Future<String?> checkNearbyReport({
    required double latitude,
    required double longitude,
    required String category,
    double radiusMeters = 20.0,
  }) async {
    try {
      print('🔍 Clustering: $category kategorisinde yakın rapor aranıyor...');
      
      // Tüm açık raporları getir
      final snapshot = await _firestore
          .collection('reports')
          .where('category', isEqualTo: category)
          .where('status', whereIn: ['pending', 'approved'])
          .get();
      
      print('📊 Clustering: ${snapshot.docs.length} açık rapor bulundu');
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final reportLat = (data['latitude'] as num).toDouble();
        final reportLng = (data['longitude'] as num).toDouble();
        
        final distance = calculateDistance(
          latitude, longitude,
          reportLat, reportLng,
        );
        
        print('📏 Clustering: Rapor ${doc.id} - Mesafe: ${distance.toStringAsFixed(2)}m');
        
        if (distance <= radiusMeters) {
          print('✅ Clustering: Yakın rapor bulundu! ID: ${doc.id}');
          return doc.id;
        }
      }
      
      print('❌ Clustering: Yakın rapor bulunamadı, yeni rapor oluşturulabilir');
      return null;
    } catch (e) {
      print('❌ Clustering hatası: $e');
      return null;
    }
  }
  
  // Mevcut rapora destek ekle
  Future<bool> addSupport(String reportId, String userId) async {
    try {
      final docRef = _firestore.collection('reports').doc(reportId);
      
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) {
          throw Exception('Rapor bulunamadı');
        }
        
        final supportedUserIds = List<String>.from(
          snapshot.data()?['supportedUserIds'] ?? []
        );
        
        if (!supportedUserIds.contains(userId)) {
          supportedUserIds.add(userId);
          
          transaction.update(docRef, {
            'supportCount': FieldValue.increment(1),
            'supportedUserIds': supportedUserIds,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          print('✅ Clustering: Destek eklendi. Rapor ID: $reportId');
        } else {
          print('⚠️ Clustering: Kullanıcı zaten destek vermiş');
        }
      });
      
      return true;
    } catch (e) {
      print('❌ Clustering: Destek eklenirken hata: $e');
      return false;
    }
  }
}
```

#### Adım 4.2: CreateReportViewModel'e Entegrasyon
**`lib/Features/CreateReport/viewmodel/create_report_viewmodel.dart`** güncelleme:

```dart
import '../../../core/services/clustering_service.dart';

class CreateReportViewModel extends ChangeNotifier {
  final ClusteringService _clusteringService = ClusteringService();
  
  Future<void> submitReport() async {
    // ... Mevcut kodlar ...
    
    // 1. Yakın rapor kontrolü
    final nearbyReportId = await _clusteringService.checkNearbyReport(
      latitude: latitude,
      longitude: longitude,
      category: category.value,
      radiusMeters: 20.0, // 20 metre yarıçap
    );
    
    if (nearbyReportId != null) {
      // Yakın rapor var, destek ekle
      final success = await _clusteringService.addSupport(
        nearbyReportId,
        currentUserId,
      );
      
      if (success) {
        _showMessage(
          'Bu sorun zaten bildirilmiş! 🎯\n'
          'Desteğiniz eklendi ve bildirim sayısı artırıldı.'
        );
        return; // Yeni rapor oluşturma
      }
    }
    
    // 2. Yakın rapor yoksa, yeni rapor oluştur
    // ... Mevcut rapor oluşturma kodları ...
  }
}
```

---

## 📦 EKLENMESİ GEREKEN PAKETLER

**`pubspec.yaml`** güncelleme:

```yaml
dependencies:
  # Mevcut paketler...
  
  # Clustering için matematik
  vector_math: ^2.1.4
  
  # Image caching (performans için)
  cached_network_image: ^3.3.1
```

Terminalde çalıştır:
```bash
flutter pub get
```

---

## ✅ 1. GÜN KONTROL LİSTESİ

- [ ] UserModel güncellendi (districts field eklendi)
- [ ] Kayıt sırasında rol belirleme (email kontrolü)
- [ ] Role bazlı yönlendirme (router güncellendi)
- [ ] MunicipalityService oluşturuldu
- [ ] MunicipalityDashboardView oluşturuldu
- [ ] ResolveReportView oluşturuldu (çözüm fotoğrafı yükleme)
- [ ] ReportDetailView'de Before/After slider eklendi
- [ ] ClusteringService oluşturuldu (Haversine formülü)
- [ ] CreateReport'a clustering kontrolü eklendi
- [ ] Gerekli paketler eklendi

---

## 🧪 TEST SENARYOLARI (1. Gün Sonu)

1. **Belediye Kaydı Testi**
   - [ ] @belediye.bel.tr email ile kayıt ol
   - [ ] Role "municipality" olarak atandı mı?
   - [ ] Dashboard'a yönlendirme çalışıyor mu?

2. **Rapor Çözme Testi**
   - [ ] Pending durumunda bir rapor seç
   - [ ] "Çöz" butonuna tıkla
   - [ ] Çözüm fotoğrafı yükle
   - [ ] Firestore'da status "resolved" oldu mu?
   - [ ] imageUrlAfter kaydedildi mi?

3. **Before/After Testi**
   - [ ] Çözülmüş bir raporun detayına git
   - [ ] Slider görünüyor mu?
   - [ ] Slider çalışıyor mu?

4. **Clustering Testi**
   - [ ] Haritada bir noktaya rapor aç
   - [ ] Aynı noktaya (20m içinde) ikinci rapor açmayı dene
   - [ ] "Bu sorun zaten bildirilmiş" mesajı geldi mi?
   - [ ] İlk raporun supportCount artmış mı?

---

## 🚨 SIKÇA KARŞILAŞILAN SORUNLAR

### Sorun 1: Before/After paketi çalışmıyor
**Çözüm:** 
```yaml
# pubspec.yaml'da versiyonu kontrol et
before_after: ^3.2.0

# Sonra
flutter pub get
flutter clean
flutter pub get
```

### Sorun 2: Firestore Security Rules hatası
**Çözüm:** Firebase Console → Firestore Database → Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /reports/{reportId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

### Sorun 3: Image picker iOS'ta çalışmıyor
**Çözüm:** `ios/Runner/Info.plist` dosyasına ekle:
```xml
<key>NSCameraUsageDescription</key>
<string>Rapor çözümü için fotoğraf çekmek istiyoruz</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Galeriden fotoğraf seçmek istiyoruz</string>
```

---

## 📞 YARDIIM

Sorun yaşarsanız:
1. Terminal loglarını kontrol edin
2. Firebase Console'dan Firestore verilerini kontrol edin
3. `flutter clean && flutter pub get` çalıştırın
4. iOS Simulator yerine gerçek cihazda test edin

**🎯 1. Gün hedefi: Belediye yetkilisi rapor çözebilmeli ve clustering çalışmalı!**
