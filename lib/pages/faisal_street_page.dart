/// ملف مستخرج تلقائيًا من main.dart
/// يحتوي الكلاس: FaisalStreetPage
library;

import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geolocator/geolocator.dart';
import 'info_page.dart';
import 'map_page.dart';

class FaisalStreetPage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const FaisalStreetPage({super.key, required this.themeNotifier});

  @override
  State<FaisalStreetPage> createState() => _FaisalStreetPageState();
}

class _FaisalStreetPageState extends State<FaisalStreetPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // ✅ تحديد نوع الشاشة (عريضة أو ضيقة)
          final bool isWide = constraints.maxWidth > 700;

          // ✅ محتوى الصفحة (المعلومات + الصور)
          final infoContent = Expanded(
            flex: isWide ? 3 : 5,
            child: InfoPage(
              title: "شارع فيصل",
              description:
                  "يُعد شارع فيصل من أبرز الشوارع التجارية في مدينة نابلس، "
                  "ويضم مجموعة كبيرة من المحلات والمطاعم والمقاهي. "
                  "يتميز بالحركة الدائمة ويُعتبر مركزًا للتسوق والنشاط الاقتصادي.",
              images: [
                "assets/images/faisal.jpg",
                "assets/images/faisal2.jpg",
              ],
              themeNotifier: widget.themeNotifier,
            ),
          );

          // ✅ زر الانتقال إلى الخريطة
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
                        destination: latlng.LatLng(32.222243, 35.262778),
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

          // ✅ التخطيط الديناميكي حسب نوع الشاشة
          if (isWide) {
            // 💻 الوضع الأفقي (تابلت أو شاشة كبيرة)
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
