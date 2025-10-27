import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('ar');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  ThemeNotifier() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    final langCode = prefs.getString('language') ?? 'ar';
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _locale = Locale(langCode);

    // ✅ نؤخر الإشعار قليلاً بعد أول إطار لضمان استقرار واجهة البداية
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        notifyListeners();
      });
    });
  }

  Future<void> setTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    final newTheme = isDark ? ThemeMode.dark : ThemeMode.light;

    // ✅ لا نعيد البناء إلا إذا فعلاً تغير الثيم
    if (newTheme != _themeMode) {
      _themeMode = newTheme;
      Future.delayed(const Duration(milliseconds: 150), () {
        notifyListeners();
      });
    }
  }

Future<void> setLanguage(String langCode, {bool forceNotify = false}) async {
  final prefs = await SharedPreferences.getInstance();
  final current = prefs.getString('language') ?? 'ar';

  // ✅ إذا نفس اللغة ولم يُطلب إجبار التغيير → لا نعيد البناء
  if (!forceNotify && _locale.languageCode == langCode) return;
  if (!forceNotify && current == langCode) return;

  await prefs.setString('language', langCode);
  _locale = Locale(langCode);

  // ✅ تأخير خفيف لمنع التعارض مع التنقّل أثناء تسجيل الدخول
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        notifyListeners();
      }
    });
  });
}


  void toggleTheme() {
    setTheme(_themeMode == ThemeMode.light);
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;
}
