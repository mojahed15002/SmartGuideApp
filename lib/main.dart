import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'theme_toggle_button.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyAppWrapper());
}

// ThemeNotifier لإدارة الوضع الليلي / النهاري
class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light);

  void toggleTheme() {
    value = value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}

// Wrapper لتطبيق MaterialApp مع ValueListenableBuilder
class MyAppWrapper extends StatelessWidget {
  final ThemeNotifier themeNotifier = ThemeNotifier();

  MyAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Smart City Guide',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.orange,
            fontFamily: "Roboto",
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.orange,
            fontFamily: "Roboto",
            brightness: Brightness.dark,
          ),
          themeMode: themeMode,
          home: WelcomePage(themeNotifier: themeNotifier),
        );
      },
    );
  }
}

//
// صفحة 1: الترحيب
//
class WelcomePage extends StatelessWidget {
  final ThemeNotifier themeNotifier;

  const WelcomePage({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          ThemeToggleButton(themeNotifier: themeNotifier), // 🔥 زر التبديل الجديد
        ],
      ),

      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              " مرحباً بك في مرشدك السياحي الخاص👋",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChoicePage(themeNotifier: themeNotifier)),
                );
              },
              child: const Text("انطلق😎"),
            ),
          ],
        ),
      ),
    );
  }
}

/// صفحة 2: البحث أو "أين أنا؟"
///
class ChoicePage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const ChoicePage({super.key, required this.themeNotifier});

  @override
  State<ChoicePage> createState() => _ChoicePageState();
}

class _ChoicePageState extends State<ChoicePage> {
  @override
  Widget build(BuildContext context) {
    // 🔹 نقلنا تعريف الماب لداخل build
    final Map<String, Widget Function()> placePages = {
      "شارع الأكاديمية": () => AcademyStreetPage(themeNotifier: widget.themeNotifier),
      "شارع سفيان": () => SofianStreetPage(themeNotifier: widget.themeNotifier),
      "شارع فيصل": () => FaisalStreetPage(themeNotifier: widget.themeNotifier),
      "دوار الشهداء": () => MartyrsRoundaboutPage(themeNotifier: widget.themeNotifier),
      "شارع فلسطين": () => PalestineStreetPage(themeNotifier: widget.themeNotifier),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("اختيار الموقع"),
        actions: [
          ThemeToggleButton(themeNotifier: widget.themeNotifier), // ✅ زر التبديل
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return placePages.keys.where((String option) {
                  return option.contains(textEditingValue.text);
                });
              },
              onSelected: (String selection) {
                final pageBuilder = placePages[selection];
                if (pageBuilder != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => pageBuilder()),
                  );
                }
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onEditingComplete) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  decoration: const InputDecoration(
                    hintText: "ابحث عن المنطقة...",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.search, color: Colors.orange),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              onPressed: () async {
                Position position = await _determinePosition();
                Navigator.push(
                  // ignore: use_build_context_synchronously
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MapPage(position: position, themeNotifier: widget.themeNotifier), // ✅ مررنا themeNotifier
                  ),
                );
              },
              child: const Text("أين أنا؟ 📍"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GeneralInfoPage(themeNotifier: widget.themeNotifier),
                  ),
                );
              },
              child: const Text("عرض جميع المدن 🏙️"),
            ),
          ],
        ),
      ),
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw Exception("خدمة الموقع غير مفعلة");
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("تم رفض إذن الموقع");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("تم رفض إذن الموقع بشكل دائم");
    }

    return await Geolocator.getCurrentPosition();
  }
}

///
/// صفحات الأماكن الفردية
class AcademyStreetPage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const AcademyStreetPage({super.key, required this.themeNotifier});

  @override
  State<AcademyStreetPage> createState() => _AcademyStreetPageState();
}

class _AcademyStreetPageState extends State<AcademyStreetPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: InfoPage(
              title: "شارع الأكاديمية",
              description: "وصف شارع الأكاديمية...",
              images:  ["assets/images/academy.jpg", "assets/images/academy2.jpg"],
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
                    themeNotifier: widget.themeNotifier,
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

class SofianStreetPage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const SofianStreetPage({super.key, required this.themeNotifier});

  @override
  State<SofianStreetPage> createState() => _SofianStreetPageState();
}

