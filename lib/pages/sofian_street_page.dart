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
      body: Column(
        children: [
           Expanded(
            child: InfoPage(
              title: "شارع سفيان",
              description: "شارع سفيان يعتبر من الشوارع الحيوية...",
              images: ["assets/images/sofian.jpg", "assets/images/sofian2.jpg"],
              themeNotifier: widget.themeNotifier,
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final position = await Geolocator.getCurrentPosition();
              if (!mounted) return; 
              Navigator.push(
                // ignore: use_build_context_synchronously
                context,
                MaterialPageRoute(
                  builder: (_) => MapPage(
                    position: position,
                    destination: latlng.LatLng(32.222376, 35.260532),
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
