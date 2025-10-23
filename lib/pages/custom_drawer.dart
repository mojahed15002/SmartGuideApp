import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_notifier.dart';
import '../l10n/gen/app_localizations.dart';

class CustomDrawer extends StatelessWidget {
  final ThemeNotifier themeNotifier;

  const CustomDrawer({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = themeNotifier.isDarkMode;
    final loc = AppLocalizations.of(context)!; // ✅ الترجمة

    return Drawer(
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
              user?.displayName ?? loc.defaultUser, // ✅ مترجم
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(user?.email ?? loc.emailNotAvailable),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                color: Colors.orange.shade700,
                size: 40,
              ),
            ),
          ),

          // الصفحة الرئيسية
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(loc.home),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),

          // القريبة مني
          ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(loc.nearMe),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/near_me');
            },
          ),

          // المفضلة
          ListTile(
            leading: const Icon(Icons.favorite),
            title: Text(loc.favorites),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/favorites');
            },
          ),

          // السجلات
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(loc.travelLogs),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/logs');
            },
          ),

          const Divider(),

          // الوضع الليلي
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: Text(loc.darkMode),
            value: isDark,
            onChanged: (val) {
              themeNotifier.setTheme(val);
            },
          ),

          const Spacer(),

          // ⚙️ الإعدادات
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(loc.settings),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/settings');
            },
          ),

          const Divider(),

          // 🔐 تسجيل الخروج مع ترجمة كاملة
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: Text(loc.logout),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      loc.logoutConfirmTitle,
                      textAlign: TextAlign.right,
                    ),
                    content: Text(
                      loc.logoutConfirmMessage,
                      textAlign: TextAlign.right,
                    ),
                    actionsAlignment: MainAxisAlignment.spaceBetween,
                    actions: [
                      TextButton(
                        child: Text(loc.cancel),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        child: Text(loc.confirmLogout),
                        onPressed: () => Navigator.pop(context, true),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                }
              },
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
