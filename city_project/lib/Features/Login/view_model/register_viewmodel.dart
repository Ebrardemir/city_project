import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterViewModel extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? selectedCity;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? selectedDistrict;

  String? errorMessage;
  void setSelectedCity(String? city) {
    selectedCity = city;
    selectedDistrict = null; // ✅ il değişince ilçe reset
    notifyListeners();
  }

  void setSelectedDistrict(String? district) {
    selectedDistrict = district;
    notifyListeners();
  }

  bool _validateForm() {
    errorMessage = null;

    if (nameController.text.trim().isEmpty) {
      errorMessage = 'Lütfen adınızı ve soyadınızı girin';
      notifyListeners();
      return false;
    }

    if (emailController.text.trim().isEmpty) {
      errorMessage = 'Lütfen email adresinizi girin';
      notifyListeners();
      return false;
    }

    if (!emailController.text.contains('@')) {
      errorMessage = 'Geçerli bir email adresi girin';
      notifyListeners();
      return false;
    }

    if (passwordController.text.length < 6) {
      errorMessage = 'Şifre en az 6 karakter olmalıdır';
      notifyListeners();
      return false;
    }

    if (selectedCity == null) {
      errorMessage = 'Lütfen şehir seçin';
      notifyListeners();
      return false;
    }
    if (selectedDistrict == null) {
      errorMessage = 'Lütfen ilçe seçin';
      notifyListeners();
      return false;
    }

    return true;
  }

  Future<bool> register() async {
    if (!_validateForm()) return false;

    _isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Kullanıcı oluşturuldu ama user null geldi');
      }

      await user.updateDisplayName(nameController.text.trim());

      // ✅ Email bazlı rol belirleme
      final email = emailController.text.trim().toLowerCase();
      String role = 'citizen';
      List<String> districts = [];
      
      // Eğer email @belediye.bel.tr ile bitiyorsa belediye yetkilisi
      if (email.endsWith('@belediye.bel.tr') || email.endsWith('@municipality.gov.tr')) {
        role = 'municipality';
        // Seçilen ilçeyi sorumlu ilçeler listesine ekle
        if (selectedDistrict != null) {
          districts = [selectedDistrict!];
        }
        debugPrint('[Register] Belediye yetkilisi kaydı: $email');
      }

      // ✅ Firestore'a kullanıcı profilini yaz
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fullName': nameController.text.trim(),
        'email': user.email,
        'city': selectedCity,
        'role': role,
        'score': 0,
        'district': selectedDistrict,
        'districts': districts, // Belediye için sorumlu ilçeler
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[Register] Kayıt başarılı: ${user.email}');
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Bu email adresi zaten kullanılıyor';
          break;
        case 'weak-password':
          errorMessage = 'Şifre çok zayıf';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz email adresi';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/şifre girişi etkin değil';
          break;
        default:
          errorMessage = 'Kayıt sırasında hata oluştu: ${e.message}';
      }
      debugPrint('[Register] FirebaseAuthException: ${e.code} - $errorMessage');
      return false;
    } catch (e) {
      errorMessage = 'Beklenmeyen bir hata oluştu: $e';
      debugPrint('[Register] Bilinmeyen hata: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
