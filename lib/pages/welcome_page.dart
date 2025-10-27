import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_notifier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../sign_in_panel.dart';
import '../deep_link_helper.dart';
import 'dart:async';
import '../l10n/gen/app_localizations.dart';
import 'main_navigation.dart';

class WelcomePage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  final String? userName;

  const WelcomePage({super.key, required this.themeNotifier, this.userName});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  User? user;
  String? userName;
  String? photoUrl; // ✅ مضافة لحفظ رابط الصورة
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

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
            // ✅ لا نكتب اسمًا فارغًا على الاسم المُجهّز مسبقًا
            final fetched =
                ((data['name'] ?? data['username'])?.toString().trim()) ?? '';
            if (fetched.isNotEmpty) {
              setState(() {
                userName = fetched;
              });
            }

            // ✅ نحاول جلب الصورة من Firestore إذا موجودة
            final fetchedPhoto = ((data['photoUrl'])?.toString().trim()) ?? '';
            if (fetchedPhoto.isNotEmpty) {
              setState(() {
                photoUrl = fetchedPhoto;
              });
            }

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

    // ✅ نجهّز الاسم والصورة فورًا قبل أول build (بدون انتظار Firestore)
    if (user != null && !(user!.isAnonymous)) {
      userName = widget.userName ??
          user!.displayName ??
          user!.email?.split('@').first ??
          '';

      // ✅ لو حساب Google فيه صورة، نعرضها فوراً
      photoUrl = user!.photoURL;
    }

    // 🎬 إعداد الانيميشن
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _scaleAnimation =
        Tween<double>(begin: 0.85, end: 1.0).animate(_fadeAnimation);
    _animController.forward();

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

    // ✅✅ الإضافة الجديدة والمضمونة:
    // إذا كان هناك رابط مؤجل (مثلاً التطبيق فُتح من رابط GitHub وهو مغلق)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uri = DeepLinkStore.take();
      if (uri != null && FirebaseAuth.instance.currentUser != null && mounted) {
        debugPrint("🚀 تم العثور على رابط مؤجل، يتم فتحه الآن: $uri");
        await Future.delayed(const Duration(milliseconds: 500)); // تأخير بسيط لضمان تحميل الواجهة
        openPlaceFromUri(
          context: context,
          themeNotifier: widget.themeNotifier,
          uri: uri,
        );
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _deepLinkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ نحمي الوصول إلى AppLocalizations
    final loc = AppLocalizations.of(context)!;

    // ✅ تجهيز النص الترحيبي بشكل ذكي
    String greeting;
    if (userName != null && userName!.trim().isNotEmpty) {
      greeting = "${loc.welcome}, $userName 👋";
    } else {
      greeting = loc.welcomeVisitor;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.welcome),
        automaticallyImplyLeading: false, // ✅ هذا السطر يلغي زر الثلاث شحطات
        actions: [
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
              const SizedBox(height: 30),

              // ✅ الصورة والاسم داخل صف جميل مع انيميشن
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (photoUrl != null && photoUrl!.isNotEmpty)
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(2, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.person, size: 50),
                              ),
                            ),
                          ),
                        ),
                      if (photoUrl != null && photoUrl!.isNotEmpty)
                        const SizedBox(width: 14),
                      Flexible(
                        child: Text(
                          greeting,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
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
