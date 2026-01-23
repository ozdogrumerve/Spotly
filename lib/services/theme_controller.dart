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

// AÇIK TEMA (PALETİMİZİ KULLANIYOR)
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,

  scaffoldBackgroundColor: const Color(0xFFAAD0E2),

  primaryColor: const Color(0xFF153A50),

  colorScheme: const ColorScheme.light(
    primary: Color(0xFF153A50),
    secondary: Color(0xFF5B8094),
  ),

  cardTheme: CardTheme(
    color: const Color(0xFF87B1C8), // KART RENGİ
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF153A50),
    foregroundColor: Colors.white,
    elevation: 0,
  ),

  cardColor: const Color(0xFF87B1C8),

  dividerColor: const Color(0xFF7198AF),

  iconTheme: const IconThemeData(
    color: Color(0xFF153A50),
  ),

  listTileTheme: const ListTileThemeData(
    iconColor: Color(0xFF153A50),
    textColor: Colors.black87,
  ),

  // 🔹 ELEVATED BUTTON
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF153A50),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),

  // 🔹 TEXT BUTTON
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF153A50),
    ),
  ),

  // 🔹 OUTLINED BUTTON
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF153A50),
      side: const BorderSide(color: Color(0xFF153A50)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),

  // 🔹 FLOATING ACTION BUTTON
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF153A50),
    foregroundColor: Colors.white,
  ),

  textTheme: const TextTheme(
    titleLarge: TextStyle(
      color: Color(0xFF153A50),
      fontWeight: FontWeight.bold,
    ),
    bodyMedium: TextStyle(
      color: Colors.black87,
    ),
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF153A50), // bar arka planı
    selectedItemColor: Colors.white,    // seçili ikon + yazı
    unselectedItemColor: Color(0xFFB0C7D6), // seçili olmayanlar
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
  ),

  splashColor: const Color(0xFF5B8094).withOpacity(0.25),
  highlightColor: const Color(0xFF5B8094).withOpacity(0.15),

);


// KARANLIK TEMA 
final ThemeData darkTheme = ThemeData.dark();
