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
      body: Column(
        children: [
           Expanded(
            child: InfoPage(
              title: "دوار الشهداء",
              description: "دوار الشهداء يُعتبر من المعالم المركزية في مدينة نابلس...",
              images: ["assets/images/martyrs.jpg", "assets/images/martyrs2.jpg"],
              themeNotifier: widget.themeNotifier,
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final position = await Geolocator.getCurrentPosition();
              if (!mounted) return; // الآن هذا الشرط صحيح لأنه داخل State
              Navigator.push(
                // ignore: use_build_context_synchronously
                context,
                MaterialPageRoute(
                  builder: (_) => MapPage(
                    position: position,
                    destination: latlng.LatLng(32.221119, 35.260817),
                    themeNotifier: widget.themeNotifier,
                     enableTap: false, // 🚫 تعطيل النقر على الخريطة + إخفاء التلميح
                     enableLiveTracking: true, // ✅ تتبع حي للموقع
                  ),
                ),
              );
            },
            icon: const Icon(Icons.directions),
            label: const Text("كيف أصل إلى هنا؟"),
          ),
        ],
      ),
    );
  }
}
