import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme_notifier.dart';
import '../places_data.dart';
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

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoritePlaces = prefs.getStringList(_prefsKey) ?? [];
    });
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

      if (userSnapshot.exists &&
          userSnapshot.data()?['favorites'] != null) {
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

    // ✅ Snackbar ملوّن لإشعار المستخدم
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAdded
              ? 'تمت الإضافة إلى المفضلة ❤️'
              : 'تمت الإزالة من المفضلة 💔',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            isAdded ? Colors.green.shade600 : Colors.red.shade600,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = widget.themeNotifier;
    final isDark = themeNotifier.value == ThemeMode.dark;
    final cityPlaces = allPlaces.entries
        .where((entry) => entry.value['city'] == widget.cityName)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cityName),
      ),
      body: cityPlaces.isEmpty
          ? const Center(
              child: Text(
                'لا توجد أماكن مسجلة لهذه المدينة بعد.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: cityPlaces.length,
                itemBuilder: (context, index) {
                  final id = cityPlaces[index].key;
                  final place = cityPlaces[index].value;

                  final String title = place["title"];
                  final List<String> images =
                      List<String>.from(place["images"]);
                  final String heroTag = place["hero"];
                  final String city = place["city"];

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
                            shape:
                                const WidgetStatePropertyAll(CircleBorder()),
                          ),
                          icon: AnimatedSwitcher(
                            duration:
                                const Duration(milliseconds: 250),
                            transitionBuilder: (Widget child,
                                    Animation<double> anim) =>
                                ScaleTransition(
                                    scale: anim, child: child),
                            child: Icon(
                              favoritePlaces.contains(id)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              key: ValueKey(
                                  favoritePlaces.contains(id)),
                              color: favoritePlaces.contains(id)
                                  ? Colors.redAccent
                                  : Colors.grey,
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
