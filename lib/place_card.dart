import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme_notifier.dart';

typedef OnFavoriteChanged = void Function(String placeId, bool isFav);

class PlaceCard extends StatefulWidget {
  final String placeId;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final ThemeNotifier themeNotifier;
  final OnFavoriteChanged? onFavoriteChanged;

  const PlaceCard({
    super.key,
    required this.placeId,
    required this.title,
    required this.subtitle,
    required this.themeNotifier,
    this.imageUrl,
    this.onFavoriteChanged,
  });

  @override
  State<PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<PlaceCard> {
  bool isFavorite = false;
  static const _prefsKey = 'favorites_list';

  @override
  void initState() {
    super.initState();
    _loadFav();
  }

  Future<void> _loadFav() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];
    setState(() {
      isFavorite = list.contains(widget.placeId);
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];

    setState(() {
      isFavorite = !isFavorite;
    });

    if (isFavorite) {
      if (!list.contains(widget.placeId)) list.add(widget.placeId);
    } else {
      list.remove(widget.placeId);
    }

    await prefs.setStringList(_prefsKey, list);

    if (widget.onFavoriteChanged != null) {
      widget.onFavoriteChanged!(widget.placeId, isFavorite);
    }

    // ✅ إظهار رسالة لطيفة بعد الضغط على القلب
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite ? 'تمت الإضافة إلى المفضلة ❤️' : 'تمت الإزالة من المفضلة 💔',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: isFavorite ? Colors.orangeAccent : Colors.grey[700],
        duration: const Duration(milliseconds: 1300),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeNotifier.value == ThemeMode.dark;
    final Color primaryColor = isDark ? Colors.orangeAccent : Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      color: isDark ? Colors.grey[900] : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: widget.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.imageUrl!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 72,
                    color: Colors.grey[300],
                    child: const Icon(Icons.location_on, color: Colors.grey),
                  ),
                ),
              )
            : Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on, color: Colors.grey),
              ),
        title: Text(
          widget.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          widget.subtitle,
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        trailing: IconButton(
          onPressed: _toggleFavorite,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(isFavorite),
              color: isFavorite
                  ? primaryColor
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
              size: 28,
            ),
          ),
        ),
        onTap: () {
          // يمكنك لاحقاً فتح تفاصيل المكان هنا
        },
      ),
    );
  }
}
