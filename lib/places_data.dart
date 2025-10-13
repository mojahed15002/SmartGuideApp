import '../theme_notifier.dart';
import '../pages/place_details_page.dart';

final Map<String, List<Map<String, dynamic>>> cityPlacesPages = {
  "نابلس": [
    {
      "id": "nablus_oldcity",
      "title": "البلدة القديمة",
      "images": ["assets/images/oldcity.jpg", "assets/images/oldcity2.jpg"],
      "hero": "nablus_oldcity",
      "url": "https://example.com/oldcity",
      "city": "نابلس",
    },
    {
      "id": "nablus_gerizim",
      "title": "جبل جرزيم",
      "images": ["assets/images/gerizim.jpg", "assets/images/gerizim2.jpg"],
      "hero": "nablus_gerizim",
      "url": "https://example.com/gerizim",
      "city": "نابلس",
    },
  ],
  "رام الله": [
    {
      "id": "ramallah_manara",
      "title": "دوار المنارة",
      "images": ["assets/images/manara.jpg", "assets/images/manara2.jpg"],
      "hero": "ramallah_manara",
      "url": "https://example.com/manara",
      "city": "رام الله",
    },
    {
      "id": "ramallah_arafat",
      "title": "متحف ياسر عرفات",
      "images": [
        "assets/images/arafat.jpg",
        "assets/images/arafat2.jpg",
        "assets/images/arafat3.jpg"
      ],
      "hero": "ramallah_arafat",
      "url": "https://example.com/arafat",
      "city": "رام الله",
    },
  ],
  "جنين": [
    {
      "id": "jenin_burqin",
      "title": "كنيسة برقين",
      "images": ["assets/images/burqin.jpg", "assets/images/burqin2.jpg"],
      "hero": "jenin_burqin",
      "url": "https://example.com/burqin",
      "city": "جنين",
    },
    {
      "id": "jenin_marj",
      "title": "سهل مرج ابن عامر",
      "images": ["assets/images/marj.jpg", "assets/images/marj2.jpg"],
      "hero": "jenin_marj",
      "url": "https://example.com/marj",
      "city": "جنين",
    },
  ],
};

/// 🔹 خريطة لجميع الأماكن (لتسهيل الوصول عبر الـ ID في صفحة المفضلة)
final Map<String, Map<String, dynamic>> allPlaces = {
  for (var city in cityPlacesPages.keys)
    for (var place in cityPlacesPages[city]!) place["id"]: place,
};
