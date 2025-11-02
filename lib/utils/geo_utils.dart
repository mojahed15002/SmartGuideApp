import 'dart:math';

/// حساب الزاوية بين موقع المستخدم والوجهة (bearing)
double calculateBearing(double startLat, double startLng, double endLat, double endLng) {
  double lat1 = startLat * pi / 180;
  double lat2 = endLat * pi / 180;
  double dLon = (endLng - startLng) * pi / 180;

  double y = sin(dLon) * cos(lat2);
  double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

  double bearing = atan2(y, x);
  bearing = bearing * 180 / pi;

  return (bearing + 360) % 360; // تحويل لقيمة بين 0-360
}

/// حساب المسافة بين نقطتين بالكيلومتر
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371; // نصف قطر الأرض بالكيلومتر

  double dLat = (lat2 - lat1) * pi / 180;
  double dLon = (lon2 - lon1) * pi / 180;

  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLon / 2) *
          sin(dLon / 2);

  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}
