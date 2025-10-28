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

// ✅ الترجمة
import '../l10n/gen/app_localizations.dart';


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

  // 💬 متغيرات التعليقات
  final TextEditingController _commentController = TextEditingController();
  bool _isSendingComment = false;

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
            '${AppLocalizations.of(context)!.ratingSubmitted}: $rating ⭐',
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

  // 💬 دالة إرسال التعليق
Future<void> _submitComment() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.pleaseLoginToComment)),
    );
    return;
  }

  final commentText = _commentController.text.trim();
  if (commentText.isEmpty) return;

  setState(() => _isSendingComment = true);

  try {
    final placeRef = FirebaseFirestore.instance.collection('places').doc(placeId);

    final userType = user.isAnonymous ? 'guest' : 'registered';
    final userName = user.isAnonymous
        ? AppLocalizations.of(context)!.guest
        : (user.displayName ?? user.email ?? AppLocalizations.of(context)!.user);

    // 👇 1. أنشئ التعليق بدون الوقت
    final newComment = {
      'uid': user.uid,
      'text': commentText,
      'type': userType,
      'name': userName,
      'photoUrl': user.photoURL ?? '',
      'time': DateTime.now(), // مبدئيًا نحط الوقت الحالي
    };

    // 👇 2. أضف التعليق إلى القائمة
    await placeRef.update({
      'comments_list': FieldValue.arrayUnion([newComment]),
    }).catchError((_) async {
      await placeRef.set({'comments_list': [newComment]}, SetOptions(merge: true));
    });

    // 👇 3. بعد الإضافة، حدث آخر تعليق بختم الوقت الحقيقي من الخادم
    await placeRef.update({
      'last_comment_time': FieldValue.serverTimestamp(),
    });

    setState(() {
      _isSendingComment = false;
      _commentController.clear();
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.commentAdded)),
    );
  } catch (e) {
    setState(() => _isSendingComment = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${AppLocalizations.of(context)!.commentFailed}: $e"),
      ),
    );
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
          "${AppLocalizations.of(context)!.detailsOf} ${widget.title}",
          style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color.fromARGB(255, 0, 0, 0)),
          onPressed: () {
            Navigator.pop(context);
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
              "${AppLocalizations.of(context)!.defaultDescription} ${widget.title} ${AppLocalizations.of(context)!.inCity} ${widget.cityName}.",
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
            Text(
              AppLocalizations.of(context)!.rateThisPlace,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // نجوم التقييم
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
                "${AppLocalizations.of(context)!.yourRating}: ${_currentRating.toStringAsFixed(1)} / 5",
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),

            Center(
              child: Text(
                "${AppLocalizations.of(context)!.averageRating}: ⭐ ${_averageRating.toStringAsFixed(1)} / 5 ($_totalRatings ${AppLocalizations.of(context)!.ratings})",
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 25),
            const Divider(thickness: 1.5),

            // 💬 قسم التعليقات
            Text(
              AppLocalizations.of(context)!.addComment,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.writeCommentHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isSendingComment ? null : _submitComment,
              icon: const Icon(Icons.send),
              label: _isSendingComment
                  ? Text(AppLocalizations.of(context)!.sending)
                  : Text(AppLocalizations.of(context)!.sendComment),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),

// 💬 عرض التعليقات
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('places')
      .doc(placeId)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!snapshot.hasData || !snapshot.data!.exists) {
      return Text(
        AppLocalizations.of(context)!.noCommentsYet,
        style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
      );
    }

    final data = snapshot.data!.data() as Map<String, dynamic>?;
    final commentsList = (data?['comments_list'] ?? []) as List<dynamic>;

    if (commentsList.isEmpty) {
      return Text(
        AppLocalizations.of(context)!.noCommentsYet,
        style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
      );
    }

    // ✅ ترتيب الأحدث أولًا
    commentsList.sort((a, b) {
      final at = (a['time'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final bt = (b['time'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return bt.compareTo(at);
    });

    final limitedComments = commentsList.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...limitedComments.map((commentInfo) {
          final commentText = commentInfo['text'] ?? '';
          final displayName = commentInfo['name'] ?? AppLocalizations.of(context)!.guest;
          final photoUrl = commentInfo['photoUrl'] ?? '';
          final timestamp = commentInfo['time'] as Timestamp?;
          final date = timestamp?.toDate();

          String formattedTime = '';
          if (date != null) {
            final diff = DateTime.now().difference(date);
            if (diff.inMinutes < 1) {
              formattedTime = AppLocalizations.of(context)!.justNow;
            } else if (diff.inMinutes < 60) {
              formattedTime = "${diff.inMinutes} ${AppLocalizations.of(context)!.minutesAgo}";
            } else if (diff.inHours < 24) {
              formattedTime = "${diff.inHours} ${AppLocalizations.of(context)!.hoursAgo}";
            } else {
              formattedTime = "${date.day}/${date.month}/${date.year}";
            }
          }

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(1, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              leading: CircleAvatar(
                radius: 22,
                backgroundImage: (photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                backgroundColor: photoUrl.isEmpty
                    ? Colors.orange.shade100
                    : Colors.transparent,
                child: photoUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.orange)
                    : null,
              ),
              title: Text(
                commentText,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          "${AppLocalizations.of(context)!.byUser}: $displayName",
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (formattedTime.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "📅 $formattedTime",
                          style: const TextStyle(fontSize: 12, color: Colors.black45),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          );
        }),

        // ✅ زر عرض جميع التعليقات (يظهر فقط عند وجود أكثر من 2)
        if (commentsList.length > 2)
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/all_comments', arguments: placeId);
              },
              icon: const Icon(Icons.comment, color: Colors.orange),
              label: Text(
                AppLocalizations.of(context)!.viewAllComments,
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  },
)
          ],
        ),
      ),
    );
  }
}
