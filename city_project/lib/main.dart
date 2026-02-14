import 'package:city_project/Features/Home/viewmodel/home_viewmodel.dart';
import 'package:city_project/Features/Profile/viewmodel/profile_view_model.dart';
import 'package:city_project/Features/Municipality/viewmodel/municipality_viewmodel.dart';
import 'package:city_project/core/Theme/theme_provider.dart';
import 'package:city_project/core/services/location_service.dart';
import 'package:city_project/Features/Home/service/report_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:city_project/core/router/app_router.dart';
import 'package:city_project/Features/Login/view_model/login_viewmodel.dart';
import 'package:city_project/Features/Login/view_model/register_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        // Tema yönetimi
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Login ViewModel
        ChangeNotifierProvider(create: (_) => LoginViewModel()),

        // Register ViewModel
        ChangeNotifierProvider(create: (_) => RegisterViewModel()),

        // Home ViewModel
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(
            LocationService(),
            ReportService(),
          ),
        ),

        // Profile ViewModel
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        
        // Municipality ViewModel
        ChangeNotifierProvider(create: (_) => MunicipalityViewModel()),
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
