import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_notifier.dart';

class ForgotPasswordPage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const ForgotPasswordPage({super.key, required this.themeNotifier});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

Future<void> resetPassword() async {
  final email = emailController.text.trim();

  if (email.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('يرجى إدخال البريد الإلكتروني'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() {
    isLoading = true;
  });

  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ تم إرسال رابط إعادة التعيين إلى البريد الإلكتروني'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context); // يرجع المستخدم لصفحة تسجيل الدخول بعد الإرسال
  } on FirebaseAuthException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('حدث خطأ: ${e.message}'),
        backgroundColor: Colors.deepOrange,
      ),
    );
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.themeNotifier.isDarkMode;


    return Scaffold(
      appBar: AppBar(
        title: const Text('استعادة كلمة المرور'),
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'أدخل بريدك الإلكتروني لإعادة تعيين كلمة المرور',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange, // 🔸 نفس اللون الأصلي
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'إرسال رابط إعادة التعيين',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
