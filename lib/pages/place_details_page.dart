import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_notifier.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'full_screen_gallery.dart';
import 'swipeable_page_route.dart';

class PlaceDetailsPage extends StatefulWidget {
  final String title;
  final String cityName;
  final List<String> images;
  final String url;
  final ThemeNotifier themeNotifier;
  final String heroTag;
  final String id;

  const PlaceDetailsPage({
    super.key,
    required this.title,
    required this.cityName,
    required this.images,
    required this.url,
    required this.themeNotifier,
    required this.heroTag,
    required this.id,
  });

  @override
  State<PlaceDetailsPage> createState() => _PlaceDetailsPageState();
}

class _PlaceDetailsPageState extends State<PlaceDetailsPage>
    with SingleTickerProviderStateMixin {
  int _activeIndex = 0;
  double _userRating = 0.0;
  double _averageRating = 0.0;
  bool _isSubmitting = false;
  String? _placeId;
  String? _guestId;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: 0.9,
      upperBound: 1.3,
    );
    _initGuestAndLoad();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// 🔹 تحديد المعرّف الصحيح للمستخدم الحالي (UID أو GuestID)
  String get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      return user.uid; // مستخدم مسجل فعليًا
    }
    return _guestId ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// إنشاء معرف ضيف ثابت + تحميل التقييم من التخزين المحلي والـ Firestore
  Future<void> _initGuestAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    _guestId = prefs.getString("guest_id");
    if (_guestId == null) {
      final random = Random();
      final suffix = List.generate(6, (_) => random.nextInt(9)).join();
      _guestId = "guest_$suffix";
      await prefs.setString("guest_id", _guestId!);
    }

    // تحميل من SharedPreferences أولًا
    final localKey = "rating_${widget.title}";
    final localRating = prefs.getDouble(localKey);
    if (localRating != null) {
      setState(() => _userRating = localRating);
    }

    // ثم Firestore
    await _loadRatings();
  }

  /// تحميل تقييمات المكان ومتوسطها
  Future<void> _loadRatings() async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('places').doc(widget.id).get();

      if (!doc.exists) return;
      _placeId = doc.id;

      final data = doc.data();
      final ratings = Map<String, dynamic>.from(data?['ratings'] ?? {});

      final currentId = _currentUserId;
      if (ratings.containsKey(currentId)) {
        _userRating = (ratings[currentId] as num).toDouble();
      }

      if (ratings.isNotEmpty) {
        double sum = 0;
        for (var r in ratings.values) {
          sum += (r as num).toDouble();
        }
        _averageRating = sum / ratings.length;
      }

      setState(() {});
    } catch (e) {
      debugPrint("⚠️ فشل تحميل التقييمات: $e");
    }
  }

  /// حفظ التقييم محليًا وعلى Firestore
  Future<void> _submitRating(double rating) async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _userRating = rating;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final localKey = "rating_${widget.id}";
      await prefs.setDouble(localKey, rating);

      final docRef =
          FirebaseFirestore.instance.collection('places').doc(widget.id);

      debugPrint("✅ Saving rating for ${_currentUserId} on place ${widget.id} = $rating");

      await docRef.update({
        'ratings.${_currentUserId}': rating,
      });

      await _loadRatings();

      _animController.forward(from: 0.9);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تم حفظ تقييمك (${rating.toStringAsFixed(1)} ⭐)"),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        debugPrint("⚠️ الوثيقة غير موجودة، سيتم إنشاؤها الآن.");
        final docRef =
            FirebaseFirestore.instance.collection('places').doc(widget.id);
        await docRef.set({
          'ratings': {_currentUserId: rating}
        }, SetOptions(merge: true));
      } else {
        debugPrint("❌ Firebase error: ${e.message}");
      }
    } catch (e) {
      debugPrint("❌ فشل حفظ التقييم: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("حدث خطأ أثناء حفظ التقييم"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
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
      appBar: AppBar(title: Text("تفاصيل ${widget.title}")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Text(
              "${widget.title} - ${widget.cityName}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // عرض الصور
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
                    Navigator.pushReplacement(
                      context,
                      SwipeablePageRoute(
                        page: FullScreenGallery(
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

            const SizedBox(height: 32),
            const Divider(height: 40),

            const Text(
              "⭐ قيّم هذا المكان:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // النجوم التفاعلية
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                final isFilled = _userRating >= starIndex;

                return GestureDetector(
                  onTap: () => _submitRating(starIndex.toDouble()),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1, end: 1.25).animate(
                      CurvedAnimation(
                        parent: _animController,
                        curve: Curves.elasticOut,
                      ),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: isFilled
                            ? [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.6),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                )
                              ]
                            : [],
                      ),
                      child: Icon(
                        Icons.star,
                        color:
                            isFilled ? Colors.amber : Colors.grey.shade400,
                        size: 38,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 12),
            if (_userRating > 0)
              Center(
                child: Text(
                  "تقييمك الحالي: ${_userRating.toStringAsFixed(1)} / 5",
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87),
                ),
              ),
            if (_averageRating > 0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Center(
                  child: Text(
                    "متوسط تقييم هذا المكان: ⭐ ${_averageRating.toStringAsFixed(1)} من 5",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
