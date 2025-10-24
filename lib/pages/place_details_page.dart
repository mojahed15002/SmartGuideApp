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
import 'swipeable_page_route.dart';

class PlaceDetailsPage extends StatefulWidget {
  final String title;
  final String cityName;
  final List<String> images;
  final String url;
  final ThemeNotifier themeNotifier;
  final String heroTag; // جديد: تاج الـ Hero

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
      appBar: AppBar(title: Text("تفاصيل ${widget.title}"), actions: []),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Text(
              "${widget.title} - ${widget.cityName}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Carousel Slider مع السحب + Fullscreen/Zoom
            CarouselSlider.builder(
              itemCount: widget.images.length,
              itemBuilder: (context, index, realIndex) {
                final imgPath = widget.images[index];

                // الصورة داخل الـ Hero عندما تكون الصورة الأولى (أو يمكنك تعديل الشرط إن أردت)
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

            // Dots Indicator
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

            // الرابط
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
          ],
        ),
      ),
    );
  }
}
