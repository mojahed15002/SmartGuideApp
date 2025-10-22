import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_notifier.dart';

// ✅ إضافة الترجمة
import '../l10n/gen/app_localizations.dart';

class CustomDrawer extends StatelessWidget {
  final ThemeNotifier themeNotifier;

  const CustomDrawer({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = themeNotifier.isDarkMode;

    // ✅ تحديد اتجاه الصفحة حسب اللغة
    final isArabic = AppLocalizations.of(context)!.localeName == 'ar';
    final direction = isArabic ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: direction,
      child: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              accountName: Text(
                user?.displayName ?? AppLocalizations.of(context)!.user,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              accountEmail: Text(user?.email ?? AppLocalizations.of(context)!.email),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  color: Colors.orange.shade700,
                  size: 40,
                ),
              ),
            ),

            // 🏠 الصفحة الرئيسية
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(AppLocalizations.of(context)!.explore),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/home');
              },
            ),

            // 📍 القريبة مني
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(AppLocalizations.of(context)!.nearMe),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/near_me');
              },
            ),

            // ❤️ المفضلة
            ListTile(
              leading: const Icon(Icons.favorite),
              title: Text(AppLocalizations.of(context)!.favorites),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/favorites');
              },
            ),

            // 🕓 السجلات
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(AppLocalizations.of(context)!.logs),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/logs');
              },
            ),

            const Divider(),

            // 🌙 الوضع الليلي
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode),
              title: Text(AppLocalizations.of(context)!.darkMode),
              value: isDark,
              onChanged: (val) {
                themeNotifier.setTheme(val);
              },
            ),

            const Spacer(),

            // ⚙️ الإعدادات
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(AppLocalizations.of(context)!.settings),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
      ),
    );
  }
}
