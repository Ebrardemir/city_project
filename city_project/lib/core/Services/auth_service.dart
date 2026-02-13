import 'package:flutter_secure_storage/flutter_secure_storage.dart';  
import 'package:hive_flutter/hive_flutter.dart';  
import 'package:city_project/Features/Login/model/user_model.dart'; // Yolunu kontrol et
import 'package:city_project/core/Storage/hive_manager.dart'; // Yolunu kontrol et
import '../logger/logger.dart'; // Kendi logger yapına göre güncelle

class AuthService {
  // Token anahtarları - Secure Storage için
  static const _kAccessTokenKey = 'access_token_secure';
  static const _kRefreshTokenKey = 'refresh_token_secure';

  // Güvenli depolama yapılandırması
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Tokenları loglarda maskelemek için yardımcı fonksiyon
  String _mask(String? value) {
    if (value == null || value.length < 8) return 'null';
    return '${value.substring(0, 4)}****${value.substring(value.length - 2)}';
  }

  /// Her işlemden önce Hive ve kutuların hazır olduğundan emin olur
  Future<void> _ensureInit() async {
    await HiveManager.init();
    if (!Hive.isBoxOpen(HiveBoxes.auth)) {
      await Hive.openBox(HiveBoxes.auth);
    }
  }

  /// Başarılı giriş sonrası tüm verileri kaydeder
  Future<void> saveLogin({
    required UserModel user, 
    required String accessToken, 
    required String refreshToken
  }) async {
    await _ensureInit();
    final box = Hive.box(HiveBoxes.auth);

    // 1. Hassas verileri (Tokenlar) Secure Storage'a yaz
    await _secureStorage.write(key: _kAccessTokenKey, value: accessToken);
    await _secureStorage.write(key: _kRefreshTokenKey, value: refreshToken);

    // 2. Kullanıcı nesnesini (Adapter sayesinde) direkt Hive'a kaydet
    await box.put(HiveKeys.user, user);

    log.i('[AuthService] Giriş verileri kaydedildi: ${user.fullName}');
    log.d('[AuthService] Token: ${_mask(accessToken)}');
  }

  /// Kayıtlı kullanıcı nesnesini döner
  Future<UserModel?> getUser() async {
    await _ensureInit();
    final box = Hive.box(HiveBoxes.auth);
    try {
      final user = box.get(HiveKeys.user);
      if (user is UserModel) {
        log.d('[AuthService] Kullanıcı getirildi: ${user.fullName} (Puan: ${user.score})');
        return user;
      }
      return null;
    } catch (e) {
      log.e('[AuthService] Kullanıcı verisi parse edilirken hata oluştu', error: e);
      return null;
    }
  }

  /// Access Token'ı güvenli depolamadan okur
  Future<String?> getAccessToken() async {
    await _ensureInit();
    final token = await _secureStorage.read(key: _kAccessTokenKey);
    log.d('[AuthService] AccessToken okundu: ${_mask(token)}');
    return token;
  }

  /// Refresh Token'ı güvenli depolamadan okur
  Future<String?> getRefreshToken() async {
    await _ensureInit();
    return await _secureStorage.read(key: _kRefreshTokenKey);
  }

  /// Çıkış yaparken hem Hive'ı hem de Secure Storage'ı temizler
  Future<void> clearAll() async {
    await _ensureInit();
    final box = Hive.box(HiveBoxes.auth);
    await box.clear();
    await _secureStorage.deleteAll();
    log.w('[AuthService] Tüm oturum verileri temizlendi.');
  }

  /// Kullanıcının aktif bir oturumu olup olmadığını kontrol eder
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    final user = await getUser();
    // Hem token hem kullanıcı verisi varsa giriş yapılmış sayılır
    return token != null && token.isNotEmpty && user != null;
  }

  /// Sadece token geçerliliğini kontrol eder
  Future<bool> isTokenValid() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Mevcut kullanıcının ID'sine hızlı erişim
  Future<int?> getCurrentUserId() async {
    final user = await getUser();
    return user?.id;
  }

  /// Debug amaçlı: Kayıtlı verileri maskelenmiş olarak konsola basar
  Future<void> debugPrintStatus() async {
    final user = await getUser();
    final token = await getAccessToken();
    log.i('''
[AuthService DEBUG]
  Oturum Açık mı: ${user != null}
  Kullanıcı: ${user?.fullName}
  Rol: ${user?.role}
  Puan: ${user?.score}
  Token: ${_mask(token)}
    ''');
  }
}