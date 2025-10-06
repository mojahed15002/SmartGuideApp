import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'theme_toggle_button.dart';
import 'theme_notifier.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'welcome_page.dart';
import 'package:firebase_auth/firebase_auth.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyAppWrapper());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

    @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart City Guide',
      home: LoginPage(themeNotifier: ThemeNotifier()),
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
    //  نقلنا تعريف الماب لداخل build
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
                    hintText: "ابحث عن منطقة أو شارع...",
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



/// صفحات الشوارع
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
                    destination: latlng.LatLng(32.226938, 35.222279),
                    themeNotifier: widget.themeNotifier,
                      enableTap: false, // 🚫 تعطيل النقر على الخريطة + إخفاء التلميح
                      enableLiveTracking: true, // ✅ تتبع حي للموقع
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
                     enableTap: false, // 🚫 تعطيل النقر على الخريطة + إخفاء التلميح
                     enableLiveTracking: true, // ✅ تتبع حي للموقع
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
                     enableTap: false, // 🚫 تعطيل النقر على الخريطة + إخفاء التلميح
                     enableLiveTracking: true, // ✅ تتبع حي للموقع
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
                     enableTap: false, // 🚫 تعطيل النقر على الخريطة + إخفاء التلميح
                     enableLiveTracking: true, // ✅ تتبع حي للموقع
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
                    destination: latlng.LatLng(32.221378, 35.259687),
                    themeNotifier: widget.themeNotifier,
                     enableTap: false, // 🚫 تعطيل النقر على الخريطة + إخفاء التلميح
                     enableLiveTracking: true, // ✅ تتبع حي للموقع
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

