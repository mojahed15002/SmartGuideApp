import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import 'nearby_places_list_page.dart';
import 'custom_drawer.dart';
import 'swipeable_page_route.dart'; // تأكد تضيف هذا بالأعلى

// ✅ إضافة ملف الترجمة
import '../l10n/gen/app_localizations.dart';

class NearMePage extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  const NearMePage({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    // ✅ تحديد اللغة والاتجاه
    final isArabic = AppLocalizations.of(context)!.localeName == 'ar';
    final direction = isArabic ? TextDirection.rtl : TextDirection.ltr;

    // ✅ قائمة الفئات مع الترجمة
    final _categories = [
      {
        'name': AppLocalizations.of(context)!.restaurants,
        'icon': Icons.restaurant,
        'type': 'restaurant',
      },
      {
        'name': AppLocalizations.of(context)!.cafes,
        'icon': Icons.local_cafe,
        'type': 'cafe',
      },
      {
        'name': AppLocalizations.of(context)!.clothingStores,
        'icon': Icons.shopping_bag,
        'type': 'clothes',
      },
      {
        'name': AppLocalizations.of(context)!.sweets,
        'icon': Icons.cake,
        'type': 'sweets',
      },
      {
        'name': AppLocalizations.of(context)!.hotels,
        'icon': Icons.hotel,
        'type': 'hotel',
      },
      {
        'name': AppLocalizations.of(context)!.touristPlaces,
        'icon': Icons.museum,
        'type': 'tourism',
      },
    ];

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.nearMe)),
        drawer: CustomDrawer(
          themeNotifier: themeNotifier,
        ), // ⬅️ هذا السطر المهم
        body: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(12),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: _categories.map((cat) {
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (ModalRoute.of(context)?.isCurrent ?? true) {
                  Navigator.pushReplacement(
                    context,
                    SwipeablePageRoute(
                      page: NearbyPlacesListPage(
                        category: cat['type'] as String,
                        categoryLabel: cat['name'] as String,
                        themeNotifier: themeNotifier,
                      ),
                    ),
                  );
                }
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
                      Icon(
                        cat['icon'] as IconData,
                        size: 44,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        cat['name'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
