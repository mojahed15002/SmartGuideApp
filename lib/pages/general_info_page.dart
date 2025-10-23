import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_notifier.dart';
import 'city_places_page.dart';
import 'custom_drawer.dart';
import 'swipeable_page_route.dart';
import '../l10n/gen/app_localizations.dart'; // ✅ الترجمة

class GeneralInfoPage extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  const GeneralInfoPage({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isArabic = loc.localeName == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.citiesTitle),
        ),
        drawer: CustomDrawer(themeNotifier: themeNotifier),

        // ✅ جلب المدن من Firestore
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('cities').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('⚠️ حدث خطأ أثناء تحميل البيانات'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text(loc.noResults));
            }

            final cities = snapshot.data!.docs;

            return ListView.builder(
              itemCount: cities.length,
              itemBuilder: (context, index) {
                final cityData = cities[index].data() as Map<String, dynamic>;

                // ✅ نعرض حسب اللغة
                final cityName = isArabic
                    ? (cityData['city_ar'] ?? '')
                    : (cityData['city_en'] ?? '');

                return ListTile(
                  title: Text(cityName),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      color: Colors.orange),
                  onTap: () {
                    if (ModalRoute.of(context)?.isCurrent ?? true) {
                      Navigator.pushReplacement(
                        context,
                        SwipeablePageRoute(
                          page: CityPlacesPage(
                            cityName: cityName,
                            themeNotifier: themeNotifier,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
