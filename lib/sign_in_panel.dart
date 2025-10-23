import 'package:flutter/material.dart';
import 'pages/welcome_page.dart';
import 'pages/forgot_password_page.dart';
import '../theme_notifier.dart';
import 'pages/signup_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'deep_link_helper.dart';

// ✅ إضافة ملف الترجمة
import 'l10n/gen/app_localizations.dart';

class SignInPanel extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const SignInPanel({super.key, required this.themeNotifier});

  @override
  State<SignInPanel> createState() => _SignInPanelState();
}

class _SignInPanelState extends State<SignInPanel> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _language = 'ar';


Future<void> _changeLanguage(String langCode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('language', langCode);
  widget.themeNotifier.setLanguage(langCode);

  if (mounted) {
    setState(() {
      _language = langCode;
    });
  }
}



  @override
  Widget build(BuildContext context) {
    bool isDarkMode = widget.themeNotifier.isDarkMode;
    final Color primaryColor = isDarkMode ? Colors.orange : Colors.deepOrange;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;

    // ✅ تحديد اتجاه الصفحة
    final isArabic = AppLocalizations.of(context)!.localeName == 'ar';
    final direction = isArabic ? TextDirection.rtl : TextDirection.ltr;
    final loc = AppLocalizations.of(context)!;

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        backgroundColor:
            isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF9F6F6),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🔸 صف يحتوي على زر الثيم وزر اللغة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // زر الثيم (كما هو)
                      IconButton(
                        icon: Icon(
                          isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                          color: primaryColor,
                        ),
                        onPressed: () async {
                          widget.themeNotifier.toggleTheme();

                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .update({
                              'theme': widget.themeNotifier.isDarkMode
                                  ? 'dark'
                                  : 'light',
                            });
                          }
                        },
                      ),
                      // 🌐 زر تغيير اللغة الجديد
                      IconButton(
                        icon: Icon(Icons.language, color: primaryColor),
                        tooltip: loc.language,
                        onPressed: () {
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
                    ],
                  ),

                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context)!.signIn,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Card(
                    elevation: 5,
                    color: isDarkMode
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF3F0F0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.email,
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.password,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ForgotPasswordPage(
                                        themeNotifier: widget.themeNotifier),
                                  ),
                                );
                              },
                              child: Text(
                                AppLocalizations.of(context)!.forgotPassword,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),


                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  final credential =
                                      await FirebaseAuth.instance
                                          .signInWithEmailAndPassword(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text.trim(),
                                  );

                                  if (!mounted) return;
                                  final user = credential.user;
                                  if (user != null) {
                                    final userDoc = FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.uid);

                                    final snapshot = await userDoc.get();

