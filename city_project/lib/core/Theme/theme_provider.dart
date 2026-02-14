import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const THEME_STATUS = "THEME_STATUS";
  bool _isDarkMode = false;

  bool get isDarkTheme => _isDarkMode;

  // HATAYI ÇÖZEN KISIM: main.dart bu 'currentTheme'i bekliyor
  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _lightTheme;

  ThemeProvider() {
    getTheme();
  }

  // Aydınlık ve Karanlık Tema Tanımları
  final _lightTheme = _buildTheme(Brightness.light);
  final _darkTheme = _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final baseColor = const Color(0xFF2563EB); // Modern Royal Blue
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: baseColor,
        brightness: brightness,
        surface: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
        background: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
      ),
      scaffoldBackgroundColor: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
      
      // Kart Tasarımı
      /* 
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
            width: 1,
          ),
        ),
        color: isLight ? Colors.white : const Color(0xFF1E293B),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      */

      // AppBar Tasarımı
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: isLight ? const Color(0xFF0F172A) : Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(
          color: isLight ? const Color(0xFF0F172A) : Colors.white,
        ),
      ),

      // Buton Tasarımları
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: baseColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: baseColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Input Tasarımı
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
        labelStyle: TextStyle(
          color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
        thickness: 1,
        space: 1,
      ),
      
      // Bottom Nav
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
        selectedItemColor: baseColor,
        unselectedItemColor: isLight ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),
    );
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(THEME_STATUS, _isDarkMode);
    notifyListeners();
  }

  Future<void> getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(THEME_STATUS) ?? false;
    notifyListeners();
  }
}
