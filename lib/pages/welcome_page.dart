import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_notifier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../sign_in_panel.dart';
import '../deep_link_helper.dart';
import 'dart:async';
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
  String? userName;

  StreamSubscription<Uri>? _deepLinkSub;

  Future<void> _loadUserTheme() async {
    try {
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null && mounted) {
            setState(() {
              userName = data['name'];
            });

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
      debugPrint("⚠️ خطأ أثناء تحميل الثيم من Firestore: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _loadUserTheme();

    // ✅ الاستماع للروابط بشكل آمن
    _deepLinkSub = deepLinkStreamController.stream.listen((uri) {
      if (!mounted) return;
      debugPrint('🌐 وصل رابط: $uri');

      // نحمي context باستخدام Future.microtask لضمان أنه بعد build
      Future.microtask(() {
        if (mounted) {
          openPlaceFromUri(
            context: context,
            themeNotifier: widget.themeNotifier,
            uri: uri,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ نحمي الوصول إلى AppLocalizations
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.welcome),
        actions: [
          // ✅ تعديل زر القمر ليعمل بشكل آمن مع المستخدمين العاديين والضيوف
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
              try {
                // ✅ بدّل الثيم أولاً بشكل فوري
                final newMode = !widget.themeNotifier.isDarkMode;
                widget.themeNotifier.setTheme(newMode);

                // ✅ نفذ تحديث Firestore بعد إعادة البناء بأمان
                Future.microtask(() async {
                  try {
                    final user = FirebaseAuth.instance.currentUser;

                    // 🔒 تحقق أن المستخدم موجود وله UID (حتى لو كان ضيف)
                    if (user == null || user.uid.isEmpty) {
                      debugPrint("⚠️ لم يتم العثور على المستخدم أثناء تبديل الثيم");
                      return;
                    }

                    // ✅ حدث Firestore فقط إن كان المستخدم ما زال متصلاً
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .set({
                      'theme': newMode ? 'dark' : 'light',
                    }, SetOptions(merge: true));

                    debugPrint("✅ تم تحديث الثيم بنجاح للمستخدم ${user.uid}");
                  } catch (e) {
                    debugPrint("⚠️ خطأ أثناء تحديث الثيم في Firestore: $e");
                  }
                });
              } catch (e) {
                debugPrint("⚠️ خطأ أثناء تبديل الثيم: $e");
              }
            },
          ),

          const SizedBox(height: 20),

          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SignInPanel(themeNotifier: widget.themeNotifier),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      drawer: CustomDrawer(themeNotifier: widget.themeNotifier),
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
              ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: Text(loc.explorePlaces),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  backgroundColor: Colors.deepOrange,
                ),
                onPressed: () {
                  if (!mounted) return;
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
