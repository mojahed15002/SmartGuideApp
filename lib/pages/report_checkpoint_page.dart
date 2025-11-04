import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/gen/app_localizations.dart';

class ReportCheckpointStatusPage extends StatefulWidget {
  final String checkpointId;
  final String checkpointName;

  const ReportCheckpointStatusPage({
    super.key,
    required this.checkpointId,
    required this.checkpointName,
  });

  @override
  State<ReportCheckpointStatusPage> createState() =>
      _ReportCheckpointStatusPageState();
}

class _ReportCheckpointStatusPageState extends State<ReportCheckpointStatusPage> {
  String? selectedStatus;
  bool _loading = false;

  Future<void> sendReport() async {
    if (selectedStatus == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loading = true);

    final docRef = FirebaseFirestore.instance
        .collection('checkpoints')
        .doc(widget.checkpointId);

// ✅ تأكد إنشاء وثيقة الحاجز لو مش موجودة قبل إضافة أي تقرير
final doc = await docRef.get();
if (!doc.exists) {
  await docRef.set({
    "name": widget.checkpointName,
    "status": "unknown",
    "statusUpdatedAt": DateTime.now(),
    "lat": null,
    "lng": null,
    "createdAt": DateTime.now(),
  }, SetOptions(merge: true));
}

    // 1️⃣ احفظ بلاغ المستخدم
    try {
      // هل المستخدم بلغ من قبل؟
      final existing = await docRef
          .collection("reports")
          .where("userId", isEqualTo: uid)
          .get();

      if (existing.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❗ لقد قمت بالإبلاغ بالفعل")),
        );
        setState(() => _loading = false);
        return;
      }

      // إضافة البلاغ
      await docRef.collection("reports").add({
        "userId": uid,
        "status": selectedStatus,
        "time": DateTime.now(),
      });
// ✅ تحديث آخر وقت بلاغ
await docRef.set({
  "lastReportAt": DateTime.now(),
}, SetOptions(merge: true));

      // 2️⃣ حساب الأصوات لكل حالة
      final reportsSnap = await docRef.collection("reports").get();

      int openCount = 0;
      int busyCount = 0;
      int closedCount = 0;

      for (var r in reportsSnap.docs) {
        final s = r['status'];
        if (s == "open") openCount++;
        if (s == "busy") busyCount++;
        if (s == "closed") closedCount++;
      }

// 3️⃣ تحديد الحالة حسب الأغلبية (بدون افتراض مسبق)
String newStatus = "unknown";
int highest = 0;

if (openCount >= highest) {
  highest = openCount;
  newStatus = "open";
}
if (busyCount > highest) {
  highest = busyCount;
  newStatus = "busy";
}
if (closedCount > highest) {
  highest = closedCount;
  newStatus = "closed";
}

// شرط: إذا أقل من 3 بلاغات لنفس الحالة → لا نعتمدها
if (highest >= 3) {
  await docRef.set({
    "status": newStatus,
    "statusUpdatedAt": DateTime.now(),
  }, SetOptions(merge: true));
}

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ تم إرسال التبليغ")),
      );

Navigator.pop(context, true); // ✅ نرجع true يعني تم الإبلاغ
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ خطأ: $e")),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text("🚧 ${widget.checkpointName}"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 10),

RadioListTile<String>(
  title: Text(loc.open),
  value: "open",
  groupValue: selectedStatus,
  onChanged: (val) => setState(() => selectedStatus = val),
),
RadioListTile<String>(
  title: Text(loc.busy),
  value: "busy",
  groupValue: selectedStatus,
  onChanged: (val) => setState(() => selectedStatus = val),
),
RadioListTile<String>(
  title: Text(loc.closed),
  value: "closed",
  groupValue: selectedStatus,
  onChanged: (val) => setState(() => selectedStatus = val),
),

                const SizedBox(height: 20),
                ElevatedButton(
onPressed: selectedStatus == null ? null : sendReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: Text(loc.submit ?? "Submit"),
                ),
              ],
            ),
    );
  }
}
