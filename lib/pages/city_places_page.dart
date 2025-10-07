/// ملف مستخرج تلقائيًا من main.dart
/// يحتوي الكلاس: CityPlacesPage
library;

import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import 'place_details_page.dart';

class CityPlacesPage extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  final String cityName;

  const CityPlacesPage({
    super.key,
    required this.cityName,
    required this.themeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    // 🔹 الماب موجود جوّا build (مع إضافات heroTag لكل مكان)
    final Map<String, List<Map<String, dynamic>>> cityPlacesPages = {
      "نابلس": [
        {
          "title": "البلدة القديمة",
          "images": ["assets/images/oldcity.jpg", "assets/images/oldcity2.jpg"],
          "hero": "nablus_oldcity",
          "page": PlaceDetailsPage(
            title: "البلدة القديمة",
            cityName: "نابلس",
            images: ["assets/images/oldcity.jpg", "assets/images/oldcity2.jpg"],
            url: "https://example.com/oldcity",
            themeNotifier: themeNotifier,
            heroTag: "nablus_oldcity",
          ),
        },
        {
          "title": "جبل جرزيم",
          "images": ["assets/images/gerizim.jpg", "assets/images/gerizim2.jpg"],
          "hero": "nablus_gerizim",
          "page": PlaceDetailsPage(
            title: "جبل جرزيم",
            cityName: "نابلس",
            images: ["assets/images/gerizim.jpg", "assets/images/gerizim2.jpg"],
            url: "https://example.com/gerizim",
            themeNotifier: themeNotifier,
            heroTag: "nablus_gerizim",
          ),
        },
      ],
      "رام الله": [
        {
          "title": "دوار المنارة",
          "images": ["assets/images/manara.jpg", "assets/images/manara2.jpg"],
          "hero": "ramallah_manara",
          "page": PlaceDetailsPage(
            title: "دوار المنارة",
            cityName: "رام الله",
            images: ["assets/images/manara.jpg", "assets/images/manara2.jpg"],
            url: "https://example.com/manara",
            themeNotifier: themeNotifier,
            heroTag: "ramallah_manara",
          ),
        },
        {
          "title": "متحف ياسر عرفات",
          "images": [
            "assets/images/arafat.jpg",
            "assets/images/arafat2.jpg",
            "assets/images/arafat3.jpg"
          ],
          "hero": "ramallah_arafat",
          "page": PlaceDetailsPage(
            title: "متحف ياسر عرفات",
            cityName: "رام الله",
            images: [
              "assets/images/arafat.jpg",
              "assets/images/arafat2.jpg",
              "assets/images/arafat3.jpg"
            ],
            url: "https://example.com/arafat",
            themeNotifier: themeNotifier,
            heroTag: "ramallah_arafat",
          ),
        },
      ],
      "جنين": [
        {
          "title": "كنيسة برقين",
          "images": ["assets/images/burqin.jpg", "assets/images/burqin2.jpg"],
          "hero": "jenin_burqin",
          "page": PlaceDetailsPage(
            title: "كنيسة برقين",
            cityName: "جنين",
            images: ["assets/images/burqin.jpg", "assets/images/burqin2.jpg"],
            url: "https://example.com/burqin",
            themeNotifier: themeNotifier,
            heroTag: "jenin_burqin",
          ),
        },
        {
          "title": "سهل مرج ابن عامر",
          "images": ["assets/images/marj.jpg", "assets/images/marj2.jpg"],
          "hero": "jenin_marj",
          "page": PlaceDetailsPage(
            title: "سهل مرج ابن عامر",
            cityName: "جنين",
            images: ["assets/images/marj.jpg", "assets/images/marj2.jpg"],
            url: "https://example.com/marj",
            themeNotifier: themeNotifier,
            heroTag: "jenin_marj",
          ),
        },
      ],
    };

    final places = cityPlacesPages[cityName] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text("أماكن في $cityName"),
        actions: [
           // ✅ زر الوضع الليلي
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: places.length <= 3
            // ✅ عرض كقائمة (كروت بعرض الشاشة)
            ? ListView.builder(
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final placeData = places[index];
                  final String title = placeData["title"];
                  final List<String> images = List<String>.from(placeData["images"]);
                  final String heroTag = placeData["hero"] ?? "${cityName}_$title";

                  // staggered animation for each item
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 300 + index * 120),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => placeData["page"]),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: Hero(
                                tag: heroTag,
                                child: Image.asset(
                                  images.first,
                                  fit: BoxFit.cover,
                                  height: 200,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
            // ✅ عرض كـ Grid
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // عمودين
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3 / 4, // نسبة العرض للارتفاع
                ),
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final placeData = places[index];
                  final String title = placeData["title"];
                  final List<String> images = List<String>.from(placeData["images"]);
                  final String heroTag = placeData["hero"] ?? "${cityName}_$title";

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 300 + index * 100),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => placeData["page"]),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: Hero(
                                  tag: heroTag,
                                  child: Image.asset(
                                    images.first, // 👈 أول صورة فقط للعرض
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}


// صفحة المعلومات العامة (Carousel)
//
