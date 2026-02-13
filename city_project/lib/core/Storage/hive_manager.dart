import 'package:city_project/Features/Login/model/user_model.dart';
import 'package:city_project/core/Storage/adapters/user_model_adapter.dart';
import 'dart:developer' as dev; // log yerine standart developer logu
import 'package:hive_flutter/hive_flutter.dart'; // hive yerine hive_flutter olmalı

class HiveBoxes {
  static const String auth = 'auth_box';
}

class HiveKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String user = 'user';
}

class HiveManager {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    
    // 1. Hive'ı başlat
    await Hive.initFlutter();

    // 2. Yeni yazdığımız Adapter'ı kaydet (Çok Önemli!)
    // Eğer bunu yapmazsan Hive UserModel'i nasıl okuyacağını bilemez.
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserModelAdapter());
    }

    try {
      // 3. Kutuyu aç
      await Hive.openBox(HiveBoxes.auth);
    } on HiveError catch (e) {
      // Eski sürümden kalan uyumsuz veriler varsa kutuyu sıfırla
      dev.log('[HiveManager] Kurtarma deneniyor: ${e.message}');
      await Hive.deleteBoxFromDisk(HiveBoxes.auth);
      await Hive.openBox(HiveBoxes.auth);
    }
    
    _initialized = true;
  }

  // --- Yardımcı Fonksiyonlar ---

  /// Kullanıcıyı ve tokenları tek seferde kaydetmek için
  static Future<void> saveAuthData({
    required UserModel user,
    String? accessToken,
    String? refreshToken,
  }) async {
    final box = Hive.box(HiveBoxes.auth);
    await box.put(HiveKeys.user, user);
    if (accessToken != null) await box.put(HiveKeys.accessToken, accessToken);
    if (refreshToken != null) await box.put(HiveKeys.refreshToken, refreshToken);
  }

  /// Kayıtlı kullanıcıyı getirir
  static UserModel? getUser() {
    final box = Hive.box(HiveBoxes.auth);
    return box.get(HiveKeys.user) as UserModel?;
  }

  /// Sadece token'ı getirir
  static String? getAccessToken() {
    final box = Hive.box(HiveBoxes.auth);
    return box.get(HiveKeys.accessToken) as String?;
  }

  /// Çıkış yaparken tüm verileri siler
  static Future<void> clearAuthData() async {
    final box = Hive.box(HiveBoxes.auth);
    await box.clear();
  }
}