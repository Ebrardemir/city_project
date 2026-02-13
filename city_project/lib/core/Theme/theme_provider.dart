import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  // ignore: constant_identifier_names
  static const THEME_STATUS = "THEME_STATUS";
  bool _darkTheme = false;

  bool get isDarkTheme => _darkTheme;

  ThemeProvider() {
    getTheme();
  }

  Future<void> toggleTheme() async {
    _darkTheme = !_darkTheme;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(THEME_STATUS, _darkTheme);
    notifyListeners();
  }

  Future<void> getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _darkTheme = prefs.getBool(THEME_STATUS) ?? false;
    notifyListeners();
  }
}
