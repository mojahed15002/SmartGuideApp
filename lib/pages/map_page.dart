/// ملف مستخرج تلقائيًا من main.dart
/// يحتوي الكلاس: MapPage
library;

import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ جديد
import 'package:firebase_auth/firebase_auth.dart'; // ✅ جديد
import 'dart:convert';
import 'dart:async';

class MapPage extends StatefulWidget {
  final Position position;
  final ThemeNotifier themeNotifier;
  final latlng.LatLng? destination;
  final bool enableTap;
  final bool enableLiveTracking;

  const MapPage({
    super.key,
    required this.position,
    required this.themeNotifier,
    this.destination,
    this.enableTap = true,
    this.enableLiveTracking = false,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  final fm.MapController _mapController = fm.MapController();

  List<latlng.LatLng> routePoints = [];
  bool _loading = true;
  StreamSubscription<Position>? _positionStream;
  String? _error;

  bool _showTip = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _isTracking = false;
  bool _tripCompleted = false; // ✅ منع تكرار الحفظ

  latlng.LatLng? _currentLocation;
  DateTime? _lastRouteUpdate;

  String _selectedMode = "driving-car";
  final Map<String, String> transportModes = {
    "🚶 مشي": "foot-walking",
    "🚗 سيارة": "driving-car",
    "🚴 دراجة": "cycling-regular",
  };

  String _currentStyle = "streets";
  latlng.LatLng? _destination;

  double? _summaryDistanceMeters;
  double? _summaryDurationSeconds;

  final distance = const latlng.Distance(); // ✅ لحساب المسافة

  @override
  void initState() {
    super.initState();
    _destination = widget.destination;

    if (_destination != null) {
      _getRoute(_destination!);
    } else {
      _loading = false;
    }

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _fadeController.forward().then((_) {
          setState(() => _showTip = false);
        });
      }
    });

    _initLocation();

