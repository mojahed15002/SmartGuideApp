import 'package:flutter/material.dart';
import '../theme_notifier.dart';

class ForgotPasswordPage extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  const ForgotPasswordPage({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('استعادة كلمة المرور')),
      body: const Center(
        child: Text('صفحة استعادة كلمة المرور قيد التطوير'),
      ),
    );
  }
}
