import 'package:dio/dio.dart';
import '../logger/logger.dart';

/// HTTP isteklerini ve yanıtlarını loglayan interceptor
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log.i('[HTTP] ${options.method} ${options.uri}');

    // Headers'ı log'la (Authorization header'ını maskele)
    final headers = Map<String, dynamic>.from(options.headers);
    if (headers.containsKey('Authorization')) {
      final auth = headers['Authorization'].toString();
      headers['Authorization'] = _maskToken(auth);
    }
    log.d('[HTTP] Headers: $headers');

    // Body varsa log'la
    if (options.data != null) {
      log.d('[HTTP] Body: ${options.data}');
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log.i(
      '[HTTP] ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}',
    );
    log.d('[HTTP] Response: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log.e(
      '[HTTP] ${err.response?.statusCode} ${err.requestOptions.method} ${err.requestOptions.uri}',
    );
    log.e('[HTTP] Error: ${err.message}');
    if (err.response?.data != null) {
      log.e('[HTTP] Error Response: ${err.response?.data}');
    }
    handler.next(err);
  }

  String _maskToken(String token) {
    if (token.length <= 20) return '*' * token.length;
    return '${token.substring(0, 10)}...${token.substring(token.length - 10)}';
  }
}
