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
// ✅ check if user reported within last 5 minutes
final existing = await docRef
    .collection("reports")
    .where("userId", isEqualTo: uid)
    .orderBy("time", descending: true)
    .limit(1)
    .get();

if (existing.docs.isNotEmpty) {
  final lastTime = (existing.docs.first["time"] as Timestamp).toDate();
  final diff = DateTime.now().difference(lastTime);

  if (diff.inMinutes < 5) {
    final remaining = 5 - diff.inMinutes;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("⏳ يمكنك الإبلاغ مرة أخرى بعد $remaining دقيقة")),
    );
    setState(() => _loading = false);
    return;
  }
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

// ✅ اعتماد الحالة مباشرة من أول بلاغ
await docRef.set({
  "status": selectedStatus,
  "statusUpdatedAt": DateTime.now(),
}, SetOptions(merge: true));

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
