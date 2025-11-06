import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_notifier.dart';
import 'city_places_page.dart';

import '../l10n/gen/app_localizations.dart'; // ✅ الترجمة

class GeneralInfoPage extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  const GeneralInfoPage({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isArabic = loc.localeName == 'ar';
    final direction = isArabic ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.citiesTitle)),
       

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

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: cities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final cityData = cities[index].data() as Map<String, dynamic>;
                final cityName = isArabic
                    ? (cityData['city_ar'] ?? '')
                    : (cityData['city_en'] ?? '');

                final imagePath = cityData['image'] ??
                    'https://images.unsplash.com/photo-1528909514045-2fa4ac7a08ba?auto=format&fit=crop&w=1200&q=60';

                // ✨ إضافة تأثير الظهور لكل كارد
                return TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(milliseconds: 600 + (index * 100)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: 0.95 + (value * 0.05),
                        child: child,
                      ),
                    );
                  },
                  child: _CityCard(
                    cityName: cityName,
                    imagePath: imagePath,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CityPlacesPage(
                            cityName: cityName,
                            themeNotifier: themeNotifier,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// 🔹 كلاس تصميم الكارد الذكي (يدعم صور الإنترنت و الـ assets)
class _CityCard extends StatelessWidget {
  final String cityName;
  final String imagePath;
  final VoidCallback onTap;

  const _CityCard({
    required this.cityName,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget imageWidget;

    // ✅ نتحقق إذا الصورة من الإنترنت أو من ملفات المشروع
    if (imagePath.startsWith('http')) {
      imageWidget = Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade300,
          alignment: Alignment.center,
          child: const Icon(Icons.location_city, size: 64),
        ),
      );
    } else {
      imageWidget = Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade300,
          alignment: Alignment.center,
          child: const Icon(Icons.location_city, size: 64),
        ),
      );
    }

    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: radius),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 🖼️ الصورة (ذكية)
              imageWidget,

              // 🎨 تدرج غامق لقراءة النص بوضوح
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // 📍 اسم المدينة
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                  child: Text(
                    cityName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: [
                        Shadow(blurRadius: 6, color: Colors.black54),
                      ],
                    ),
                  ),
                ),
              ),

              // ☁️ لمسة ديكورية في الأعلى
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
