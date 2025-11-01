
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
import 'place_details_page.dart';

class MapPage extends StatefulWidget {
  final Position position;
  final ThemeNotifier themeNotifier;
  final latlng.LatLng? destination;
  final Map<String, dynamic>? placeInfo;
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
    this.placeInfo,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}


class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  final fm.MapController _mapController = fm.MapController();


  List<fm.Marker> _placeMarkers = [];

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

final Map<String, IconData> categoryIcons = {
  'restaurant': Icons.restaurant,
  'cafe': Icons.local_cafe,
  'clothes': Icons.shopping_bag,
  'sweets': Icons.cake,
  'hotel': Icons.hotel,
  'tourism': Icons.museum,
};

Widget _buildCategoryMarker(List<dynamic>? categories) {
  String cat = "default";

  if (categories != null && categories.isNotEmpty) {
    cat = categories.first.toString().toLowerCase();
  }

  IconData icon = categoryIcons[cat] ?? Icons.location_on;

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 6,
          offset: Offset(0, 3),
        )
      ]
    ),
    padding: EdgeInsets.all(6),
    child: Icon(
      icon,
      color: Colors.orange,
      size: 28,
    ),
  );
}


Future<Map<String, dynamic>?> _findPlaceByCoordinates(
  latlng.LatLng point,
  BuildContext context,
) async {
  try {
    final snap = await FirebaseFirestore.instance.collection('places').get();

    // هل اللغة الحالية عربية؟
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    for (var doc in snap.docs) {
      final data = doc.data();
      final lat = (data['latitude'] as num).toDouble();
      final lng = (data['longitude'] as num).toDouble();

      final dist = distance(
        latlng.LatLng(lat, lng),
        point,
      );

      if (dist < 40) {
        return {
          "id": doc.id,
          "name": isArabic ? data['title_ar'] : data['title_en'],
          "city": isArabic ? data['city_ar'] : data['city_en'],
          "images": List<String>.from(data['images'] ?? []),
          "url": data['url'] ?? "",
        };
      }
    }
  } catch (e) {
    debugPrint("❌ Error searching Firestore: $e");
  }
  return null;
}


  String _selectedMode = "driving-car";
Map<String, String> get transportModes => {
  AppLocalizations.of(context)!.modeWalk: "foot-walking",
  AppLocalizations.of(context)!.modeCar: "driving-car",
  AppLocalizations.of(context)!.modeBike: "cycling-regular",
};

  String _currentStyle = "streets";
  latlng.LatLng? _destination;

  double? _summaryDistanceMeters;
  double? _summaryDurationSeconds;

  final distance = const latlng.Distance(); // ✅ لحساب المسافة
  Map<String, dynamic>? _selectedPlace;

  @override
  void initState() {
    super.initState();
    _destination = widget.destination;
    _selectedPlace = widget.placeInfo; // ✅ تظهر أول ما يدخل الخريطة
    print("📍 placeInfo received: ${widget.placeInfo}");

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
_loadPlaceMarkers();

    if (widget.enableLiveTracking) {
      _startLiveTracking();
    }
  }

