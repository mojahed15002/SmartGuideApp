import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme_notifier.dart';
import 'place_details_page.dart';
import '../places_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'custom_drawer.dart';
import 'swipeable_page_route.dart'; // تأكد تضيف هذا بالأعلى

// ✅ إضافة ملف الترجمة
import '../l10n/gen/app_localizations.dart';

class FavoritesPage extends StatefulWidget {
  final ThemeNotifier themeNotifier;

  const FavoritesPage({super.key, required this.themeNotifier});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
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

    // 🔹 تحميل المفضلات من Firestore إن وُجد مستخدم
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data()?['favorites'] != null) {
        setState(() {
          favoritePlaces = List<String>.from(doc.data()!['favorites']);
        });
        await prefs.setStringList(_prefsKey, favoritePlaces);
        return;
      }
    }

    // 🔹 تحميل من SharedPreferences في حال عدم وجود Firestore
    setState(() {
      favoritePlaces = prefs.getStringList(_prefsKey) ?? [];
    });
  }

  Future<void> _toggleFavorite(String placeId) async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    bool isAdded = false; // ✅ لتحديد نوع العملية لاحقًا

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

    // 🔹 تحديث Firestore بالمفضلات
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'favorites': favoritePlaces,
      }, SetOptions(merge: true));
    }

    // ✅ إظهار Snackbar مع الترجمة
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAdded
              ? AppLocalizations.of(context)!.addedToFavorites
              : AppLocalizations.of(context)!.removedFromFavorites,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isAdded ? Colors.green.shade600 : Colors.red.shade600,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = widget.themeNotifier;
    final isDark = themeNotifier.isDarkMode;

    // ✅ تحديد اتجاه الصفحة
    final isArabic = AppLocalizations.of(context)!.localeName == 'ar';
    final direction = isArabic ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.favoritesTitle),
        ),
        drawer: CustomDrawer(
          themeNotifier: themeNotifier,
        ), // ⬅️ هذا السطر المهم
        body: favoritePlaces.isEmpty
            ? Center(
                child: Text(
                  AppLocalizations.of(context)!.noFavorites,
                  style: const TextStyle(fontSize: 18),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(12.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 3 / 4,
                  ),
                  itemCount: favoritePlaces.length,
                  itemBuilder: (context, index) {
                    final id = favoritePlaces[index];
                    final place = allPlaces[id];
                    if (place == null) return const SizedBox();

                    final String title = place["title"];
                    final List<String> images = List<String>.from(
                      place["images"],
                    );
                    final String heroTag = place["hero"];
                    final String city = place["city"];

                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (!mounted) return;
                            if (ModalRoute.of(context)?.isCurrent ?? false) {
                              Navigator.push(
                                context,
                                SwipeablePageRoute(
                                  page: PlaceDetailsPage(
                                    title: title,
                                    cityName: city,
                                    images: images,
                                    url: place["url"],
                                    themeNotifier: themeNotifier,
                                    heroTag: heroTag,
                                  ),
                                ),
                              );
                            }
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
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            iconSize: 34,
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                isDark
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.8),
                              ),
                              shape: const WidgetStatePropertyAll(
                                CircleBorder(),
                              ),
                            ),
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder:
                                  (Widget child, Animation<double> anim) =>
                                      ScaleTransition(
                                        scale: anim,
                                        child: child,
                                      ),
                              child: Icon(
                                Icons.favorite,
                                key: ValueKey(id),
                                color: Colors.redAccent,
                                size: 30,
                              ),
                            ),
                            onPressed: () async {
                              await _toggleFavorite(id);
                              setState(() {
                                favoritePlaces.remove(id);
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }
}
