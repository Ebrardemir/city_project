import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:city_project/Features/Login/view_model/login_viewmodel.dart';
import 'package:city_project/Features/Login/view_model/register_viewmodel.dart';
// Çekirdek Yapılandırmalar
import 'package:city_project/core/config/app_config.dart';
import 'package:city_project/core/services/auth_service.dart';
import 'package:city_project/core/network/auth_interceptor.dart';
import 'package:city_project/core/network/logging_interceptor.dart';

// Login Özelliği
import 'package:city_project/Features/Login/service/login_service.dart';
// HOME FEATURE
import 'package:city_project/core/services/location_service.dart';
import 'package:city_project/Features/Home/viewmodel/home_viewmodel.dart';

final locator = GetIt.instance;

void setupLocator() {
  // Hot-reload sırasında tekrar kayıt yapmaya çalışıp hata vermemesi için kontrol
  if (locator.isRegistered<AuthService>()) return;

  // 1. TEMEL SERVİSLER
  // AuthService: Kullanıcı oturumunu ve güvenli depolamayı yönetir
  locator.registerLazySingleton<AuthService>(() => AuthService());

  // GPS, Geocoding, kullanıcı konumu alma işlemleri
  locator.registerLazySingleton<LocationService>(() => LocationService());

  // 2. NETWORK (DIO) YAPILANDIRMASI
  locator.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Her isteğe otomatik token ekleyen interceptor
    dio.interceptors.add(AuthInterceptor(locator<AuthService>()));

    // Geliştirme modunda tüm trafiği konsola yazdıran interceptor
    if (kDebugMode) {
      dio.interceptors.add(LoggingInterceptor());
    }

    return dio;
  });

  // 3. ÖZELLİK SERVİSLERİ (Features)
  // LoginService: Dio bağımlılığını otomatik olarak locator'dan alır
  locator.registerLazySingleton(() => LoginService(locator<Dio>()));

  // 4. VIEWMODEL'LER
  // registerFactory: Her sayfa açıldığında ViewModel'in yeni bir kopyasını oluşturur
  locator.registerFactory(
    () => LoginViewModel(locator<LoginService>(), locator<AuthService>()),
  );

  // RegisterViewModel
  locator.registerFactory(() => RegisterViewModel());

  // LocationService bağımlılığını locator'dan alır
  locator.registerFactory(() => HomeViewModel(locator<LocationService>()));
}