Future<void> _loadPlaceMarkers() async {
  final snap = await FirebaseFirestore.instance.collection('places').get();
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  List<fm.Marker> markers = [];

  for (var doc in snap.docs) {
    var data = doc.data();
    var lat = data['latitude'];
    var lng = data['longitude'];

    markers.add(
      fm.Marker(
        width: 60,
        height: 60,
        point: latlng.LatLng(lat, lng),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedPlace = {
                "id": doc.id,
"name": isArabic ? data['title_ar'] : data['title_en'],
"city": isArabic ? data['city_ar'] : data['city_en'],
                "images": List<String>.from(data['images'] ?? []),
                "url": data['url'] ?? "",
              };
            });
          },
          child: _buildCategoryMarker(data['categories']),
        ),
      ),
    );
  }

  setState(() {
    _placeMarkers = markers;
  });
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
title: Text(AppLocalizations.of(context)!.arrivedTitle),
content: Text(AppLocalizations.of(context)!.arrivedMessage),
actions: [
  TextButton(
    onPressed: () async {
      Navigator.pop(context);
      await _saveTripLogToFirebase();
    },
    child: Text(AppLocalizations.of(context)!.yes),
  ),
  TextButton(
    onPressed: () => Navigator.pop(context),
    child: Text(AppLocalizations.of(context)!.no),
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
String placeName = AppLocalizations.of(context)!.unknownLocation;
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
  SnackBar(content: Text(AppLocalizations.of(context)!.liveTrackingDisabled)),
);
    } else {
      _startLiveTracking();
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(AppLocalizations.of(context)!.liveTrackingEnabled)),
);
    }
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
setState(() => _error = AppLocalizations.of(context)!.enableLocationPermission);
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
setState(() => _error = "${AppLocalizations.of(context)!.locationFailed}: $e");
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
_error = AppLocalizations.of(context)!.noValidRoute;
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
_error = AppLocalizations.of(context)!.serverRouteError;
        _loading = false;
      });
    }
  } catch (e) {
    setState(() {
_error = AppLocalizations.of(context)!.connectionError;
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

String _getLocalizedTileUrl(BuildContext context) {
  return "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
}


  @override
  Widget build(BuildContext context) {
    final userLocation = _currentLocation ??
        latlng.LatLng(widget.position.latitude, widget.position.longitude);

    return Scaffold(
      appBar: AppBar(
title: Text("${AppLocalizations.of(context)!.mapTitle} (${_currentStyle.toUpperCase()})"),
        
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _currentStyle = value),
itemBuilder: (context) => [
  PopupMenuItem(
      value: "streets",
      child: Text(AppLocalizations.of(context)!.mapStyleStreets)),
  PopupMenuItem(
      value: "satellite",
      child: Text(AppLocalizations.of(context)!.mapStyleSatellite)),
],
          )
        ],
      ),
      drawer: CustomDrawer(
          themeNotifier: widget.themeNotifier,), // ⬅️ هذا السطر المهم

body: Stack(
  children: [
    // الطبقة الأساسية: العناصر العلوية + الخريطة
    Column(
      children: [
        // Dropdown وسيلة النقل
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

        // بطاقة ملخص المسافة/الوقت
        if (_summaryDistanceMeters != null || _summaryDurationSeconds != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
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
"${AppLocalizations.of(context)!.distanceLabel}: ${_summaryDistanceMeters != null ? _formatDistance(_summaryDistanceMeters!) : AppLocalizations.of(context)!.notAvailable}"
" • "
"${AppLocalizations.of(context)!.timeLabel}: ${_summaryDurationSeconds != null ? _formatDuration(_summaryDurationSeconds!) : AppLocalizations.of(context)!.notAvailable}",                        style: const TextStyle(fontSize: 16),
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


        // الخريطة تملأ ما تبقى
        Expanded(
          child: fm.FlutterMap(
            mapController: _mapController,
            options: fm.MapOptions(
              center: userLocation,
              zoom: 14,
              maxZoom: _currentStyle == "satellite" ? 18 : 22,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && _isTracking) {
                  _stopLiveTracking();
                }
              },
onTap: widget.enableTap
    ? (tapPosition, point) async {
        _destination = point;
        _error = null;
        _showTip = false;

        // 🔍 حاول نلاقي المكان في Firestore
final found = await _findPlaceByCoordinates(point, context);

        setState(() {
          _selectedPlace = found; // لو لقيه، بنعرضه، لو لا → null
        });

        _getRoute(point);
      }
                  : null,
            ),
            children: [
fm.TileLayer(
  urlTemplate: _getLocalizedTileUrl(context),
  userAgentPackageName: 'com.example.smartguideapp',
),
fm.MarkerLayer(
  markers: [
    // ✅ ماركرات الأماكن من Firestore
    ..._placeMarkers,

    // ✅ موقع المستخدم
    if (_currentLocation != null)
      fm.Marker(
        point: _currentLocation!,
        width: 60,
        height: 60,
        child: const Icon(Icons.person_pin_circle,
            color: Colors.blue, size: 40),
      ),

    // ✅ ماركر الوجهة الحمراء
    if (_destination != null)
      fm.Marker(
        point: _destination!,
        width: 60,
        height: 60,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedPlace = {
                "id": widget.placeInfo?['id'],
                "name": widget.placeInfo?['name'],
                "city": widget.placeInfo?['city'],
                "images": widget.placeInfo?['images'],
                "url": widget.placeInfo?['url'],
              };
            });
          },
          child: const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 40,
          ),
        ),
      ),
  ],
),

              if (routePoints.isNotEmpty)
                fm.PolylineLayer(
                  polylines: [
                    fm.Polyline(
                      points: routePoints,
                      color: _routeColor,
                      strokeWidth: 4,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    ),

    // ===== هنا العناصر العائمة فوق كل شيء (Overlay) =====

    // Banner يظهر فقط عند عرض رحلة محفوظة
    if (_showSavedTripBanner && widget.savedPath != null && widget.savedPath!.isNotEmpty)
      Positioned(
        top: 20,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 350),
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

if (_selectedPlace != null && _selectedPlace!['name'] != null)
  Positioned(
    bottom: 10,
    left: 10,
    right: 10,
    child: _buildMapPlaceCard(_selectedPlace!),
  ),


// زر التتبع الحي + زر توسيط الموقع
Positioned(
  top: 16,
  left: 16,
  child: Row(
    children: [
      FloatingActionButton(
        heroTag: "liveTrackTop",
        backgroundColor: _isTracking ? Colors.green : Colors.grey,
        onPressed: _toggleLiveTracking,
tooltip: _isTracking 
  ? AppLocalizations.of(context)!.stopLiveTracking 
  : AppLocalizations.of(context)!.startLiveTracking,
        child: Icon(_isTracking ? Icons.gps_fixed : Icons.gps_off),
      ),
      const SizedBox(width: 12), // مسافة بينهم
      FloatingActionButton(
        heroTag: "centerBtn",
        backgroundColor: Colors.orange,
        onPressed: () {
          final loc = _currentLocation ??
              latlng.LatLng(widget.position.latitude, widget.position.longitude);
          _mapController.move(loc, 16.0);
        },
        child: const Icon(Icons.my_location),
      ),
    ],
  ),
),



    // مؤشرات التحميل/الأخطاء/التلميح
    if (_loading) const Center(child: CircularProgressIndicator()),
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
            child:  Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, color: Colors.orange),
                  SizedBox(width: 6),
Text(
  AppLocalizations.of(context)!.mapTapHint,
  style: TextStyle(fontSize: 13.5, color: Colors.black87),
),
                ],
              ),
            ),
          ),
        ),
      ),
  ],
),
    );
  }

