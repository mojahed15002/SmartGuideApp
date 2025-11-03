import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../l10n/gen/app_localizations.dart';
import 'report_checkpoint_page.dart'; // تأكد من اسم صفحة التبليغ
import 'package:firebase_auth/firebase_auth.dart';

class CheckpointsPage extends StatefulWidget {
  const CheckpointsPage({super.key});

  @override
  State<CheckpointsPage> createState() => _CheckpointsPageState();
}

class _CheckpointsPageState extends State<CheckpointsPage> {
  Position? _position;
  bool _loading = true;
  double _radiusKm = 5.0;

  List<dynamic> _osmCheckpoints = []; // نقاط من OSM
  Map<String, dynamic> _dbCheckpoints = {}; // من Firestore
  Map<String, dynamic> _userCheckpointNames = {}; // ✅ أسماء نقاط حسب المستخدم

@override
void initState() {
  super.initState();
  _initLocation();
}

Future<void> _initLocation() async {
  // ✅ تسجيل الضيف تلقائيًا لو مافي مستخدم
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
    print("✅ Anonymous user created");
  }

  LocationPermission perm = await Geolocator.requestPermission();
  if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
    setState(() => _loading = false);
    return;
  }

  final pos = await Geolocator.getCurrentPosition();
  print("✅ User position: ${pos.latitude}, ${pos.longitude}");

  setState(() => _position = pos);

  await _loadFirestoreCheckpoints();
  await _loadUserCheckpointNames();
  _fetchOSMCheckpoints();
}


Future<void> _loadFirestoreCheckpoints() async {
  try {
    final snap = await FirebaseFirestore.instance
        .collection('checkpoints')
        .get();

    for (var d in snap.docs) {
      _dbCheckpoints[d.id] = d.data();
    }

    setState(() {});
  } catch (e) {
    print("Error loading Firestore Checkpoints: $e");
  }
}

Future<void> _loadUserCheckpointNames() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    print("⚠️ No user logged in, skipping user checkpoint names");
    return;
  }

  try {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('checkpointNames')
        .get();

    for (var doc in snap.docs) {
      _userCheckpointNames[doc.id] = doc.data()['name'];
    }

    setState(() {});
  } catch (e) {
    print("❌ Error loading user checkpoint names: $e");
  }
}


  Future<void> _fetchOSMCheckpoints() async {
    if (_position == null) return;

    final url = Uri.parse(
      "https://overpass-api.de/api/interpreter?data=[out:json];"
      "node[barrier=checkpoint](around:${(_radiusKm * 1000).toInt()},${_position!.latitude},${_position!.longitude});out;"
    );

    final res = await http.get(url);
if (res.statusCode == 200) {
  final data = json.decode(res.body);

  setState(() {
    _osmCheckpoints = data["elements"] ?? [];
  });
} else {
  print("❌ OSM Error: ${res.statusCode}");
}

setState(() => _loading = false);
  }

  Color _statusColor(String s) {
    return {
      "open": Colors.green,
      "busy": Colors.orange,
      "closed": Colors.red,
    }[s] ?? Colors.grey;
  }

  IconData _statusIcon(String s) {
    return {
      "open": Icons.check_circle,
      "busy": Icons.access_time_filled,
      "closed": Icons.block,
    }[s] ?? Icons.help;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text("🚧 ${loc.checkpoints}"),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ===== Slider =====
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text("${loc.searchRadius}: ${_radiusKm.toStringAsFixed(0)} كم",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Slider(
                        value: _radiusKm,
                        min: 1,
                        max: 100,
                        divisions: 99,
                        label: "${_radiusKm.toStringAsFixed(0)} كم",
                        activeColor: Colors.orange,
onChanged: (v) async {
  setState(() {
    _radiusKm = v;
    _loading = true;
  });

  await _fetchOSMCheckpoints();
  await _loadFirestoreCheckpoints();  // ✅ نعيد تحميل بيانات الحالة من DB
  setState(() => _loading = false);
},
                      ),
                    ],
                  ),
                ),

                // ===== Results =====
