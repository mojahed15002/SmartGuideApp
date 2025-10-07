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
      body: Column(
        children: [
          Expanded(
            child: InfoPage(
              title: "شارع الأكاديمية",
              description: "وصف شارع الأكاديمية...",
              images:  ["assets/images/academy.jpg", "assets/images/academy2.jpg"],
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
                    destination: latlng.LatLng(32.226938, 35.222279),
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
