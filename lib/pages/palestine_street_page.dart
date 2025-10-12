/// ملف مستخرج تلقائيًا من main.dart
/// يحتوي الكلاس: PalestineStreetPage
library;

import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geolocator/geolocator.dart';
import 'info_page.dart';
import 'map_page.dart';

class PalestineStreetPage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const PalestineStreetPage({super.key, required this.themeNotifier});

  @override
  State<PalestineStreetPage> createState() => _PalestineStreetPageState();
}

class _PalestineStreetPageState extends State<PalestineStreetPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // ✅ تحديد ما إذا كانت الشاشة عريضة أم لا
          final bool isWide = constraints.maxWidth > 700;

          // ✅ محتوى الصفحة (العنوان، النص، الصور)
          final infoContent = Expanded(
            flex: isWide ? 3 : 5,
            child: InfoPage(
              title: "شارع فلسطين",
              description:
                  "يُعد شارع فلسطين من أهم الشوارع الحيوية في مدينة نابلس، "
                  "ويتميز بامتداده الواسع وموقعه الاستراتيجي الذي يربط بين عدة مناطق رئيسية. "
                  "يضم العديد من المراكز التجارية والمباني الحديثة.",
              images: [
                "assets/images/palestine.jpg",
                "assets/images/palestine2.jpg",
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
                        destination: latlng.LatLng(32.221378, 35.259687),
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
          );

          // ✅ التوزيع الديناميكي حسب عرض الجهاز
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
