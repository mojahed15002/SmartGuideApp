import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/geo_utils.dart';
import 'package:flutter/services.dart';
import '../l10n/gen/app_localizations.dart';

class ARDirectionPage extends StatefulWidget {
  final double destLat;
  final double destLng;

  const ARDirectionPage({
    super.key,
    required this.destLat,
    required this.destLng,
  });

  @override
  State<ARDirectionPage> createState() => _ARDirectionPageState();
}

class _ARDirectionPageState extends State<ARDirectionPage>
    with WidgetsBindingObserver {
  CameraController? _camera;
  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<Position>? _locSub;

  double _deviceHeading = 0; // 0..360
  Position? _position;
  bool _initializing = true;
  String? _error;
  DateTime? _lastHapticAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAll();
  }

  Future<void> _initAll() async {
    try {
      // 1) صلاحيات الموقع
      LocationPermission perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() => _error = "رجاءً فعّل إذن الموقع");
        return;
      }

      // اخر موقع معروف + ستريم التحديث
      _position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      _locSub = Geolocator.getPositionStream(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).listen((p) => setState(() => _position = p));

      // 2) الكاميرا
      final cams = await availableCameras();
      _camera = CameraController(
        cams.first, // الخلفية غالبًا أول كاميرا
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _camera!.initialize();

      // 3) البوصلة
      _compassSub = FlutterCompass.events?.listen((e) {
        // قد تكون null على بعض الأجهزة
        final h = (e.heading ?? 0);
        setState(() => _deviceHeading = (h + 360) % 360);
      });

      setState(() => _initializing = false);
    } catch (e) {
      setState(() => _error = "تعذر التهيئة: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _compassSub?.cancel();
    _locSub?.cancel();
    _camera?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // أوقف/استأنف الكاميرا حسب الحالة
    if (_camera == null || !_camera!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _camera?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCameraOnly();
    }
  }

  Future<void> _initCameraOnly() async {
    try {
      final cams = await availableCameras();
      _camera = CameraController(cams.first, ResolutionPreset.medium, enableAudio: false);
      await _camera!.initialize();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    
    if (_error != null) {
      
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.ar_title)),
        body: Center(child: Text(_error!, textAlign: TextAlign.center)),
      );
    }

    if (_initializing || _camera == null || !_camera!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // احسب اتجاه الوجهة إن توفر الموقع
    double? deltaDeg;
    if (_position != null) {
      final brng = calculateBearing(
        _position!.latitude,
        _position!.longitude,
        widget.destLat,
        widget.destLng,
      );
      deltaDeg = headingDelta(_deviceHeading, brng);
    }

// ✅ عند الاقتراب من الاتجاه الصحيح نهتز مرة واحدة
if (deltaDeg != null && deltaDeg.abs() < 8) {
  final now = DateTime.now();
  if (_lastHapticAt == null || now.difference(_lastHapticAt!).inMilliseconds > 1200) {
    HapticFeedback.mediumImpact(); // أو lightImpact() إذا بدك أضعف
    _lastHapticAt = now;
  }
}
// نصوص التلميح المترجمة
String directionTip = "";
String alignText = AppLocalizations.of(context)!.ar_acquiring_heading;

if (deltaDeg != null) {
  final absD = deltaDeg.abs();
  if (absD <= 8) {
    directionTip = AppLocalizations.of(context)!.ar_correct_direction;
  } else if (deltaDeg > 0) {
    directionTip = AppLocalizations.of(context)!.ar_turn_left;
  } else {
    directionTip = AppLocalizations.of(context)!.ar_turn_right;
  }
}

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
            // خلفية الكاميرا
            Positioned.fill(child: CameraPreview(_camera!)),

            // السهم في الوسط
            if (deltaDeg != null)
              Center(
                child: Transform.rotate(
                  angle: deltaDeg * pi / 180.0 * -1, // عكس لاتجاه الدوران
child: Icon(
  Icons.navigation,
  size: 120,
  color: (deltaDeg!.abs() < 8) ? Colors.greenAccent : Colors.orangeAccent,
),
                ),
              ),

            // معلومات صغيرة أعلى الشاشة
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54, borderRadius: BorderRadius.circular(12)),
child: Text(
  alignText,
  style: const TextStyle(color: Colors.white),
),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    )
                  ],
                ),
              ),
            ),
            // شارة “اتجه يسارًا/يمينًا/الاتجاه صحيح”
if (directionTip.isNotEmpty)
  Positioned(
    bottom: 120,
    left: 0,
    right: 0,
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          directionTip,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    ),
  ),

        ],
      ),
    );
  }
}

double headingDelta(double heading, double bearing) {
  // نتيجة بالنطاق [-180, +180]
  double d = (bearing - heading + 540) % 360 - 180;
  return d;
}
