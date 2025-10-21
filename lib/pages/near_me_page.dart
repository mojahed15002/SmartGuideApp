import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import 'nearby_places_list_page.dart';
import 'custom_drawer.dart';
import 'swipeable_page_route.dart'; // تأكد تضيف هذا بالأعلى

class NearMePage extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  const NearMePage({super.key, required this.themeNotifier});

  // قائمة الفئات
  static const _categories = [
    {'name': 'مطاعم',      'icon': Icons.restaurant,  'type': 'restaurant'},
    {'name': 'كوفيشوبات',  'icon': Icons.local_cafe,  'type': 'cafe'},
    {'name': 'محلات ملابس','icon': Icons.shopping_bag,'type': 'clothes'},
    {'name': 'حلويات',     'icon': Icons.cake,        'type': 'sweets'},
    {'name': 'فنادق',      'icon': Icons.hotel,       'type': 'hotel'},
    {'name': 'أماكن سياحية','icon': Icons.museum,     'type': 'tourism'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الأماكن القريبة مني")),
      drawer: CustomDrawer(themeNotifier: themeNotifier), // ⬅️ هذا السطر المهم
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(12),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: _categories.map((cat) {
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                SwipeablePageRoute(
                    page:NearbyPlacesListPage(
                    category: cat['type'] as String,
                    categoryLabel: cat['name'] as String,
                    themeNotifier: themeNotifier,
                  ),
                ),
              );
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat['icon'] as IconData, size: 44, color: Colors.orange),
                    const SizedBox(height: 10),
                    Text(
                      cat['name'] as String,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
