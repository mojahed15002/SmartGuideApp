import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'register_page.dart';
import 'theme_notifier.dart';

class SignInPanel extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const SignInPanel({super.key, required this.themeNotifier});

  @override
  State<SignInPanel> createState() => _SignInPanelState();
}

class _SignInPanelState extends State<SignInPanel> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Color _primaryColor(BuildContext c) => Theme.of(c).colorScheme.primary;
  Color _onPrimaryColor(BuildContext c) => Theme.of(c).colorScheme.onPrimary;
  Color _surfaceColor(BuildContext c) => Theme.of(c).colorScheme.surface;

  Future<void> _signInWithEmail() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final email = _email.text.trim();
      final pass = _password.text;
      if (email.isEmpty || pass.isEmpty) {
        _toast('الرجاء إدخال البريد وكلمة المرور');
        return;
      }
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
      // StreamBuilder في WelcomePage يتعامل مع الإخفاء/التوجيه بعد تسجيل الدخول.
    } on FirebaseAuthException catch (e) {
      _toast(_mapAuthError(e));
    } catch (e) {
      _toast('خطأ غير متوقع: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
        if (gUser == null) {
          if (mounted) setState(() => _loading = false);
          return;
        }
        final gAuth = await gUser.authentication;
        final cred = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken,
          idToken: gAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(cred);
      }
    } on FirebaseAuthException catch (e) {
      _toast(_mapAuthError(e));
    } catch (e) {
      _toast('تعذّر تسجيل الدخول عبر Google: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح.';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب.';
      case 'user-not-found':
        return 'لا يوجد مستخدم بهذا البريد.';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة.';
      case 'account-exists-with-different-credential':
        return 'هذا البريد مرتبط بمزوّد آخر.';
      case 'operation-not-allowed':
        return 'طريقة المصادقة غير مفعلة في Firebase.';
      default:
        return e.message ?? 'خطأ في المصادقة.';
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final primary = _primaryColor(context);
    final onPrimary = _onPrimaryColor(context);
    final surface = _surfaceColor(context);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header row: title + theme toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('تسجيل الدخول', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      tooltip: 'تبديل الثيم',
                      onPressed: () => widget.themeNotifier.toggleTheme(),
                      icon: Icon(Theme.of(context).brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Inputs
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: const Icon(Icons.email),
                    filled: true,
                    fillColor: surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock),
                    filled: true,
                    fillColor: surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Primary sign-in button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _loading ? null : _signInWithEmail,
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('تسجيل الدخول'),
                  ),
                ),

                const SizedBox(height: 10),

                // Google sign in (outlined with logo space)
                SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: primary.withOpacity(0.9)),
                    ),
                    onPressed: _loading ? null : _signInWithGoogle,
                    icon: Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                      width: 20, height: 20,
                      errorBuilder: (_, __, ___) => const Icon(Icons.login),
                    ),
                    label: const Text('تسجيل الدخول بواسطة Google'),
                  ),
                ),

                const SizedBox(height: 8),

                // Create account link
                Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('مستخدم جديد؟'),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RegisterPage(themeNotifier: widget.themeNotifier),
                                  ),
                                );
                              },
                        child: const Text('إنشاء حساب'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