// أماكن داخل كل مدينة
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
    // 🔹 الماب موجود جوّا build (مع إضافات heroTag لكل مكان)
    final Map<String, List<Map<String, dynamic>>> cityPlacesPages = {
      "نابلس": [
        {
          "title": "البلدة القديمة",
          "images": ["assets/images/oldcity.jpg", "assets/images/oldcity2.jpg"],
          "hero": "nablus_oldcity",
          "page": PlaceDetailsPage(
            title: "البلدة القديمة",
            cityName: "نابلس",
            images: ["assets/images/oldcity.jpg", "assets/images/oldcity2.jpg"],
            url: "https://example.com/oldcity",
            themeNotifier: themeNotifier,
            heroTag: "nablus_oldcity",
          ),
        },
        {
          "title": "جبل جرزيم",
          "images": ["assets/images/gerizim.jpg", "assets/images/gerizim2.jpg"],
          "hero": "nablus_gerizim",
          "page": PlaceDetailsPage(
            title: "جبل جرزيم",
            cityName: "نابلس",
            images: ["assets/images/gerizim.jpg", "assets/images/gerizim2.jpg"],
            url: "https://example.com/gerizim",
            themeNotifier: themeNotifier,
            heroTag: "nablus_gerizim",
          ),
        },
      ],
      "رام الله": [
        {
          "title": "دوار المنارة",
          "images": ["assets/images/manara.jpg", "assets/images/manara2.jpg"],
          "hero": "ramallah_manara",
          "page": PlaceDetailsPage(
            title: "دوار المنارة",
            cityName: "رام الله",
            images: ["assets/images/manara.jpg", "assets/images/manara2.jpg"],
            url: "https://example.com/manara",
            themeNotifier: themeNotifier,
            heroTag: "ramallah_manara",
          ),
        },
        {
          "title": "متحف ياسر عرفات",
          "images": [
            "assets/images/arafat.jpg",
            "assets/images/arafat2.jpg",
            "assets/images/arafat3.jpg"
          ],
          "hero": "ramallah_arafat",
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
            heroTag: "ramallah_arafat",
          ),
        },
      ],
      "جنين": [
        {
          "title": "كنيسة برقين",
          "images": ["assets/images/burqin.jpg", "assets/images/burqin2.jpg"],
          "hero": "jenin_burqin",
          "page": PlaceDetailsPage(
            title: "كنيسة برقين",
            cityName: "جنين",
            images: ["assets/images/burqin.jpg", "assets/images/burqin2.jpg"],
            url: "https://example.com/burqin",
            themeNotifier: themeNotifier,
            heroTag: "jenin_burqin",
          ),
        },
        {
          "title": "سهل مرج ابن عامر",
          "images": ["assets/images/marj.jpg", "assets/images/marj2.jpg"],
          "hero": "jenin_marj",
          "page": PlaceDetailsPage(
            title: "سهل مرج ابن عامر",
            cityName: "جنين",
            images: ["assets/images/marj.jpg", "assets/images/marj2.jpg"],
            url: "https://example.com/marj",
            themeNotifier: themeNotifier,
            heroTag: "jenin_marj",
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
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: places.length <= 3
            // ✅ عرض كقائمة (كروت بعرض الشاشة)
            ? ListView.builder(
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final placeData = places[index];
                  final String title = placeData["title"];
                  final List<String> images = List<String>.from(placeData["images"]);
                  final String heroTag = placeData["hero"] ?? "${cityName}_$title";

                  // staggered animation for each item
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 300 + index * 120),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => placeData["page"]),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: Hero(
                                tag: heroTag,
                                child: Image.asset(
                                  images.first,
                                  fit: BoxFit.cover,
                                  height: 200,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
            // ✅ عرض كـ Grid
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // عمودين
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3 / 4, // نسبة العرض للارتفاع
                ),
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final placeData = places[index];
                  final String title = placeData["title"];
                  final List<String> images = List<String>.from(placeData["images"]);
                  final String heroTag = placeData["hero"] ?? "${cityName}_$title";

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 300 + index * 100),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => placeData["page"]),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: Hero(
                                  tag: heroTag,
                                  child: Image.asset(
                                    images.first, // 👈 أول صورة فقط للعرض
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}


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



/// صفحة الخريطة (محدثة مع ميزات التحكم الكامل)
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
    // ✅ تفعيل تتبع حي للموقع
  if (widget.enableLiveTracking) {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    ).listen((Position pos) {
      final newPos = latlng.LatLng(pos.latitude, pos.longitude);
      setState(() {
        widget.position.latitude == pos.latitude;
        widget.position.longitude == pos.longitude;
      });
      // تحريك الكاميرا على الموقع الجديد
      _mapController.move(newPos, _mapController.camera.zoom);
    });
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

  String _getUrlTemplate() {
    switch (_currentStyle) {
      case "satellite":
        return "https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=EvrUD11e3k8dXq0KBsyK";
      case "hybrid":
        return "https://api.maptiler.com/maps/hybrid/{z}/{x}/{y}.jpg?key=EvrUD11e3k8dXq0KBsyK";
      default:
        return "https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=EvrUD11e3k8dXq0KBsyK";
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
    // ignore: unnecessary_brace_in_string_interps
    if (hours > 0) return "${hours} س ${minutes} د";
    // ignore: unnecessary_brace_in_string_interps
    if (minutes > 0) return "${minutes} د ${secs} ث";
    // ignore: unnecessary_brace_in_string_interps
    return "${secs} ث";
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

      // ✅ زر يعيد تمركز الخريطة فعليًا (يُخفي تلقائيًا إذا الصفحة غير تفاعلية)
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

          /// عرض الملخص (المسافة/الزمن)
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

          /// الخريطة
          Expanded(
            child: Stack(
              children: [
                fm.FlutterMap(
                  mapController: _mapController,
                  options: fm.MapOptions(
                    // ignore: deprecated_member_use
                    center: userLocation,
                    // ignore: deprecated_member_use
                    zoom: 14,
                    onTap: widget.enableTap
                        ? (tapPosition, point) {
                            setState(() {
                              _destination = point;
                              _error = null;
                            });
                            _getRoute(point);
                          }
                        : null, // ❌ تعطيل النقر إذا enableTap = false
                  ),
                  children: [
                    fm.TileLayer(
                      urlTemplate: _getUrlTemplate(),
                      userAgentPackageName:
                          'com.example.smartguideapp', // عدل لو مشروعك له اسم آخر
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

                // ✅ التلميح يظهر فقط عندما enableTap = true
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
}


/// صفحة تفاصيل الأماكن (Carousel)
class PlaceDetailsPage extends StatefulWidget {
  final String title;
  final String cityName;
  final List<String> images;
  final String url;
  final ThemeNotifier themeNotifier;
  final String heroTag; // جديد: تاج الـ Hero

  const PlaceDetailsPage({
    super.key,
    required this.title,
    required this.cityName,
    required this.images,
    required this.url,
    required this.themeNotifier,
    required this.heroTag,
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

                // الصورة داخل الـ Hero عندما تكون الصورة الأولى (أو يمكنك تعديل الشرط إن أردت)
                Widget imageWidget = Image.asset(
                  imgPath,
                  fit: BoxFit.cover,
                  width: screenWidth,
                );

                if (index == 0) {
                  imageWidget = Hero(
                    tag: widget.heroTag,
                    child: imageWidget,
                  );
                }

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
                      child: imageWidget,
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
                heroAttributes: PhotoViewHeroAttributes(
                  tag: "gallery_${images[index]}", // 👈 tag فريد للصورة
                ),
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

class MyAppWrapperBackup1 extends StatelessWidget {
  final ThemeNotifier themeNotifier = ThemeNotifier();

  MyAppWrapperBackup1({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Smart City Guide',
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
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasData) {
                return WelcomePage(themeNotifier: themeNotifier);
              }
              return LoginPage(themeNotifier: themeNotifier);
            },
          ),
        );
      },
    );
  }
}
