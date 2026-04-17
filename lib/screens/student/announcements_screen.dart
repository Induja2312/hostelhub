import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/announcement_model.dart';
import '../../providers/announcement_provider.dart';
import '../../core/utils/helpers.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: StreamBuilder<List<AnnouncementModel>>(
        stream: context.read<AnnouncementProvider>().getAnnouncementsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final items = snapshot.data ?? [];
          if (items.isEmpty)
            return const Center(child: Text('No announcements yet'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final a = items[i];
              final isUrgent = a.priority == 'urgent';

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 300 + i * 60),
                curve: Curves.easeOut,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)), child: child),
                ),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isUrgent
                        ? BorderSide(color: Colors.red.shade300, width: 1.5)
                        : BorderSide.none,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(a.title,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                          ),
                          if (isUrgent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade300),
                              ),
                              child: Text('URGENT',
                                  style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            ),
                        ]),
                        const SizedBox(height: 8),
                        Text(a.body,
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 13)),
                        const SizedBox(height: 10),
                        Text(
                            '${a.postedByName} · ${Helpers.formatDate(a.createdAt)}',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 11)),
                        if (a.imageUrl.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(a.imageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover),
                          ),
                        ],
                      ],
                    ),
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
