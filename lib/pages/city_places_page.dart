library;

import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import 'place_details_page.dart';
import '/../place_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../places_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CityPlacesPage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  final String cityName;

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

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

Future<void> _loadFavorites() async {
  final prefs = await SharedPreferences.getInstance();
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data()?['favorites'] != null) {
      setState(() {
        favoritePlaces = List<String>.from(doc.data()!['favorites']);
      });
      await prefs.setStringList(_prefsKey, favoritePlaces);
      return;
    }
  }

  // إذا المستخدم مش مسجل دخول أو ما في بيانات
  setState(() {
    favoritePlaces = prefs.getStringList(_prefsKey) ?? [];
  });
}


Future<void> _toggleFavorite(String placeId) async {
  final prefs = await SharedPreferences.getInstance();
  final user = FirebaseAuth.instance.currentUser;

  setState(() {
    if (favoritePlaces.contains(placeId)) {
      favoritePlaces.remove(placeId);
    } else {
      favoritePlaces.add(placeId);
    }
  });

  // 🔹 حفظ محلي دائمًا
  await prefs.setStringList(_prefsKey, favoritePlaces);

  // 🔹 إذا المستخدم مسجل دخول → عدّل Firestore بدل ما تستبدل البيانات
  if (user != null) {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userSnapshot = await userDoc.get();

    List<String> existingFavorites = [];

    if (userSnapshot.exists && userSnapshot.data()?['favorites'] != null) {
      existingFavorites = List<String>.from(userSnapshot.data()!['favorites']);
    }

    // تحديث حسب العملية
    if (favoritePlaces.contains(placeId)) {
      if (!existingFavorites.contains(placeId)) {
        existingFavorites.add(placeId);
      }
    } else {
      existingFavorites.remove(placeId);
    }

    await userDoc.set({'favorites': existingFavorites}, SetOptions(merge: true));
  }
}


  @override
  Widget build(BuildContext context) {
    final cityName = widget.cityName;
    final themeNotifier = widget.themeNotifier;
    final isDark = themeNotifier.value == ThemeMode.dark;

    // 🔹 الماب موجود جوّا build (مع إضافات heroTag لكل مكان)

    final places = cityPlacesPages[widget.cityName] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text("أماكن في $cityName"),
        actions: [
          // ✅ زر الوضع الليلي
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
                  final String id = placeData["id"];
                  final String title = placeData["title"];
                  final List<String> images =
                      List<String>.from(placeData["images"]);
                  final String heroTag =
                      placeData["hero"] ?? "${cityName}_$title";
                  final bool isFav = favoritePlaces.contains(id);

                  return Stack(
                    children: [
                      TweenAnimationBuilder<double>(
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
                              MaterialPageRoute(
                                  builder: (_) => placeData["page"]),
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
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          iconSize: 34,
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder:
                                (Widget child, Animation<double> anim) =>
                                    ScaleTransition(scale: anim, child: child),
                            child: Icon(
                              isFav
                                  ? Icons.favorite
                                  : Icons.favorite_border_outlined,
                              key: ValueKey<bool>(isFav),
                              color: isFav
                                  ? Colors.redAccent
                                  : (isDark
                                      ? Colors.white70
                                      : Colors.black54),
                                      size: 30,
                            ),
                          ),
                          onPressed: () => _toggleFavorite(id),
                        ),
                      ),
                    ],
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
                  final String id = placeData["id"];
                  final String title = placeData["title"];
                  final List<String> images =
                      List<String>.from(placeData["images"]);
                  final String heroTag =
                      placeData["hero"] ?? "${cityName}_$title";
                  final bool isFav = favoritePlaces.contains(id);

                  return Stack(
                    children: [
                      TweenAnimationBuilder<double>(
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
                              MaterialPageRoute(
                                  builder: (_) => placeData["page"]),
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
                                      top: Radius.circular(16),
                                    ),
                                    child: Hero(
                                      tag: heroTag,
                                      child: Image.asset(
                                        images.first,
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
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          iconSize: 34,
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder:
                                (Widget child, Animation<double> anim) =>
                                    ScaleTransition(scale: anim, child: child),
                            child: Icon(
                              isFav
                                  ? Icons.favorite
                                  : Icons.favorite_border_outlined,
                              key: ValueKey<bool>(isFav),
                              color: isFav
                                  ? Colors.redAccent
                                  : (isDark
                                      ? Colors.white70
                                      : Colors.black54),
                                      size: 30,
                            ),
                          ),
                          onPressed: () => _toggleFavorite(id),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
