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
      body: Column(
        children: [
           Expanded(
            child: InfoPage(
              title: "شارع فيصل",
              description: "وصف شارع فيصل...",
              images: ["assets/images/faisal.jpg", "assets/images/faisal2.jpg"],
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
                    destination: latlng.LatLng(32.222243, 35.262778),
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
