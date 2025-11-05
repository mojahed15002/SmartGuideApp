// lib/widgets/smart_place_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../l10n/gen/app_localizations.dart';
import '../theme_notifier.dart';

class SmartPlaceCardWidget extends StatelessWidget {
  final Map<String, dynamic> place;
  final ThemeNotifier themeNotifier;

  // حالات وأحداث
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onDetails;
  final VoidCallback? onNavigate;
  final VoidCallback? onStart;
  final VoidCallback? onAR;
  final bool isTripActive;

  const SmartPlaceCardWidget({
    super.key,
    required this.place,
    required this.themeNotifier,
    required this.isFavorite,
    required this.isTripActive,
    this.onFavoriteToggle,
    this.onDetails,
    this.onNavigate,
    this.onStart,
    this.onAR,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final bool isKnown = place["id"] != null;
    final String name = place['name'] ?? loc.unknownLocation;
    final String city = place['city'] ?? "";
    final double? lat = (place['latitude'] as num?)?.toDouble();
    final double? lng = (place['longitude'] as num?)?.toDouble();
    final images = place['images'] ?? [];
    final rating = place['rating'] is num ? (place['rating'] as num).toDouble() : 4.5;
    final reviews = place['reviews'] ?? 12;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة + اسم + مدينة + تقييم
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: images is List && images.isNotEmpty
                        ? Image.asset(
                            images[0],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.place, color: Colors.orange),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            )),
                        if (isKnown && city.isNotEmpty)
                          Text(
                            city,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        if (isKnown)
                          Row(
                            children: [
                              const Icon(Icons.star, size: 18, color: Colors.orange),
                              Text("$rating "),
                              Text(
                                "($reviews ${loc.reviews})",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // زر التفاصيل (إذا كان المكان معروف)
              if (isKnown)
                IconButton(
                  tooltip: loc.details,
                  icon: const Icon(Icons.info_outline, color: Colors.orange),
                  onPressed: onDetails,
                ),

              // الأزرار (AR - مفضلة - ملاحة - بدء الرحلة)
              Row(
                children: [
                  // AR
                  IconButton(
                    tooltip: loc.arDirection,
                    icon: const Icon(Icons.camera_alt, color: Colors.orange, size: 26),
                    onPressed: (lat == null || lng == null) ? null : onAR,
                  ),

                  // مفضلة
                  if (isKnown)
                    IconButton(
                      tooltip: loc.favoritesLabel, // تأكد أن لديك هذا النص، أو ضع "مفضلة"
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.orange,
                        size: 26,
                      ),
                      onPressed: onFavoriteToggle,
                    ),

                  // ملاحة
                  IconButton(
                    tooltip: loc.timeLabel, // أو غيّره لـ "تنقّل"
                    icon: const Icon(Icons.navigation, color: Colors.orange, size: 28),
                    onPressed: (lat == null || lng == null) ? null : onNavigate,
                  ),

                  const Spacer(),

// زر بدء/إيقاف الرحلة
ElevatedButton.icon(
  onPressed: (lat == null || lng == null) ? null : onStart,
  icon: Icon(
    isTripActive ? Icons.stop : Icons.play_arrow,
  ),
  label: Text(
    isTripActive ? loc.stop : loc.start, // "إيقاف" بدلاً من "ابدأ"
  ),
  style: ElevatedButton.styleFrom(
    backgroundColor: isTripActive ? Colors.red : Colors.green,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