Expanded(
  child: _osmCheckpoints.isEmpty
      ? Center(
          child: Text(
            "لا توجد حواجز قريبة ضمن $_radiusKm كم",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        )
      : ListView.builder(
          itemCount: _osmCheckpoints.length,
          itemBuilder: (_, i) {
            final cp = _osmCheckpoints[i];
            final lat = cp["lat"];
            final lon = cp["lon"];
            final osmId = cp["id"].toString();
            final Map<String, dynamic> tags =
                (cp["tags"] as Map?)?.cast<String, dynamic>() ?? {};
            final String osmName =
                tags["name:ar"] ?? tags["name"] ?? "حاجز";
                bool hasOSMName = tags["name"] != null || tags["name:ar"] != null;

final existsInDB = _dbCheckpoints.containsKey(osmId);
final dbData = existsInDB ? _dbCheckpoints[osmId] : null;

final userCustomName = _userCheckpointNames[osmId];
final defaultName = dbData?['name'] ?? osmName;
final displayName = userCustomName ?? defaultName;

            final status = dbData?['status'] ?? "unknown";

final distanceMeters = Geolocator.distanceBetween(
  _position!.latitude,
  _position!.longitude,
  lat,
  lon,
);
final distanceKm = (distanceMeters / 1000).toStringAsFixed(2);

return Container(
  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 6,
        offset: Offset(0, 2),
      )
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(_statusIcon(status), color: _statusColor(status), size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(
child: Text(
  displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // زر تعديل الاسم (فقط للحواجز المضافة وليس من OSM)
                if (existsInDB && !hasOSMName)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.blueGrey),
                    onPressed: () async {
                      TextEditingController editCtrl =
                          TextEditingController(text: displayName);

                      await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("تعديل اسم الحاجز"),
                          content: TextField(
                            controller: editCtrl,
                            decoration: const InputDecoration(
                              labelText: "اسم الحاجز",
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("إلغاء"),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('checkpoints')
                                    .doc(osmId)
                                    .set({
                                  "name": editCtrl.text.trim(),
                                }, SetOptions(merge: true));
await _loadUserCheckpointNames();
                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("✅ تم تعديل اسم الحاجز")),
                                );

                                await _loadFirestoreCheckpoints();
                                setState(() {});
                              },
                              child: const Text("حفظ"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          Text(
            "$distanceKm كم",
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),

      const SizedBox(height: 8),

      Row(
        children: [
          // ✅ إذا الحاجز موجود → زر الإبلاغ فقط
          if (existsInDB)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.flag),
              label: Text(loc.report),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportCheckpointStatusPage(
                      checkpointId: osmId,
                      checkpointName: displayName,
                    ),
                  ),
                );
              },
            )

          // ✅ إذا غير موجود ولا اسم OSM → اقتراح اسم فقط
          else if (!hasOSMName)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text("اقتراح اسم",
                  style: TextStyle(fontSize: 13)),
              onPressed: () async {
                TextEditingController nameCtrl = TextEditingController();

                await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("اقتراح اسم للحاجز"),
                    content: TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "الاسم المقترح",
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: const Text("إلغاء"),
                        onPressed: () => Navigator.pop(context),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        child: const Text("إرسال"),
                        onPressed: () async {

String uid = FirebaseAuth.instance.currentUser!.uid;

// ✅ حفظ الاسم عند المستخدم فقط
await FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .collection('checkpointNames')
    .doc(osmId)
    .set({
  "name": nameCtrl.text.trim(),
  "lat": lat,
  "lon": lon,
  "savedAt": DateTime.now(),
});

// ✅ إرسال الاقتراح للتقييم لاحقًا
await FirebaseFirestore.instance
    .collection('checkpoints')
    .doc(osmId)
    .collection('nameSuggestions')
    .add({
  "suggestedName": nameCtrl.text.trim(),
  "time": DateTime.now(),
});

// ✅ تحديث الاسم محليًا فورًا
_userCheckpointNames[osmId] = nameCtrl.text.trim();

// ✅ أغلق الـ Dialog مرّة واحدة فقط
Navigator.pop(context);

// ✅ إبلاغ المستخدم
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text("📌 تم حفظ الاسم لك فقط")),
);

// ✅ تحديث الواجهة
setState(() {});

// ✅ تحميل بيانات المستخدم من Firestore ليتحدث الزر
await _loadUserCheckpointNames();

                        },
                      ),
                    ],
                  ),
                );
              },
            ),
       
        ],
      ),
    ],
  ),
);
         
          },
        ),
)
              
              ],
            ),
    );
  }
}
