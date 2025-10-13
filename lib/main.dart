import 'package:flutter/material.dart';
import 'theme_notifier.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'sign_in_panel.dart';
import 'pages/welcome_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final ThemeNotifier themeNotifier = ThemeNotifier();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
class MyAppWrapper extends StatelessWidget {
  final ThemeNotifier themeNotifier;

  const MyAppWrapper({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
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

          /// ✅ هنا التعديل الأهم
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
                // قراءة الثيم من Firestore مرة واحدة عند تسجيل الدخول
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get()
                    .then((doc) {
                  if (doc.exists && doc.data()?['theme'] != null) {
                    final savedTheme = doc['theme'];
                    themeNotifier.setTheme(savedTheme == 'dark');
                  }
                });
                return WelcomePage(themeNotifier: themeNotifier);
              }
              // ✅ المستخدم غير مسجّل → عرض صفحة تسجيل الدخول
              return SignInPanel(themeNotifier: themeNotifier);
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