Widget _buildPlaceCard(Map<String, dynamic> p) {
  return Card(
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: p['images'] != null && p['images'].isNotEmpty
                ? Image.asset(
                    p['images'][0],
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.image_not_supported, size: 60),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['name'] ?? "",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  p['city'] ?? "",
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(Icons.directions, color: Colors.orange),
            onPressed: () {
              if (_destination != null) {
                _getRoute(_destination!);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.blue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlaceDetailsPage(
                    id: p['id'],
                    title: p['name'],
                    cityName: p['city'],
                    images: List<String>.from(p['images'] ?? []),
                    url: p['url'],
                    themeNotifier: widget.themeNotifier,
                    heroTag: p['id'],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

Widget _buildMapPlaceCard(Map<String, dynamic> p) {
final name = p['name'] ?? AppLocalizations.of(context)!.mapUnknownPlace;
  final city = p['city'] ?? "";
  final rating = p['rating']?.toDouble() ?? 4.5;
  final reviews = p['reviews'] ?? 12;

  Widget placeImage;
  if (p['images'] != null && p['images'].isNotEmpty) {
    placeImage = Image.asset(
      p['images'][0],
      width: 70,
      height: 70,
      fit: BoxFit.cover,
    );
  } else {
    placeImage = Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[300],
      ),
      child: const Icon(Icons.place, color: Colors.black54),
    );
  }

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(10), child: placeImage),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              if (city.isNotEmpty)
                Text(city,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 4),

              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 18),
                  Text("$rating ",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("($reviews ${AppLocalizations.of(context)!.reviews})",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              )
            ],
          ),
        ),

        Column(
          children: [
            IconButton(
              icon: const Icon(Icons.navigation, color: Colors.orange),
              onPressed: () => _getRoute(_destination!),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlaceDetailsPage(
                      id: p['id'],
                      title: name,
                      cityName: city,
                      images: List<String>.from(p['images'] ?? []),
                      url: p['url'],
                      themeNotifier: widget.themeNotifier,
                      heroTag: p['id'],
                    ),
                  ),
                );
              },
            ),
          ],
        )
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