if (!snapshot.exists) {
  // 📦 جلب اللغة من SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('language') ?? 'ar';

  await userDoc.set({
    'email': user.email,
    'theme': widget.themeNotifier.isDarkMode ? 'dark' : 'light',
    'language': savedLang, // ✅ حفظ اللغة المختارة
    'favorites': [],
    'createdAt': FieldValue.serverTimestamp(),
  });
} else {
  // 📦 جلب اللغة الحالية وتحديثها في حالة المستخدم موجود
  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('language') ?? 'ar';

  await userDoc.set({
    'email': user.email,
    'theme': widget.themeNotifier.isDarkMode ? 'dark' : 'light',
    'language': savedLang, // ✅ تحديث اللغة دائمًا
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

                                    if (!mounted) return;
                                    final pending = DeepLinkStore.take();
                                    if (pending != null) {
                                      openPlaceFromUri(
                                        context: context,
                                        themeNotifier: widget.themeNotifier,
                                        uri: pending,
                                      );
                                    }

                                    final favSnapshot =
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(user.uid)
                                            .get();

                                    if (!mounted) return;
                                    List<dynamic> favorites = [];
                                    if (favSnapshot.exists) {
                                      final data = favSnapshot.data();
                                      if (data != null &&
                                          data.containsKey('favorites')) {
                                        favorites = List<String>.from(
                                            data['favorites']);
                                        final prefs =
                                            await SharedPreferences.getInstance();
                                        await prefs.setStringList(
                                            'favorites_list',
                                            favorites.cast<String>());
                                      }
                                    }

                                    if (!mounted) return;
                                    final userDocData = await userDoc.get();

if (userDocData.exists) {
  final data = userDocData.data();
  if (data != null) {
    // 🟢 تطبيق اللغة المحفوظة
    if (data.containsKey('language')) {
      final savedLang = data['language'];
      widget.themeNotifier.setLanguage(savedLang);
      setState(() {
        _language = savedLang;
      });
    }

    // 🌙 تطبيق الثيم المحفوظ
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

                                  if (!mounted) return;
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => WelcomePage(
                                        themeNotifier: widget.themeNotifier,
                                        userName: credential.user?.email ??
                                            AppLocalizations.of(context)!.user,
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          "${AppLocalizations.of(context)!.signInError}: $e"),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.signIn,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // تسجيل الدخول بجوجل
OutlinedButton.icon(
  onPressed: () async {
    try {
      if (Theme.of(context).platform == TargetPlatform.android ||
          Theme.of(context).platform == TargetPlatform.iOS) {
        final GoogleSignInAccount? googleUser =
            await GoogleSignIn().signIn();
        if (googleUser == null) return;
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      } else {
        await FirebaseAuth.instance
            .signInWithPopup(GoogleAuthProvider());
      }

      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final snapshot = await userDoc.get();

        // ✅ قراءة اللغة من SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final savedLang = prefs.getString('language') ?? _language;

        if (!snapshot.exists) {
          await userDoc.set({
            'name': user.displayName ??
                AppLocalizations.of(context)!.googleUser,
            'email': user.email,
            'photoUrl': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'theme': widget.themeNotifier.isDarkMode ? 'dark' : 'light',
            'language': savedLang, // ✅ حفظ اللغة الفعلية
            'favorites': [],
          });
        } else {
          await userDoc.set({
            'name': user.displayName ??
                AppLocalizations.of(context)!.googleUser,
            'email': user.email,
            'photoUrl': user.photoURL,
            'theme': widget.themeNotifier.isDarkMode ? 'dark' : 'light',
            'language': savedLang, // ✅ تحديث اللغة
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        // ✅ قراءة اللغة والثيم من قاعدة البيانات بعد تسجيل الدخول بحساب Google
        final userDocData = await userDoc.get();
        if (userDocData.exists) {
          final data = userDocData.data();
          if (data != null) {
            // 🌐 اللغة
            if (data.containsKey('language')) {
              final savedLang = data['language'];
              widget.themeNotifier.setLanguage(savedLang);
              setState(() {
                _language = savedLang;
              });
            }

            // 🌙 الثيم
            if (data.containsKey('theme')) {
              final savedTheme = data['theme'];
              if (savedTheme == 'dark' &&
                  !widget.themeNotifier.isDarkMode) {
                widget.themeNotifier.setTheme(true);
              } else if (savedTheme == 'light' &&
                  widget.themeNotifier.isDarkMode) {
                widget.themeNotifier.setTheme(false);
              }
            }
          }
        }

        // ✅ جلب المفضلة وتخزينها محليًا
        final favSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        List<String> favorites = [];
        if (favSnapshot.exists) {
          final data = favSnapshot.data();
          if (data != null && data.containsKey('favorites')) {
            favorites = List<String>.from(data['favorites']);
          }
        }

        final pending = DeepLinkStore.take();
        if (pending != null) {
          openPlaceFromUri(
            context: context,
            themeNotifier: widget.themeNotifier,
            uri: pending,
          );
        }

        await prefs.setStringList('favorites_list', favorites);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WelcomePage(
            themeNotifier: widget.themeNotifier,
            userName: FirebaseAuth.instance.currentUser?.displayName ??
                AppLocalizations.of(context)!.googleUser,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${AppLocalizations.of(context)!.googleSignInError}: $e",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  },
  icon: Icon(Icons.g_mobiledata, color: primaryColor),
  label: Text(
    AppLocalizations.of(context)!.signInWithGoogle,
    style: TextStyle(color: primaryColor),
  ),
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: primaryColor),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  ),
),
const SizedBox(height: 10),

                          // زر الدخول كضيف
                          OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                UserCredential userCredential =
                                    await FirebaseAuth.instance
                                        .signInAnonymously();

                                if (!mounted) return;
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WelcomePage(
                                      userName:
                                          AppLocalizations.of(context)!.guest,
                                      themeNotifier: widget.themeNotifier,
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context)!
                                        .guestLoginError),
                                  ),
                                );
                              }
                            },
                            icon: Icon(Icons.person_outline,
                                color: primaryColor),
                            label: Text(
                              AppLocalizations.of(context)!.guestLogin,
                              style: TextStyle(color: primaryColor),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SignUpPage(
                                      themeNotifier: widget.themeNotifier),
                                ),
                              );
                            },
                            child: Text(
                              AppLocalizations.of(context)!.createAccount,
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
