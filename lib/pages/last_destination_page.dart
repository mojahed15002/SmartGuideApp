import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart' as latlng;
import '../theme_notifier.dart';
import 'map_page.dart';
import 'place_details_page.dart';

class LastDestinationPage extends StatefulWidget {
  final String destinationName;
  final ThemeNotifier themeNotifier;

  const LastDestinationPage({
    super.key,
    required this.destinationName,
    required this.themeNotifier,
  });

  @override
  State<LastDestinationPage> createState() => _LastDestinationPageState();
}

class _LastDestinationPageState extends State<LastDestinationPage> {
  Map<String, dynamic>? placeData;
  bool loading = true;
  String? lastVisitTime;
  List<Map<String, dynamic>> recommendedPlaces = [];

  @override
  void initState() {
    super.initState();
    _loadPlaceData();
  }

  Future<void> _loadPlaceData() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('places')
          .where('title_ar', isEqualTo: widget.destinationName)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        placeData = {
          ...snap.docs.first.data(),
          'docId': snap.docs.first.id,
        };
      }

      final logs = await FirebaseFirestore.instance
          .collection('travel_logs')
          .orderBy('time', descending: true)
          .limit(1)
          .get();

      if (logs.docs.isNotEmpty) {
        final t = logs.docs.first['time']?.toDate();
        if (t != null) {
          lastVisitTime = "${t.day}/${t.month}/${t.year} - ${t.hour}:${t.minute}";
        }
      }

      await _loadNearbyRecommendations();

      setState(() => loading = false);
    } catch (e) {
      debugPrint("⚠️ error: $e");
      setState(() => loading = false);
    }
  }

  Future<void> _loadNearbyRecommendations() async {
    if (placeData == null || placeData!['latitude'] == null) return;

    final double lat = (placeData!['latitude'] as num).toDouble();
    final double lng = (placeData!['longitude'] as num).toDouble();

    final allPlaces = await FirebaseFirestore.instance.collection('places').get();

    for (var doc in allPlaces.docs) {
      final d = doc.data();
      final dLat = (d['latitude'] as num?)?.toDouble();
      final dLng = (d['longitude'] as num?)?.toDouble();
      if (dLat == null || dLng == null) continue;

      final distance = Geolocator.distanceBetween(lat, lng, dLat, dLng);

      if (distance < 5000 && d['title_ar'] != widget.destinationName) {
        recommendedPlaces.add({
          ...d,
          'docId': doc.id,
        });
      }
    }
  }

  Future<void> _openInGoogleMaps(double lat, double lng) async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final place = placeData;

    return Scaffold(
      appBar: AppBar(
        title: Text("آخر وجهة — ${widget.destinationName}"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : place == null
              ? const Center(child: Text("لم يتم العثور على معلومات حول هذه الوجهة"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.destinationName,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        "🕓 آخر زيارة: ${lastVisitTime ?? "غير متوفر"}",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 15),

                      if (place['images'] != null && place['images'].isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            place['images'][0],
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),

                      const SizedBox(height: 20),

                      _actionCard(
                        icon: Icons.map,
                        text: "عرض على الخريطة",
                        onTap: () async {
                          try {
                            final userPos = await Geolocator.getCurrentPosition(
                                desiredAccuracy: LocationAccuracy.best);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MapPage(
                                  position: userPos,
                                  destination: latlng.LatLng(
                                    (place['latitude'] as num).toDouble(),
                                    (place['longitude'] as num).toDouble(),
                                  ),
                                  themeNotifier: widget.themeNotifier,
                                  enableLiveTracking: false,
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("تعذّر تحديد موقعك: $e"),
                              ),
                            );
                          }
                        },
                      ),

                      _actionCard(
                        icon: Icons.location_pin,
                        text: "فتح في Google Maps",
                        onTap: () => _openInGoogleMaps(
                          (place['latitude'] as num).toDouble(),
                          (place['longitude'] as num).toDouble(),
                        ),
                      ),

                      _actionCard(
                        icon: Icons.star_rate,
                        text: "تقييم هذا المكان",
                        onTap: () {
                          final images = List<String>.from(place['images'] ?? []);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaceDetailsPage(
                                title: widget.destinationName,
                                cityName: place['city_ar'] ?? "",
                                images: images,
                                url: (place['url'] ?? "").toString(),
                                themeNotifier: widget.themeNotifier,
                                heroTag: (place['docId'] ?? "last_dest").toString(), id: '',
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 25),
                      const Text(
                        "أماكن مقترحة قريبة:",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      Column(
                        children: recommendedPlaces.take(5).map((e) {
                          final images = List<String>.from(e['images'] ?? []);
                          return ListTile(
                            leading: const Icon(Icons.place, color: Colors.orange),
                            title: Text(e['title_ar']),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlaceDetailsPage(
                                    title: e['title_ar'],
                                    cityName: e['city_ar'],
                                    images: images,
                                    url: (e['url'] ?? "").toString(),
                                    themeNotifier: widget.themeNotifier,
                                    heroTag: (e['docId'] ?? "").toString(), id: '',
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(text),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
