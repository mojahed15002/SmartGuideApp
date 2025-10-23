import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_notifier.dart';

class CustomDrawer extends StatelessWidget {
  final ThemeNotifier themeNotifier;

  const CustomDrawer({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = themeNotifier.isDarkMode;

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
              user?.displayName ?? "مستخدم التطبيق",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(user?.email ?? "البريد غير متوفر"),
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
            title: const Text("الصفحة الرئيسية"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),

          // القريبة مني
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text("القريبة مني"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/near_me');
            },
          ),

          // المفضلة
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text("المفضلة"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/favorites');
            },
          ),

          // السجلات
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text("سجل الرحلات"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/logs');
            },
          ),

          const Divider(),

          // الوضع الليلي
          SwitchListTile(
  secondary: const Icon(Icons.dark_mode),
  title: const Text("الوضع الليلي"),
  value: isDark,
  onChanged: (val) {
    themeNotifier.setTheme(val);
  },
),


          const Spacer(),

// السجلات
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("الاعدادات"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/settings');
            },
          ),

          const Divider(),

          // 🔐 تسجيل الخروج مع رسالة تأكيد
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
  child: ElevatedButton.icon(
    icon: const Icon(Icons.logout),
    label: const Text("تسجيل الخروج"),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.redAccent,
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    onPressed: () async {
      // 🔔 عرض رسالة التأكيد
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            "هل أنت متأكد من تسجيل الخروج؟",
            textAlign: TextAlign.right,
          ),
          content: const Text(
            "في حال قمت بتسجيل الخروج، ستبقى معلومات هذا الحساب محفوظة ولن يتم حذفها.",
            textAlign: TextAlign.right,
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              child: const Text("إلغاء"),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text("تأكيد"),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );

      // ✅ إذا المستخدم أكّد الخروج
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
