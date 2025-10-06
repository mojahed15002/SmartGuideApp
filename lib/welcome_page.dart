import 'package:flutter/material.dart';
import 'theme_toggle_button.dart';
import 'theme_notifier.dart';
import 'choice_page_stub.dart';
import 'sign_in_panel.dart';

class WelcomePage extends StatelessWidget {
  final ThemeNotifier themeNotifier;

  const WelcomePage({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          ThemeToggleButton(themeNotifier: themeNotifier), // 🔥 زر التبديل الجديد
        ],
      ),

      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "مرحباً بك في مرشدك السياحي الخاص👋",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            SignInPanel(themeNotifier: themeNotifier),
            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChoicePage(themeNotifier: themeNotifier)),
                );
              },
              child: const Text("انطلق😎"),
            ),
          ],
        ),
      ),
    );
  }
}
