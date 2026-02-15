import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/profile_response.dart';
import '../service/profile_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileService _service = ProfileService();

  bool isLoading = false;
  ProfileResponse? profile;

  Future<void> fetchProfile() async {
    isLoading = true;
    notifyListeners();

    try {
      profile = await _service.getProfile();
    } catch (e) {
      debugPrint("Profile error: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  /// DEBUG: Rol değiştirme (citizen -> municipality -> admin -> citizen)
  /// Returns: Yeni rol (yönlendirme için)
  Future<String?> changeRole() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('[ProfileViewModel] Kullanıcı giriş yapmamış');
      return null;
    }

    try {
      // Firestore'dan mevcut rolü al
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final currentRole = userDoc.data()?['role'] ?? 'citizen';
      
      // Rol döngüsü: citizen -> municipality -> admin -> citizen
      String newRole;
      List<String> districts = [];
      
      if (currentRole == 'citizen') {
        newRole = 'municipality';
        districts = ['Kadıköy']; // Örnek ilçe
      } else if (currentRole == 'municipality') {
        newRole = 'admin';
      } else {
        newRole = 'citizen';
      }

      // Firestore'da rolü güncelle
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'role': newRole,
        'districts': districts,
      });

      debugPrint('[ProfileViewModel] Rol değiştirildi: $currentRole → $newRole');
      
      // Profili yeniden yükle
      await fetchProfile();
      
      return newRole;
    } catch (e) {
      debugPrint('[ProfileViewModel] Rol değiştirme hatası: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      debugPrint('[ProfileViewModel] Kullanıcı çıkış yaptı');
    } catch (e) {
      debugPrint('[ProfileViewModel] Çıkış hatası: $e');
      rethrow;
    }
  }
}
