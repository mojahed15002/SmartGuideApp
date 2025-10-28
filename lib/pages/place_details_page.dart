/// ملف مستخرج تلقائيًا من main.dart
/// يحتوي الكلاس: PlaceDetailsPage
library;

import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'full_screen_gallery.dart';

// ✅ إضافات جديدة
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlaceDetailsPage extends StatefulWidget {
  final String title;
  final String cityName;
  final List<String> images;
  final String url;
  final ThemeNotifier themeNotifier;
  final String heroTag;

  const PlaceDetailsPage({
    super.key,
    required this.title,
    required this.cityName,
    required this.images,
    required this.url,
    required this.themeNotifier,
    required this.heroTag,
  });

  @override
  State<PlaceDetailsPage> createState() => _PlaceDetailsPageState();
}

class _PlaceDetailsPageState extends State<PlaceDetailsPage> {
  int _activeIndex = 0;

  // ⭐ متغيرات التقييم
  double _currentRating = 0.0;
  double _averageRating = 0.0;
  int _totalRatings = 0;

  String get placeId => widget.heroTag; // استخدم heroTag كـ id (هو نفسه place id عادة)

  @override
  void initState() {
    super.initState();
    _fetchRatings();
  }

  Future<void> _fetchRatings() async {
    try {
      final placeDoc = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .get();

      if (!placeDoc.exists) return;
      final data = placeDoc.data();
      if (data == null || !data.containsKey('ratings')) return;

      final ratings = Map<String, dynamic>.from(data['ratings']);
      final user = FirebaseAuth.instance.currentUser;
      double total = 0;
      int count = 0;

      ratings.forEach((key, value) {
        if (value is num) {
          total += value.toDouble();
          count++;
        }
      });

      double avg = count > 0 ? total / count : 0;
      double userRating = 0;
      if (user != null && ratings.containsKey(user.uid)) {
        userRating = (ratings[user.uid] ?? 0).toDouble();
      }

      setState(() {
        _averageRating = avg;
        _totalRatings = count;
        _currentRating = userRating;
      });
    } catch (e) {
      debugPrint("⚠️ فشل تحميل التقييمات: $e");
    }
  }

  Future<void> _submitRating(double rating) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final placeRef =
          FirebaseFirestore.instance.collection('places').doc(placeId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(placeRef);
        if (!snapshot.exists) return;

        final data = Map<String, dynamic>.from(snapshot.data() ?? {});
        Map<String, dynamic> ratings =
            Map<String, dynamic>.from(data['ratings'] ?? {});

        ratings[user.uid] = rating;

        double total = 0;
        int count = 0;
        ratings.forEach((key, value) {
          if (value is num) {
            total += value.toDouble();
            count++;
          }
        });

        double avg = count > 0 ? total / count : 0;

        transaction.update(placeRef, {
          'ratings': ratings,
          'average_rating': avg,
          'ratings_count': count,
        });

        setState(() {
          _currentRating = rating;
          _averageRating = avg;
          _totalRatings = count;
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تسجيل تقييمك: $rating ⭐',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orange.shade600,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint("❌ فشل حفظ التقييم: $e");
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("تعذر فتح الرابط: $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
  title: Text(
    "تفاصيل ${widget.title}",
    style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
  ),
  leading: IconButton(
    icon: const Icon(Icons.arrow_back_ios_new, color: Color.fromARGB(255, 0, 0, 0)),
    onPressed: () {
      Navigator.pop(context); // ⬅️ بيرجع المستخدم للصفحة السابقة (CityPlacesPage)
    },
  ),
),

      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Text(
              "${widget.title} - ${widget.cityName}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Carousel Slider
            CarouselSlider.builder(
              itemCount: widget.images.length,
              itemBuilder: (context, index, realIndex) {
                final imgPath = widget.images[index];
                Widget imageWidget = Image.asset(
                  imgPath,
                  fit: BoxFit.cover,
                  width: screenWidth,
                );

                if (index == 0) {
                  imageWidget = Hero(tag: widget.heroTag, child: imageWidget);
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenGallery(
                          images: widget.images,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: kIsWeb ? 16 / 9 : 4 / 3,
                      child: imageWidget,
                    ),
                  ),
                );
              },
              options: CarouselOptions(
                height: kIsWeb ? 400 : 250,
                enlargeCenterPage: true,
                enableInfiniteScroll: true,
                viewportFraction: 0.9,
                onPageChanged: (index, reason) {
                  setState(() => _activeIndex = index);
                },
              ),
            ),

            const SizedBox(height: 12),
            Center(
              child: AnimatedSmoothIndicator(
                activeIndex: _activeIndex,
                count: widget.images.length,
                effect: ExpandingDotsEffect(
                  dotHeight: 10,
                  dotWidth: 10,
                  activeDotColor: Colors.orange,
                  dotColor: Colors.grey.shade400,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              "هذا وصف افتراضي لـ ${widget.title} في ${widget.cityName}. يمكنك تعديله لاحقًا.",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: () => _launchURL(widget.url),
              child: Text(
                widget.url,
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ⭐ قسم التقييم
            const Divider(thickness: 1.5),
            const SizedBox(height: 10),
            const Text(
              "⭐ قيّم هذا المكان:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // نجوم التقييم مع توهج
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                final selected = starValue <= _currentRating;
                return GestureDetector(
                  onTap: () => _submitRating(starValue.toDouble()),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(
                      Icons.star,
                      size: 42,
                      color: selected ? Colors.amber : Colors.grey.shade400,
                      shadows: selected
                          ? [
                              Shadow(
                                color: Colors.orange.withOpacity(0.6),
                                blurRadius: 10,
                              )
                            ]
                          : [],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),

            Center(
              child: Text(
                "تقييمك الحالي: ${_currentRating.toStringAsFixed(1)} / 5",
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),

            Center(
              child: Text(
                "متوسط التقييم: ⭐ ${_averageRating.toStringAsFixed(1)} من 5 ($_totalRatings تقييم)",
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
