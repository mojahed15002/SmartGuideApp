import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme_notifier.dart';
import 'bottom_nav_bar.dart';
import 'map_page.dart';
import 'favorites_page.dart';
import 'profile_page.dart';
import 'choice_page.dart';
import 'custom_drawer.dart';


class MainNavigation extends StatefulWidget {
  final ThemeNotifier themeNotifier;

  const MainNavigation({super.key, required this.themeNotifier});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  Position? _initialPosition;
  String? _locError;

  @override
  void initState() {
    super.initState();
    _loadInitialPosition();
  }

void _onDrawerItemSelected(String item) {
  Navigator.pop(context); // لإغلاق القائمة الجانبية

  switch (item) {
    case 'home':
      setState(() => _currentIndex = 0);
      break;
    case 'near_me':
      setState(() => _currentIndex = 1);
      break;
    case 'favorites':
      setState(() => _currentIndex = 2);
      break;
  }
}

  Future<void> _loadInitialPosition() async {
    try {
      // طلب الإذن
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() => _locError = "الرجاء تفعيل إذن الموقع من الإعدادات.");
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      if (!mounted) return;
      setState(() {
        _initialPosition = pos;
        _locError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _locError = "تعذّر الحصول على الموقع: $e");
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return ChoicePage(
          themeNotifier: widget.themeNotifier,
          
        ); // 🏠 الرئيسية
      case 1:
        if (_locError != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _locError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        }
        if (_initialPosition == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return MapPage(
          position: _initialPosition!,               // ✅ Position (مش LatLng)
          themeNotifier: widget.themeNotifier,
          enableLiveTracking: true,                  // اختياري
        );
      case 2:
        return FavoritesPage(themeNotifier: widget.themeNotifier); // ❤️
      
      case 3:
        return ProfilePage(themeNotifier: widget.themeNotifier);  // ⚙️
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(
    themeNotifier: widget.themeNotifier,
    onItemSelected: _onDrawerItemSelected, // ⬅️ استدعاء دالة عند اختيار عنصر من القائمة
  ),
      body: _buildBody(),

      // 🔸 الزر العائم (الخريطة)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        elevation: 6,
        onPressed: () => setState(() => _currentIndex = 1),
        child: const Icon(Icons.map, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 🔹 الشريط السفلي
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
