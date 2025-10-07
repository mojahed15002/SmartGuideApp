import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_notifier.dart';
import '../choice_page_stub.dart';

class WelcomePage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  final String? userName; // ✅ تأكدنا أن userName معرف هنا

  const WelcomePage({
    Key? key,
    required this.themeNotifier,
    this.userName,
  }) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مرحباً بك'),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              widget.themeNotifier.toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_city,
                  size: 100, color: Colors.orange.shade600),
              const SizedBox(height: 20),
              Text(
                'مرحباً ${widget.userName ?? user?.displayName ?? user?.email ?? "بالزائر"} 👋', // ✅ تم إصلاحها هنا
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'يسعدنا انضمامك إلى تطبيق Smart City Guide!',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // ✅ زر الانتقال إلى ChoicePage
              ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text('استكشف المدينة'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  backgroundColor: Colors.deepOrange,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChoicePageStub(
                        themeNotifier: widget.themeNotifier,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              
            ],
          ),
        ),
      ),
    );
  }
}
