import 'package:flutter/material.dart';
import '../l10n/gen/app_localizations.dart';

class CategoryFilter extends StatefulWidget {
  final List<String> selectedCategories;
  final Function(List<String>) onChanged;
final Map<String, int> categoryCounts;

  const CategoryFilter({
    super.key,
    required this.selectedCategories,
    required this.onChanged,
    required this.categoryCounts,
  });

  @override
  State<CategoryFilter> createState() => _CategoryFilterState();
}

class _CategoryFilterState extends State<CategoryFilter> {

  List<Map<String, dynamic>> _categories(context) => [
{ 'key': 'all', 'label': AppLocalizations.of(context)!.showAll, 'icon': null },
    { 'key': 'tourism',    'label': AppLocalizations.of(context)!.touristPlaces,  'icon': Icons.museum },
    { 'key': 'restaurant', 'label': AppLocalizations.of(context)!.restaurants,    'icon': Icons.restaurant },
    { 'key': 'cafe',       'label': AppLocalizations.of(context)!.cafes,          'icon': Icons.local_cafe },
    { 'key': 'clothes',    'label': AppLocalizations.of(context)!.clothingStores, 'icon': Icons.shopping_bag },
    { 'key': 'sweets',     'label': AppLocalizations.of(context)!.sweets,         'icon': Icons.cake },
    { 'key': 'hotel',      'label': AppLocalizations.of(context)!.hotels,         'icon': Icons.hotel },
  ];

  @override
  Widget build(BuildContext context) {
    final cats = _categories(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color activeColor = Colors.deepOrange;
    Color inactiveText = isDark ? Colors.white70 : Colors.black87;
    Color inactiveBorder = Colors.deepOrange;
    Color inactiveBg = isDark ? Colors.black26 : Colors.grey.shade200;

    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: cats.length,
        itemBuilder: (context, index) {
          final item = cats[index];
          final key = item['key'];
          final label = item['label'];
          final icon = item['icon'];

          bool isSelected = widget.selectedCategories.isEmpty && key == "all"
              || widget.selectedCategories.contains(key);

return GestureDetector(
  onTap: () => _handleSelect(key),
  child: AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: isSelected ? activeColor : inactiveBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: inactiveBorder,
        width: 1.4,
      ),
    ),
    child: Row(
      children: [
        if (icon != null)
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : inactiveBorder,
          ),
        if (icon != null) const SizedBox(width: 5),

        // ✅ اظهار الاسم + العدد
        Builder(
          builder: (_) {
            int count = widget.categoryCounts[key] ?? 0;
            String textLabel = key == "all" ? label : "$label ($count)";

            return Text(
              textLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : inactiveText,
              ),
            );
          },
        ),
      ],
    ),
  ),
);
        },
      ),
    );
  }

  void _handleSelect(String key) {
    List<String> updated = List.from(widget.selectedCategories);

    if (key == "all") {
      updated.clear();
    } else {
      updated.remove("all");
      if (updated.contains(key)) {
        updated.remove(key);
      } else {
        updated.add(key);
      }
    }

    if (updated.isEmpty) updated = ["all"];

    widget.onChanged(updated);
    setState(() {});
  }
}
