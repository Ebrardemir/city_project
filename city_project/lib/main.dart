import 'package:city_project/Features/Home/viewmodel/home_viewmodel.dart';
import 'package:city_project/Features/Profile/viewmodel/profile_view_model.dart';
import 'package:city_project/core/Theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:city_project/core/di/locator.dart';
import 'package:city_project/core/storage/hive_manager.dart';
import 'package:city_project/core/init/boot_manager.dart';
import 'package:city_project/core/router/app_router.dart';
import 'package:city_project/core/init/firebase_test_service.dart';
import 'package:city_project/Features/Login/view_model/login_viewmodel.dart';

void main() async {
  // 1. Flutter motorunu hazırla
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase'i başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firebase test - Konsolda sonuçları görebilirsin
  final testResults = await FirebaseTestService.testFirebaseConnection();
  FirebaseTestService.printTestResults(testResults);

  // 3. Veritabanını (Hive) başlat (AuthService için kritik)
  await HiveManager.init();

  // 4. Bağımlılık Havuzunu (GetIt) kur
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

        ChangeNotifierProvider(create: (_) => locator<HomeViewModel>()),

        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
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
