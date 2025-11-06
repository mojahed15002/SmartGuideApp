import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_notifier.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'map_page.dart';
import 'package:geolocator/geolocator.dart';
import 'main_navigation.dart';
// ✅ إضافة ملف الترجمة
import '../l10n/gen/app_localizations.dart';

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
        title: Text(AppLocalizations.of(context)!.confirmDeleteAllTitle),
        content: Text(AppLocalizations.of(context)!.confirmDeleteAllMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.deleteAll),
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
      SnackBar(content: Text(AppLocalizations.of(context)!.allLogsDeleted)),
    );
  }

  // ✅ تأكيد قبل حذف سجل واحد فقط
  Future<void> _confirmDeleteSingleLog(String logId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDeleteTripTitle),
        content: Text(AppLocalizations.of(context)!.confirmDeleteTripMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete),
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
        SnackBar(content: Text(AppLocalizations.of(context)!.tripDeleted)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${AppLocalizations.of(context)!.tripDeleteFailed} $e"),
        ),
      );
    }
  }

  // ✅ عرض الوجهة على الخريطة (السابق)
  Future<void> _openMap(dynamic destinationData) async {
    try {
      double? lat;
      double? lng;

      if (destinationData is GeoPoint) {
        lat = destinationData.latitude;
        lng = destinationData.longitude;
      } else if (destinationData is String) {
        final regex = RegExp(
          r'LatLng\(latitude[:=]\s*([-]?\d+\.\d+),\s*longitude[:=]\s*([-]?\d+\.\d+)\)',
        );
        final match = regex.firstMatch(destinationData);
        if (match != null) {
          lat = double.tryParse(match.group(1)!);
          lng = double.tryParse(match.group(2)!);
        }
      }

      if (lat == null || lng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.cannotLocateDestination,
            ),
          ),
        );
        return;
      }

      final destination = latlng.LatLng(lat, lng);
      final position = await Geolocator.getCurrentPosition();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MapPage(
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
        SnackBar(
          content: Text("${AppLocalizations.of(context)!.mapError}: $e"),
        ),
      );
    }
  }

  // ✅ جديد: عرض الرحلة المحفوظة (start + destination + path)
  Future<void> _openSavedTrip(Map<String, dynamic> log) async {
    try {
      latlng.LatLng? start;
      latlng.LatLng? destination;
      List<latlng.LatLng>? savedPath;

      final s = log['start'];
      if (s is Map && s['latitude'] != null && s['longitude'] != null) {
        start = latlng.LatLng(
          (s['latitude'] as num).toDouble(),
          (s['longitude'] as num).toDouble(),
        );
      }

      final d = log['destination'];
      if (d is Map && d['latitude'] != null && d['longitude'] != null) {
        destination = latlng.LatLng(
          (d['latitude'] as num).toDouble(),
          (d['longitude'] as num).toDouble(),
        );
      } else if (d is String) {
        final regex = RegExp(
          r'LatLng\(latitude[:=]\s*([-]?\d+\.\d+),\s*longitude[:=]\s*([-]?\d+\.\d+)\)',
        );
        final match = regex.firstMatch(d);
        if (match != null) {
          destination = latlng.LatLng(
            double.parse(match.group(1)!),
            double.parse(match.group(2)!),
          );
        }
      }

      final p = log['path'];
      if (p is List) {
        savedPath = p.whereType<Map>().map<latlng.LatLng>((m) {
          final lat = (m['latitude'] as num).toDouble();
          final lng = (m['longitude'] as num).toDouble();
          return latlng.LatLng(lat, lng);
        }).toList();
        if (savedPath.isEmpty) savedPath = null;
      }

      final position = await Geolocator.getCurrentPosition();

      if (destination == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.cannotLocateDestination)),
        );
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MapPage(
            position: position,
            themeNotifier: widget.themeNotifier,
            destination: destination,
            enableTap: false,
            enableLiveTracking: false,
            start: start,
            savedPath: savedPath,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${AppLocalizations.of(context)!.mapError}: $e")),
      );
    }
  }

  // ✅ نافذة التفاصيل المنبثقة
  void _showLogDetails(Map<String, dynamic> log, String logId) {
    final destination =
        log['place_name'] ??
        log['destination'] ??
        AppLocalizations.of(context)!.unknownPlace;
    final time = log['time'] ?? "";
    final dateTime = DateTime.tryParse(time);
    final formattedDate = dateTime != null
        ? "${dateTime.year}/${dateTime.month}/${dateTime.day}"
        : AppLocalizations.of(context)!.unknown;
    final formattedTime = dateTime != null
        ? "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}"
        : "";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)!.tripDetails,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${AppLocalizations.of(context)!.destinationLabel}:\n$destination",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "${AppLocalizations.of(context)!.dateLabel}: $formattedDate",
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              "${AppLocalizations.of(context)!.timeLabel}: $formattedTime",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Divider(),
            Text(
              AppLocalizations.of(context)!.chooseAction,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteSingleLog(logId);
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            label: Text(
              AppLocalizations.of(context)!.deleteTrip,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(context);
              _openSavedTrip(log); // ✅ بدلاً من _openMap(destination)
            },
            icon: const Icon(Icons.map, color: Colors.white),
            label: Text(
              AppLocalizations.of(context)!.viewOnMap,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    // ✅ اتجاه الصفحة
    final isArabic = AppLocalizations.of(context)!.localeName == 'ar';
    final direction = isArabic ? TextDirection.rtl : TextDirection.ltr;

    if (user == null) {
      return Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Center(
            child: Text(AppLocalizations.of(context)!.pleaseLoginToViewLogs),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.travelLogsTitle),
          leading: Builder(
  builder: (context) => IconButton(
    icon: const Icon(Icons.menu, color: Colors.black),
    onPressed: () {
      context
          .findAncestorStateOfType<MainNavigationState>()
          ?.scaffoldKey
          .currentState
          ?.openDrawer();
    },
  ),
),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: AppLocalizations.of(context)!.deleteAllLogsTooltip,
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
              return Center(
                child: Text(AppLocalizations.of(context)!.noTripsYet),
              );
            }

            final logs = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final doc = logs[index];
                final log = doc.data() as Map<String, dynamic>;
                final destination =
                    log['place_name'] ??
                    log['destination'] ??
                    AppLocalizations.of(context)!.unknownPlace;
                final time = log['time'] ?? "";
                final dateTime = DateTime.tryParse(time);
                final formattedTime = dateTime != null
                    ? "${dateTime.year}/${dateTime.month}/${dateTime.day} - ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}"
                    : AppLocalizations.of(context)!.unknown;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    onTap: () => _showLogDetails(log, doc.id),
                    leading: const Icon(
                      Icons.location_on,
                      color: Colors.orange,
                      size: 30,
                    ),
                    title: Text(
                      destination,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${AppLocalizations.of(context)!.timeLabel}: $formattedTime",
                    ),
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () => _openSavedTrip(log), // ✅ الجديد
                      icon: const Icon(Icons.map, color: Colors.white),
                      label: Text(
                        AppLocalizations.of(context)!.viewOnMap,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
