import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlng;
import '../theme_notifier.dart';
import 'map_page.dart';
import '../l10n/gen/app_localizations.dart';
import 'place_details_page.dart';

class NearbyPlacesListPage extends StatefulWidget {
  final String category;       // restaurant, cafe, ...
  final String categoryLabel;  // النص المعروض
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
bool _isSearching = false;
String _searchQuery = "";
final TextEditingController _searchController = TextEditingController();

  // نحفظ «كل» النتائج هنا مرة واحدة، ثم نفلتر محليًا حسب نصف القطر
  List<_PlaceItem> _allItems = [];
  List<_PlaceItem> _items = [];

  // نصف القطر المتحرّك (كم)
  double _radiusKm = 5.0; // القيمة الافتراضية

  // حدود المنزلق
  static const double _minKm = 1.0;
  static const double _maxKm = 15.0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // 1) إذن الموقع + الإحداثيات الحالية
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() {
_error = AppLocalizations.of(context)!.locationPermissionDenied;
          _loading = false;
        });
        return;
      }

      _pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 2) جلب أماكن الفئة من Firestore
      final snap = await FirebaseFirestore.instance
          .collection('places')
          .where('categories', arrayContains: widget.category)
          .get();

      final userLL = latlng.LatLng(_pos!.latitude, _pos!.longitude);

      final temp = <_PlaceItem>[];
      for (final d in snap.docs) {
        final data = d.data();
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
final isArabic = AppLocalizations.of(context)!.localeName == 'ar';

final name = isArabic
    ? (data['title_ar'] ?? data['title_en'] ?? AppLocalizations.of(context)!.unnamedPlace)
    : (data['title_en'] ?? data['title_ar'] ?? AppLocalizations.of(context)!.unnamedPlace);

        if (lat == null || lng == null) continue;

        final pll = latlng.LatLng(lat, lng);
        final meters = _distance(userLL, pll);

temp.add(
  _PlaceItem(
    id: d.id,
    name: name,
    latLng: pll,
    meters: meters,
    images: (data['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    url: data['url'] ?? "",
    cityName: isArabic ? (data['city_ar'] ?? "") : (data['city_en'] ?? ""),
  ),
);
      }

      // نخزّن الكل، ونرتبهم، ثم نطبّق فلترة نصف القطر
      temp.sort((a, b) => a.meters.compareTo(b.meters));

      setState(() {
        _allItems = temp;
        _applyRadiusFilter(); // يملأ _items من _allItems حسب _radiusKm
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "تعذر تحميل الأماكن: $e";
        _loading = false;
      });
    }
  }

void _applyRadiusFilter() {
  final kmLimit = _radiusKm;

  _items = _allItems.where((it) {
    final inRadius = (it.meters / 1000.0) <= kmLimit;

    final matchSearch = _searchQuery.isEmpty
        ? true
        : it.name.toLowerCase().contains(_searchQuery);

    return inRadius && matchSearch;
  }).toList();

  setState(() {});
}


  String _fmtDistance(double meters) {
    if (meters >= 1000) return "${(meters / 1000).toStringAsFixed(2)} كم";
    return "${meters.toStringAsFixed(0)} م";
  }

  // تقدير سريع للوقت (بدون API خارجي)
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
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
appBar: AppBar(
  title: _isSearching
      ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchHint,
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
              _applyRadiusFilter(); // مع فلترة البحث
            });
          },
        )
      : Text(widget.categoryLabel),

  leading: IconButton(
    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
    onPressed: () => Navigator.pop(context),
  ),

  actions: [
    if (_isSearching)
      IconButton(
        icon: Icon(Icons.close),
        onPressed: () {
          setState(() {
            _isSearching = false;
            _searchQuery = "";
            _searchController.clear();
            _applyRadiusFilter();
          });
        },
      )
    else
      IconButton(
        icon: Icon(Icons.search),
        onPressed: () {
          setState(() {
            _isSearching = true;
          });
        },
      ),
  ],
),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, textAlign: TextAlign.center))
              : Column(
                  children: [
                    // ===== شريط التحكم بالمسافة =====
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: Row(
                        children: [
                          const Icon(Icons.near_me, color: Colors.orange),
                          const SizedBox(width: 8),
Text(
  "${loc.searchRadius}: ${_radiusKm.toStringAsFixed(0)} ${loc.km}",
  style: const TextStyle(fontWeight: FontWeight.w600),
),
                          const Spacer(),
                          // زر إعادة تعيين سريع إلى 5كم
                          TextButton.icon(
                            onPressed: () {
                              setState(() => _radiusKm = 5.0);
                              _applyRadiusFilter();
                            },
                            icon: const Icon(Icons.refresh),
label: Text(loc.reset),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Slider(
                        value: _radiusKm,
                        min: _minKm,
                        max: _maxKm,
                        divisions: (_maxKm - _minKm).round(),
                        label: "${_radiusKm.toStringAsFixed(0)} ${loc.km}",
                        onChanged: (v) {
                          setState(() => _radiusKm = v);
                          _applyRadiusFilter();
                        },
                        activeColor: Colors.orange,
                        inactiveColor: Colors.orange.withOpacity(0.2),
                      ),
                    ),

                    // ===== قائمة النتائج =====
                    Expanded(
                      child: _items.isEmpty
                          ? Center(child: Text(loc.noNearbyPlaces))
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final it = _items[i];
return InkWell(
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PlaceDetailsPage(
        id: it.id,
        title: it.name,
        cityName: it.cityName,
        images: it.images,
        url: it.url,
        themeNotifier: widget.themeNotifier,
        heroTag: it.id,
      ),
    ),
  );
},

  child: Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: (it.images.isNotEmpty)
                ? Image.asset(
                    it.images.first,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  )
                : Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  it.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),

                Row(
                  children: [
                    Icon(Icons.place, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(_fmtDistance(it.meters)),
                    const SizedBox(width: 10),
                    Icon(Icons.directions_walk, size: 16, color: Colors.green),
                    Text(" ${_fmtEta(it.meters, walking: true)}"),
                    const SizedBox(width: 10),
                    Icon(Icons.directions_car, size: 16, color: Colors.blue),
                    Text(" ${_fmtEta(it.meters, walking: false)}"),
                  ],
                ),
              ],
            ),
          ),
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.orange,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  child: const Icon(Icons.map, color: Colors.white),
  onPressed: () {
    Navigator.push(
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
            altitudeAccuracy: _pos!.altitudeAccuracy,
            headingAccuracy: _pos!.headingAccuracy,
          ),
          destination: it.latLng,
          enableTap: false,
          enableLiveTracking: false,
          themeNotifier: widget.themeNotifier,
            // ✅ نمرر بيانات المكان للخريطة
  placeInfo: {
    'id': it.id,
    'name': it.name,
    'city': it.cityName,
    'images': it.images,
    'url': it.url,
  },

        ),
      ),
    );
  },
)

        ],
      ),
    ),
  ),
);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _PlaceItem {
  final String id;
  final String name;
  final latlng.LatLng latLng;
  final double meters;
  final List<String> images;
  final String url;
  final String cityName;

  _PlaceItem({
    required this.id,
    required this.name,
    required this.latLng,
    required this.meters,
        required this.images,
    required this.url,
    required this.cityName,

  });
}
