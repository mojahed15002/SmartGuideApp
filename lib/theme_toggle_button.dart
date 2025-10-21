import 'package:flutter/material.dart';
import 'theme_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ThemeToggleButton extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  const ThemeToggleButton({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    // ✅ استخدم AnimatedBuilder بدل ValueListenableBuilder
    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, _) {
        final isDark = themeNotifier.isDarkMode;

        return TextButton.icon(
          onPressed: () async {
            // ✅ تغيير الثيم محليًا
            themeNotifier.setTheme(!isDark);

            // ✅ تحديث الثيم في Firebase للمستخدمين المسجلين فقط (ليس الضيوف)
            final user = FirebaseAuth.instance.currentUser;
            if (user != null && !user.isAnonymous) {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({
                  'theme': isDark ? 'light' : 'dark',
                  'updatedAt': FieldValue.serverTimestamp(),
                });
              } catch (e) {
                debugPrint('⚠️ فشل تحديث الثيم في Firebase: $e');
              }
            }
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
