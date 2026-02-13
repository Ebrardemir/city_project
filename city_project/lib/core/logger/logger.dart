import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Uygulama genelinde kullanacağın logger.
/// Dev'de: debug/info/uyarı/hata hepsi görünür
/// Prod'da: sadece uyarı ve hatalar görünür
final log = Logger(
  level: kReleaseMode ? Level.warning : Level.debug,
  printer: kReleaseMode
      ? SimplePrinter()
      : PrettyPrinter(
          //methodCount: 0,          // #0 #1 call stack'ı kapat
          errorMethodCount: 5, // hata olunca kısa stack
          noBoxingByDefault: false, // kutu çizme
          printEmojis: true, // 💡 vb kapat
          colors: false, // ^[[38;5;12m gibi ANSI kodlarını kapat
          lineLength: 120,
        ),
);
