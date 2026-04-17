import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/emergency_model.dart';
import '../../core/utils/helpers.dart';

class EmergencyAlertsScreen extends StatelessWidget {
  const EmergencyAlertsScreen({Key? key}) : super(key: key);

  void _resolve(BuildContext context, String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('emergency_alerts')
          .doc(id)
          .update({'status': 'resolved'});
      if (context.mounted) Helpers.showSnackBar(context, 'Alert resolved');
    } catch (e) {
      if (context.mounted)
        Helpers.showSnackBar(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Alerts'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emergency_alerts')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF4444)));
          }
          final docs = snapshot.data?.docs ?? [];
          final alerts = docs
              .map((d) => EmergencyModel.fromMap(
                  d.data() as Map<String, dynamic>, d.id))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (alerts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.green, size: 56),
                  SizedBox(height: 12),
                  Text('No emergency alerts'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, i) {
              final a = alerts[i];
              final isActive = a.status == 'active';
              final color = isActive ? Colors.red : Colors.green;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: color.withOpacity(0.4))),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isActive ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                            color: color, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(a.senderName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(a.status.toUpperCase(),
                                style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(a.message),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.meeting_room_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('Room ${a.roomNumber}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const Spacer(),
                          Text(Helpers.formatDateTime(a.createdAt),
                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      if (isActive) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _resolve(context, a.id),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            icon: const Icon(Icons.check, color: Colors.white, size: 16),
                            label: const Text('Mark Resolved',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
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
