import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart' as fs;

/// نموذج بيانات المكان
class Place {
  final String id;
  final String name;
  final String city;
  final String category; // museum, park, cafe...
  final double lat;
  final double lng;
  final double rating; // 0..5
  final String imageUrl;
  final String description;

  const Place({
    required this.id,
    required this.name,
    required this.city,
    required this.category,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.imageUrl,
    required this.description,
  });

  factory Place.fromMap(String id, Map<String, dynamic> m) {
    return Place(
      id: id,
      name: (m['name'] ?? '').toString(),
      city: (m['city'] ?? '').toString(),
      category: (m['category'] ?? '').toString(),
      lat: (m['lat'] as num?)?.toDouble() ?? 0,
      lng: (m['lng'] as num?)?.toDouble() ?? 0,
      rating: (m['rating'] as num?)?.toDouble() ?? 0,
      imageUrl: (m['imageUrl'] ?? '').toString(),
      description: (m['description'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'city': city,
        'category': category,
        'lat': lat,
        'lng': lng,
        'rating': rating,
        'imageUrl': imageUrl,
        'description': description,
      };
}

/// واجهة المستودع
abstract class PlacesRepository {
  Future<List<Place>> listAll();
  Stream<List<Place>> watchAll();
  Future<Place?> getById(String id);
  Future<List<Place>> nearby(double centerLat, double centerLng, {double radiusKm = 5});
  Stream<Set<String>> watchFavorites(String uid);
  Future<void> toggleFavorite(String uid, String placeId, bool setFavorite);
}

/// ------------------------------------------------------------------------------------
/// تنفيذ Mock (يعمل بدون أي إعدادات خارجية)
/// ------------------------------------------------------------------------------------
class MockPlacesRepository implements PlacesRepository {
  final List<Place> _mock = const [
    Place(
      id: 'p1',
      name: 'حديقة الاستقلال',
      city: 'رام الله',
      category: 'park',
      lat: 31.903, lng: 35.203,
      rating: 4.5,
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/6/65/City_Park_Example.jpg',
      description: 'مساحات خضراء ومرافق عائلية ومسارات مشي.',
    ),
    Place(
      id: 'p2',
      name: 'متحف الزمن',
      city: 'نابلس',
      category: 'museum',
      lat: 32.219, lng: 35.261,
      rating: 4.2,
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/3/3a/Museum_example.jpg',
      description: 'مقتنيات تاريخية وعروض تفاعلية.',
    ),
    Place(
      id: 'p3',
      name: 'مقهى الساحة',
      city: 'بيت لحم',
      category: 'cafe',
      lat: 31.705, lng: 35.201,
      rating: 4.0,
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/45/Cafe_terrace_example.jpg',
      description: 'قهوة ممتازة وجلسات خارجية مريحة.',
    ),
  ];

  final _favoritesByUser = <String, Set<String>>{};
  final _controller = StreamController<List<Place>>.broadcast();

  MockPlacesRepository() {
    _controller.add(_mock);
  }

  @override
  Future<List<Place>> listAll() async => _mock;

  @override
  Stream<List<Place>> watchAll() => _controller.stream;

  @override
  Future<Place?> getById(String id) async {
    for (final p in _mock) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<List<Place>> nearby(double centerLat, double centerLng, {double radiusKm = 5}) async {
    // تبسيط: نعيد الكل — لاحقًا نفلتر بالحساب
    return _mock;
  }

  @override
  Stream<Set<String>> watchFavorites(String uid) async* {
    _favoritesByUser.putIfAbsent(uid, () => <String>{});
    yield _favoritesByUser[uid]!;
  }

  @override
  Future<void> toggleFavorite(String uid, String placeId, bool setFavorite) async {
    final set = _favoritesByUser.putIfAbsent(uid, () => <String>{});
    if (setFavorite) {
      set.add(placeId);
    } else {
      set.remove(placeId);
    }
  }
}

/// ------------------------------------------------------------------------------------
/// تنفيذ Firestore (جاهز — بما أنك فعّلت cloud_firestore)
/// collections:
///   - places
///   - users/{uid} { favorites: [placeId, ...] }
/// ------------------------------------------------------------------------------------
class FirestorePlacesRepository implements PlacesRepository {
  final fs.FirebaseFirestore _db;
  FirestorePlacesRepository({fs.FirebaseFirestore? db}) : _db = db ?? fs.FirebaseFirestore.instance;

  @override
  Future<List<Place>> listAll() async {
    final q = await _db.collection('places').orderBy('name').get();
    return q.docs.map((d) => Place.fromMap(d.id, d.data())).toList();
  }

  @override
  Stream<List<Place>> watchAll() {
    return _db.collection('places').orderBy('name').snapshots().map(
          (s) => s.docs.map((d) => Place.fromMap(d.id, d.data())).toList(),
        );
  }

  @override
  Future<Place?> getById(String id) async {
    final d = await _db.collection('places').doc(id).get();
    if (!d.exists) return null;
    return Place.fromMap(d.id, d.data()!);
  }

  @override
  Future<List<Place>> nearby(double centerLat, double centerLng, {double radiusKm = 5}) async {
    // تبسيط: نجلب الكل ثم نفلتر بالمسافة (للإنتاج استعمل geohash).
    final all = await listAll();
    return all.where((p) => _haversineKm(centerLat, centerLng, p.lat, p.lng) <= radiusKm).toList();
  }

  @override
  Stream<Set<String>> watchFavorites(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      final data = snap.data();
      final list = (data?['favorites'] as List?)?.cast<String>() ?? const <String>[];
      return list.toSet();
    });
  }

  @override
  Future<void> toggleFavorite(String uid, String placeId, bool setFavorite) async {
    final ref = _db.collection('users').doc(uid);
    if (setFavorite) {
      await ref.set({'favorites': fs.FieldValue.arrayUnion([placeId])}, fs.SetOptions(merge: true));
    } else {
      await ref.set({'favorites': fs.FieldValue.arrayRemove([placeId])}, fs.SetOptions(merge: true));
    }
  }
}

/// حساب المسافة (km) بصيغة Haversine باستخدام dart:math
double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371.0; // نصف قطر الأرض بالكيلومتر
  double toRad(double deg) => deg * math.pi / 180.0;

  final dLat = toRad(lat2 - lat1);
  final dLon = toRad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(toRad(lat1)) * math.cos(toRad(lat2)) *
          math.sin(dLon / 2) * math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return R * c;
}
