/// ملف مستخرج تلقائيًا من main.dart
/// يحتوي الكلاس: MapPage
library;

import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
class MapPage extends StatefulWidget {
  /// الموقع الحالي للمستخدم
  final Position position;
  final ThemeNotifier themeNotifier;

  /// الوجهة (اختيارية)
  final latlng.LatLng? destination;

  /// هل يُسمح بالنقر على الخريطة؟
  final bool enableTap;

  final bool enableLiveTracking; // ✅ ميزة التتبع الحي

  const MapPage({
    super.key,
    required this.position,
    required this.themeNotifier,
    this.destination,
    this.enableTap = true,
    this.enableLiveTracking = false, // الافتراضي: معطل
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  
  final fm.MapController _mapController = fm.MapController(); // 💡 للتحكم بالخريطة

  List<latlng.LatLng> routePoints = [];
  bool _loading = true;
  StreamSubscription<Position>? _positionStream;
  String? _error;

  /// وسيلة النقل المختارة
  String _selectedMode = "driving-car"; // الافتراضي سيارة
  final Map<String, String> transportModes = {
    "🚶 مشي": "foot-walking",
    "🚗 سيارة": "driving-car",
    "🚴 دراجة": "cycling-regular",
  };

  /// ستايل الخريطة
  String _currentStyle = "streets";

  /// الوجهة التي يحددها المستخدم بالنقر (تُستخدم بدل widget.destination إذا ضُبطت)
  latlng.LatLng? _destination;

  /// نتائج ملخص المسار
  double? _summaryDistanceMeters;
  double? _summaryDurationSeconds;

  @override
  void initState() {
    super.initState();
    _destination = widget.destination;

    if (_destination != null) {
      _getRoute(_destination!);
    } else {
      _loading = false;
    }

    // ✅ استدعاء دالة الموقع بأمان
    _initLocation();

    // ✅ تفعيل تتبع حي للموقع
   if (widget.enableLiveTracking) {
  _positionStream = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
  ).listen((Position pos) {
    final newPos = latlng.LatLng(pos.latitude, pos.longitude);
    if (mounted) {
      _mapController.move(newPos, _mapController.camera.zoom);
    }
  });
}
}

  Future<void> _initLocation() async {
    try {
      // طلب إذن الموقع
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _error = "يرجى تفعيل إذن الموقع من الإعدادات");
        return;
      }

      // الحصول على الموقع الحالي بدقة عالية
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      final userLocation = latlng.LatLng(pos.latitude, pos.longitude);

      // ✅ تحريك الخريطة بعد تحميل الواجهة
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(userLocation, 16.0);
      });
    } catch (e) {
      setState(() => _error = "تعذر تحديد الموقع: $e");
    }
  }

  Future<void> _getRoute(latlng.LatLng destination) async {
    setState(() {
      _loading = true;
      _error = null;
      routePoints = [];
      _summaryDistanceMeters = null;
      _summaryDurationSeconds = null;
    });

    const apiKey =
        "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjVlZTQ1YWY4YjIzMDQxYmZiZjUzNDhmZjhhOTU5MTc5IiwiaCI6Im11cm11cjY0In0=";

    final start = "${widget.position.longitude},${widget.position.latitude}";
    final end = "${destination.longitude},${destination.latitude}";

    final url = Uri.parse(
      "https://api.openrouteservice.org/v2/directions/$_selectedMode?start=$start&end=$end",
    );

    try {
      final response = await http.get(url, headers: {
        'Authorization': apiKey,
        'Accept': 'application/json, application/geo+json'
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final coords = data["features"][0]["geometry"]["coordinates"] as List;
        final points = coords
            .map((c) =>
                latlng.LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();

        double? distance;
        double? duration;
        try {
          final summary = data["features"][0]["properties"]["summary"];
          if (summary != null) {
            distance = (summary["distance"] as num).toDouble();
            duration = (summary["duration"] as num).toDouble();
          }
        } catch (_) {}

        setState(() {
          routePoints = points;
          _summaryDistanceMeters = distance;
          _summaryDurationSeconds = duration;
          _loading = false;
        });
      } else {
        setState(() {
          _error = "خطأ من خادم ORS: ${response.statusCode}";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "خطأ في الاتصال: $e";
        _loading = false;
      });
    }
  }

  /// ✅ تم تعديل هذه الدالة لاستخدام OpenStreetMap + Esri Satellite
  String _getUrlTemplate() {
    switch (_currentStyle) {
      case "satellite":
        // 🔹 خريطة واقعية من Esri (صور الأقمار الصناعية المجانية)
        return "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}";
      default:
        // 🔹 خريطة شوارع من OpenStreetMap
        return "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
    }
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      return "${km.toStringAsFixed(2)} كم";
    } else {
      return "${meters.toStringAsFixed(0)} م";
    }
  }

  String _formatDuration(double seconds) {
    final int s = seconds.round();
    final hours = s ~/ 3600;
    final minutes = (s % 3600) ~/ 60;
    final secs = s % 60;
    if (hours > 0) return "$hours س $minutes د";
    if (minutes > 0) return "$minutes د $secs ث";
    return "$secs ث";
  }

  @override
  Widget build(BuildContext context) {
    final userLocation =
        latlng.LatLng(widget.position.latitude, widget.position.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text("الخريطة (${_currentStyle.toUpperCase()})"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _currentStyle = value;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: "streets",
                child: Text("شوارع افتراضية مع عناوين"),
              ),
              PopupMenuItem(
                value: "satellite",
                child: Text("صورة فضائية (تضاريس واقعية)"),
              ),
            ],
          )
        ],
      ),
      floatingActionButton: widget.enableTap
          ? FloatingActionButton.extended(
              backgroundColor: Colors.orange,
              icon: const Icon(Icons.my_location),
              label: const Text("مركّز إلى موقعي"),
              onPressed: () {
                final userLocation = latlng.LatLng(
                  widget.position.latitude,
                  widget.position.longitude,
                );
                _mapController.move(userLocation, 16.0);
              },
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _selectedMode,
              items: transportModes.entries
                  .map((entry) => DropdownMenuItem(
                        value: entry.value,
                        child: Text(entry.key),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null && _destination != null) {
                  setState(() {
                    _selectedMode = value;
                  });
                  _getRoute(_destination!);
                } else {
                  setState(() {
                    _selectedMode = value ?? _selectedMode;
                  });
                }
              },
            ),
          ),
          if (_summaryDistanceMeters != null || _summaryDurationSeconds != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              child: Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "المسافة: ${_summaryDistanceMeters != null ? _formatDistance(_summaryDistanceMeters!) : 'غير متوفر'}  •  الوقت: ${_summaryDurationSeconds != null ? _formatDuration(_summaryDurationSeconds!) : 'غير متوفر'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _summaryDistanceMeters = null;
                            _summaryDurationSeconds = null;
                            routePoints = [];
                            _destination = null;
                          });
                        },
                      )
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                fm.FlutterMap(
                  mapController: _mapController,
                  options: fm.MapOptions(
  center: userLocation,
  zoom: 14,
  maxZoom: _currentStyle == "satellite" ? 18 : 22,
  onPositionChanged: (position, hasGesture) {
    if (_currentStyle == "satellite" && position.zoom != null && position.zoom! > 18) {
      _mapController.move(position.center!, 18);
    }
  },
  onTap: widget.enableTap
      ? (tapPosition, point) {
          setState(() {
            _destination = point;
            _error = null;
          });
          _getRoute(point);
        }
      : null,
),

                  children: [
                    fm.TileLayer(
                      urlTemplate: _getUrlTemplate(),
                      userAgentPackageName: 'com.example.smartguideapp',
                    ),
                    fm.MarkerLayer(
                      markers: [
                        fm.Marker(
                          point: userLocation,
                          width: 60,
                          height: 60,
                          child: const Icon(Icons.person_pin_circle,
                              color: Colors.blue, size: 40),
                        ),
                        if (_destination != null)
                          fm.Marker(
                            point: _destination!,
                            width: 60,
                            height: 60,
                            child: const Icon(Icons.location_pin,
                                color: Colors.red, size: 40),
                          ),
                      ],
                    ),
                    if (routePoints.isNotEmpty)
                      fm.PolylineLayer(
                        polylines: [
                          fm.Polyline(
                            points: routePoints,
                            color: Colors.orange,
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                  ],
                ),
                if (_loading)
                  const Center(child: CircularProgressIndicator()),
                if (_error != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      color: Colors.red.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_error!),
                      ),
                    ),
                  ),
                if (widget.enableTap)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: const Text(
                            "اضغط أي مكان في الخريطة لتعيين وجهة. اختر وسيلة النقل لإعادة حساب المسار."),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  @override
void dispose() {
  _positionStream?.cancel(); // ✅ إلغاء التتبع لتجنب الفريز
  super.dispose();
}

}
