import 'package:flutter/material.dart';
import 'theme_notifier.dart'; // عشان تقدر تستخدم ThemeNotifier من عندك

class ThemeToggleButton extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  const ThemeToggleButton({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;

        return TextButton.icon(
          onPressed: () {
          },
          icon: Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            color: Colors.orange,
          ),
          label: Text(
            isDark ? "إيقاف" : "تفعيل",
            style: const TextStyle(color: Colors.orange, fontSize: 16),
          ),
        );
      },
    );
  }
}
