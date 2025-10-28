import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/gen/app_localizations.dart';

class AllCommentsPage extends StatelessWidget {
  final String placeId;
  const AllCommentsPage({super.key, required this.placeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.allComments)),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('places')
            .doc(placeId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final commentsList = (data?['comments_list'] ?? []) as List<dynamic>;

          if (commentsList.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.noCommentsYet,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            );
          }

          // ✅ ترتيب الأحدث أولاً
          commentsList.sort((a, b) {
            final aTime = (a['time'] as Timestamp?)?.toDate() ?? DateTime(2000);
            final bTime = (b['time'] as Timestamp?)?.toDate() ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: commentsList.length,
            itemBuilder: (context, index) {
              final comment = commentsList[index] as Map<String, dynamic>;
              final name = comment['name'] ?? AppLocalizations.of(context)!.guest;
              final text = comment['text'] ?? '';
              final photoUrl = comment['photoUrl'] ?? '';
              final timestamp = comment['time'] as Timestamp?;
              final date = timestamp?.toDate();

              // ⏰ صيغة الوقت
              String formattedTime = '';
              if (date != null) {
                final diff = DateTime.now().difference(date);
                if (diff.inMinutes < 1) {
                  formattedTime = AppLocalizations.of(context)!.justNow;
                } else if (diff.inMinutes < 60) {
                  formattedTime =
                      "${diff.inMinutes} ${AppLocalizations.of(context)!.minutesAgo}";
                } else if (diff.inHours < 24) {
                  formattedTime =
                      "${diff.inHours} ${AppLocalizations.of(context)!.hoursAgo}";
                } else {
                  formattedTime =
                      "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
                }
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                color: Colors.orange.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        (photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                    backgroundColor: photoUrl.isEmpty
                        ? Colors.orange.shade100
                        : Colors.transparent,
                    child: photoUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.orange)
                        : null,
                  ),
                  title: Text(
                    text,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            "${AppLocalizations.of(context)!.byUser}: $name",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      if (formattedTime.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 13, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              "📅 $formattedTime",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black45),
                            ),
                          ],
                        ),
                      ]
                    ],
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
