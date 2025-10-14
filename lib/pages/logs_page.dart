import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme_notifier.dart';

class LogsPage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const LogsPage({super.key, required this.themeNotifier});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  List<Map<String, dynamic>> logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedLogs = prefs.getStringList('travel_logs');
    if (savedLogs != null) {
      setState(() {
        logs = savedLogs
            .map((item) => json.decode(item) as Map<String, dynamic>)
            .toList();
      });
    }
  }

  Future<void> _clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('travel_logs');
    setState(() => logs.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("السجلات"),
        actions: [
          if (logs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: _clearLogs,
              tooltip: "حذف كل السجلات",
            )
        ],
      ),
      body: logs.isEmpty
          ? const Center(child: Text("لا توجد رحلات محفوظة بعد."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.orange),
                    title: Text(log['destination'] ?? "موقع غير معروف"),
                    subtitle: Text("الوقت: ${log['time']}"),
                  ),
                );
              },
            ),
    );
  }
}
