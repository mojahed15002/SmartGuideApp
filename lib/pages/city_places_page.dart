import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../theme_notifier.dart';
import 'place_details_page.dart';
import 'custom_drawer.dart';
import 'swipeable_page_route.dart';
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

class _CityPlacesPageState extends State<CityPlacesPage> {
  final String _prefsKey = 'favorites_list';
  List<String> favoritePlaces = [];

  List<Map<String, dynamic>> _places = [];
  List<Map<String, dynamic>> _filteredPlaces = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  List<String> _searchHistory = [];

  final bool _isHeartPressed = false;
  final bool _isSharePressed = false;

  final Map<String, double> _uiUserRatings = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadSearchHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPlaces();
    });
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
      });
    } catch (e) {
      debugPrint("❌ فشل تحميل الأماكن: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterPlaces(String query) {
    if (query.isEmpty) {
      setState(() => _filteredPlaces = _places);
      return;
    }

    final results = _places.where((place) {
      final titleAr = (place['title_ar'] ?? '').toString().toLowerCase();
      final titleEn = (place['title_en'] ?? '').toString().toLowerCase();
      return titleAr.contains(query.toLowerCase()) ||
          titleEn.contains(query.toLowerCase());
    }).toList();

    setState(() => _filteredPlaces = results);
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
    final String encodedCity = Uri.encodeComponent(city);
    final String encodedId = Uri.encodeComponent(id);
    final String webLink =
        'https://mojahed15002.github.io/SmartGuideApp/place?city=$encodedCity&id=$encodedId';
    final loc = AppLocalizations.of(context)!;
    final String shareText =
        '📍 ${loc.discoverPlaceIn} $city:\n$title\n\n${loc.openInApp}:\n$webLink';
    Share.share(shareText);
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
        ),
        drawer: CustomDrawer(themeNotifier: widget.themeNotifier),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (query) async {
                        _filterPlaces(query);
                        if (query.isEmpty) {
                          _loadSearchHistory();
                          return;
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
                                          Navigator.pushReplacement(
                                            context,
                                            SwipeablePageRoute(
                                              page: PlaceDetailsPage(
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
