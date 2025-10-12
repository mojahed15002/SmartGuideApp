/// ملف مستخرج تلقائيًا من main.dart
/// يحتوي الكلاس: MartyrsRoundaboutPage
library;

import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geolocator/geolocator.dart';
import 'info_page.dart';
import 'map_page.dart';

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
          // ✅ تحديد ما إذا كانت الشاشة عريضة أم ضيقة
          final bool isWide = constraints.maxWidth > 700;

          // ✅ محتوى المعلومات والصور
          final infoContent = Expanded(
            flex: isWide ? 3 : 5,
            child: InfoPage(
              title: "دوار الشهداء",
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

          // ✅ الزر الذي ينقل المستخدم إلى صفحة الخريطة
          final routeButton = Padding(
            padding: const EdgeInsets.all(12.0),
            child: Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 14.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final position = await Geolocator.getCurrentPosition();
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapPage(
                        position: position,
                        destination: latlng.LatLng(32.221119, 35.260817),
                        themeNotifier: widget.themeNotifier,
                        enableTap: false, // 🚫 تعطيل النقر على الخريطة
                        enableLiveTracking: true, // ✅ تتبع حي للموقع
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

          // ✅ التخطيط الديناميكي حسب حجم الشاشة
          if (isWide) {
            // 💻 شاشة عريضة (مثل التابلت)
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
            // 📱 شاشة الهاتف (عمودية)
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