    if (widget.enableLiveTracking) {
      _startLiveTracking();
    }
  }

  // ✅ تفعيل التتبع الحي للموقع
  void _startLiveTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    ).listen((Position pos) {
      final newPos = latlng.LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;

      setState(() {
        _currentLocation = newPos;
      });

      _mapController.move(newPos, _mapController.camera.zoom);

      // ✅ فحص المسافة بين المستخدم والوجهة
      _checkProximity(newPos);

      // ✅ تحديث المسار البرتقالي كل 5 ثواني
      if (_destination != null) {
        final now = DateTime.now();
        if (_lastRouteUpdate == null ||
            now.difference(_lastRouteUpdate!).inSeconds > 5) {
          _lastRouteUpdate = now;
          _getRoute(_destination!);
        }
      }
    });

    setState(() => _isTracking = true);
  }

  // ✅ فحص القرب من الوجهة
  Future<void> _checkProximity(latlng.LatLng currentPos) async {
    if (_destination == null || _tripCompleted) return;

    final double dist = distance(currentPos, _destination!);
    if (dist <= 30) {
      _tripCompleted = true; // منع تكرار التنبيه
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("🎉 تهانينا!"),
            content: const Text("لقد وصلت إلى وجهتك بنجاح."),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _saveTripLogToFirebase();
                },
                child: const Text("تم"),
              ),
            ],
          ),
        );
      }
    }
  }

  // ✅ حفظ الرحلة داخل Firestore
  Future<void> _saveTripLogToFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('travel_logs').add({
        'user_id': user.uid,
        'destination': _destination.toString(),
        'time': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ تم حفظ الرحلة في السجلات")),
        );
      }
    } catch (e) {
      debugPrint("⚠️ فشل حفظ السجل: $e");
    }
  }

  void _stopLiveTracking() {
    _positionStream?.cancel();
    setState(() => _isTracking = false);
  }

  void _toggleLiveTracking() {
    if (_isTracking) {
      _stopLiveTracking();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🔴 تم إيقاف التتبع الحي")),
      );
    } else {
      _startLiveTracking();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🟢 تم تفعيل التتبع الحي")),
      );
    }
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _error = "يرجى تفعيل إذن الموقع من الإعدادات");
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      final userLocation = latlng.LatLng(pos.latitude, pos.longitude);

      // ✅ حفظ الموقع كبداية للتتبع
      setState(() {
        _currentLocation = userLocation;
      });

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

    final startLatLng = _currentLocation ??
        latlng.LatLng(widget.position.latitude, widget.position.longitude);
    final start = "${startLatLng.longitude},${startLatLng.latitude}";
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

  String _getUrlTemplate() {
    switch (_currentStyle) {
      case "satellite":
        return "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}";
      default:
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
    final userLocation = _currentLocation ??
        latlng.LatLng(widget.position.latitude, widget.position.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text("الخريطة (${_currentStyle.toUpperCase()})"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _currentStyle = value),
            itemBuilder: (context) => const [
              PopupMenuItem(
                  value: "streets",
                  child: Text("شوارع افتراضية مع عناوين")),
              PopupMenuItem(
                  value: "satellite",
                  child: Text("صورة فضائية (تضاريس واقعية)")),
            ],
          )
        ],
      ),
      floatingActionButton: widget.enableTap
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: "centerBtn",
                  backgroundColor: Colors.orange,
                  icon: const Icon(Icons.my_location),
                  label: const Text("مركّز إلى موقعي"),
                  onPressed: () {
                    final loc = _currentLocation ??
                        latlng.LatLng(widget.position.latitude,
                            widget.position.longitude);
                    _mapController.move(loc, 16.0);
                  },
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _selectedMode,
              items: transportModes.entries
                  .map((entry) =>
                      DropdownMenuItem(value: entry.value, child: Text(entry.key)))
                  .toList(),
              onChanged: (value) {
                if (value != null && _destination != null) {
                  setState(() => _selectedMode = value);
                  _getRoute(_destination!);
                } else {
                  setState(() => _selectedMode = value ?? _selectedMode);
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
                    maxZoom:
                        _currentStyle == "satellite" ? 18 : 22,
                    onPositionChanged: (pos, hasGesture) {
                      if (hasGesture && _isTracking) {
                        _stopLiveTracking();
                      }
                    },
                    onTap: widget.enableTap
                        ? (tapPosition, point) {
                            setState(() {
                              _destination = point;
                              _error = null;
                              _showTip = false;
                            });
                            _getRoute(point);
                          }
                        : null,
                  ),
                  children: [
                    fm.TileLayer(
                      urlTemplate: _getUrlTemplate(),
                      userAgentPackageName:
                          'com.example.smartguideapp',
                    ),
                    fm.MarkerLayer(
                      markers: [
                        if (_currentLocation != null)
                          fm.Marker(
                            point: _currentLocation!,
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
                // 🔘 زر التتبع الحي أعلى يسار الشاشة
                Positioned(
                  top: 16,
                  left: 16,
                  child: FloatingActionButton(
                    heroTag: "liveTrackTop",
                    backgroundColor:
                        _isTracking ? Colors.green : Colors.grey,
                    onPressed: _toggleLiveTracking,
                    tooltip: _isTracking
                        ? "إيقاف التتبع الحي"
                        : "تفعيل التتبع الحي",
                    child:
                        Icon(_isTracking ? Icons.gps_fixed : Icons.gps_off),
                  ),
                ),
                if (_loading)
                  const Center(child: CircularProgressIndicator()),
                if (_error != null)
                  Positioned(
                    top: 80,
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
                if (_showTip && widget.enableTap)
                  Positioned(
                    top: 10,
                    right: 100,
                    child: FadeTransition(
                      opacity: ReverseAnimation(_fadeAnimation),
                      child: Card(
                        elevation: 6,
                        color: Colors.white.withOpacity(0.95),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.touch_app, color: Colors.orange),
                              SizedBox(width: 6),
                              Text(
                                "اضغط أي مكان في الخريطة لتعيين وجهة. اختر وسيلة النقل لإعادة حساب المسار.",
                                style: TextStyle(
                                    fontSize: 13.5, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
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
    _positionStream?.cancel();
    _fadeController.dispose();
    super.dispose();
  }
}
