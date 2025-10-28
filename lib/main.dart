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
import 'pages/all_comments_page.dart';

// ✅ الإضافة الجديدة
  
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

  // ✅ إضافات مطلوبة: اشتراك wrapper بالستريم + قفل منع الفتح المكرر
  StreamSubscription<Uri>? _deepStreamSub; // ✅
  bool _navInProgress = false;             // ✅

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

      // ✅ اشتراك إضافي مضمون من الـ Wrapper نفسه
      _deepStreamSub = deepLinkStreamController.stream.listen((uri) {
        if (!_isValidPlaceLink(uri)) {
          debugPrint('ℹ️ (wrapper) تجاهل رابط غير صالح للمكان.');
          return;
        }
        _openDeepLinkNow(uri); // يفتح مباشرة (ويسجّل ضيف عند الحاجة)
      }, onError: (err) {
        debugPrint('❌ (wrapper) خطأ في ستريم الروابط: $err');
      });

if (_pendingDeepLink != null) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && context.mounted) {
      final uri = Uri.parse(_pendingDeepLink!);
      // ⛔️ لا تفتح إلا إذا الرابط رابط مكان صالح
if (_isValidPlaceLink(uri)) {
  debugPrint('📦 تم العثور على رابط مؤجل صالح، سيتم فتحه لاحقًا داخل WelcomePage');
  DeepLinkStore.set(uri);
} else {
  debugPrint('ℹ️ initialUri ليست رابط مكان صالح — تم تجاهلها.');
}
      _pendingDeepLink = null;
    }
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

    // ⛔️ إذا مش رابط مكان صالح، تجاهله
    if (!_isValidPlaceLink(uri)) {
      debugPrint('ℹ️ تم تجاهل رابط غير متعلق بصفحة مكان.');
      return;
    }

    // ✅ مهم: خزّن الرابط دائمًا حتى لو كان المستخدم مسجّل
    DeepLinkStore.set(uri);

if (FirebaseAuth.instance.currentUser == null) {
  // لا يوجد مستخدم: خزّن الرابط وسيفتح لاحقًا بعد تسجيل الدخول أو كضيف
  debugPrint('🕒 لا يوجد مستخدم — سيتم فتح الرابط بعد تسجيل الدخول');
  DeepLinkStore.set(uri);
  return;
}

    // يوجد مستخدم: ابعثه للصفحات المفتوحة (WelcomePage راح تسمع)
    if (mounted && context.mounted) {
      deepLinkStreamController.add(uri);
    }
  } catch (e) {
    debugPrint('❌ خطأ في تحليل الرابط: $e');
  }
}


// ✅ جديد: نتحقق أن الرابط هو رابط "مكان" فعلاً
bool _isValidPlaceLink(Uri uri) {
  final hasId = uri.queryParameters.containsKey('id'); // مطلوب
  final isGithub =
      uri.scheme == 'https' &&
      uri.host == 'mojahed15002.github.io' &&
      uri.path.startsWith('/SmartGuideApp/place'); // نضيّق للمسار /place
  final isCustom =
      uri.scheme == 'smartcityguide' &&
      uri.host == 'place';

  return hasId && (isGithub || isCustom);
}


  // ✅ جديد: دالة موحّدة تضمن تسجيل ضيف ثم فتح الرابط مباشرة + قفل
Future<void> _openDeepLinkNow(Uri uri) async {
  try {
    if (_navInProgress) {
      debugPrint('⚠️ تم تجاهل فتح مكرر للرابط: $uri');
      return;
    }
    _navInProgress = true;

    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
      debugPrint("👤 تم تسجيل الدخول كضيف من MyAppWrapper لفتح الرابط");
    }

    // ✅ تأجيل التنفيذ حتى يتم بناء الواجهة فعليًا
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted || !context.mounted) {
        _navInProgress = false;
        return;
      }

      openPlaceFromUri(
        context: context,
        themeNotifier: widget.themeNotifier,
        uri: uri,
      );

      Future.delayed(const Duration(seconds: 2), () {
        _navInProgress = false;
      });
    });
  } catch (e) {
    _navInProgress = false;
    debugPrint("❌ فشل _openDeepLinkNow: $e");
  }
}


  @override
  void dispose() {
    _sub?.cancel();
    _deepStreamSub?.cancel(); // ✅ إلغاء الاشتراك الإضافي
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
          routes: {
            '/home': (context) => ChoicePage(themeNotifier: widget.themeNotifier),
            '/near_me': (context) => NearMePage(themeNotifier: widget.themeNotifier),
            '/favorites': (context) => FavoritesPage(themeNotifier: widget.themeNotifier),
            '/logs': (context) => LogsPage(themeNotifier: widget.themeNotifier),
            '/login': (context) => SignInPanel(themeNotifier: widget.themeNotifier),
            '/settings': (context) => SettingsPage(themeNotifier: widget.themeNotifier),
            '/all_comments': (context) {
  final placeId = ModalRoute.of(context)!.settings.arguments as String;
  return AllCommentsPage(placeId: placeId);
},

          },
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // ✅ جديد: لو لا يوجد مستخدم لكن لدينا رابط مؤجل، افتحه الآن بتسجيل ضيف
final Uri? pendingBeforeLogin = (() {
  final fromStore = DeepLinkStore.take();
  if (fromStore != null && _isValidPlaceLink(fromStore)) return fromStore;

  if (_pendingDeepLink != null) {
    try {
      final u = Uri.parse(_pendingDeepLink!);
      if (_isValidPlaceLink(u)) return u;
    } catch (_) {}
  }
  return null;
})();

              if (!snapshot.hasData && pendingBeforeLogin != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    _openDeepLinkNow(pendingBeforeLogin);
                    _pendingDeepLink = null;
                  }
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasData) {
                final user = snapshot.data!;
                final pending = DeepLinkStore.take();
                if (pending != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && context.mounted) {
                      openPlaceFromUri(
                        context: context,
                        themeNotifier: widget.themeNotifier,
                        uri: pending,
                      );
                    }
                  });
                }

                // ✅ تحميل اللغة والثيم من Firestore بشكل آمن بعد تسجيل الدخول التلقائي
                Future.microtask(() async {
                  final user = FirebaseAuth.instance.currentUser;

                  if (user == null || user.isAnonymous) {
                    debugPrint("🚫 المستخدم ضيف أو غير مسجل، لا حاجة لتحميل إعدادات Firestore");
                    return;
                  }

                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get();

                  if (!userDoc.exists) return;

                  final prefs = await SharedPreferences.getInstance();
                  final data = userDoc.data() ?? {};

                  if (data['theme'] != null) {
                    final savedTheme = data['theme'];
                    widget.themeNotifier.setTheme(savedTheme == 'dark');
                    await prefs.setBool('isDarkMode', savedTheme == 'dark');
                  }

                  if (data['language'] != null) {
                    final savedLang = data['language'];
                    widget.themeNotifier.setLanguage(savedLang);
                    await prefs.setString('language', savedLang);
                  }
                });

                if (_pendingDeepLink != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final uri = Uri.parse(_pendingDeepLink!);
                    openPlaceFromUri(
                      context: context,
                      themeNotifier: widget.themeNotifier,
                      uri: uri,
                    );
                    _pendingDeepLink = null;
                  });
                }

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
