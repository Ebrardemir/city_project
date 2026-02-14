import 'package:city_project/Features/Login/model/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/profile_response.dart';

class ProfileService {
  Future<ProfileResponse> getProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Kullanıcı giriş yapmamış');
    }

    try {
      // Firestore'dan kullanıcı verisini çek
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('Kullanıcı profili bulunamadı');
      }

      final userData = userDoc.data()!;
      final user = UserModel(
        id: currentUser.uid,
        fullName: userData['fullName'] ?? currentUser.displayName ?? 'Kullanıcı',
        email: userData['email'] ?? currentUser.email ?? '',
        role: userData['role'] ?? 'citizen',
        score: userData['score'] ?? 0,
        city: userData['city'],
        district: userData['district'],
        districts: List<String>.from(userData['districts'] ?? []),
        createdAt: (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

      // Rapor sayılarını hesapla (şimdilik mock)
      // TODO: Firestore'dan gerçek verileri çek
      return ProfileResponse(
        user: user,
        reportsCount: 0,
        supportedCount: 0,
        resolvedCount: 0,
      );
    } catch (e) {
      throw Exception('Profil yüklenirken hata: $e');
    }
  }
}
