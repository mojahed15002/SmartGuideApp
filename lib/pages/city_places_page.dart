import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart'; 
import '../theme_notifier.dart';
import 'place_details_page.dart';

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

  // ✅ بيانات الأماكن
  List<Map<String, dynamic>> _places = [];
  List<Map<String, dynamic>> _filteredPlaces = [];
  bool _isLoading = true;

  // ✅ متغيرات سجل البحث
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchHistory = [];

  // ✅ متغيرات الأنيميشن للأزرار
  bool _isHeartPressed = false;
  bool _isSharePressed = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _fetchPlaces();
    _loadSearchHistory();
  }

  /// تحميل السجل من Firestore
Future<void> _loadSearchHistory() async {
  try {
    // نبدأ بالقراءة من التخزين المحلي
    final prefs = await SharedPreferences.getInstance();
    List<String> localHistory = prefs.getStringList('local_search_history') ?? [];

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // مستخدم غير مسجل → نعرض السجل المحلي فقط
      setState(() => _searchHistory = localHistory);
      return;
    }

    // مستخدم مسجل → نقرأ من Firestore
    final doc = await FirebaseFirestore.instance
        .collection('search_history')
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data() != null && doc['history'] is List) {
      final firebaseHistory = List<String>.from(doc['history']);
      // ندمج السجلين بدون تكرار
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


  /// حفظ البحث الجديد
Future<void> _saveSearch(String query) async {
  final user = FirebaseAuth.instance.currentUser;
  if (query.isEmpty) return; // لا نحفظ البحث الفارغ

  // نحفظ محليًا أيضًا (حتى المستخدم غير المسجل يشوف السجل)
  final prefs = await SharedPreferences.getInstance();
  List<String> localHistory = prefs.getStringList('local_search_history') ?? [];

  // منع التكرار
  localHistory.remove(query);
  localHistory.insert(0, query);

  // نحتفظ فقط بآخر 8 عمليات بحث
  if (localHistory.length > 8) localHistory = localHistory.sublist(0, 8);

  await prefs.setStringList('local_search_history', localHistory);

  // نحفظ أيضاً على Firestore إذا المستخدم مسجل
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

  debugPrint('✅ تم حفظ البحث: $query');
}

/// حذف عنصر من سجل البحث
Future<void> _deleteSearchItem(String query) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> localHistory = prefs.getStringList('local_search_history') ?? [];

  localHistory.remove(query);
  await prefs.setStringList('local_search_history', localHistory);

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      final ref =
          FirebaseFirestore.instance.collection('search_history').doc(user.uid);
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

  debugPrint('🗑️ تم حذف "$query" من سجل البحث');
}

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoritePlaces = prefs.getStringList(_prefsKey) ?? [];
    });
  }

  /// جلب الأماكن من Firestore حسب المدينة
  Future<void> _fetchPlaces() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('places')
          .where('city', isEqualTo: widget.cityName.trim())
          .get();

      final List<Map<String, dynamic>> data =
          snapshot.docs.map((doc) => doc.data()).toList();

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

  /// فلترة النتائج حسب النص
  void _filterPlaces(String query) {
    if (query.isEmpty) {
      setState(() => _filteredPlaces = _places);
      return;
    }

    final results = _places.where((place) {
      final title = (place['title'] ?? '').toString().toLowerCase();
      return title.contains(query.toLowerCase());
    }).toList();

    setState(() => _filteredPlaces = results);
  }

  /// حفظ البحث وتصفية النتائج مع اقتراحات
  void _onSearchChanged(String query) {
    _filterPlaces(query);
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
        existingFavorites =
            List<String>.from(userSnapshot.data()!['favorites']);
      }

      if (favoritePlaces.contains(placeId)) {
        if (!existingFavorites.contains(placeId)) {
          existingFavorites.add(placeId);
        }
      } else {
        existingFavorites.remove(placeId);
      }

      await userDoc.set({'favorites': existingFavorites},
          SetOptions(merge: true));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAdded
              ? 'تمت الإضافة إلى المفضلة ❤️'
              : 'تمت الإزالة من المفضلة 💔',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor:
            isAdded ? Colors.green.shade600 : Colors.red.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _sharePlace(String city, String id, String title) {
    final String encodedCity = Uri.encodeComponent(city);
    final String encodedId = Uri.encodeComponent(id);
    final String webLink =
        'https://mojahed15002.github.io/SmartGuideApp/place?city=$encodedCity&id=$encodedId';
    final String shareText =
        '📍 اكتشف هذا المكان في $city:\n$title\n\nافتحه في Smart City Guide:\n$webLink';
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🧩 عدد عناصر السجل: ${_searchHistory.length}');
    final themeNotifier = widget.themeNotifier;
    final isDark = themeNotifier.value == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: Text(widget.cityName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // 🔍 البحث + الاقتراحات
Expanded(
  flex: 0,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      TextField(
        controller: _searchController,
        onChanged: (query) async {
          _onSearchChanged(query);
          if (query.isEmpty) {
            _loadSearchHistory();
            return;
          }

          try {
            final snapshot = await FirebaseFirestore.instance
                .collection('places')
                .where('city', isEqualTo: widget.cityName.trim())
                .where('title', isGreaterThanOrEqualTo: query)
                .where('title', isLessThanOrEqualTo: "$query\uf8ff")
                .limit(5)
                .get();

            final suggestions =
                snapshot.docs.map((d) => d['title'].toString()).toList();

            setState(() {
              _searchHistory = suggestions;
            });
          } catch (e) {
            debugPrint("⚠️ خطأ أثناء البحث السريع: $e");
          }
        },
        decoration: InputDecoration(
          hintText: 'ابحث عن منطقة...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      const SizedBox(height: 4),

      if (_searchHistory.isNotEmpty)
  Flexible(
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _searchHistory.length,
        itemBuilder: (context, index) {
          final suggestion = _searchHistory[index];
          return ListTile(
            leading: const Icon(Icons.history, color: Colors.blueAccent),
            title: Text(suggestion),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: Colors.redAccent),
              tooltip: 'حذف من السجل',
              onPressed: () => _deleteSearchItem(suggestion),
            ),
            onTap: () {
              _searchController.text = suggestion;
              _filterPlaces(suggestion);
              _saveSearch(suggestion);
              setState(() {
                _searchHistory = [];
              });
            },
          );
        },
      ),
    ),
  ),
    ],
  ),
),

