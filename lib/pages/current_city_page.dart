import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:flutter_map/flutter_map.dart';
import 'package:just_audio/just_audio.dart';
import 'package:geolocator/geolocator.dart';
import '../theme_notifier.dart';
import 'map_page.dart';

class CurrentCityPage extends StatefulWidget {
  final String cityName;
  final ThemeNotifier themeNotifier;

  const CurrentCityPage({
    super.key,
    required this.cityName,
    required this.themeNotifier,
  });

  @override
  State<CurrentCityPage> createState() => _CurrentCityPageState();
}

class _CurrentCityPageState extends State<CurrentCityPage>
    with TickerProviderStateMixin {
  latlng.LatLng? _cityCenter;
  String? _geoError;

  late final AudioPlayer _player;
  bool _audioLoading = false;

  late final AnimationController _cardsAnim; // أنيميشن للكروت

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _cardsAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      lowerBound: 0.96,
      upperBound: 1.0,
    )..forward();
    _resolveCityCenter();
  }

  @override
  void dispose() {
    _player.dispose();
    _cardsAnim.dispose();
    super.dispose();
  }

  Future<void> _resolveCityCenter() async {
    try {
      final list = await locationFromAddress(widget.cityName);
      if (list.isNotEmpty) {
        setState(() {
          _cityCenter = latlng.LatLng(list.first.latitude, list.first.longitude);
          _geoError = null;
        });
      } else {
        setState(() => _geoError = "تعذّر تحديد إحداثيات المدينة");
      }
    } catch (e) {
      setState(() => _geoError = "خطأ في تحديد الموقع: $e");
    }
  }

  Future<void> _playGuide(String url) async {
    try {
      setState(() => _audioLoading = true);
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("تعذّر تشغيل الدليل السمعي: $e")),
      );
    } finally {
      if (mounted) setState(() => _audioLoading = false);
    }
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          t,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );

  // بطاقة صغيرة بظل خفيف + أنيميشن Scale
  Widget _cardShell({required Widget child, EdgeInsets? margin, VoidCallback? onTap}) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _cardsAnim, curve: Curves.easeOutBack),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: margin ?? const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.orange.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _eventsStrip() {
    return SizedBox(
      height: 112,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .where('city', isEqualTo: widget.cityName)
            .orderBy('date', descending: false)
            .limit(10)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return _cardShell(
              child: const Center(child: Text("لا توجد فعاليات اليوم")),
            );
          }
          final items = snap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (_, i) {
              final it = items[i];
              final title = (it['title'] ?? 'فعالية').toString();
              final place = (it['place'] ?? '').toString();
              final time  = (it['time'] ?? '').toString(); // نص مختصر
              return _cardShell(
                child: SizedBox(
                  width: 250,
                  child: Text("🎉 $title\n📍 $place\n🕒 $time",
                      style: const TextStyle(fontSize: 16)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _bestPlacesStrip() {
    return SizedBox(
      height: 112,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('best_places')
            .where('city', isEqualTo: widget.cityName)
            .orderBy('rating', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return _cardShell(
              child: const Center(child: Text("لا توجد أماكن مميزة بعد")),
            );
          }
          final items = snap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (_, i) {
              final it = items[i];
              final name = (it['name'] ?? '').toString();
              final rating = (it['rating'] ?? 0).toString();
              return _cardShell(
                onTap: () {
                  // لاحقاً: افتح PlaceDetailsPage إذا عندك id
                },
                child: SizedBox(
                  width: 220,
                  child: Text("🏆 $name — ⭐ $rating",
                      style: const TextStyle(fontSize: 16)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _foodsStrip() {
    return SizedBox(
      height: 120,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('foods')
            .where('city', isEqualTo: widget.cityName)
            .limit(10)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return _cardShell(
              child: const Center(child: Text("لا توجد أطباق مسجلة")),
            );
          }
          final items = snap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (_, i) {
              final it = items[i];
              final title = (it['title'] ?? 'طبق').toString();
              final img   = (it['image'] ?? '').toString(); // URL أو Asset
              return Container(
                margin: const EdgeInsets.only(right: 10),
                width: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  image: img.isNotEmpty
                      ? DecorationImage(image: NetworkImage(img), fit: BoxFit.cover)
                      : null,
                  color: Colors.orange.shade50,
                ),
                child: img.isEmpty
                    ? _cardShell(child: Center(child: Text(title)))
                    : Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                          ),
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _audioGuideCard() {
    // خزّن رابط الصوت في Firestore: collection "city_audio_guides" وثّيقة تحتوي { city, url }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('city_audio_guides')
          .where('city', isEqualTo: widget.cityName)
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        String? url;
        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          final data = snap.data!.docs.first.data() as Map<String, dynamic>;
          url = data['url']?.toString();
        }
        return _cardShell(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.headphones, color: Colors.orange),
              const SizedBox(width: 10),
              const Expanded(
                child: Text("🎧 دليل سمعي للمدينة — استمع لنبذة سريعة"),
              ),
              if (_audioLoading)
                const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.play_circle_fill, color: Colors.orange),
                  onPressed: (url != null && url!.isNotEmpty) 
    ? () => _playGuide(url!) 
    : null,

                ),
              IconButton(
                icon: const Icon(Icons.stop_circle, color: Colors.redAccent),
                onPressed: () => _player.stop(),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _embeddedMap() {
    if (_cityCenter == null) {
      if (_geoError != null) return Text(_geoError!);
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 180,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: _cityCenter!,
            initialZoom: 12.5,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: 'smart.city.guide',
            ),
            MarkerLayer(markers: [
              Marker(
                point: _cityCenter!,
                width: 40,
                height: 40,
                child: const Icon(Icons.location_on, size: 40, color: Colors.redAccent),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final city = widget.cityName;

    return Scaffold(
      appBar: AppBar(
        title: Text(
    (widget.cityName != null && widget.cityName != "غير معروف" && widget.cityName != "—")
        ? widget.cityName
        : "المدينة الحالية",
  ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color.fromARGB(255, 130, 130, 130),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // صورة رأسية (يمكن لاحقاً تغييرها بحسب المدينة)
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              image: const DecorationImage(
                image: AssetImage("assets/images/city_default.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // معلومات سريعة
          _sectionTitle("ℹ️ لمحة عن المدينة"),
          _cardShell(
            margin: const EdgeInsets.only(bottom: 12, right: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("• مدينة حيوية ومراكز تسوق ومطاعم مميزة."),
                SizedBox(height: 6),
                Text("• استخدم هذه الصفحة لاكتشاف الفعاليات والأماكن الشهيرة."),
              ],
            ),
          ),

          // خريطة مدمجة
          _sectionTitle("🗺️ خريطة المدينة"),
          _embeddedMap(),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.map),
            label: const Text("افتح الخريطة"),
            onPressed: _cityCenter == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapPage(
                          position: // تحويل LatLng إلى Position “تقريبي”
                              // إذا بدك دقة كاملة مرّر Position من خارج الصفحة
                              // لكن هنا نستخدم قيم تقريبية بدون سرعة/دقة
                              GeocodingPositionAdapter.toPosition(_cityCenter!),
                          themeNotifier: widget.themeNotifier,
                          enableLiveTracking: false,
                        ),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          const SizedBox(height: 18),
          _sectionTitle("🎉 فعاليات اليوم"),
          _eventsStrip(),

          const SizedBox(height: 18),
          _sectionTitle("🏆 أفضل الأماكن"),
          _bestPlacesStrip(),

          const SizedBox(height: 18),
          _sectionTitle("🍽️ أشهر الأكلات"),
          _foodsStrip(),

          const SizedBox(height: 18),
          _sectionTitle("🎧 دليل سمعي"),
          _audioGuideCard(),
        ],
      ),
    );
  }
}

/// مُحوِّل بسيط من LatLng إلى Position يناسب MapPage لديك.
class GeocodingPositionAdapter {
  static Position toPosition(latlng.LatLng p) {
    return Position(
      latitude: p.latitude,
      longitude: p.longitude,
      timestamp: DateTime.now(),
      accuracy: 30,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }
}
