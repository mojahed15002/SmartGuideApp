import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_notifier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../sign_in_panel.dart';
import '../deep_link_helper.dart';
import 'dart:async'; // ✅ لاستعمال StreamSubscription
import '../l10n/gen/app_localizations.dart';
import 'custom_drawer.dart';
import 'main_navigation.dart';

class WelcomePage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  final String? userName;

  const WelcomePage({super.key, required this.themeNotifier, this.userName});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  User? user;
  String? userName; // 🔹 لحفظ اسم المستخدم من Firestore

  StreamSubscription<Uri>? _deepLinkSub; // ✅ متغير للاشتراك في الروابط

  Future<void> _loadUserTheme() async {
    try {
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null) {
            // 🔹 نحفظ الاسم في المتغير المحلي
            setState(() {
              userName =
                  data['name']; // تأكد أن اسم الحقل في Firestore هو "name"
            });

            // 🔹 تحميل الثيم
            if (data.containsKey('theme')) {
              final savedTheme = data['theme'];
              if (savedTheme == 'dark' && !widget.themeNotifier.isDarkMode) {
                widget.themeNotifier.setTheme(true);
              } else if (savedTheme == 'light' &&
                  widget.themeNotifier.isDarkMode) {
                widget.themeNotifier.setTheme(false);
              }
            }
          }
        }
      }
    } catch (e) {
      print("⚠️ خطأ أثناء تحميل الثيم من Firestore: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _loadUserTheme();

    // ✅ الاستماع لأي روابط تصل أثناء وجود المستخدم داخل التطبيق
    _deepLinkSub = deepLinkStreamController.stream.listen((uri) {
      debugPrint('🌐 وصل رابط أثناء وجود المستخدم داخل التطبيق: $uri');
      openPlaceFromUri(
        context: context,
        themeNotifier: widget.themeNotifier,
        uri: uri,
      );
    });
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel(); // ✅ إلغاء الاشتراك عند مغادرة الصفحة
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!; // ✅ الوصول إلى الترجمة

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.welcome), // ✅ "مرحباً بك" / "Welcome"
        actions: [
          // زر التبديل بين النمطين
          IconButton(
            icon: Icon(
              widget.themeNotifier.isDarkMode
                  ? Icons.wb_sunny
                  : Icons.nightlight_round,
              color: widget.themeNotifier.isDarkMode
                  ? Colors.orange
                  : Colors.deepOrange,
            ),
            onPressed: () async {
              // تبديل الثيم محلياً
              widget.themeNotifier.toggleTheme();

              // تحديث الحالة الجديدة في Firestore
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .set({
                        'theme': widget.themeNotifier.isDarkMode
                            ? 'dark'
                            : 'light',
                      }, SetOptions(merge: true));
                } catch (e) {
                  print("خطأ أثناء تحديث الثيم في Firestore: $e");
                }
              }
            },
          ),

          const SizedBox(height: 20),

          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج', // ✅ يبقى ثابت أو يمكن ترجمة tooltip لاحقاً
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SignInPanel(themeNotifier: widget.themeNotifier),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      drawer: CustomDrawer(
        themeNotifier: widget.themeNotifier,
      ), // ⬅️ هذا السطر المهم
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_city,
                size: 100,
                color: Colors.orange.shade600,
              ),
              const SizedBox(height: 20),
              Text(
                loc.welcomeVisitor,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                loc.cityGuideDescription,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // ✅ زر الانتقال إلى ChoicePage
              ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: Text(loc.explorePlaces), // ✅ "استكشف الأماكن"
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  backgroundColor: Colors.deepOrange,
                ),
                onPressed: () {
                  if (ModalRoute.of(context)?.isCurrent ?? false) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MainNavigation(
                          themeNotifier: widget.themeNotifier,
                        ),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
