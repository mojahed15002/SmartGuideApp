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
  // ✅ هذه الدالة موجودة في جميع الإصدارات القديمة والجديدة
  final Uri? initialUri = await appLinks.getInitialLink();

  if (initialUri != null) {
    _pendingDeepLink = initialUri.toString();
  }
} catch (e) {
  debugPrint("⚠️ خطأ أثناء قراءة الرابط الابتدائي: $e");
}


  runApp(MyAppWrapper(themeNotifier: themeNotifier));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart City Guide',
      home: SignInPanel(themeNotifier: ThemeNotifier()),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      // تثبيت اللغة العربية
      locale: const Locale('ar'),
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
  StreamSubscription<Uri?>? _sub; // ✅ تعديل النوع من String إلى Uri
  late final AppLinks _appLinks; // ✅ إنشاء كائن AppLinks

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  /// ✅ تهيئة روابط app_links (أثناء تشغيل التطبيق)
  Future<void> _initDeepLinks() async {
    try {
      _appLinks = AppLinks();

      // ✅ الاستماع للروابط أثناء عمل التطبيق
      _sub = _appLinks.uriLinkStream.listen((Uri? uri) {
        if (uri != null) _handleIncomingLink(uri.toString());
      }, onError: (err) {
        debugPrint("❌ خطأ أثناء استقبال الرابط: $err");
      });

      // ✅ إذا وُجد رابط مؤجل من حالة "التطبيق المغلق"
      if (_pendingDeepLink != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleIncomingLink(_pendingDeepLink!);
          _pendingDeepLink = null; // تفريغ الرابط بعد المعالجة
        });
      }
    } catch (e) {
      debugPrint("❌ فشل في تهيئة الروابط: $e");
    }
  }

  /// ✅ معالجة الرابط الوارد
void _handleIncomingLink(String link) {
  try {
    final uri = Uri.parse(link);
    debugPrint('✅ وصل رابط: $uri');

    // إذا المستخدم غير مسجل دخول حالياً → خزّنه مؤقتاً وارجع
    if (FirebaseAuth.instance.currentUser == null) {
      DeepLinkStore.set(uri);
      debugPrint('🕒 خزنّا الرابط مؤقتاً لفتحه بعد تسجيل الدخول');
      return;
    }

    // المستخدم داخل التطبيق → افتح الصفحة فوراً
    deepLinkStreamController.add(
      uri,
    );
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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: widget.themeNotifier,
      builder: (context, themeMode, _) {
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
          themeMode: themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          locale: const Locale('ar'),

/// StreamBuilder يتحقق إن كان المستخدم مسجّل دخول أم لا
home: StreamBuilder<User?>(
  stream: FirebaseAuth.instance.authStateChanges(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (snapshot.hasData) {
      // ✅ المستخدم مسجّل دخول بالفعل
      final user = snapshot.data!;

      // ✅ التحقق إن كان هناك رابط مؤجل لفتحه مباشرة بعد الدخول
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

      // قراءة الثيم من Firestore مرة واحدة عند تسجيل الدخول
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

    // ✅ المستخدم غير مسجّل → عرض صفحة تسجيل الدخول
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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
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
          themeMode: themeMode,
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
