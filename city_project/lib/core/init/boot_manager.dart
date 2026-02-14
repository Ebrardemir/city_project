import 'package:city_project/core/Services/auth_service.dart';
import 'package:city_project/core/di/locator.dart';
import 'package:flutter/foundation.dart';

enum AuthState { unknown, unauthenticated, authenticated }

/// BootManager: Uygulamanın "Isınma Turunu" yönetir.
class BootManager extends ChangeNotifier {
  bool _bootCompleted = false;
  bool get bootCompleted => _bootCompleted;

  bool forceUpdateRequired = false;
  AuthState authState = AuthState.unknown;

  /// Uygulama ilk açıldığında çalışır (Splash Screen aşaması)
  Future<void> startBoot() async {
    final authService = locator<AuthService>();

    // 1. Kullanıcının oturumu var mı kontrol et
    final isLoggedIn = await authService.isLoggedIn();

    authState = isLoggedIn
        ? AuthState.authenticated
        : AuthState.unauthenticated;

    // 2. Yapay bir gecikme ekleyerek (veya gerçek veri çekerek)
    // uygulamanın hazır olduğundan emin ol
    await Future.delayed(const Duration(milliseconds: 500));

    _bootCompleted = true;
    notifyListeners();
  }

  /// Kullanıcı çıkış yaptığında çalışır
  void logout() async {
    final authService = locator<AuthService>();

    // HATA ÇÖZÜMÜ: Eğer AuthService içinde metodun adı 'clearAll' ise
    // burayı .clearAll() olarak güncelle.
    await authService.clearAll();

    authState = AuthState.unauthenticated;
    notifyListeners();
  }
}
