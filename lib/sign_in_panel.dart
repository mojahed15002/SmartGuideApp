import 'package:flutter/material.dart';
import 'pages/welcome_page.dart';
import 'pages/forgot_password_page.dart';
import '../theme_notifier.dart';
import 'pages/signup_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = widget.themeNotifier.isDarkMode;
    final Color primaryColor = isDarkMode ? Colors.orange : Colors.deepOrange;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF9F6F6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // زر التبديل بين النمطين
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: Icon(
                      isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                      color: primaryColor,
                    ),
                    onPressed: () async {
  widget.themeNotifier.toggleTheme();

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'theme': widget.themeNotifier.isDarkMode ? 'dark' : 'light',
    });
  }
},
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 30),

                // الكارد
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
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
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

                        // هل نسيت كلمة المرور؟
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
                              "هل نسيت كلمة المرور؟",
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // زر تسجيل الدخول
SizedBox(
  width: double.infinity,
  height: 48,
  child: ElevatedButton(
    onPressed: () async {
      try {
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final user = credential.user;
        if (user != null) {
          final userDoc = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid);

          final snapshot = await userDoc.get();

          if (!snapshot.exists) {
            // المستخدم جديد → أنشئ الوثيقة لأول مرة
            await userDoc.set({
              'email': user.email,
              'theme': widget.themeNotifier.isDarkMode ? 'dark' : 'light',
              'favorites': [],
              'createdAt': FieldValue.serverTimestamp(),
            });
          } else {
            // المستخدم موجود → حدث فقط الثيم والإيميل بدون لمس favorites
            await userDoc.set({
              'email': user.email,
              'theme': widget.themeNotifier.isDarkMode ? 'dark' : 'light',
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }

          // ✅ قراءة المفضلات من Firestore بعد تسجيل الدخول
          final favSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          List<dynamic> favorites = [];
          if (favSnapshot.exists) {
            final data = favSnapshot.data();
            if (data != null && data.containsKey('favorites')) {
              favorites = List<String>.from(data['favorites']);

              // 🧠 تخزين المفضلات محليًا لعرضها بصفحة Favorites
              final prefs = await SharedPreferences.getInstance();
              await prefs.setStringList('favorites_list', favorites.cast<String>());
            }
          }

          // قراءة الثيم المحفوظ
          final userDocData = await userDoc.get();

          if (userDocData.exists) {
            final data = userDocData.data();
            if (data != null && data.containsKey('theme')) {
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

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => WelcomePage(
                themeNotifier: widget.themeNotifier,
                userName: credential.user?.email ?? "المستخدم",
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("حدث خطأ أثناء تسجيل الدخول: $e"),
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
    child: const Text(
      "تسجيل الدخول",
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
),
const SizedBox(height: 20),


                        // زر تسجيل الدخول بواسطة Google
OutlinedButton.icon(
  onPressed: () async {
    try {
      if (Theme.of(context).platform == TargetPlatform.android ||
          Theme.of(context).platform == TargetPlatform.iOS) {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
      } else {
        await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      }

      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final userDoc =
            FirebaseFirestore.instance.collection('users').doc(user.uid);

        final snapshot = await userDoc.get();

        if (!snapshot.exists) {
          // 🟢 المستخدم جديد → أنشئ الوثيقة لأول مرة
          await userDoc.set({
            'name': user.displayName ?? 'مستخدم جوجل',
            'email': user.email,
            'photoUrl': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'theme': widget.themeNotifier.isDarkMode ? 'dark' : 'light',
            'favorites': [],
          });
        } else {
          // 🟡 المستخدم موجود → حدث فقط الحقول الأخرى بدون لمس favorites
          await userDoc.set({
            'name': user.displayName ?? 'مستخدم جوجل',
            'email': user.email,
            'photoUrl': user.photoURL,
            'theme': widget.themeNotifier.isDarkMode ? 'dark' : 'light',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        // ✅ قراءة المفضلات من Firestore بعد تسجيل الدخول
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

        // ✅ حفظ المفضلات محليًا حتى تظهر في صفحة المفضلة
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('favorites_list', favorites);

        // يمكنك اختبارها:
        // print('Favorites Loaded & Saved: $favorites');
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WelcomePage(
              themeNotifier: widget.themeNotifier,
              userName: FirebaseAuth.instance.currentUser?.displayName ??
                  'مستخدم جوجل',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تسجيل الدخول بحساب Google: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  },
  icon: Icon(Icons.g_mobiledata, color: primaryColor),
  label: Text(
    "تسجيل الدخول بواسطة Google",
    style: TextStyle(color: primaryColor),
  ),
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: primaryColor),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WelcomePage(
                                    userName: "أيها الزائر",
                                    themeNotifier: widget.themeNotifier,
                                  ),
                                ),
                              );
                            } catch (e) {
                              print(
                                  'حدث خطأ أثناء تسجيل الدخول كضيف: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('فشل تسجيل الدخول كضيف')),
                              );
                            }
                          },
                          icon:
                              Icon(Icons.person_outline, color: primaryColor),
                          label: Text(
                            "الدخول كضيف",
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

                        // إنشاء حساب جديد
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
                            "إنشاء حساب جديد",
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
    );
  }
}
