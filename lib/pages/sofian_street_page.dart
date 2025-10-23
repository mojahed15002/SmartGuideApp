/// ملف مستخرج تلقائيًا من main.dart
/// يحتوي الكلاس: SofianStreetPage
library;

import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geolocator/geolocator.dart';
import 'info_page.dart';
import 'map_page.dart';
import 'swipeable_page_route.dart'; // تأكد تضيفه بالأعلى
class SofianStreetPage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const SofianStreetPage({super.key, required this.themeNotifier});

  @override
  State<SofianStreetPage> createState() => _SofianStreetPageState();
}

class _SofianStreetPageState extends State<SofianStreetPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 700;

          // ✅ محتوى الصفحة
          final infoContent = Expanded(
            flex: isWide ? 3 : 5,
            child: InfoPage(
              title: "شارع سفيان",
              description:
                  "شارع سفيان من الشوارع الحيوية والمشهورة في المدينة، "
                  "يحتوي على العديد من المحلات التجارية والمطاعم، "
                  "ويُعد وجهة مميزة للزوار بفضل قربه من المرافق الرئيسية.",
              images: [
                "assets/images/sofian.jpg",
                "assets/images/sofian2.jpg",
              ],
              themeNotifier: widget.themeNotifier,
            ),
          );

          // ✅ الزر (مع SafeArea لتجنّب تغطيته من أزرار النظام)
          final routeButton = SafeArea(
            minimum: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                    if (ModalRoute.of(context)?.isCurrent ?? true) {
                    Navigator.pushReplacement(
                      context,
                     SwipeablePageRoute(
                          page: MapPage(
                          position: position,
                          destination: latlng.LatLng(32.222376, 35.260532),
                          themeNotifier: widget.themeNotifier,
                          enableTap: false, // 🚫 تعطيل النقر على الخريطة
                          enableLiveTracking: true, // ✅ تتبع حي
                        ),
                      ),
                    );
                    }
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

          // ✅ توزيع ديناميكي حسب حجم الشاشة
          if (isWide) {
            // 💻 الوضع الأفقي (تابلت أو شاشة واسعة)
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
            // 📱 الوضع العمودي (موبايل)
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
