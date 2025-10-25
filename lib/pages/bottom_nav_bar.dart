import 'package:flutter/material.dart';

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

class _BottomNavBarState extends State<BottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: Colors.orange.shade700,
      child: SizedBox(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                Icons.home,
                color: widget.currentIndex == 0
                    ? Colors.white
                    : Colors.white70,
              ),
              onPressed: () => widget.onTap(0),
            ),
            IconButton(
              icon: Icon(
                Icons.favorite,
                color: widget.currentIndex == 1
                    ? Colors.white
                    : Colors.white70,
              ),
              onPressed: () => widget.onTap(1),
            ),
            const SizedBox(width: 40), // مكان الزر العائم
            
            IconButton(
              icon: Icon(
                Icons.person,
                color: widget.currentIndex == 3
                    ? Colors.white
                    : Colors.white70,
              ),
              onPressed: () => widget.onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}
