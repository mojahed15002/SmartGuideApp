/// ملف مستخرج تلقائيًا من main.dart
/// يحتوي الكلاس: SofianStreetPage
library;

import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geolocator/geolocator.dart';
import 'info_page.dart';
import 'map_page.dart';

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
          // ✅ التكيّف حسب عرض الشاشة
          final bool isWide = constraints.maxWidth > 700;

          // ✅ محتوى الصفحة: العنوان + الوصف + الصور
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

          // ✅ الزر الذي يفتح صفحة الخريطة
          final routeButton = Padding(
            padding: const EdgeInsets.all(12.0),
            child: Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 14.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final position = await Geolocator.getCurrentPosition();
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapPage(
                        position: position,
                        destination: latlng.LatLng(32.222376, 35.260532),
                        themeNotifier: widget.themeNotifier,
                        enableTap: false, // 🚫 تعطيل النقر على الخريطة
                        enableLiveTracking: true, // ✅ تتبع الموقع لحظيًا
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
          );

          // ✅ توزيع ديناميكي للتخطيط
          if (isWide) {
            // 💻 الوضع الأفقي (مثل التابلت)
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
            // 📱 الوضع العمودي (الموبايل)
            return Column(
              children: [
                infoContent,
                routeButton,
              ],
            );
          }
        },
      ),
    );
  }
}
