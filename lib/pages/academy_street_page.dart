/// ملف مستخرج تلقائيًا من main.dart
/// يحتوي الكلاس: AcademyStreetPage
library;

import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geolocator/geolocator.dart';
import 'info_page.dart';
import 'map_page.dart';
class AcademyStreetPage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const AcademyStreetPage({super.key, required this.themeNotifier});

  @override
  State<AcademyStreetPage> createState() => _AcademyStreetPageState();
}

class _AcademyStreetPageState extends State<AcademyStreetPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 700;

          // ✅ محتوى الصفحة (المعلومات + الصور)
          final infoContent = Expanded(
            flex: isWide ? 3 : 5,
            child: InfoPage(
              title: "شارع الأكاديمية",
              description:
                  "شارع الأكاديمية من أكثر الشوارع الحيوية في المدينة، "
                  "ويضم العديد من المرافق الأكاديمية والخدمات المتنوعة. "
                  "يُعتبر وجهة رئيسية للطلاب والزوار.",
              images: [
                "assets/images/academy.jpg",
                "assets/images/academy2.jpg",
              ],
              themeNotifier: widget.themeNotifier,
            ),
          );

          // ✅ الزر (مع استخدام SafeArea للحماية من الحواف السفلية)
          final routeButton = SafeArea(
            minimum: const EdgeInsets.only(bottom: 16.0), // مسافة من الحافة السفلية
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 24.0 : 20.0,
                      vertical: isWide ? 18.0 : 14.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final position = await Geolocator.getCurrentPosition();
                    if (!mounted) return;
                  
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MapPage(
                          position: position,
                          destination: latlng.LatLng(32.226938, 35.222279),
                          themeNotifier: widget.themeNotifier,
                          enableTap: false,
                          enableLiveTracking: true,
                        ),
                      ),
                    );
                  
                  },
                  icon: const Icon(Icons.directions, color: Colors.white),
                  label: const Text(
                    "كيف أصل إلى هنا؟",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          );

          // ✅ تخطيط ديناميكي حسب حجم الشاشة
          if (isWide) {
            // 📱 عرضي (صف جانبي)
            return Row(
              children: [
                infoContent,
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.grey[100],
                    child: Center(child: routeButton),
                  ),
                ),
              ],
            );
          } else {
            // 📱 عمودي (زر ثابت بأسفل الشاشة لكن مع مسافة آمنة)
            return Stack(
              children: [
                Column(
                  children: [
                    infoContent,
                    const SizedBox(height: 80), // مساحة تحت للمحتوى
                  ],
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: routeButton,
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
