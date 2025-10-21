import 'package:flutter/material.dart';
import 'theme_notifier.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'sign_in_panel.dart';
import 'pages/welcome_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'deep_link_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/gen/app_localizations.dart';

import 'pages/choice_page.dart';
import 'pages/near_me_page.dart';
import 'pages/favorites_page.dart';
import 'pages/logs_page.dart';
import 'pages/settings_page.dart';
 
final ThemeNotifier themeNotifier = ThemeNotifier();

// ✅ متغير لتخزين الرابط المؤجل (في حال كان التطبيق مغلق)
String? _pendingDeepLink;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ محاولة قراءة الرابط عند تشغيل التطبيق لأول مرة
  try {
    final appLinks = AppLinks();
    final Uri? initialUri = await appLinks.getInitialLink();
    if (initialUri != null) {
      _pendingDeepLink = initialUri.toString();
    }
  } catch (e) {
    debugPrint("⚠️ خطأ أثناء قراءة الرابط الابتدائي: $e");
  }

  runApp(MyAppWrapper(themeNotifier: themeNotifier));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('ar');
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('language') ?? 'ar';
    final isDark = prefs.getBool('isDarkMode') ?? false;

    setState(() {
      _locale = Locale(savedLang);
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart City Guide',
      debugShowCheckedModeBanner: false,

      // ✅ الثيمات
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: "Roboto",
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: "Roboto",
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,

      // ✅ اللغة والترجمة
      locale: _locale,
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate, // 🔥 ضروري جداً
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ✅ الاتجاه حسب اللغة
      builder: (context, child) {
        return Directionality(
          textDirection:
              _locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },



      home: SignInPanel(themeNotifier: themeNotifier),
    );
  }
}

/// الصفحة الرئيسية التي تتحكم بتبديل الثيم والتنقل بين تسجيل الدخول والترحيب
class MyAppWrapper extends StatefulWidget {
  final ThemeNotifier themeNotifier;

  const MyAppWrapper({super.key, required this.themeNotifier});

  @override
  State<MyAppWrapper> createState() => _MyAppWrapperState();
}

class _MyAppWrapperState extends State<MyAppWrapper> {
  StreamSubscription<Uri?>? _sub;
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      _appLinks = AppLinks();

      _sub = _appLinks.uriLinkStream.listen((Uri? uri) {
        if (uri != null) _handleIncomingLink(uri.toString());
      }, onError: (err) {
        debugPrint("❌ خطأ أثناء استقبال الرابط: $err");
      });

      if (_pendingDeepLink != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleIncomingLink(_pendingDeepLink!);
          _pendingDeepLink = null;
        });
      }
    } catch (e) {
      debugPrint("❌ فشل في تهيئة الروابط: $e");
    }
  }

  void _handleIncomingLink(String link) {
    try {
      final uri = Uri.parse(link);
      debugPrint('✅ وصل رابط: $uri');

      if (FirebaseAuth.instance.currentUser == null) {
        DeepLinkStore.set(uri);
        debugPrint('🕒 خزنّا الرابط مؤقتاً لفتحه بعد تسجيل الدخول');
        return;
      }

      deepLinkStreamController.add(uri);
    } catch (e) {
      debugPrint('❌ خطأ في تحليل الرابط: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.themeNotifier,
      builder: (context, _) {
        return MaterialApp(
          title: 'Smart City Guide',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.orange,
            fontFamily: "Roboto",
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.orange,
            fontFamily: "Roboto",
            brightness: Brightness.dark,
          ),
          themeMode: widget.themeNotifier.themeMode,
          locale: widget.themeNotifier.locale,
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return Directionality(
              textDirection: widget.themeNotifier.locale.languageCode == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: child!,
            );
          },
          // ⬇️ أضف هان
  routes: {
    '/home': (context) => ChoicePage(themeNotifier: widget.themeNotifier),
    '/near_me': (context) => NearMePage(themeNotifier: widget.themeNotifier),
    '/favorites': (context) => FavoritesPage(themeNotifier: widget.themeNotifier),
    '/logs': (context) => LogsPage(themeNotifier: widget.themeNotifier),
    '/login': (context) => SignInPanel(themeNotifier: widget.themeNotifier),
    '/settings': (context) => SettingsPage(themeNotifier: widget.themeNotifier),
  },
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasData) {
                final user = snapshot.data!;
                final pending = DeepLinkStore.take();
                if (pending != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    openPlaceFromUri(
                      context: context,
                      themeNotifier: widget.themeNotifier,
                      uri: pending,
                    );
                  });
                }

                FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get()
                    .then((doc) {
                  if (doc.exists && doc.data()?['theme'] != null) {
                    final savedTheme = doc['theme'];
                    widget.themeNotifier.setTheme(savedTheme == 'dark');
                  }
                });

                return WelcomePage(themeNotifier: widget.themeNotifier);
              }

              return SignInPanel(themeNotifier: widget.themeNotifier);
            },
          ),
        );
      },
    );
  }
}

/// النسخة الاحتياطية القديمة (نتركها كما هي في حال رغبت لاحقًا بالرجوع)
class MyAppWrapperBackup1 extends StatelessWidget {
  final ThemeNotifier themeNotifier = ThemeNotifier();

  MyAppWrapperBackup1({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Smart City Guide',
          theme: ThemeData(
            primarySwatch: Colors.orange,
            fontFamily: "Roboto",
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.orange,
            fontFamily: "Roboto",
            brightness: Brightness.dark,
          ),
          themeMode: themeNotifier.themeMode,
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasData) {
                return WelcomePage(themeNotifier: themeNotifier);
              }
              return SignInPanel(themeNotifier: themeNotifier);
            },
          ),
        );
      },
    );
  }
}
