import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
