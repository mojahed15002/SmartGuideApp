import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_notifier.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class RegisterPage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const RegisterPage({super.key, required this.themeNotifier});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _dob;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _birthController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// نافذة اختيار تاريخ الميلاد
 Future<void> _pickDob() async {
  final now = DateTime.now();
  final initial = DateTime(now.year - 20, now.month, now.day);
  final first = DateTime(now.year - 100);
  final last = DateTime(now.year - 10);

  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first,
    lastDate: last,
    builder: (context, child) {
      // نضيف الـ Localizations محليًا لتفادي خطأ No MaterialLocalizations
      return Localizations(
        locale: const Locale('en'),
        delegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // 👇 بدل TextDirection.rtl استخدم اتجاه السياق (يحل الخطأ)
        child: Directionality(
          textDirection: Directionality.of(context),
          child: child ?? const SizedBox.shrink(),
        ),
      );
    },
  );

  if (picked != null && mounted) {
    setState(() {
      _dob = picked;
      _birthController.text = DateFormat('yyyy-MM-dd').format(picked);
    });
  }
}

/// التحقق من الحقول قبل التسجيل
  String? _validateInputs() {
    final u = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    final phone = _phoneController.text.trim();

    if (u.isEmpty) return 'الرجاء إدخال اسم مستخدم';
    if (email.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) return 'البريد غير صحيح';
    if (pass.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    if (phone.isEmpty) return 'الرجاء إدخال رقم الهاتف';
    if (_dob == null) return 'الرجاء اختيار تاريخ الميلاد';
    return null;
  }

  /// عملية إنشاء الحساب وتخزين البيانات في Firebase
  Future<void> _register() async {
    final err = _validateInputs();
    if (err != null) {
      _showError(err);
      return;
    }

    setState(() => _loading = true);
    try {
      final email = _emailController.text.trim();
      final pass = _passwordController.text;
      final username = _usernameController.text.trim();
      final phone = _phoneController.text.trim();

      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);
      final uid = cred.user?.uid;
      if (uid == null) throw Exception('فشل الحصول على uid للمستخدم الجديد');

      // حفظ البيانات في Firestore
      final usersRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final dobIso = _dob?.toIso8601String();

      await usersRef.set({
        'username': username,
        'email': email,
        'phone': phone,
        'dob': dobIso,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'خطأ أثناء التسجيل');
    } catch (e) {
      _showError('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, textAlign: TextAlign.center)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إنشاء حساب جديد"),
        actions: [],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "إنشاء حساب",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // username
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: "اسم المستخدم",
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "البريد الإلكتروني",
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // password
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: "كلمة المرور",
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure
                            ? Icons.visibility
                            : Icons.visibility_off),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // phone
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "رقم الهاتف",
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                      hintText: "+9705xxxxxxxx",
                    ),
                  ),
                  const SizedBox(height: 10),

                  // dob (تاريخ الميلاد)
                  TextField(
                    controller: _birthController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'تاريخ الميلاد',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: _pickDob,
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: _loading ? null : _register,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text("إنشاء حساب"),
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
