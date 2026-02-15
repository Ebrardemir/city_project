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
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        print('⚠️ ProfileService: Kullanıcı dokümanı bulunamadı. Otomatik oluşturuluyor...');
        
        // Eksik profili oluştur
        final newUser = {
          'fullName': currentUser.displayName ?? 'İsimsiz Kullanıcı',
          'email': currentUser.email ?? '',
          'role': 'citizen',
          'score': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'districts': [],
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set(newUser);
            
        // Yeni oluşturulan veriyi çek
        userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      }

      final userData = userDoc.data() as Map<String, dynamic>;
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