const SizedBox(height: 10),

             
                 // ✅ عرض الأماكن
                  Expanded(
                    child: _filteredPlaces.isEmpty
                        ? const Center(
                            child: Text(
                              'لا توجد نتائج حالياً.',
                              style: TextStyle(fontSize: 18),
                            ),
                          )
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 3 / 4,
                            ),
                            itemCount: _filteredPlaces.length,
                            itemBuilder: (context, index) {
                              final place = _filteredPlaces[index];
                              final String id = place["id"];
                              final String title = place["title"];
                              final List<String> images =
                                  List<String>.from(place["images"] ?? []);
                              final String heroTag = place["hero"];
                              final String city = place["city"];
// ✅ حساب التقييم الحالي
final Map<String, dynamic> ratings = Map<String, dynamic>.from(place["ratings"] ?? {});
final user = FirebaseAuth.instance.currentUser;
final double userRating = user != null && ratings.containsKey(user.uid)
    ? (ratings[user.uid] as num).toDouble()
    : 0.0;

// حساب المتوسط العام
double avgRating = 0.0;
if (ratings.isNotEmpty) {
  avgRating = ratings.values
      .map((v) => (v as num).toDouble())
      .reduce((a, b) => a + b) /
      ratings.length;
}


                              return Stack(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PlaceDetailsPage(
                                            title: title,
                                            cityName: city,
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
                                        borderRadius: BorderRadius.circular(16),
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
                                                      top: Radius.circular(16)),
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
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
// ⭐ تقييم النجوم
Positioned(
  bottom: 12,
  right: 8,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (starIndex) {
      final ratingValue = starIndex + 1;
      return IconButton(
        iconSize: 24,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(
          ratingValue <= userRating ? Icons.star : Icons.star_border,
          color: Colors.amber,
        ),
        onPressed: user == null
            ? null
            : () async {
                await FirebaseFirestore.instance
                    .collection('places')
                    .doc(place["id"])
                    .update({
                  'ratings.${user.uid}': ratingValue.toDouble(),
                });

                setState(() {
                  _fetchPlaces(); // تحديث الأماكن بعد التقييم
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم تقييم المكان بـ $ratingValue نجوم ⭐'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
      );
    }),
  ),
),

// 📊 عرض المتوسط العام للتقييم
if (avgRating > 0)
  Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 18),
        const SizedBox(width: 4),
        Text(
          avgRating.toStringAsFixed(1), // مثلاً 4.3
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(${ratings.length} تقييم)', // عدد المقيمين
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
      ],
    ),
  ),

   // ❤️ المفضلة (مع أنيميشن النبضة)
Positioned(
  top: 8,
  right: 8,
  child: AnimatedScale(
    scale: _isHeartPressed ? 1.3 : 1.0,
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOutBack,
    child: IconButton(
      iconSize: 28,
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(
          isDark
              ? Colors.black.withOpacity(0.3)
              : Colors.white.withOpacity(0.8),
        ),
        shape: const WidgetStatePropertyAll(CircleBorder()),
      ),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: Icon(
          favoritePlaces.contains(id)
              ? Icons.favorite
              : Icons.favorite_border,
          key: ValueKey(favoritePlaces.contains(id)),
          color: favoritePlaces.contains(id)
              ? Colors.redAccent
              : Colors.grey,
          size: 28,
        ),
      ),
      onPressed: () async {
        setState(() => _isHeartPressed = true);
        await Future.delayed(const Duration(milliseconds: 150));
        setState(() => _isHeartPressed = false);
        _toggleFavorite(id);
      },
    ),
  ),
),


  // 🔗 المشاركة (مع أنيميشن النبضة)
Positioned(
  top: 8,
  left: 8,
  child: AnimatedScale(
    scale: _isSharePressed ? 1.3 : 1.0,
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOutBack,
    child: IconButton(
      iconSize: 28,
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(
          isDark
              ? Colors.black.withOpacity(0.3)
              : Colors.white.withOpacity(0.8),
        ),
        shape: const WidgetStatePropertyAll(CircleBorder()),
      ),
      icon: const Icon(Icons.share, size: 28),
      onPressed: () async {
        setState(() => _isSharePressed = true);
        await Future.delayed(const Duration(milliseconds: 150));
        setState(() => _isSharePressed = false);
        _sharePlace(city, id, title);
      },
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
    );
  }
}
