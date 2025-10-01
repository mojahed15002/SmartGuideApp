import 'package:flutter/foundation.dart' show kIsWeb;
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
              " مرحباً بك في مرشدك السياحي الخاص👋",
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
              child: const Text("انطلق😎"),
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
                    builder: (context) => const GeneralInfoPage(),
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
      imageUrl: "https://upload.wikimedia.org/wikipedia/commons/b/ba/Najah_001.jpg",
    );
  }
}

class SofianStreetPage extends StatelessWidget {
  const SofianStreetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoPage(
      title: "شارع سفيان",
      description: '''
شارع سفيان يعتبر من الشوارع الحيوية في المدينة ويشتهر بالأنشطة التالية:
- محلات تجارية متنوعة تشمل الملابس والأحذية.
- مقاهي ومطاعم تقدم أطباق محلية وعالمية.
- مراكز خدمات مثل صيدليات ومكاتب بريد.
- حركة مرور نشطة خصوصًا في ساعات الذروة.
- يسهل الوصول منه إلى المرافق التعليمية والصحية القريبة.
''',
      imageUrl:
          "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/%D8%B4%D8%A7%D8%B1%D8%B9_%D8%B3%D9%81%D9%8A%D8%A7%D9%86_%D9%81%D9%8A_%D9%86%D8%A7%D8%A8%D9%84%D8%B3_-_%D9%88%D8%B3%D8%B7_%D8%A7%D9%84%D9%85%D8%AF%D9%8A%D9%86%D8%A9.jpg/2560px-%D8%B4%D8%A7%D8%B1%D8%B9_%D8%B3%D9%81%D9%8A%D8%A7%D9%86_%D9%81%D9%8A_%D9%86%D8%A7%D8%A8%D9%84%D8%B3_-_%D9%88%D8%B3%D8%B7_%D8%A7%D9%84%D9%85%D8%AF%D9%8A%D9%86%D8%A9.jpg",
    );
  }
}

class FaisalStreetPage extends StatelessWidget {
  const FaisalStreetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoPage(
      title: "شارع فيصل",
      description: '''
شارع فيصل هو أحد الشوارع الرئيسية في مدينة نابلس ويتميز بالتالي:
- يربط بين مناطق المدينة الحيوية ويسهل الوصول إلى الأسواق والمراكز التجارية.
- يحتوي على محلات تجارية متنوعة، من الملابس إلى الإلكترونيات.
- وجود مقاهي ومطاعم شعبية وعالمية تناسب جميع الأذواق.
- حركة مرور معتدلة نسبيًا مع مواقف سيارات متوفرة بجانب الشارع.
- قريب من المدارس والمرافق الحكومية والخدمية، مما يجعله شارعًا مهمًا لسكان نابلس.
''',
      imageUrl: "",
    );
  }
}

class MartyrsRoundaboutPage extends StatelessWidget {
  const MartyrsRoundaboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoPage(
      title: "دوار الشهداء",
      description: '''
دوار الشهداء يُعتبر من المعالم المركزية في مدينة نابلس ويتميز بالتالي:
- يعد نقطة التقاء رئيسية للطرق في وسط المدينة، مما يسهل التنقل بين المناطق المختلفة.
- محاط بعدد من المحلات التجارية والمقاهي والمطاعم.
- يوجد بالقرب منه مكاتب حكومية ومرافق عامة مهمة.
- يعتبر مكانًا للتجمعات والمناسبات المحلية أحيانًا.
- الحركة المرورية فيه نشطة خلال النهار، مع وجود إشارات مرور لتنظيم السير.
''',
      imageUrl:
          "https://upload.wikimedia.org/wikipedia/commons/8/89/%D9%85%D9%86%D8%B7%D9%82%D8%A9_%D9%88%D8%B3%D8%B7_%D8%A7%D9%84%D8%A8%D9%84%D8%AF%D8%8C_%D9%85%D9%86%D8%B7%D9%82%D8%A9_%D8%AF%D9%88%D8%A7%D8%B1_%D8%A7%D9%84%D8%B4%D9%87%D8%AF%D8%A7%D8%A1%D8%8C_%D8%A8%D9%86%D8%A7%D8%A8%D9%84%D8%B3_%D9%81%D9%8A_%D9%81%D9%84%D8%B3%D8%B7%D9%8A%D9%86.jpg",
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
// أماكن داخل المدينة
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
          imageUrl: "https://www.aljazeera.net/wp-content/uploads/2023/04/12-3.jpg",
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
            trailing:
                const Icon(Icons.arrow_forward_ios, color: Colors.orange),
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
// صفحة المعلومات العامة (Responsive Image)
//
class InfoPage extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;

  const InfoPage({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  Widget _imageWidget(BuildContext context, BoxConstraints constraints) {
    // الارتفاع الافتراضي حسب المنصة
    final double maxHeight = kIsWeb ? 360 : 220;

    // Placeholder لو الرابط فاضي أو فشل التحميل
    final Widget placeholder = Container(
      height: maxHeight,
      width: double.infinity,
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.image, size: 64, color: Colors.grey[500]),
      ),
    );

    if (imageUrl.trim().isEmpty) return placeholder;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: constraints.maxWidth,
        maxHeight: maxHeight,
      ),
      child: Image.network(
        imageUrl,
        width: double.infinity,
        height: maxHeight,
        fit: kIsWeb ? BoxFit.contain : BoxFit.cover,
        // لو فشل تحميل الصورة، نعرض placeholder بدل الخطأ
        errorBuilder: (context, error, stackTrace) => placeholder,
        // أثناء التحميل نعرض مؤشر
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            height: maxHeight,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            // عنوان أو وصف مختصر
            Text(description, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            // الصورة المتجاوبة
            LayoutBuilder(builder: (context, constraints) {
              return _imageWidget(context, constraints);
            }),
            const SizedBox(height: 16),
            // محتوى إضافي (نفس الوصف مرة ثانية إن رغبت)
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
// صفحة تفاصيل عامة للأماكن (Responsive Image)
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

  Widget _imageWidget(BuildContext context, BoxConstraints constraints) {
    final double maxHeight = kIsWeb ? 360 : 220;
    final Widget placeholder = Container(
      height: maxHeight,
      width: double.infinity,
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.image, size: 64, color: Colors.grey[500]),
      ),
    );

    if (imageUrl.trim().isEmpty) return placeholder;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: constraints.maxWidth, maxHeight: maxHeight),
      child: Image.network(
        imageUrl,
        width: double.infinity,
        height: maxHeight,
        fit: kIsWeb ? BoxFit.contain : BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            height: maxHeight,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
              ),
            ),
          );
        },
      ),
    );
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
            LayoutBuilder(builder: (context, constraints) {
              return _imageWidget(context, constraints);
            }),
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
