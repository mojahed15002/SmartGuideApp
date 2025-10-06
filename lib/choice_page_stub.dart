import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme_notifier.dart';
import 'choice_page_redirect.dart';

class ChoicePageStub extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  const ChoicePageStub({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cards = [
_HubCard(
  title: 'استكشف الأماكن',
  icon: Icons.travel_explore,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChoicePageRedirect(themeNotifier: themeNotifier),
      ),
    );
  },
),


      _HubCard(
        title: 'القريبة مني',
        icon: Icons.my_location,
        onTap: () => Navigator.pushNamed(context, '/nearby'),
      ),
      _HubCard(
        title: 'المفضلة',
        icon: Icons.favorite,
        onTap: () => Navigator.pushNamed(context, '/favorites'),
      ),
      _HubCard(
        title: 'الإعدادات',
        icon: Icons.settings,
        onTap: () => Navigator.pushNamed(context, '/settings'),
      ),
      _HubCard(
        title: 'تسجيل الخروج',
        icon: Icons.logout,
        onTap: () async {
          await FirebaseAuth.instance.signOut();
          if (context.mounted) Navigator.popUntil(context, (r) => r.isFirst);
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('المرشد السياحي الذكي'),
        actions: [
          IconButton(
            tooltip: 'تبديل الثيم',
            onPressed: () => themeNotifier.toggleTheme(),
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: cards.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.1),
        itemBuilder: (_, i) => cards[i],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _HubCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          boxShadow: kElevationToShadow[2],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 38),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class ChoicePage extends ChoicePageStub {
  const ChoicePage({super.key, required super.themeNotifier});
}
