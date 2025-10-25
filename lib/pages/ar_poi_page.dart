import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart' as latlng;

class ARPoiPage extends StatefulWidget {
  const ARPoiPage({super.key});

  @override
  State<ARPoiPage> createState() => _ARPoiPageState();
}

class _ARPoiPageState extends State<ARPoiPage> with WidgetsBindingObserver {
  CameraController? _cam;
  StreamSubscription? _compassSub;
  double _headingDeg = 0.0; // اتجاه الجهاز (0=شمال)
  Position? _pos;

  // مجال رؤية الكاميرا أفقياً (تقريبي بالدرجات). تستطيع تعديله بين 50–70.
  static const double _hFov = 60;

  // أماكن سيتم تحميلها من Firestore
  List<Map<String, dynamic>> _places = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    try {
      // 1) صلاحيات
      await Geolocator.requestPermission();
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _error = "يرجى تفعيل خدمة الموقع");
        return;
      }

      // 2) موقع المستخدم
      _pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // 3) الكاميرا الخلفية
      final cams = await availableCameras();
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      _cam = CameraController(back, ResolutionPreset.medium, enableAudio: false);
      await _cam!.initialize();

      // 4) البوصلة
      _compassSub = FlutterCompass.events?.listen((event) {
        final h = event.heading; // قد تكون null
        if (h != null && mounted) {
          setState(() => _headingDeg = h);
        }
      });

      // 5) تحميل أماكن Firestore (قريب/كلّي)
      await _loadNearbyPlaces();

      setState(() => _loading = false);
    } catch (e) {
      setState(() => _error = "تعذر التهيئة: $e");
    }
  }

  Future<void> _loadNearbyPlaces() async {
    // أبسط شيء: اجلب أول 50 مكان. لاحقًا: اعمل فلترة بمربع حدودي (bounding box).
    final snap = await FirebaseFirestore.instance
        .collection('places')
        .limit(50)
        .get();

    _places = snap.docs.map((d) => d.data()).toList();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _cam?.dispose();
    super.dispose();
  }

  // حساب الزاوية (bearing) من موقع المستخدم نحو مكان معيّن (0=شمال، باتجاه عقارب الساعة)
  double _bearing(latlng.LatLng from, latlng.LatLng to) {
    final lat1 = _deg2rad(from.latitude);
    final lat2 = _deg2rad(to.latitude);
    final dLon = _deg2rad(to.longitude - from.longitude);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final brng = (math.atan2(y, x) * 180.0 / math.pi + 360.0) % 360.0;
    return brng;
  }

  double _deg2rad(double d) => d * math.pi / 180.0;

  // تحويل زاوية نسبية إلى موقع X على الشاشة
  double _angleToScreenX(double relAngle, double screenWidth) {
    // المجال الظاهر هو ± (_hFov/2). نرسمه خطياً على عرض الشاشة.
    final halfFov = _hFov / 2;
    final normalized = (relAngle + halfFov) / (2 * halfFov); // 0..1
    return normalized * screenWidth;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("AR-POI")),
        body: Center(child: Text(_error!, textAlign: TextAlign.center)),
      );
    }
    if (_cam == null || !_cam!.value.isInitialized || _pos == null) {
      return const Scaffold(
        body: Center(child: Text("الكاميرا/الموقع غير جاهزين")),
      );
    }

    final userLL = latlng.LatLng(_pos!.latitude, _pos!.longitude);

    // نبني طبقة علامات محسوبة فورياً من heading + bearing
    final pins = <Widget>[];
    for (final p in _places) {
      final name = (p['name'] ?? 'مكان').toString();
      final lat = (p['latitude'] as num?)?.toDouble();
      final lon = (p['longitude'] as num?)?.toDouble();
      if (lat == null || lon == null) continue;

      final poi = latlng.LatLng(lat, lon);
      final brng = _bearing(userLL, poi); // 0..360
      // الفرق بين اتجاه المكان واتجاه الجهاز
      double rel = brng - _headingDeg; // -∞..∞
      // طبّع الزاوية إلى [-180, +180]
      while (rel > 180) rel -= 360;
      while (rel < -180) rel += 360;

      // أعرض فقط ما يقع داخل مجال رؤية الكاميرا
      if (rel.abs() <= _hFov / 2) {
        final x = _angleToScreenX(rel, size.width);
        // موضع عمودي ثابت (تقدر تربطه بالمسافة)
        final y = size.height * 0.35;

        pins.add(Positioned(
          left: x - 60, // نصف عرض البطاقة
          top: y,
          child: _PoiChip(
            title: name,
            onTap: () {
              // TODO: افتح تفاصيل/خريطة لهذا المكان
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("فتح: $name")),
              );
            },
          ),
        ));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("استكشاف AR")),
      body: Stack(
        children: [
          CameraPreview(_cam!),
          // تدرّج خفيف لتوضيح النص فوق الكاميرا
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.05),
                      Colors.transparent,
                      Colors.black.withOpacity(0.15),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          // طبقة الدبابيس
          ...pins,
          // بوصلة و Heading
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Heading: ${_headingDeg.toStringAsFixed(0)}°",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PoiChip extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _PoiChip({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.orange.withOpacity(0.95),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: const BoxConstraints(minWidth: 120),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.place, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
