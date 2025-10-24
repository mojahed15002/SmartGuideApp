/// ملف مستخرج تلقائيًا من main.dart
/// يحتوي الكلاس: MartyrsRoundaboutPage
library;

import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geolocator/geolocator.dart';
import 'info_page.dart';
import 'map_page.dart';
import 'swipeable_page_route.dart';

class MartyrsRoundaboutPage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const MartyrsRoundaboutPage({super.key, required this.themeNotifier});

  @override
  State<MartyrsRoundaboutPage> createState() => _MartyrsRoundaboutPageState();
}

class _MartyrsRoundaboutPageState extends State<MartyrsRoundaboutPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 700;

          // ✅ محتوى الصفحة (العنوان + الوصف + الصور)
          final infoContent = Expanded(
            flex: isWide ? 3 : 5,
            child: InfoPage(
              title: "دوّار الشهداء",
              description:
                  "دوّار الشهداء يُعد من أهم المعالم في مدينة نابلس، "
                  "ويقع في قلب المدينة القديمة. تحيط به العديد من المحلات والمطاعم "
                  "والمباني التاريخية، ويُعتبر نقطة التقاء رئيسية للسكان والزوار.",
              images: [
                "assets/images/martyrs.jpg",
                "assets/images/martyrs2.jpg",
              ],
              themeNotifier: widget.themeNotifier,
            ),
          );

          // ✅ زر "كيف أصل إلى هنا؟" بتصميم متجاوب
          final routeButton = SafeArea(
            minimum: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
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
                        SwipeablePageRoute(
                          page: MapPage(
                            position: position,
                            destination: latlng.LatLng(32.221119, 35.260817),
                            themeNotifier: widget.themeNotifier,
                            enableTap: false, // 🚫 تعطيل النقر على الخريطة
                            enableLiveTracking: true, // ✅ تتبع الموقع الحي
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

          // ✅ التوزيع الديناميكي حسب نوع الشاشة
          if (isWide) {
            // 💻 الوضع الأفقي (شاشة عريضة)
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
            // 📱 الوضع العمودي (الهاتف)
            return Stack(
              children: [
                Column(
                  children: [
                    infoContent,
                    const SizedBox(height: 80), // مساحة تحت المحتوى
                  ],
                ),
                Positioned(bottom: 0, left: 0, right: 0, child: routeButton),
              ],
            );
          }
        },
      ),
    );
  }
}
