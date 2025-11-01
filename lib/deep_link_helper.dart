import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme_notifier.dart';
import 'pages/place_details_page.dart';

/// ✅ Stream عام لإرسال الروابط إلى الصفحات المفتوحة داخل التطبيق
final StreamController<Uri> deepLinkStreamController =
    StreamController.broadcast();

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
Future<void> openPlaceFromUri({
  required BuildContext context,
  required ThemeNotifier themeNotifier,
  required Uri uri,
}) async {
  try {
    debugPrint("🔗 تم استقبال الرابط: $uri");

    String? city = uri.queryParameters['city'];
    String? id = uri.queryParameters['id'];

    if (city == null || id == null) {
      debugPrint('⚠️ الرابط لا يحتوي على city أو id');
      return;
    }

    // ✅ التحقق من المستخدم الحالي أو تسجيل دخول كضيف
    final auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    if (user == null) {
      try {
        final userCred = await auth.signInAnonymously();
        user = userCred.user;
        debugPrint("👤 تم تسجيل الدخول كضيف: ${user?.uid}");
      } catch (e) {
        debugPrint("❌ فشل تسجيل الدخول كضيف: $e");
      }
    }

    // ✅ تحميل بيانات المكان من Firestore باستخدام الـ id
    DocumentSnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot =
          await FirebaseFirestore.instance.collection('places').doc(id).get();
    } catch (e) {
      debugPrint('❌ خطأ في تحميل بيانات المكان من Firestore: $e');
      return;
    }

    if (!snapshot.exists || snapshot.data() == null) {
      debugPrint('⚠️ لم يتم العثور على المستند المطلوب في Firestore.');
      return;
    }

    final placeData = snapshot.data()!;
    final title = placeData['title_ar'] ?? placeData['title_en'] ?? 'بدون عنوان';
    final cityName = placeData['city_ar'] ?? placeData['city_en'] ?? city;
    final images = List<String>.from(placeData['images'] ?? []);
    final url = placeData['url'] ?? '';
    final heroTag = placeData['hero'] ?? 'hero_$id';

// ✅ نفتح الصفحة بعد التأكد من جاهزية الواجهة والـ Navigator بشكل مضمون
WidgetsBinding.instance.addPostFrameCallback((_) async {
  // نعطي فرصة قصيرة إضافية على بعض الأجهزة البطيئة
  await Future.delayed(const Duration(milliseconds: 300));
  if (!context.mounted) return;

  // استخدام الـ rootNavigator لضمان وجود Navigator صالح حتى لو تغيّر الـ context
  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => PlaceDetailsPage(
         id: id,
        title: title,
        cityName: cityName,
        images: images,
        url: url,
        themeNotifier: themeNotifier,
        heroTag: heroTag,
      ),
    ),
    (route) => false,
  );
});
  } catch (e) {
    debugPrint("❌ خطأ أثناء تنفيذ openPlaceFromUri: $e");
  }
}
