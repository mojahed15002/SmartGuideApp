import 'package:flutter/material.dart';
import 'dart:ui';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          color: Colors.transparent,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          child: Container(
            height: 75,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepOrange.shade400,
                  Colors.orange.shade600,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAnimatedItem(Icons.home, 0),       // 🏠 الرئيسية
                _buildAnimatedItem(Icons.favorite, 1),   // ❤️ المفضلة
                const SizedBox(width: 40),               // مكان الزر العائم
                _buildAnimatedItem(Icons.place, 2),      // 📍 القريبة مني
                _buildAnimatedItem(Icons.person, 3),     // 👤 الملف الشخصي
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedItem(IconData icon, int index) {
    final bool isActive = widget.currentIndex == index;

    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        transform: Matrix4.identity()
          ..translate(0.0, isActive ? -8.0 : 0.0) // ⬆️ تحريك للأعلى عند التفعيل
          ..scale(isActive ? 1.25 : 1.0), // 🔍 تكبير بسيط عند التفعيل
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: isActive ? 30 : 25,
          color: isActive ? Colors.white : Colors.white70,
        ),
      ),
    );
  }
}
