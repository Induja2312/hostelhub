import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WardenVisitorScreen extends StatelessWidget {
  const WardenVisitorScreen({Key? key}) : super(key: key);

  Future<void> _updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance
        .collection('visitor_log')
        .doc(docId)
        .update({'status': status});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('visitor_log')
          .orderBy('visitTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty)
          return const Center(child: Text('No visitor requests'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';
            final visitTime = (data['visitTime'] as Timestamp?)?.toDate();
            final statusColor = status == 'approved'
                ? Colors.green
                : status == 'rejected'
                    ? Colors.red
                    : Colors.orange;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: statusColor.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(data['visitorName'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(status.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor)),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Text('Phone: ${data['visitorPhone'] ?? ''}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      Text(
                          'Student: ${data['studentName']} · Block ${data['hostelBlock']} Room ${data['roomNumber']}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      if ((data['purpose'] ?? '').isNotEmpty)
                        Text('Purpose: ${data['purpose']}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      if (visitTime != null) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.schedule, size: 14, color: Colors.deepPurple),
                          const SizedBox(width: 4),
                          Text(DateFormat('MMM d, h:mm a').format(visitTime),
                              style: const TextStyle(
                                  color: Colors.deepPurple,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ],
                      if (status == 'pending') ...[
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.close, color: Colors.red, size: 16),
                              label: const Text('Reject',
                                  style: TextStyle(color: Colors.red)),
                              onPressed: () => _updateStatus(doc.id, 'rejected'),
                              style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Approve'),
                              onPressed: () => _updateStatus(doc.id, 'approved'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                            ),
                          ),
                        ]),
                      ],
                    ]),
              ),
            );
          },
        );
      },
    );
  }
}