class _SofianStreetPageState extends State<SofianStreetPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
           Expanded(
            child: InfoPage(
              title: "شارع سفيان",
              description: "شارع سفيان يعتبر من الشوارع الحيوية...",
              images: ["assets/images/sofian.jpg", "assets/images/sofian2.jpg"],
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
                    destination: latlng.LatLng(32.222376, 35.260532),
                    themeNotifier: widget.themeNotifier,
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


class FaisalStreetPage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const FaisalStreetPage({super.key, required this.themeNotifier});

  @override
  State<FaisalStreetPage> createState() => _FaisalStreetPageState();
}

class _FaisalStreetPageState extends State<FaisalStreetPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
           Expanded(
            child: InfoPage(
              title: "شارع فيصل",
              description: "وصف شارع فيصل...",
              images: ["assets/images/faisal.jpg", "assets/images/faisal2.jpg"],
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
                    destination: latlng.LatLng(32.222243, 35.262778),
                    themeNotifier: widget.themeNotifier,
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


class MartyrsRoundaboutPage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const MartyrsRoundaboutPage({super.key, required this.themeNotifier});

  @override
  State<MartyrsRoundaboutPage> createState() => _MartyrsRoundaboutPageState();
}

class _MartyrsRoundaboutPageState extends State<MartyrsRoundaboutPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
           Expanded(
            child: InfoPage(
              title: "دوار الشهداء",
              description: "دوار الشهداء يُعتبر من المعالم المركزية في مدينة نابلس...",
              images: ["assets/images/martyrs.jpg", "assets/images/martyrs2.jpg"],
              themeNotifier: widget.themeNotifier,
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final position = await Geolocator.getCurrentPosition();
              if (!mounted) return; // الآن هذا الشرط صحيح لأنه داخل State
              Navigator.push(
                // ignore: use_build_context_synchronously
                context,
                MaterialPageRoute(
                  builder: (_) => MapPage(
                    position: position,
                    destination: latlng.LatLng(32.221119, 35.260817),
                    themeNotifier: widget.themeNotifier,
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
                    themeNotifier: widget.themeNotifier,
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
class GeneralInfoPage extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  const GeneralInfoPage({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    final cities = ["نابلس", "رام الله", "جنين"];

    return Scaffold(
      appBar: AppBar(
        title: const Text("المدن"),
        actions: [
          ThemeToggleButton(themeNotifier: themeNotifier), // 🔥 زر التبديل الجديد
        ],
      ),
      body: ListView(
        children: cities.map((city) {
          return ListTile(
            title: Text(city),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.orange),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CityPlacesPage(cityName: city, themeNotifier: themeNotifier),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

//
// أماكن داخل المدينة
//
class CityPlacesPage extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  final String cityName;

  const CityPlacesPage({
    super.key,
    required this.cityName,
    required this.themeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    // 🔹 الماب صار جوّا build
    final Map<String, List<Map<String, dynamic>>> cityPlacesPages = {
      "نابلس": [
        {
          "title": "البلدة القديمة",
          "page": PlaceDetailsPage(
            title: "البلدة القديمة",
            cityName: "نابلس",
            images: ["assets/images/oldcity.jpg", "assets/images/oldcity2.jpg"],
            url: "https://example.com/oldcity",
            themeNotifier: themeNotifier,
          ),
        },
        {
          "title": "جبل جرزيم",
          "page": PlaceDetailsPage(
            title: "جبل جرزيم",
            cityName: "نابلس",
            images: ["assets/images/gerizim.jpg", "assets/images/gerizim2.jpg"],
            url: "https://example.com/gerizim",
            themeNotifier: themeNotifier,
          ),
        },
      ],
      "رام الله": [
        {
          "title": "دوار المنارة",
          "page": PlaceDetailsPage(
            title: "دوار المنارة",
            cityName: "رام الله",
            images: ["assets/images/manara.jpg", "assets/images/manara2.jpg"],
            url: "https://example.com/manara",
            themeNotifier: themeNotifier,
          ),
        },
        {
          "title": "متحف ياسر عرفات",
          "page": PlaceDetailsPage(
            title: "متحف ياسر عرفات",
            cityName: "رام الله",
            images: [
              "assets/images/arafat.jpg",
              "assets/images/arafat2.jpg",
              "assets/images/arafat3.jpg"
            ],
            url: "https://example.com/arafat",
            themeNotifier: themeNotifier,
          ),
        },
      ],
      "جنين": [
        {
          "title": "كنيسة برقين",
          "page": PlaceDetailsPage(
            title: "كنيسة برقين",
            cityName: "جنين",
            images: ["assets/images/burqin.jpg", "assets/images/burqin2.jpg"],
            url: "https://example.com/burqin",
            themeNotifier: themeNotifier,
          ),
        },
        {
          "title": "سهل مرج ابن عامر",
          "page": PlaceDetailsPage(
            title: "سهل مرج ابن عامر",
            cityName: "جنين",
            images: ["assets/images/marj.jpg", "assets/images/marj2.jpg"],
            url: "https://example.com/marj",
            themeNotifier: themeNotifier,
          ),
        },
      ],
    };

    final places = cityPlacesPages[cityName] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text("أماكن في $cityName"),
        actions: [
          ThemeToggleButton(themeNotifier: themeNotifier), // ✅ زر الوضع الليلي
        ],
      ),
      body: ListView(
        children: places.map((placeData) {
          return ListTile(
            title: Text(placeData["title"]),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.orange),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => placeData["page"]),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

//
// صفحة المعلومات العامة (Carousel)
//
class InfoPage extends StatefulWidget {
  final String title;
  final String description;
  final List<String> images;
  final ThemeNotifier themeNotifier;

  const InfoPage({
    super.key,
    required this.title,
    required this.description,
    required this.images,
    required this.themeNotifier,
  });

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          ThemeToggleButton(themeNotifier: widget.themeNotifier),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Text(widget.description, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),

            // Carousel Slider مع السحب + Fullscreen/Zoom
            CarouselSlider.builder(
              itemCount: widget.images.length,
              itemBuilder: (context, index, realIndex) {
                final imgPath = widget.images[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenGallery(
                          images: widget.images,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: kIsWeb ? 16 / 9 : 4 / 3,
                      child: Image.asset(
                        imgPath,
                        fit: BoxFit.cover,
                        width: screenWidth,
                      ),
                    ),
                  ),
                );
              },
              options: CarouselOptions(
                height: kIsWeb ? 400 : 250,
                enlargeCenterPage: true,
                enableInfiniteScroll: true,
                viewportFraction: 0.9,
                onPageChanged: (index, reason) {
                  setState(() => _activeIndex = index);
                },
              ),
            ),

            const SizedBox(height: 12),

            // Dots Indicator
            Center(
              child: AnimatedSmoothIndicator(
                activeIndex: _activeIndex,
                count: widget.images.length,
                effect: ExpandingDotsEffect(
                  dotHeight: 10,
                  dotWidth: 10,
                  activeDotColor: Colors.orange,
                  dotColor: Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



/// صفحة الخريطة
class MapPage extends StatefulWidget {
  /// الموقع الحالي للمستخدم
  final Position position;
  final ThemeNotifier themeNotifier;
  /// الوجهة (اختيارية)
  final latlng.LatLng? destination;

  const MapPage({
    super.key,
    required this.position,
    required this.themeNotifier,
    this.destination,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<latlng.LatLng> routePoints = [];
  bool _loading = true;
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

  @override
  void initState() {
    super.initState();
    if (widget.destination != null) {
      _getRoute(widget.destination!);
    } else {
      _loading = false;
    }
  }

  Future<void> _getRoute(latlng.LatLng destination) async {
    setState(() {
      _loading = true;
      _error = null;
      routePoints = [];
    });

    const apiKey =
        "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjVlZTQ1YWY4YjIzMDQxYmZiZjUzNDhmZjhhOTU5MTc5IiwiaCI6Im11cm11cjY0In0=";

    final start = "${widget.position.longitude},${widget.position.latitude}";
    final end = "${destination.longitude},${destination.latitude}";

    final url = Uri.parse(
      "https://api.openrouteservice.org/v2/directions/$_selectedMode?start=$start&end=$end",
    );

    final response = await http.get(url, headers: {
      'Authorization': apiKey,
      'Accept': 'application/json, application/geo+json'
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final coords = data["features"][0]["geometry"]["coordinates"] as List;

      setState(() {
        routePoints = coords
            .map((c) => latlng.LatLng(
                (c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();
        _loading = false;
      });
    } else {
      setState(() {
        _error = "ORS error: ${response.statusCode}";
        _loading = false;
      });
    }
  }

  String _getUrlTemplate() {
    switch (_currentStyle) {
      case "satellite":
        return "https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=EvrUD11e3k8dXq0KBsyK";
      case "hybrid":
        return "https://api.maptiler.com/maps/hybrid/{z}/{x}/{y}.jpg?key=EvrUD11e3k8dXq0KBsyK";
      case "streets":
      default:
        return "https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=EvrUD11e3k8dXq0KBsyK";
    }
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
                child: Text("صورة فضائية"),
              ),
              PopupMenuItem(
                value: "hybrid",
                child: Text("مدمج"),
              ),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          /// Dropdown لاختيار وسيلة النقل
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
                if (value != null && widget.destination != null) {
                  setState(() {
                    _selectedMode = value;
                  });
                  _getRoute(widget.destination!);
                }
              },
            ),
          ),

          /// الخريطة
          Expanded(
            child: Stack(
              children: [
                fm.FlutterMap(
                  options: fm.MapOptions(
                    initialCenter: userLocation,
                    initialZoom: 14,
                  ),
                  children: [
                    fm.TileLayer(
                      urlTemplate: _getUrlTemplate(),
                      userAgentPackageName: 'com.example.flutter_application_1',
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
                        if (widget.destination != null)
                          fm.Marker(
                            point: widget.destination!,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// صفحة تفاصيل الأماكن (Carousel)
class PlaceDetailsPage extends StatefulWidget {
  final String title;
  final String cityName;
  final List<String> images;
  final String url;
  final ThemeNotifier themeNotifier;

  const PlaceDetailsPage({
    super.key,
    required this.title,
    required this.cityName,
    required this.images,
    required this.url,
    required this.themeNotifier,
  });

  @override
  State<PlaceDetailsPage> createState() => _PlaceDetailsPageState();
}

class _PlaceDetailsPageState extends State<PlaceDetailsPage> {
  int _activeIndex = 0;

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("تعذر فتح الرابط: $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text("تفاصيل ${widget.title}"),
        actions: [
          ThemeToggleButton(themeNotifier: widget.themeNotifier),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Text(
              "${widget.title} - ${widget.cityName}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Carousel Slider مع السحب + Fullscreen/Zoom
            CarouselSlider.builder(
              itemCount: widget.images.length,
              itemBuilder: (context, index, realIndex) {
                final imgPath = widget.images[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenGallery(
                          images: widget.images,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: kIsWeb ? 16 / 9 : 4 / 3,
                      child: Image.asset(
                        imgPath,
                        fit: BoxFit.cover,
                        width: screenWidth,
                      ),
                    ),
                  ),
                );
              },
              options: CarouselOptions(
                height: kIsWeb ? 400 : 250,
                enlargeCenterPage: true,
                enableInfiniteScroll: true,
                viewportFraction: 0.9,
                onPageChanged: (index, reason) {
                  setState(() => _activeIndex = index);
                },
              ),
            ),

            const SizedBox(height: 12),

            // Dots Indicator
            Center(
              child: AnimatedSmoothIndicator(
                activeIndex: _activeIndex,
                count: widget.images.length,
                effect: ExpandingDotsEffect(
                  dotHeight: 10,
                  dotWidth: 10,
                  activeDotColor: Colors.orange,
                  dotColor: Colors.grey.shade400,
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              "هذا وصف افتراضي لـ ${widget.title} في ${widget.cityName}. يمكنك تعديله لاحقًا.",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // الرابط
            InkWell(
              onTap: () => _launchURL(widget.url),
              child: Text(
                widget.url,
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenGallery extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenGallery({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            itemCount: images.length,
            pageController: PageController(initialPage: initialIndex),
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: AssetImage(images[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
              );
            },
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

