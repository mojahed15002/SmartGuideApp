import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../theme_notifier.dart';
import 'bottom_nav_bar.dart';
import 'map_page.dart';
import 'favorites_page.dart';
import 'profile_page.dart';
import 'choice_page.dart';
import 'custom_drawer.dart';
import 'near_me_page.dart';

class MainNavigation extends StatefulWidget {
  final ThemeNotifier themeNotifier;

  const MainNavigation({super.key, required this.themeNotifier});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>(); // ✅ مفتاح للتحكم بالـ Drawer
  int _currentIndex = 0;
  Position? _initialPosition;
  String? _locError;

  @override
  void initState() {
    super.initState();
    _loadInitialPosition();
  }

  void _onDrawerItemSelected(String item) {
    Navigator.pop(context); // يغلق القائمة الجانبية

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

  // ✅ محتوى التبويبات
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return ChoicePage(themeNotifier: widget.themeNotifier);
      case 1:
        return FavoritesPage(themeNotifier: widget.themeNotifier);
      case 2:
        return NearMePage(themeNotifier: widget.themeNotifier);
      case 3:
        return ProfilePage(themeNotifier: widget.themeNotifier);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey, // ✅ نربط المفتاح هنا
      drawer: CustomDrawer(
        themeNotifier: widget.themeNotifier,
        onTabSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      body: _buildBody(),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrangeAccent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        onPressed: () {
          if (_initialPosition != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MapPage(
                  position: _initialPosition!,
                  themeNotifier: widget.themeNotifier,
                  enableLiveTracking: true,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('لم يتم تحديد موقعك بعد!'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        child: const Icon(Icons.map, color: Colors.white, size: 28),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
