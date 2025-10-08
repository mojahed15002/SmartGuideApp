import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_notifier.dart';
import '../choice_page_stub.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WelcomePage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  final String? userName; 

  const WelcomePage({
    super.key,
    required this.themeNotifier,
    this.userName,
  });

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  User? user;
Future<void> _loadUserTheme() async {
  try {
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data.containsKey('theme')) {
          final savedTheme = data['theme'];
          if (savedTheme == 'dark' && !widget.themeNotifier.isDarkMode) {
            widget.themeNotifier.setTheme(true);
          } else if (savedTheme == 'light' && widget.themeNotifier.isDarkMode) {
            widget.themeNotifier.setTheme(false);
          }
        }
      }
    }
  } catch (e) {
    print("⚠️ خطأ أثناء تحميل الثيم من Firestore: $e");
  }
}

  @override
  void initState() {
    
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _loadUserTheme();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مرحباً بك'),
       actions: [
  // زر التبديل بين النمطين
  IconButton(
    icon: Icon(
      widget.themeNotifier.isDarkMode
          ? Icons.wb_sunny
          : Icons.nightlight_round,
      color: widget.themeNotifier.isDarkMode
          ? Colors.orange
          : Colors.deepOrange,
    ),
   onPressed: () async {
  // تبديل الثيم محلياً
  widget.themeNotifier.toggleTheme();

  // تحديث الحالة الجديدة في Firestore
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
            {
              'isDarkMode': widget.themeNotifier.isDarkMode ? 'dark' : 'light',
            },
            SetOptions(merge: true),
          );
    } catch (e) {
      print("خطأ أثناء تحديث الثيم في Firestore: $e");
    }
  }
},

  ),

  const SizedBox(height: 20),

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
                'مرحباً ${widget.userName ?? user?.displayName ?? user?.email ?? "بالزائر"} 👋',
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
