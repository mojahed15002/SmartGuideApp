/// ملف مستخرج تلقائيًا من main.dart
/// يحتوي الكلاس: ChoicePage
library;

import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import 'package:geolocator/geolocator.dart';
import 'academy_street_page.dart';
import 'faisal_street_page.dart';
import 'general_info_page.dart';
import 'map_page.dart';
import 'martyrs_roundabout_page.dart';
import 'palestine_street_page.dart';
import 'sofian_street_page.dart';
import 'custom_drawer.dart';
import 'swipeable_page_route.dart';
class ChoicePage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const ChoicePage({super.key, required this.themeNotifier});

  @override
  State<ChoicePage> createState() => _ChoicePageState();
}

class _ChoicePageState extends State<ChoicePage> {
  @override
  Widget build(BuildContext context) {
    //  نقلنا تعريف الماب لداخل build
    final Map<String, Widget Function()> placePages = {
      "شارع الأكاديمية": () => AcademyStreetPage(themeNotifier: widget.themeNotifier),
      "شارع سفيان": () => SofianStreetPage(themeNotifier: widget.themeNotifier),
      "شارع فيصل": () => FaisalStreetPage(themeNotifier: widget.themeNotifier),
      "دوار الشهداء": () => MartyrsRoundaboutPage(themeNotifier: widget.themeNotifier),
      "شارع فلسطين": () => PalestineStreetPage(themeNotifier: widget.themeNotifier),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("اختيار الموقع"),
        actions: [
           // ✅ زر التبديل
        ],
      ),
      drawer: CustomDrawer(themeNotifier: widget.themeNotifier), // ⬅️ هذا السطر المهم
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return placePages.keys.where((String option) {
                  return option.contains(textEditingValue.text);
                });
              },
              onSelected: (String selection) {
                final pageBuilder = placePages[selection];
                if (pageBuilder != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => pageBuilder()),
                  );
                }
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onEditingComplete) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  decoration: const InputDecoration(
                    hintText: "ابحث عن منطقة أو شارع...",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.search, color: Colors.orange),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              onPressed: () async {
                Position position = await _determinePosition();
                Navigator.push(
                  // ignore: use_build_context_synchronously
                  context,
                  SwipeablePageRoute(
                    page: MapPage(position: position, themeNotifier: widget.themeNotifier), // ✅ مررنا themeNotifier
                  ),
                );
              },
              child: const Text("أين أنا؟ 📍"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GeneralInfoPage(themeNotifier: widget.themeNotifier),
                  ),
                );
              },
              child: const Text("عرض جميع المدن 🏙️"),
            ),
          ],
        ),
      ),
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw Exception("خدمة الموقع غير مفعلة");
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("تم رفض إذن الموقع");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("تم رفض إذن الموقع بشكل دائم");
    }

    return await Geolocator.getCurrentPosition();
  }
}



