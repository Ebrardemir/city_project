import 'package:flutter/material.dart';
import '../service/login_service.dart';
import '../../../core/services/auth_service.dart';

class LoginViewModel extends ChangeNotifier {
  final LoginService _loginService;
  final AuthService _authService;

  LoginViewModel(this._loginService, this._authService);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Giriş yapma fonksiyonu örneği
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Giriş işlemleri burada yapılacak...

    _isLoading = false;
    notifyListeners();
  }
}