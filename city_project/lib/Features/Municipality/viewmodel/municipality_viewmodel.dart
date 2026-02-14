import 'dart:async'; // StreamSubscription için gerekli
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Home/model/report_model.dart';
import '../../Login/model/user_model.dart';
import '../service/municipality_service.dart';

/// Belediye Dashboard ViewModel
/// Belediye yetkililerinin rapor yönetimi için state yönetimi
class MunicipalityViewModel extends ChangeNotifier {
  final MunicipalityService _service = MunicipalityService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
  
  // State
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMoreReports = true;
  DocumentSnapshot? lastDocument;
  String? errorMessage;
  
  // Kullanıcı bilgileri
  UserModel? currentUser;
  List<String> userDistricts = [];
  
  // Raporlar
  List<ReportModel> reports = [];
  List<ReportModel> filteredReports = [];
  
  // Filtreler
  ReportStatus? selectedStatusFilter;
  ReportCategory? selectedCategoryFilter;
  String? selectedDistrictFilter;
  
  // İstatistikler
  Map<String, int> stats = {
    'total': 0,
    'pending': 0,
    'approved': 0,
    'resolved': 0,
    'fake': 0,
  };
  
  /// ViewModel'i başlat - kullanıcı bilgilerini dinle
  Future<void> init() async {
    isLoading = true;
    notifyListeners();
    
    try {
      // Mevcut kullanıcıyı al
      final user = _auth.currentUser;
      if (user == null) {
        errorMessage = 'Kullanıcı oturumu bulunamadı';
        isLoading = false;
        notifyListeners();
        return;
      }
      
      // Kullanıcı bilgilerini stream olarak dinle (Rol değişikliklerini anlık yakalamak için)
      _userSubscription?.cancel(); // Varsa eski aboneliği iptal et
      _userSubscription = _firestore.collection('users').doc(user.uid).snapshots().listen((userDoc) {
          if (!userDoc.exists) {
            errorMessage = 'Kullanıcı profili bulunamadı';
            isLoading = false;
            notifyListeners();
            return;
          }

          currentUser = UserModel.fromFirestore(userDoc);
      
          // Belediye yetkilisi mi kontrol et
          if (!currentUser!.isMunicipality) {
            errorMessage = 'Bu sayfaya erişim yetkiniz yok. (Rol: ${currentUser!.role})';
            isLoading = false;
            notifyListeners();
            return;
          }
          
          // Erişim izni var, hata mesajını temizle
          if (errorMessage != null) {
            errorMessage = null; 
          }

          // Sorumlu olunan ilçeleri al
          userDistricts = currentUser!.districts;
          
          // Raporları yükle (Eğer henüz yüklenmediyse veya boşsa)
          if (reports.isEmpty) {
            loadReports();
            loadStatistics();
          }
          
          isLoading = false;
          notifyListeners();
      }, onError: (e) {
        print('❌ MunicipalityViewModel: Stream hatası: $e');
        errorMessage = 'Kullanıcı bilgileri alınamadı: $e';
        isLoading = false;
        notifyListeners();
      });

    } catch (e) {
      print('❌ MunicipalityViewModel: Init hatası: $e');
      errorMessage = 'Bir hata oluştu: $e';
      isLoading = false;
      notifyListeners();
    }
  }
  
  /// Raporları yükle (filtreler uygulanmış halde)
  Future<void> loadReports() async {
    isLoading = true;
    notifyListeners();
    
    // Sayfalamayı sıfırla
    hasMoreReports = true;
    lastDocument = null;
    reports = [];
    filteredReports = [];
    
    try {
      print('📥 MunicipalityViewModel: Raporlar yükleniyor...');
      
      // İlçe filtresi sorguya dahil ediliyor
      List<String> queryDistricts = selectedDistrictFilter != null 
          ? [selectedDistrictFilter!] 
          : userDistricts;
      
      final result = await _service.getReportsForMunicipalityPaginated(
        districts: queryDistricts,
        statusFilter: selectedStatusFilter,
        categoryFilter: selectedCategoryFilter,
        limit: 10,
      );
      
      reports = result.reports;
      filteredReports = result.reports;
      lastDocument = result.lastDoc;
      hasMoreReports = result.reports.length >= 10;
      
      print('✅ MunicipalityViewModel: ${filteredReports.length} rapor yüklendi');
    } catch (e) {
      print('❌ MunicipalityViewModel: Rapor yükleme hatası: $e');
      errorMessage = 'Raporlar yüklenirken hata: $e';
    }
    
    isLoading = false;
    notifyListeners();
  }

  /// Daha fazla rapor yükle (Sayfalama)
  Future<void> loadMoreReports() async {
    if (isLoadingMore || !hasMoreReports || lastDocument == null) return;
    
    isLoadingMore = true;
    notifyListeners();
    
    try {
      // İlçe filtresi
      List<String> queryDistricts = selectedDistrictFilter != null 
          ? [selectedDistrictFilter!] 
          : userDistricts;
          
      final result = await _service.getReportsForMunicipalityPaginated(
        districts: queryDistricts,
        statusFilter: selectedStatusFilter,
        categoryFilter: selectedCategoryFilter,
        lastDocument: lastDocument,
        limit: 10,
      );
      
      if (result.reports.isNotEmpty) {
        reports.addAll(result.reports);
        filteredReports.addAll(result.reports);
        lastDocument = result.lastDoc;
        hasMoreReports = result.reports.length >= 10;
      } else {
        hasMoreReports = false;
      }
    } catch (e) {
      print('❌ MunicipalityViewModel: Ek rapor yükleme hatası: $e');
    }
    
    isLoadingMore = false;
    notifyListeners();
  }
  
  /// İstatistikleri yükle
  Future<void> loadStatistics() async {
    try {
      stats = await _service.getStatistics(userDistricts);
      notifyListeners();
    } catch (e) {
      print('❌ MunicipalityViewModel: İstatistik yükleme hatası: $e');
    }
  }
  
  /// Durum filtresini değiştir
  void setStatusFilter(ReportStatus? status) {
    selectedStatusFilter = status;
    loadReports();
  }
  
  /// Kategori filtresini değiştir
  void setCategoryFilter(ReportCategory? category) {
    selectedCategoryFilter = category;
    loadReports();
  }
  
  /// İlçe filtresini değiştir
  void setDistrictFilter(String? district) {
    selectedDistrictFilter = district;
    loadReports();
  }
  
  /// Tüm filtreleri temizle
  void clearFilters() {
    selectedStatusFilter = null;
    selectedCategoryFilter = null;
    selectedDistrictFilter = null;
    loadReports();
  }
  
  /// Raporu onayla
  Future<bool> approveReport(String reportId) async {
    try {
      final success = await _service.approveReport(
        reportId,
        _auth.currentUser!.uid,
      );
      
      if (success) {
        await loadReports();
        await loadStatistics();
      }
      
      return success;
    } catch (e) {
      print('❌ MunicipalityViewModel: Onaylama hatası: $e');
      return false;
    }
  }
  
  /// Raporu sahte olarak işaretle
  Future<bool> markReportAsFake(String reportId, {String? reason}) async {
    try {
      final success = await _service.markAsFake(
        reportId,
        _auth.currentUser!.uid,
        reason: reason,
      );
      
      if (success) {
        await loadReports();
        await loadStatistics();
      }
      
      return success;
    } catch (e) {
      print('❌ MunicipalityViewModel: Sahte işaretleme hatası: $e');
      return false;
    }
  }
  
  /// Refresh (çekme yenileme için)
  Future<void> refresh() async {
    await loadReports();
    await loadStatistics();
  }
}
