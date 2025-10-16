import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_notifier.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'map_page.dart';
import 'package:geolocator/geolocator.dart';

class LogsPage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const LogsPage({super.key, required this.themeNotifier});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ✅ تأكيد قبل حذف جميع السجلات
  Future<void> _confirmClearLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الحذف 🗑️"),
        content: const Text("هل أنت متأكد أنك تريد حذف جميع السجلات؟ لا يمكن التراجع عن هذه العملية."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("حذف الكل"),
          ),
        ],
      ),
    );

    if (confirm == true) _clearLogs();
  }

  Future<void> _clearLogs() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();
    final logs = await _firestore
        .collection('travel_logs')
        .where('user_id', isEqualTo: user.uid)
        .get();

    for (var doc in logs.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🗑️ تم حذف جميع السجلات")),
    );
  }

  // ✅ تأكيد قبل حذف سجل واحد فقط
  Future<void> _confirmDeleteSingleLog(String logId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد حذف الرحلة 🗑️"),
        content: const Text("هل أنت متأكد أنك تريد حذف هذه الرحلة؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("حذف"),
          ),
        ],
      ),
    );

    if (confirm == true) _deleteSingleLog(logId);
  }

  Future<void> _deleteSingleLog(String logId) async {
    try {
      await _firestore.collection('travel_logs').doc(logId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🗑️ تم حذف هذه الرحلة")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ فشل حذف الرحلة: $e")),
      );
    }
  }

  // ✅ عرض الوجهة على الخريطة
  Future<void> _openMap(String destinationString) async {
    try {
      final regex = RegExp(r'LatLng\(([^,]+), ([^)]+)\)');
      final match = regex.firstMatch(destinationString);
      if (match == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ لا يمكن قراءة الإحداثيات")),
        );
        return;
      }

      final lat = double.tryParse(match.group(1)!);
      final lng = double.tryParse(match.group(2)!);
      if (lat == null || lng == null) return;

      final destination = latlng.LatLng(lat, lng);
      final position = await Geolocator.getCurrentPosition();

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MapPage(
            position: position,
            destination: destination,
            enableTap: false,
            enableLiveTracking: true,
            themeNotifier: widget.themeNotifier,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ خطأ أثناء فتح الخريطة: $e")),
      );
    }
  }

  // ✅ نافذة التفاصيل المنبثقة مع خيارات إضافية
  void _showLogDetails(Map<String, dynamic> log, String logId) {
    final destination = log['destination'] ?? "موقع غير معروف";
    final time = log['time'] ?? "";
    final dateTime = DateTime.tryParse(time);
    final formattedDate = dateTime != null
        ? "${dateTime.year}/${dateTime.month}/${dateTime.day}"
        : "غير معروف";
    final formattedTime = dateTime != null
        ? "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}"
        : "";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("تفاصيل الرحلة 🧭", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📍 الوجهة:\n$destination", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("📅 التاريخ: $formattedDate", style: const TextStyle(fontSize: 16)),
            Text("🕓 الوقت: $formattedTime", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            const Divider(),
            const Text(
              "اختر إجراء:",
              style: TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إغلاق")),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteSingleLog(logId);
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text("حذف الرحلة", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(context);
              _openMap(destination);
            },
            icon: const Icon(Icons.map, color: Colors.white),
            label: const Text("عرض على الخريطة", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("الرجاء تسجيل الدخول لعرض السجلات.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("سجل الرحلات"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: "حذف جميع السجلات",
            onPressed: _confirmClearLogs,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('travel_logs')
            .where('user_id', isEqualTo: user.uid)
            .orderBy('time', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("لا توجد رحلات محفوظة بعد."));
          }

          final logs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final doc = logs[index];
              final log = doc.data() as Map<String, dynamic>;
              final destination = log['destination'] ?? "موقع غير معروف";
              final time = log['time'] ?? "";

              final dateTime = DateTime.tryParse(time);
              final formattedTime = dateTime != null
                  ? "${dateTime.year}/${dateTime.month}/${dateTime.day} - ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}"
                  : "غير معروف";

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  onTap: () => _showLogDetails(log, doc.id),
                  leading: const Icon(Icons.location_on, color: Colors.orange, size: 30),
                  title: Text(destination, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("الوقت: $formattedTime"),
                  trailing: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () => _openMap(destination),
                    icon: const Icon(Icons.map, color: Colors.white),
                    label: const Text("عرض على الخريطة", style: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
