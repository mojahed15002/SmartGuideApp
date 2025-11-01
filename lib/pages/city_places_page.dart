import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../theme_notifier.dart';
import 'place_details_page.dart';
import '../category_filter.dart';
import '../l10n/gen/app_localizations.dart';

class CityPlacesPage extends StatefulWidget {
  final String cityName;
  final ThemeNotifier themeNotifier;

  const CityPlacesPage({
    super.key,
    required this.cityName,
    required this.themeNotifier,
  });

  @override
  State<CityPlacesPage> createState() => _CityPlacesPageState();
}

class _CityPlacesPageState extends State<CityPlacesPage>
    with SingleTickerProviderStateMixin {
  final String _prefsKey = 'favorites_list';
  List<String> favoritePlaces = [];

  List<Map<String, dynamic>> _places = [];
  List<Map<String, dynamic>> _filteredPlaces = [];
  List<String> _suggestions = [];
  bool _isLoading = true;

List<String> _selectedCategories = []; // ✅ التصنيفات المختارة

  final TextEditingController _searchController = TextEditingController();
  List<String> _searchHistory = [];

  final Map<String, double> _uiUserRatings = {};

final Map<String, int> _categoryCounts = {};

  late AnimationController _animController;
  double _heartScale = 1.0;
  double _shareScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadSearchHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPlaces();
    });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.9,
      upperBound: 1.1,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> localHistory =
          prefs.getStringList('local_search_history') ?? [];

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _searchHistory = localHistory);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('search_history')
          .doc(user.uid)
          .get();



      if (doc.exists && doc.data() != null && doc['history'] is List) {
        final firebaseHistory = List<String>.from(doc['history']);
        for (var item in localHistory) {
          if (!firebaseHistory.contains(item)) firebaseHistory.add(item);
        }
        setState(() => _searchHistory = firebaseHistory);
      } else {
        setState(() => _searchHistory = localHistory);
      }
    } catch (e) {
      debugPrint("⚠️ فشل تحميل سجل البحث: $e");
    }
    
  }

  Future<void> _saveSearch(String query) async {
    final user = FirebaseAuth.instance.currentUser;
    if (query.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> localHistory =
        prefs.getStringList('local_search_history') ?? [];

    localHistory.remove(query);
    localHistory.insert(0, query);

    if (localHistory.length > 8) localHistory = localHistory.sublist(0, 8);

    await prefs.setStringList('local_search_history', localHistory);

    if (user != null) {
      final ref =
          FirebaseFirestore.instance.collection('search_history').doc(user.uid);
      _searchHistory.remove(query);
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 8) {
        _searchHistory = _searchHistory.sublist(0, 8);
      }
      await ref.set({'history': _searchHistory});
    }

  }

  Future<void> _deleteSearchItem(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> localHistory =
        prefs.getStringList('local_search_history') ?? [];

    localHistory.remove(query);
    await prefs.setStringList('local_search_history', localHistory);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final ref = FirebaseFirestore.instance
            .collection('search_history')
            .doc(user.uid);
        final doc = await ref.get();
        if (doc.exists && doc.data()?['history'] != null) {
          List<String> firebaseHistory =
              List<String>.from(doc.data()!['history']);
          firebaseHistory.remove(query);
          await ref.set({'history': firebaseHistory});
        }
      } catch (e) {
        debugPrint("⚠️ فشل حذف البحث من Firestore: $e");
      }
    }

    setState(() {
      _searchHistory.remove(query);
    });
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoritePlaces = prefs.getStringList(_prefsKey) ?? [];
    });
  }

  Future<void> _fetchPlaces() async {
    try {
      final loc = AppLocalizations.of(context)!;
      final isArabic = loc.localeName == 'ar';

      final String cityField = isArabic ? 'city_ar' : 'city_en';
      final String queryValue = widget.cityName.trim();

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('places')
          .where(cityField, isEqualTo: queryValue)
          .get();

      if (snapshot.docs.isEmpty) {
        final fallbackField = isArabic ? 'city_en' : 'city_ar';
        snapshot = await FirebaseFirestore.instance
            .collection('places')
            .where(fallbackField, isEqualTo: queryValue)
            .get();
      }

      final List<Map<String, dynamic>> data =
          snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

setState(() {
  _places = data;
  _filteredPlaces = data;
  _isLoading = false;

  // ✅ حساب عدد الأماكن لكل تصنيف
  _categoryCounts.clear();
  for (var place in _places) {
    List<String> cats = List<String>.from(place["categories"] ?? []);
    for (var c in cats) {
      _categoryCounts[c] = (_categoryCounts[c] ?? 0) + 1;
    }
  }
});
    } catch (e) {
      debugPrint("❌ فشل تحميل الأماكن: $e");
      setState(() => _isLoading = false);
    }
  }





  Future<void> _toggleFavorite(String placeId) async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    bool isAdded = false;

    setState(() {
      if (favoritePlaces.contains(placeId)) {
        favoritePlaces.remove(placeId);
        isAdded = false;
      } else {
        favoritePlaces.add(placeId);
        isAdded = true;
      }
      _heartScale = 1.2;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      setState(() => _heartScale = 1.0);
    });

    await prefs.setStringList(_prefsKey, favoritePlaces);

    if (user != null) {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userSnapshot = await userDoc.get();

      List<String> existingFavorites = [];

      if (userSnapshot.exists && userSnapshot.data()?['favorites'] != null) {
        existingFavorites = List<String>.from(
          userSnapshot.data()!['favorites'],
        );
      }

      if (favoritePlaces.contains(placeId)) {
        if (!existingFavorites.contains(placeId)) {
          existingFavorites.add(placeId);
        }
      } else {
        existingFavorites.remove(placeId);
      }

      await userDoc.set({
        'favorites': existingFavorites,
      }, SetOptions(merge: true));
    }

    final loc = AppLocalizations.of(context)!;
    final addedMsg = loc.addedToFavorites;
    final removedMsg = loc.removedFromFavorites;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAdded ? addedMsg : removedMsg,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isAdded ? Colors.green.shade600 : Colors.red.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _sharePlace(String city, String id, String title) {
    setState(() => _shareScale = 1.2);
    Future.delayed(const Duration(milliseconds: 150),
        () => setState(() => _shareScale = 1.0));

    final String encodedCity = Uri.encodeComponent(city);
    final String encodedId = Uri.encodeComponent(id);
    final String webLink =
        'https://mojahed15002.github.io/SmartGuideApp/place?city=$encodedCity&id=$encodedId';
    final loc = AppLocalizations.of(context)!;
    final String shareText =
        '📍 ${loc.discoverPlaceIn} $city:\n$title\n\n${loc.openInApp}:\n$webLink';
    Share.share(shareText);
  }

  void _applyFilters() {
  final query = _searchController.text.trim().toLowerCase();

// ✅ بناء الاقتراحات حسب النص المكتوب
_suggestions = _places
    .where((place) {
      final titleAr = (place['title_ar'] ?? '').toString().toLowerCase();
      final titleEn = (place['title_en'] ?? '').toString().toLowerCase();
      return titleAr.contains(query) || titleEn.contains(query);
    })
    .map((place) => (place['title_ar'] ?? place['title_en']).toString())
    .toList(); 
    setState(() {});


  List<Map<String, dynamic>> results = _places;

  // ✅ فلترة حسب البحث
  if (query.isNotEmpty) {
    results = results.where((place) {
      final titleAr = (place['title_ar'] ?? '').toString().toLowerCase();
      final titleEn = (place['title_en'] ?? '').toString().toLowerCase();
      return titleAr.contains(query) || titleEn.contains(query);
    }).toList();
  }

  // ✅ فلترة حسب التصنيف
  if (_selectedCategories.isNotEmpty && !_selectedCategories.contains("all")) {
    results = results.where((place) {
      final List<String> placeCats =
          List<String>.from(place["categories"] ?? []);
      return _selectedCategories.any((cat) => placeCats.contains(cat));
    }).toList();
  }
  
// ✅ إعادة حساب الاعداد حسب القائمة المعروضة الآن
_categoryCounts.clear();
for (var place in results) {
  List<String> cats = List<String>.from(place["categories"] ?? []);
  for (var c in cats) {
    _categoryCounts[c] = (_categoryCounts[c] ?? 0) + 1;
  }
}

  setState(() {
    _filteredPlaces = results;
  });
}


  @override
  Widget build(BuildContext context) {
    final themeNotifier = widget.themeNotifier;
    final loc = AppLocalizations.of(context)!;
    final isArabic = loc.localeName == 'ar';
    final direction = isArabic ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        appBar: AppBar(
  title: Text(loc.citiesTitle),
  leading: IconButton(
    icon: const Icon(Icons.arrow_back_ios_new, color: Color.fromARGB(255, 0, 0, 0)),
    onPressed: () {
      Navigator.pop(context); // ⬅️ بيرجع خطوة للخلف
    },
  ),
  
),

        
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
onChanged: (query) async {
  if (query.isEmpty) {
    await _loadSearchHistory(); 
    _applyFilters();
  } else {
    _applyFilters();
  }
  setState(() {});
},

onSubmitted: (query) async {
  query = query.trim();
  if (query.isNotEmpty) {
    await _saveSearch(query);
    await _loadSearchHistory();
    _applyFilters();
    setState(() {});
  }
},

                      decoration: InputDecoration(
                        hintText: loc.searchHint,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ✅ عرض سجل البحث إذا مربع البحث فاضي
if (_searchController.text.isEmpty && _searchHistory.isNotEmpty)
  SizedBox(
    height: 50,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: _searchHistory.map((q) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              _searchController.text = q;
              _applyFilters();
            },
            child: Chip(
              label: Text(q),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => _deleteSearchItem(q),
            ),
          ),
        );
      }).toList(),
    ),
  ),

