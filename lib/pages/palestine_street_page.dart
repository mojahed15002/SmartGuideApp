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
      body: Column(
        children: [ 
          Expanded(
            child: InfoPage(
              title: "شارع فلسطين",
              description: "شارع فلسطين يعتبر من الشوارع الحيوية...",
              images:  ["", ""],
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
                    destination: latlng.LatLng(32.221378, 35.259687),
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

// صفحة المدن
//
