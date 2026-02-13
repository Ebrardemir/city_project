import 'package:dio/dio.dart';
import '../logger/logger.dart';
import '../services/auth_service.dart';

/// Tüm HTTP isteklerine access token'ı otomatik olarak ekleyen interceptor
class AuthInterceptor extends Interceptor {
  final AuthService _authService;

  AuthInterceptor(this._authService);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Opt-out mekanizması: extra['requiresAuth'] == false ise token ekleme
      final requiresAuth = options.extra['requiresAuth'] ?? true;
      if (requiresAuth == false) {
        log.d(
          '[AuthInterceptor] Skipping auth header for ${options.method} ${options.path}',
        );
        handler.next(options);
        return;
      }

      // Access token'ı al
      final accessToken = await _authService.getAccessToken();

      if (accessToken != null && accessToken.isNotEmpty) {
        // Authorization header'ını ekle
        options.headers['Authorization'] = 'Bearer $accessToken';
        log.d(
          '[AuthInterceptor] Added Bearer token to ${options.method} ${options.path}',
        );
      } else {
        log.w(
          '[AuthInterceptor] No access token found for ${options.method} ${options.path}',
        );
      }
    } catch (e) {
      log.e('[AuthInterceptor] Error getting access token: $e');
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 401 Unauthorized hatası gelirse token'ın süresi dolmuş olabilir
    if (err.response?.statusCode == 401) {
      log.w('[AuthInterceptor] 401 Unauthorized - token may be expired');
      // TODO: Implement concurrency-safe refresh token flow with retry-once logic here.
    }

    handler.next(err);
  }
}
