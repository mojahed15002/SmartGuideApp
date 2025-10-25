import 'dart:async';
import 'package:flutter/material.dart';
import 'theme_notifier.dart';
import 'pages/place_details_page.dart';
import 'places_data.dart';

/// ✅ Stream عام لإرسال الروابط إلى الصفحات المفتوحة داخل التطبيق
final StreamController<Uri> deepLinkStreamController = StreamController.broadcast();

/// خازن بسيط للرابط المؤجل (يُستخدم عند فتح التطبيق وهو مغلق)
class DeepLinkStore {
  static Uri? _pending;
  static void set(Uri uri) => _pending = uri;
  static Uri? take() {
    final u = _pending;
    _pending = null;
    return u;
  }
}

/// ✅ دالة عامة لفتح صفحة المكان من Uri (تُستخدم من أي مكان في التطبيق)
void openPlaceFromUri({
  required BuildContext context,
  required ThemeNotifier themeNotifier,
  required Uri uri,
}) {
  try {
    debugPrint("🔗 تم استقبال الرابط: $uri");
    String? city;
    String? id;

    if (uri.scheme == 'smartcityguide' && uri.host == 'place') {
      city = uri.queryParameters['city'];
      id = uri.queryParameters['id'];
    } else if (uri.host.contains('github.io') && uri.path.contains('/place')) {
      city = uri.queryParameters['city'];
      id = uri.queryParameters['id'];
    }

    if (city == null || id == null) {
      debugPrint('⚠️ الرابط لا يحتوي city أو id');
      return;
    }

    final place = allPlaces[id];
    if (place == null) {
      debugPrint('⚠️ لم يتم العثور على المكان $id');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 🛡️ فحص الأمان لمنع استخدام context غير فعّال بعد تبديل الثيم
      if (!context.mounted) {
        debugPrint('⚠️ تم تجاهل openPlaceFromUri لأن الـ context لم يعد فعّالاً.');
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlaceDetailsPage(
            title: place['title'],
            cityName: place['city'],
            images: List<String>.from(place['images']),
            url: place['url'],
            themeNotifier: themeNotifier,
            heroTag: place['hero'],
          ),
        ),
      );
    });
  } catch (e) {
    debugPrint("❌ خطأ أثناء تحليل الرابط: $e");
  }
}
