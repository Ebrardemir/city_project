import 'package:flutter/material.dart';
import '../service/login_service.dart';
import '../../../core/services/auth_service.dart';

class LoginViewModel extends ChangeNotifier {
  final LoginService _loginService;
  final AuthService _authService;

  LoginViewModel(this._loginService, this._authService);

  // Controller'lar veriyi arayüzden çekmek için kullanılır
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Backend bağlandığında burası LoginService üzerinden çağrılacak
      await Future.delayed(const Duration(seconds: 2));

      // Başarılı giriş simülasyonu
      debugPrint("Giriş yapılıyor: ${emailController.text}");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
