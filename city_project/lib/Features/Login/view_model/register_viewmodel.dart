import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterViewModel extends ChangeNotifier {
  // Controller'lar
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? selectedCity;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? errorMessage;

  /// Şehir seçimi güncelle
  void setSelectedCity(String? city) {
    selectedCity = city;
    notifyListeners();
  }

  /// Form validasyonu
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

    return true;
  }

  /// Firebase ile kayıt işlemi
  Future<bool> register() async {
    if (!_validateForm()) {
      return false;
    }

    _isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Firebase Authentication ile kullanıcı oluştur
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Kullanıcı profil bilgilerini güncelle
      await userCredential.user?.updateDisplayName(nameController.text.trim());

      debugPrint('[Register] Kayıt başarılı: ${userCredential.user?.email}');
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;

      // Firebase hatalarını Türkçe'ye çevir
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
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      errorMessage = 'Beklenmeyen bir hata oluştu: $e';
      debugPrint('[Register] Bilinmeyen hata: $e');
      notifyListeners();
      return false;
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
