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
import 'package:geocoding/geocoding.dart';
import 'custom_drawer.dart';
import '../l10n/gen/app_localizations.dart';

class MapPage extends StatefulWidget {
  final Position position;
  final ThemeNotifier themeNotifier;
  final latlng.LatLng? destination;
  final bool enableTap;
  final bool enableLiveTracking;
  // ✅ جديد: لدعم عرض الرحلات المحفوظة من Firestore
  final latlng.LatLng? start;
  final List<latlng.LatLng>? savedPath;

  const MapPage({
    super.key,
    required this.position,
    required this.themeNotifier,
    this.destination,
    this.enableTap = true,
    this.enableLiveTracking = false,
        this.start,        // ✅ جديد
    this.savedPath,    // ✅ جديد

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

Color _routeColor = Colors.orange;
bool _showSavedTripBanner = true;


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
    
    // ✅ في حال الرحلة من Firestore (يوجد مسار محفوظ)
    if (widget.savedPath != null && widget.savedPath!.isNotEmpty) {
      routePoints = widget.savedPath!;
      _loading = false;
      _destination ??= routePoints.last;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(widget.start ?? routePoints.first, 14.5);
      });
      return; // 🟢 نخرج لأننا لسنا بحاجة لحساب المسار من جديد
    }

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
            content: const Text("لقد وصلت إلى وجهتك بنجاح.\nهل ترغب في حفظ الرحلة؟"),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _saveTripLogToFirebase();
                },
                child: const Text("نعم"),
              ),
              TextButton(
              onPressed: () {
                Navigator.pop(context); // فقط إغلاق النافذة
              },
              child: const Text("لا"),
            ),
            ],
          ),
        );
      }
    }
  }

  // ✅ حفظ الرحلة داخل Firestore
  // ✅ حفظ الرحلة داخل Firestore
  Future<void> _saveTripLogToFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _destination == null) return;

      // 🔹 نحاول نحصل على اسم المكان من الإحداثيات
      String placeName = "موقع غير معروف";
      try {
        final placemarks = await placemarkFromCoordinates(
          _destination!.latitude,
          _destination!.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          placeName = [
            p.locality,
            p.subLocality,
            p.administrativeArea,
            p.street
          ].where((e) => e != null && e.isNotEmpty).join(' - ');
        }
      } catch (e) {
        debugPrint("⚠️ فشل في تحديد اسم المكان: $e");
      }

      // ✅ تجهيز بيانات البداية والمسار
      final startLatLng = _currentLocation ??
          latlng.LatLng(widget.position.latitude, widget.position.longitude);

      // نحول نقاط المسار إلى List<Map<String,double>>
      final pathList = routePoints
          .map((p) => {
                'latitude': p.latitude,
                'longitude': p.longitude,
              })
          .toList();

      // 🔹 حفظ السجل في Firestore (إضافة start و path)
      await FirebaseFirestore.instance.collection('travel_logs').add({
        'user_id': user.uid,
        'start': {
          'latitude': startLatLng.latitude,
          'longitude': startLatLng.longitude,
        },
        'destination': {
          'latitude': _destination!.latitude,
          'longitude': _destination!.longitude,
        },
        'path': pathList,
        'place_name': placeName,
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

// ✅ النسخة النهائية من _getRoute() باستخدام OSRM + تلوين الخط حسب وسيلة النقل
Future<void> _getRoute(latlng.LatLng destination) async {
  setState(() {
    _loading = true;
    _error = null;
    routePoints = [];
    _summaryDistanceMeters = null;
    _summaryDurationSeconds = null;
  });

  try {
    // 📍 نقطة البداية (الموقع الحالي أو الافتراضي)
    final startLatLng = _currentLocation ??
        latlng.LatLng(widget.position.latitude, widget.position.longitude);
    final start = "${startLatLng.longitude},${startLatLng.latitude}";
    final end = "${destination.longitude},${destination.latitude}";

    // 🚗 اختيار وسيلة النقل بناءً على _selectedMode
    String mode = "driving";
    if (_selectedMode.contains("foot")) mode = "foot";
    if (_selectedMode.contains("cycling")) mode = "bike";

    // 🌍 طلب OSRM (مجاني ولا يحتاج مفتاح)
    final url = Uri.parse(
      "https://router.project-osrm.org/route/v1/$mode/$start;$end?overview=full&geometries=geojson",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data["routes"] == null || data["routes"].isEmpty) {
        setState(() {
          _error = "⚠️ لم يتم العثور على مسار صالح.";
          _loading = false;
        });
        return;
      }

      // 🧭 تحويل نقاط المسار
      final coords = data["routes"][0]["geometry"]["coordinates"] as List;
      final points = coords
          .map((c) => latlng.LatLng(
                (c[1] as num).toDouble(),
                (c[0] as num).toDouble(),
              ))
          .toList();

      // 📏 استخراج المسافة والمدة
      final distance = (data["routes"][0]["distance"] as num?)?.toDouble();
      final duration = (data["routes"][0]["duration"] as num?)?.toDouble();

      // 🎨 تحديد لون الخط حسب وسيلة النقل
      Color routeColor = Colors.orange; // افتراضي للسيارة
      if (mode == "foot") routeColor = Colors.blueAccent;
      if (mode == "bike") routeColor = Colors.green;

      setState(() {
        routePoints = points;
        _summaryDistanceMeters = distance;
        _summaryDurationSeconds = duration;
        _loading = false;

        // ✅ نضيف اللون كمعلومة مؤقتة لاستخدامها في رسم Polyline
        _routeColor = routeColor;
      });
    } else {
      setState(() {
        _error = "⚠️ خطأ من خادم OSRM: ${response.statusCode}";
        _loading = false;
      });
    }
  } catch (e) {
    setState(() {
      _error = "⚠️ خطأ في الاتصال: $e";
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
      drawer: CustomDrawer(
          themeNotifier: widget.themeNotifier,), // ⬅️ هذا السطر المهم
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
        color: _routeColor, // 🎨 بدل الثابت القديم
        strokeWidth: 4,
      ),
    ],
  ),
                  ],
                ),

// ✅ Banner يظهر فقط عند عرض رحلة محفوظة
if (_showSavedTripBanner && widget.savedPath != null && widget.savedPath!.isNotEmpty)
  Positioned(
    top: 20,
    left: 0,
    right: 0,
    child: Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 350, // 🔹 عرض أقصى ثابت — مناسب لجميع الأجهزة
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orange.shade600,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.route, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                AppLocalizations.of(context)!.viewSavedTripBanner,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showSavedTripBanner = false;
                });
              },
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white24,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
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
