import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_notifier.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/gen/app_localizations.dart';
import '../sign_in_panel.dart';
import 'swipeable_page_route.dart'; // أو المسار الصحيح حسب موقع الملف

class SettingsPage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const SettingsPage({super.key, required this.themeNotifier});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;
  String _language = 'ar';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _language = prefs.getString('language') ?? 'ar';
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);

    widget.themeNotifier.setTheme(value); // 👈 تحديث الثيم

    if (mounted) {
      setState(() => _isDarkMode = value);
    }
  }

  Future<void> _changeLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);

    // ✅ تغيير اللغة فوريًا
    widget.themeNotifier.setLanguage(langCode);

    if (mounted) {
      setState(() => _language = langCode);
    }

    // ✅ إشعار المستخدم
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.languageApplied)),
    );
  }

  void _showAboutDialog() {
    final loc = AppLocalizations.of(context)!;
    showAboutDialog(
      context: context,
      applicationName: loc.appTitle,
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 Smart City Guide',
      children: [
        const SizedBox(height: 10),
        Text(
          loc.cityGuideDescription,
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }

  Future<void> _contactUs() async {
    const url = 'mailto:smartcityguide@gmail.com?subject=استفسار حول التطبيق';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

Future<void> _signOut() async {
  final user = FirebaseAuth.instance.currentUser;

  try {
    if (user != null) {
      // ✅ إذا المستخدم مسجل كضيف
      if (user.isAnonymous) {
        await user.delete(); // نحذف الجلسة المؤقتة
      } else {
        await FirebaseAuth.instance.signOut();
      }
    }

    // ✅ بعد الخروج نرجع لصفحة تسجيل الدخول
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        SwipeablePageRoute(
          page: SignInPanel(themeNotifier: widget.themeNotifier),
        ),
        (route) => false,
      );
    }
  } catch (e) {
    debugPrint('⚠️ خطأ أثناء تسجيل الخروج: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء تسجيل الخروج')),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),

          // 🌙 الوضع الداكن
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: Text(loc.darkMode),
            trailing: Switch(
              value: _isDarkMode,
              onChanged: _toggleTheme,
            ),
          ),
          const Divider(),

          // 🌐 اللغة
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(loc.language),
            subtitle: Text(_language == 'ar' ? loc.arabic : loc.english),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(loc.language),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String>(
                        title: Text(loc.arabic),
                        value: 'ar',
                        groupValue: _language,
                        onChanged: (val) {
                          if (val != null) {
                            _changeLanguage(val);
                            Navigator.pop(context);
                          }
                        },
                      ),
                      RadioListTile<String>(
                        title: Text(loc.english),
                        value: 'en',
                        groupValue: _language,
                        onChanged: (val) {
                          if (val != null) {
                            _changeLanguage(val);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const Divider(),

          // ℹ️ عن التطبيق
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(loc.aboutApp),
            onTap: _showAboutDialog,
          ),
          const Divider(),

          // 📧 تواصل معنا
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(loc.contactUs),
            onTap: _contactUs,
          ),
          const Divider(),

          // 🚪 تسجيل الخروج مع رسالة تأكيد احترافية
ListTile(
  leading: const Icon(Icons.logout, color: Colors.red),
  title: Text(
    loc.logout,
    style: const TextStyle(color: Colors.red),
  ),
  onTap: () async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2C2C2C)
            : Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "تأكيد تسجيل الخروج",
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          "هل أنت متأكد أنك تريد تسجيل الخروج؟\n\n"
          "  في حال قمت بتسجيل الخروج، ستبقى معلومات هذا الحساب محفوظة ولن يتم حذفها.",
          textAlign: TextAlign.right,
          style: TextStyle(height: 1.4, fontSize: 15),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            child: const Text(
              "إلغاء",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "تأكيد الخروج",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 🔥 استدعاء دالة تسجيل الخروج الأصلية مع دعم المستخدم الضيف
      await _signOut();
    }
  },
),

        ],
      ),
    );
  }
}
