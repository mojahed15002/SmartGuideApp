import 'package:flutter/material.dart';

class CheckpointCard extends StatelessWidget {
  final String id;
  final String name;
  final double lat;
  final double lon;

  /// من Firestore (إن وُجد)
  final String status;               // open | busy | closed | unknown
  final int reports;                 // عدد البلاغات
  final DateTime? statusUpdatedAt;   // آخر تحديث

  /// تحكم بالعرض حسب السياق
  final bool showMapButton;          // في MapPage = false
  final bool showSuggestName;        // إذا الحاجز غير موجود بالـ DB

  /// أزرار الإجراءات (نمررها من الصفحة المالكة)
  final VoidCallback onReportPressed;
  final VoidCallback? onShowOnMap;       // في CheckpointsPage فقط
  final VoidCallback? onSuggestName;     // عند عدم وجوده في DB

  const CheckpointCard({
    super.key,
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.status,
    required this.reports,
    required this.statusUpdatedAt,
    required this.showMapButton,
    required this.showSuggestName,
    required this.onReportPressed,
    this.onShowOnMap,
    this.onSuggestName,
  });

  Color _statusColor(String s) => {
        "open": Colors.green,
        "busy": Colors.orange,
        "closed": Colors.red,
      }[s] ?? Colors.grey;

  IconData _statusIcon(String s) => {
        "open": Icons.check_circle,
        "busy": Icons.access_time_filled,
        "closed": Icons.block,
      }[s] ?? Icons.help;

  String _statusLabel(String s) {
    switch (s) {
      case "open": return "مفتوح";
      case "busy": return "مكتظ";
      case "closed": return "مغلق";
      default: return "غير معروف";
    }
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return "غير متوفر";
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "منذ لحظات";
    if (diff.inMinutes < 60) return "قبل ${diff.inMinutes} دقيقة";
    if (diff.inHours   < 24) return "قبل ${diff.inHours} ساعة";
    return "قبل ${diff.inDays} يوم";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0,2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان + الحالة + البلاغات + آخر تحديث
          Row(
            children: [
              Expanded(
                child: Text(name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(_statusIcon(status), color: _statusColor(status), size: 16),
              const SizedBox(width: 4),
              Text("${_statusLabel(status)} ($reports)",
                style: TextStyle(fontSize: 12, color: _statusColor(status), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text("آخر تحديث: ${_timeAgo(statusUpdatedAt)}",
              style: TextStyle(fontSize: 11, color: Colors.grey[700])),

          const SizedBox(height: 10),

          // الأزرار
          Row(
            children: [
              // إبلاغ
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                icon: const Icon(Icons.flag),
                label: const Text("إبلاغ"),
                onPressed: onReportPressed,
              ),

              const SizedBox(width: 8),

              // اقتراح اسم (اختياري)
              if (showSuggestName && onSuggestName != null)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text("اقتراح اسم", style: TextStyle(fontSize: 13)),
                  onPressed: onSuggestName,
                ),

              const SizedBox(width: 8),

              // عرض على الخريطة (اختياري)
              if (showMapButton && onShowOnMap != null)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  icon: const Icon(Icons.map),
                  label: const Text("عرض على الخريطة"),
                  onPressed: onShowOnMap,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
