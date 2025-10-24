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

// ✅ إضافة ملف الترجمة
import '../l10n/gen/app_localizations.dart';

class ChoicePage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const ChoicePage({super.key, required this.themeNotifier});

  @override
  State<ChoicePage> createState() => _ChoicePageState();
}

class _ChoicePageState extends State<ChoicePage> {
  @override
  Widget build(BuildContext context) {
    // ✅ تحديد اتجاه الصفحة حسب اللغة
    final isArabic = AppLocalizations.of(context)!.localeName == 'ar';
    final direction = isArabic ? TextDirection.rtl : TextDirection.ltr;

    //  نقلنا تعريف الماب لداخل build
    final Map<String, Widget Function()> placePages = {
      AppLocalizations.of(context)!.academyStreet: () =>
          AcademyStreetPage(themeNotifier: widget.themeNotifier),
      AppLocalizations.of(context)!.sofianStreet: () =>
          SofianStreetPage(themeNotifier: widget.themeNotifier),
      AppLocalizations.of(context)!.faisalStreet: () =>
          FaisalStreetPage(themeNotifier: widget.themeNotifier),
      AppLocalizations.of(context)!.martyrsRoundabout: () =>
          MartyrsRoundaboutPage(themeNotifier: widget.themeNotifier),
      AppLocalizations.of(context)!.palestineStreet: () =>
          PalestineStreetPage(themeNotifier: widget.themeNotifier),
    };

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.chooseLocation),
          actions: [
            // ✅ زر التبديل
          ],
        ),
        drawer: CustomDrawer(
          themeNotifier: widget.themeNotifier,
        ), // ⬅️ هذا السطر المهم
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
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.searchHint,
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(
                            Icons.search,
                            color: Colors.orange,
                          ),
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
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      // ignore: use_build_context_synchronously
                      context,
                      SwipeablePageRoute(
                        page: MapPage(
                          position: position,
                          themeNotifier: widget.themeNotifier,
                        ), // ✅ مررنا themeNotifier
                      ),
                    );
                  
                },
                child: Text(AppLocalizations.of(context)!.whereAmI),
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
                      builder: (context) =>
                          GeneralInfoPage(themeNotifier: widget.themeNotifier),
                    ),
                  );
                },
                child: Text(AppLocalizations.of(context)!.viewAllCities),
              ),
            ],
          ),
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
      throw Exception(AppLocalizations.of(context)!.locationServiceDisabled);
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(AppLocalizations.of(context)!.locationDenied);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(AppLocalizations.of(context)!.locationDeniedForever);
    }

    return await Geolocator.getCurrentPosition();
  }
}
