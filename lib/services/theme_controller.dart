import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  bool get isDark => themeMode.value == ThemeMode.dark;

  // uygulama açılırken daha önce kayıtlı temayı yükler
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('isDarkTheme');

    if (saved != null) {
      themeMode.value = saved ? ThemeMode.dark : ThemeMode.light;
    }
  }

  // tema değişiminde hem UI güncellenir hem kaydedilir
  Future<void> setTheme(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', mode == ThemeMode.dark);
  }

  Future<void> toggle() async {
    final isCurrentlyDark = themeMode.value == ThemeMode.dark;
    await setTheme(isCurrentlyDark ? ThemeMode.light : ThemeMode.dark);
  }
}