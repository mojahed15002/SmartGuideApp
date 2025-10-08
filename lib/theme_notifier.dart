import 'package:flutter/material.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light);

  void toggleTheme() {
    value = value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDarkMode => value == ThemeMode.dark;

  void setTheme(bool isDark) {
    value = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}
