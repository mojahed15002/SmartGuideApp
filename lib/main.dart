import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const SmartGuideApp());
}

class SmartGuideApp extends StatelessWidget {
  const SmartGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart City Guide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.orange, fontFamily: "Roboto"),
      home: const WelcomePage(),
    );
  }
}

//
// صفحة 1: الترحيب
//
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "مرحباً بك 👋",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
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
                  MaterialPageRoute(builder: (context) => const ChoicePage()),
                );
              },
              child: const Text("ابدأ"),
            ),
          ],
        ),
      ),
    );
  }
}

//
// صفحة 2: البحث أو "أين أنا؟"
//
class ChoicePage extends StatefulWidget {
  const ChoicePage({super.key});

  @override
  State<ChoicePage> createState() => _ChoicePageState();
}

class _ChoicePageState extends State<ChoicePage> {
  final Map<String, Widget Function()> placePages = {
    "شارع الأكاديمية": () => const AcademyStreetPage(),
    "شارع سفيان": () => const SofianStreetPage(),
    "شارع فيصل": () => const FaisalStreetPage(),
    "دوار الشهداء": () => const MartyrsRoundaboutPage(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("اختيار الموقع")),
      backgroundColor: Colors.white,
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
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapPage(position: position),
                  ),
                );
              },
              child: const Text("أين أنا؟"),
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
                    builder: (context) => const GeneralInfoPage(),
                  ),
                );
              },
              child: const Text("عرض جميع المدن"),
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

//
// صفحات الأماكن الفردية
//
class AcademyStreetPage extends StatelessWidget {
  const AcademyStreetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoPage(
      title: "شارع الأكاديمية",
      description:
          '''سُمّي "شارع الأكاديمية" نسبةً إلى أكاديمية النجاح الوطنية (جامعة النجاح الوطنية – الحرم الجديد) التي تقع بمحاذاته.

الطابع العام:
- شارع حيوي خصوصًا في أوقات الدوام الجامعي.
- يحتوي على عدد كبير من المطاعم والمقاهي التي تخدم الطلبة.
- تنتشر فيه المكتبات، مراكز التصوير والطباعة، ومحلات القرطاسية.
- يوجد أيضًا محلات ملابس وأحذية ومستلزمات متنوعة.
''',
      imageUrl:
          "https://commons.wikimedia.org/wiki/Category:Images#/media/File:Alois_Mentasti.jpg",
    );
  }
}

class SofianStreetPage extends StatelessWidget {
  const SofianStreetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoPage(
      title: "شارع سفيان",
      description: "هذه صفحة خاصة بمعلومات شارع سفيان.",
      imageUrl:
          "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d5/%D7%A8%D7%9B%D7%A1_%D7%94%D7%A8_%D7%92%D7%A8%D7%99%D7%96%D7%99%D7%9D.jpg/1280px-%D7%A8%D7%9B%D7%A1_%D7%94%D7%A8_%D7%92%D7%A8%D7%99%D7%96%D7%99%D7%9D.jpg",
    );
  }
}

class FaisalStreetPage extends StatelessWidget {
  const FaisalStreetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoPage(
      title: "شارع فيصل",
      description: "هذه صفحة خاصة بمعلومات شارع فيصل.",
      imageUrl:
          "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d5/%D7%A8%D7%9B%D7%A1_%D7%94%D7%A8_%D7%92%D7%A8%D7%99%D7%96%D7%99%D7%9D.jpg/1280px-%D7%A8%D7%9B%D7%A1_%D7%94%D7%A8_%D7%92%D7%A8%D7%99%D7%96%D7%99%D7%9D.jpg",
    );
  }
}

class MartyrsRoundaboutPage extends StatelessWidget {
  const MartyrsRoundaboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoPage(
      title: "دوار الشهداء",
      description: "هذه صفحة خاصة بمعلومات دوار الشهداء.",
      imageUrl:
          "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d5/%D7%A8%D7%9B%D7%A1_%D7%94%D7%A8_%D7%92%D7%A8%D7%99%D7%96%D7%99%D7%9D.jpg/1280px-%D7%A8%D7%9B%D7%A1_%D7%94%D7%A8_%D7%92%D7%A8%D7%99%D7%96%D7%99%D7%9D.jpg",
    );
  }
}

//
// صفحة المدن
//
class GeneralInfoPage extends StatelessWidget {
  const GeneralInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cities = ["نابلس", "رام الله", "جنين"];

