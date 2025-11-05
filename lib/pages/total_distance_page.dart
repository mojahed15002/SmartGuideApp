import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_notifier.dart';

class TotalDistancePage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const TotalDistancePage({super.key, required this.themeNotifier});

  @override
  State<TotalDistancePage> createState() => _TotalDistancePageState();
}

class _TotalDistancePageState extends State<TotalDistancePage> {
  double totalDistanceM = 0;
  double averageDistanceM = 0;
  double longestTripM = 0;
  double shortestTripM = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadDistanceStats();
  }

  Future<void> _loadDistanceStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final logsSnap = await FirebaseFirestore.instance
          .collection('travel_logs')
          .where('user_id', isEqualTo: user.uid)
          .orderBy('time')
          .get();

      if (logsSnap.docs.isEmpty) {
        setState(() => loading = false);
        return;
      }

      List<double> distances = [];

      for (var doc in logsSnap.docs) {
        final data = doc.data();
        if (data['distance_m'] != null) {
          distances.add((data['distance_m'] as num).toDouble());
        }
      }

      distances.sort();

      totalDistanceM = distances.fold(0.0, (sum, value) => sum + value);
      longestTripM = distances.last;
      shortestTripM = distances.first;
      averageDistanceM = totalDistanceM / distances.length;

      setState(() => loading = false);
    } catch (e) {
      debugPrint("⚠️ Error loading stats: $e");
      setState(() => loading = false);
    }
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  String _formatKm(double meters) {
    return (meters / 1000).toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📍 إحصائيات المسافة"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _statCard(
                    "📏 إجمالي المسافة المقطوعة",
                    "${_formatKm(totalDistanceM)} كم",
                    Icons.alt_route,
                    Colors.orange,
                  ),
                  _statCard(
                    "📎 متوسط المسافة لكل رحلة",
                    "${_formatKm(averageDistanceM)} كم",
                    Icons.timeline,
                    Colors.blue,
                  ),
                  _statCard(
                    "🚀 أطول رحلة",
                    "${_formatKm(longestTripM)} كم",
                    Icons.flag,
                    Colors.green,
                  ),
                  _statCard(
                    "🐾 أقصر رحلة",
                    "${_formatKm(shortestTripM)} كم",
                    Icons.directions_walk,
                    Colors.redAccent,
                  ),
                ],
              ),
            ),
    );
  }
}
