import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlng;
import '../theme_notifier.dart';
import 'map_page.dart';

class NearbyPlacesListPage extends StatefulWidget {
  final String category; // مثل: restaurant, cafe ...
  final String categoryLabel; // النص المعروض: مطاعم، كوفيشوبات...
  final ThemeNotifier themeNotifier;

  const NearbyPlacesListPage({
    super.key,
    required this.category,
    required this.categoryLabel,
    required this.themeNotifier,
  });

  @override
  State<NearbyPlacesListPage> createState() => _NearbyPlacesListPageState();
}

class _NearbyPlacesListPageState extends State<NearbyPlacesListPage> {
  final _distance = const latlng.Distance();
  Position? _pos;
  bool _loading = true;
  String? _error;
  List<_PlaceItem> _items = [];

  static const double _radiusKm = 3.0; // فلترة داخل 3 كم (غيره كما تشاء)

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // طلب صلاحية الموقع + جلب الموقع الحالي
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() => _error = "يرجى منح إذن الوصول للموقع.");
        return;
      }

      _pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // جلب أماكن الفئة من Firestore
      final snap = await FirebaseFirestore.instance
          .collection('places')
          .where('category', isEqualTo: widget.category)
          .limit(150) // مؤقتًا؛ لاحقًا نضيف GeoQuery
          .get();

      final userLL = latlng.LatLng(_pos!.latitude, _pos!.longitude);

      final temp = <_PlaceItem>[];
      for (final d in snap.docs) {
        final data = d.data();
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        final name = (data['name'] ?? 'مكان بدون اسم').toString();

        if (lat == null || lng == null) continue;

        final pll = latlng.LatLng(lat, lng);
        final meters = _distance(userLL, pll);
        final km = meters / 1000.0;

        if (km <= _radiusKm) {
          temp.add(
            _PlaceItem(id: d.id, name: name, latLng: pll, meters: meters),
          );
        }
      }

      temp.sort((a, b) => a.meters.compareTo(b.meters));

      setState(() {
        _items = temp;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "تعذر تحميل الأماكن: $e";
        _loading = false;
      });
    }
  }

  String _fmtDistance(double meters) {
    if (meters >= 1000) return "${(meters / 1000).toStringAsFixed(2)} كم";
    return "${meters.toStringAsFixed(0)} م";
  }

  // تقدير سريع للوقت (بدون اتصال API): مشي 4.5 كم/س، سيارة 35 كم/س داخل المدينة
  String _fmtEta(double meters, {bool walking = true}) {
    final speedKmh = walking ? 4.5 : 35.0;
    final hours = (meters / 1000) / speedKmh;
    final totalSeconds = (hours * 3600).round();
    final min = totalSeconds ~/ 60;
    final sec = totalSeconds % 60;
    if (min > 0) return walking ? "$min د" : "$min د ${sec}s";
    return "$sec ث";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryLabel)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, textAlign: TextAlign.center))
          : _items.isEmpty
          ? const Center(child: Text("لا يوجد أماكن قريبة ضمن النطاق المحدد"))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final it = _items[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.place, color: Colors.orange),
                    title: Text(
                      it.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "المسافة: ${_fmtDistance(it.meters)} • "
                      "مشي: ${_fmtEta(it.meters, walking: true)} • "
                      "سيارة: ${_fmtEta(it.meters, walking: false)}",
                    ),
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      icon: const Icon(Icons.map, color: Colors.white),
                      label: const Text(
                        "خريطة",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: _pos == null
                          ? null
                          : () {
                              
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MapPage(
                                      position: Position(
                                        latitude: _pos!.latitude,
                                        longitude: _pos!.longitude,
                                        timestamp: _pos!.timestamp,
                                        accuracy: _pos!.accuracy,
                                        altitude: _pos!.altitude,
                                        heading: _pos!.heading,
                                        speed: _pos!.speed,
                                        speedAccuracy: _pos!.speedAccuracy,
                                        altitudeAccuracy:
                                            _pos!.altitudeAccuracy,
                                        headingAccuracy: _pos!.headingAccuracy,
                                      ),
                                      destination: it.latLng,
                                      enableTap: false,
                                      enableLiveTracking: false,
                                      themeNotifier: widget.themeNotifier,
                                    ),
                                  ),
                                );
                              
                            },
                    ),
                    onTap: () {
                      // TODO: افتح صفحة تفاصيل للمكان إن رغبت
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _PlaceItem {
  final String id;
  final String name;
  final latlng.LatLng latLng;
  final double meters;

  _PlaceItem({
    required this.id,
    required this.name,
    required this.latLng,
    required this.meters,
  });
}
