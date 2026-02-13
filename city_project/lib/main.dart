import 'package:city_project/core/Theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Çekirdek Yapılandırmalar
import 'package:city_project/core/di/locator.dart';
import 'package:city_project/core/storage/hive_manager.dart';

import 'package:city_project/core/init/boot_manager.dart';
import 'package:city_project/core/router/app_router.dart';

// ViewModels (Sadece mevcut olanları ekle)
import 'package:city_project/Features/Login/view_model/login_viewmodel.dart';

void main() async {
  // 1. Flutter motorunu hazırla
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Veritabanını (Hive) başlat (AuthService için kritik)
  await HiveManager.init();

  // 3. Bağımlılık Havuzunu (GetIt) kur
  setupLocator();

  runApp(
    MultiProvider(
      providers: [
        // Uygulama açılışını yöneten ana sağlayıcı
        ChangeNotifierProvider(create: (_) => BootManager()),

        // Tema yönetimi
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Login ViewModel - locator üzerinden çağırıyoruz
        ChangeNotifierProvider(create: (_) => locator<LoginViewModel>()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Tema verisini Provider'dan alıyoruz
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'City Project',

      // GoRouter yapılandırması
      routerConfig: AppRouter.router,

      // Tema Yapılandırması
      theme: themeProvider.currentTheme,
      themeMode: themeProvider.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
    );
  }
}
