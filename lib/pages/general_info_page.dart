/// ملف مستخرج تلقائيًا من main.dart
/// يحتوي الكلاس: GeneralInfoPage
library;

import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import 'city_places_page.dart';
import 'custom_drawer.dart';
import 'swipeable_page_route.dart'; // تأكد تضيف هذا بالأعلى

class GeneralInfoPage extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  const GeneralInfoPage({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    final cities = ["نابلس", "رام الله", "جنين"];

    return Scaffold(
      appBar: AppBar(
        title: const Text("المدن"),
        actions: [
           // 🔥 زر التبديل الجديد
        ],
      ),
      drawer: CustomDrawer(themeNotifier: themeNotifier), // ⬅️ هذا السطر المهم
      body: ListView(
        children: cities.map((city) {
          return ListTile(
            title: Text(city),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.orange),
            onTap: () {
              Navigator.push(
                context,
                SwipeablePageRoute(
                  page: CityPlacesPage(cityName: city, themeNotifier: themeNotifier),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

// أماكن داخل كل مدينة
//
