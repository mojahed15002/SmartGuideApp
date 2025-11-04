import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../l10n/gen/app_localizations.dart';
import 'report_checkpoint_page.dart'; // تأكد من اسم صفحة التبليغ
import 'package:firebase_auth/firebase_auth.dart';
import 'map_page.dart'; 
import '../theme_notifier.dart';
import 'dart:async';
import '../checkpoint_card.dart';

class CheckpointsPage extends StatefulWidget {
  final ThemeNotifier themeNotifier;

  const CheckpointsPage({
    super.key,
    required this.themeNotifier,
  });

  @override
  State<CheckpointsPage> createState() => _CheckpointsPageState();
  
}

class _CheckpointsPageState extends State<CheckpointsPage> {
  ThemeNotifier get themeNotifier => widget.themeNotifier;
  Position? _position;
  bool _loading = true;
  double _radiusKm = 5.0;
  Timer? _autoRefreshTimer;

  List<dynamic> _osmCheckpoints = []; // نقاط من OSM
  final Map<String, dynamic> _dbCheckpoints = {}; // من Firestore
  final Map<String, dynamic> _userCheckpointNames = {}; // ✅ أسماء نقاط حسب المستخدم
  final Map<String, int> _reportsCount = {};

@override
void initState() {
  super.initState();
  _initLocation();
  // ✅ تحديث تلقائي للحالة والعداد كل 30 دقيقة
  _autoRefreshTimer = Timer.periodic(const Duration(minutes: 30), (timer) async {
    if (!mounted) return;                
    await _loadFirestoreCheckpoints();   
    if (mounted) setState(() {});        
  });

}

Future<void> _initLocation() async {
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

      DateTime? lastUpdate = d.data().containsKey("statusUpdatedAt")
          ? (d["statusUpdatedAt"] as Timestamp).toDate()
          : null;

      if (lastUpdate != null) {
        final diff = DateTime.now().difference(lastUpdate);

        if (diff.inMinutes >= 30 && d.data()["status"] != "unknown") {
          await FirebaseFirestore.instance
              .collection("checkpoints")
              .doc(d.id)
              .set({
            "status": "unknown",
            "statusUpdatedAt": DateTime.now(),
          }, SetOptions(merge: true));

          final reports = await FirebaseFirestore.instance
              .collection("checkpoints")
              .doc(d.id)
              .collection("reports")
              .get();

          for (var r in reports.docs) {
            await r.reference.delete();
          }

          _reportsCount[d.id] = 0;
          _dbCheckpoints[d.id]["status"] = "unknown";
          _dbCheckpoints[d.id]["statusUpdatedAt"] = DateTime.now();
        }
      }

      if (d.data().containsKey('statusUpdatedAt')) {
        _dbCheckpoints[d.id]['statusUpdatedAt'] =
            (d['statusUpdatedAt'] as Timestamp).toDate();
      }

      final reportsSnap = await FirebaseFirestore.instance
          .collection('checkpoints')
          .doc(d.id)
          .collection('reports')
          .get();

      _reportsCount[d.id] = reportsSnap.docs.length;
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
      "node[barrier=checkpoint](around:${(_radiusKm * 1000).toInt()},${_position!.latitude},${_position!.longitude});out;");
  final res = await http.get(url);

  if (res.statusCode == 200) {
    final data = json.decode(res.body);

    setState(() {
      _osmCheckpoints = data["elements"] ?? [];
    });
  }

  setState(() => _loading = false);
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
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text("${loc.searchRadius}: ${_radiusKm.toStringAsFixed(0)} كم",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Slider(
                      value: _radiusKm,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      label: "${_radiusKm.toStringAsFixed(0)} كم",
                      activeColor: Colors.orange,
                      onChanged: (v) async {
                        setState(() {
                          _radiusKm = v;
                          _loading = true;
                        });

                        await _fetchOSMCheckpoints();
                        await _loadFirestoreCheckpoints();
                        setState(() => _loading = false);
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _osmCheckpoints.isEmpty
                    ? Center(
                        child: Text(
                          "لا توجد حواجز قريبة ضمن $_radiusKm كم",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
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

                          final existsInDB = _dbCheckpoints.containsKey(osmId);
                          final dbData = existsInDB ? _dbCheckpoints[osmId] : null;
                          final userCustomName = _userCheckpointNames[osmId];
                          final defaultName = dbData?['name'] ?? osmName;
                          final displayName = userCustomName ?? defaultName;
                          final status = dbData?['status'] ?? "unknown";
                          final DateTime? updatedAt = dbData?['statusUpdatedAt'];
                          final int reportsCount = _reportsCount[osmId] ?? 0;

                          return CheckpointCard(
                            id: osmId,
                            name: displayName,
                            lat: lat,
                            lon: lon,
                            status: status,
                            reports: reportsCount,
                            statusUpdatedAt: updatedAt,
                            showMapButton: true,
                            showSuggestName: !existsInDB,

                            onReportPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReportCheckpointStatusPage(
                                    checkpointId: osmId,
                                    checkpointName: displayName,
                                  ),
                                ),
                              );
                              if (result == true) {
                                await _loadFirestoreCheckpoints();
                                if (mounted) setState(() {});
                              }
                            },

                            onShowOnMap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MapPage(
                                    position: _position!,
                                    themeNotifier: widget.themeNotifier,
                                    targetLat: lat,
                                    targetLon: lon,
                                    checkpointName: displayName,
                                  ),
                                ),
                              );
                            },

                            onSuggestName: !existsInDB
                                ? () async {
                                    final nameCtrl = TextEditingController();

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
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text("إلغاء"),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                            onPressed: () async {
                                              final uid = FirebaseAuth.instance.currentUser!.uid;

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

                                              await FirebaseFirestore.instance
                                                  .collection('checkpoints')
                                                  .doc(osmId)
                                                  .collection('nameSuggestions')
                                                  .add({
                                                "suggestedName": nameCtrl.text.trim(),
                                                "time": DateTime.now(),
                                              });

                                              _userCheckpointNames[osmId] = nameCtrl.text.trim();
                                              Navigator.pop(context);
                                              setState(() {});
                                              await _loadUserCheckpointNames();
                                            },
                                            child: const Text("إرسال"),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                : null,
                          );
                        },
                      ),
              )
            ],
          ),
  );
}

@override
void dispose() {
  _autoRefreshTimer?.cancel();
  super.dispose();
}
}
