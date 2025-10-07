/// ملف مستخرج تلقائيًا من main.dart
/// يحتوي الكلاس: InfoPage
library;

import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter/foundation.dart';
import 'full_screen_gallery.dart';

class InfoPage extends StatefulWidget {
  final String title;
  final String description;
  final List<String> images;
  final ThemeNotifier themeNotifier;

  const InfoPage({
    super.key,
    required this.title,
    required this.description,
    required this.images,
    required this.themeNotifier,
  });

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Text(widget.description, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),

            // Carousel Slider مع السحب + Fullscreen/Zoom
            CarouselSlider.builder(
              itemCount: widget.images.length,
              itemBuilder: (context, index, realIndex) {
                final imgPath = widget.images[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenGallery(
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
                      child: Image.asset(
                        imgPath,
                        fit: BoxFit.cover,
                        width: screenWidth,
                      ),
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
          ],
        ),
      ),
    );
  }
}



/// صفحة الخريطة (محدثة مع ميزات التحكم الكامل)