    return Scaffold(
      appBar: AppBar(title: const Text("المدن")),
      body: ListView(
        children: cities.map((city) {
          return ListTile(
            title: Text(city),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.orange),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CityPlacesPage(cityName: city),
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
// أماكن داخل المدينة (صفحات مستقلة لكل مكان)
//
class CityPlacesPage extends StatelessWidget {
  final String cityName;

  CityPlacesPage({super.key, required this.cityName});

  final Map<String, List<Map<String, dynamic>>> cityPlacesPages = {
    "نابلس": [
      {
        "title": "البلدة القديمة",
        "page": const PlaceDetailsPage(
          title: "البلدة القديمة",
          cityName: "نابلس",
          imageUrl:
              "https://www.aljazeera.net/wp-content/uploads/2023/04/12-3.jpg",
          url: "https://example.com/oldcity",
        ),
      },
      {
        "title": "جبل جرزيم",
        "page": const PlaceDetailsPage(
          title: "جبل جرزيم",
          cityName: "نابلس",
          imageUrl:
              "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d5/%D7%A8%D7%9B%D7%A1_%D7%94%D7%A8_%D7%92%D7%A8%D7%99%D7%96%D7%99%D7%9D.jpg/1280px-%D7%A8%D7%9B%D7%A1_%D7%94%D7%A8_%D7%92%D7%A8%D7%99%D7%96%D7%99%D7%9D.jpg",
          url: "https://example.com/gerizim",
        ),
      },
    ],
    "رام الله": [
      {
        "title": "دوار المنارة",
        "page": const PlaceDetailsPage(
          title: "دوار المنارة",
          cityName: "رام الله",
          imageUrl:
              "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/Al-Manara2009.JPG/1280px-Al-Manara2009.JPG",
          url: "https://example.com/manara",
        ),
      },
      {
        "title": "متحف ياسر عرفات",
        "page": const PlaceDetailsPage(
          title: "متحف ياسر عرفات",
          cityName: "رام الله",
          imageUrl:
              "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0d/Yasser_Arafat_Museum002.jpg/1280px-Yasser_Arafat_Museum002.jpg",
          url: "https://example.com/arafat",
        ),
      },
    ],
    "جنين": [
      {
        "title": "كنيسة برقين",
        "page": const PlaceDetailsPage(
          title: "كنيسة برقين",
          cityName: "جنين",
          imageUrl:
              "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b1/Burqin_Church-1.jpg/800px-Burqin_Church-1.jpg",
          url: "https://example.com/burqin",
        ),
      },
      {
        "title": "سهل مرج ابن عامر",
        "page": const PlaceDetailsPage(
          title: "سهل مرج ابن عامر",
          cityName: "جنين",
          imageUrl:
              "https://upload.wikimedia.org/wikipedia/commons/b/ba/PikiWiki_Israel_14301_Gilboa_Mountain.JPG",
          url: "https://example.com/marj",
        ),
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    final places = cityPlacesPages[cityName] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text("أماكن في $cityName")),
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
// صفحة المعلومات العامة
//
class InfoPage extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;

  const InfoPage({super.key, required this.title, required this.description, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Text(description, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Image.network(imageUrl, height: 200, fit: BoxFit.cover),
            const SizedBox(height: 16),
            Text(description, style: const TextStyle(fontSize: 18)),

          ],
        ),
      ),
    );
  }
}

//
// صفحة الخريطة
//
class MapPage extends StatelessWidget {
  final Position position;

  const MapPage({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    final userLocation = latlng.LatLng(position.latitude, position.longitude);

    return Scaffold(
      appBar: AppBar(title: const Text("انت هنا")),
      body: fm.FlutterMap(
        options: fm.MapOptions(initialCenter: userLocation, initialZoom: 16),
        children: [
          fm.TileLayer(
            urlTemplate:
                "https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=EvrUD11e3k8dXq0KBsyK",
            userAgentPackageName: 'com.example.flutter_application_1',
          ),
          fm.MarkerLayer(
            markers: [
              fm.Marker(
                point: userLocation,
                width: 80,
                height: 80,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//
// صفحة تفاصيل عامة للأماكن
//
class PlaceDetailsPage extends StatelessWidget {
  final String title;
  final String cityName;
  final String imageUrl;
  final String url;

  const PlaceDetailsPage({
    super.key,
    required this.title,
    required this.cityName,
    required this.imageUrl,
    required this.url,
  });

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("تعذر فتح الرابط: $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("تفاصيل $title")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Text(
              "$title - $cityName",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Image.network(imageUrl, height: 200, fit: BoxFit.cover),
            const SizedBox(height: 16),
            Text(
              "هذا وصف افتراضي لـ $title في $cityName. يمكنك تعديله لاحقًا.",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _launchURL(url),
              child: Text(
                url,
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