// ✅ اقتراحات كتابة البحث
if (_searchController.text.isNotEmpty && _suggestions.isNotEmpty)
  SizedBox(
    height: 50,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: _suggestions.take(8).map((s) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              _searchController.text = s;
              _applyFilters();
              FocusScope.of(context).unfocus(); // اغلاق الكيبورد
            },
            child: Chip(
              label: Text(s),
            ),
          ),
        );
      }).toList(),
    ),
  ),


                    // ✅ فلتر التصنيفات
CategoryFilter(
  selectedCategories: _selectedCategories,
  onChanged: (cats) {
    setState(() {
      _selectedCategories = cats;
    });
_applyFilters();
  },
  categoryCounts: _categoryCounts, // 👈 أرسل الأرقام
),

const SizedBox(height: 10),


                    Expanded(
                      child: _filteredPlaces.isEmpty
                          ? Center(
                              child: Text(
                                loc.noResults,
                                style: const TextStyle(fontSize: 18),
                              ),
                            )
                          : GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 2.6 / 4,
                              ),
                              itemCount: _filteredPlaces.length,
                              itemBuilder: (context, index) {
                                final place = _filteredPlaces[index];
                                final String id = place["id"] ?? '';
                                final String title = isArabic
                                    ? (place["title_ar"] ?? '')
                                    : (place["title_en"] ?? '');
                                final List<String> images =
                                    List<String>.from(place["images"] ?? []);
                                final String heroTag =
                                    place["hero"] ?? 'place_$index';
                                final String cityName = isArabic
                                    ? (place['city_ar'] ?? '')
                                    : (place['city_en'] ?? '');

                                return Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (!mounted) return;
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PlaceDetailsPage(
                                                   id: id,
                                              title: title,
                                              cityName: cityName,
                                              images: images,
                                              url: place["url"],
                                              themeNotifier: themeNotifier,
                                              heroTag: heroTag,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        elevation: 4,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                  top: Radius.circular(16),
                                                ),
                                                child: Hero(
                                                  tag: heroTag,
                                                  child: Image.asset(
                                                    images.isNotEmpty
                                                        ? images.first
                                                        : 'assets/images/default.jpg',
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                title,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // ❤️ زر المفضلة مع نبضة
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => _toggleFavorite(id),
                                        child: AnimatedScale(
                                          scale: _heartScale,
                                          duration: const Duration(
                                              milliseconds: 150),
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withOpacity(0.8),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              favoritePlaces.contains(id)
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color:
                                                  favoritePlaces.contains(id)
                                                      ? Colors.red
                                                      : Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // 🔗 زر المشاركة مع نبضة
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: GestureDetector(
                                        onTap: () => _sharePlace(
                                            cityName, id, title),
                                        child: AnimatedScale(
                                          scale: _shareScale,
                                          duration: const Duration(
                                              milliseconds: 150),
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withOpacity(0.8),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.share,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
