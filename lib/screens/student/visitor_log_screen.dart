import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';

class VisitorLogScreen extends StatefulWidget {
  const VisitorLogScreen({Key? key}) : super(key: key);

  @override
  State<VisitorLogScreen> createState() => _VisitorLogScreenState();
}

class _VisitorLogScreenState extends State<VisitorLogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddSheet() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    DateTime? visitTime;
    final user = context.read<AuthProvider>().currentUserModel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Register Visitor',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Visitor Name *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Visitor Phone *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: purposeCtrl,
                decoration: const InputDecoration(
                    labelText: 'Purpose of Visit',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(visitTime == null
                    ? 'Expected visit time *'
                    : DateFormat('MMM d, h:mm a').format(visitTime!)),
                onPressed: () async {
                  final date = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 7)));
                  if (date == null) return;
                  final time = await showTimePicker(
                      context: ctx, initialTime: TimeOfDay.now());
                  if (time == null) return;
                  setModal(() => visitTime = DateTime(date.year, date.month,
                      date.day, time.hour, time.minute));
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty ||
                      phoneCtrl.text.isEmpty ||
                      visitTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Fill name, phone and visit time')));
                    return;
                  }
                  await FirebaseFirestore.instance
                      .collection('visitor_log')
                      .add({
                    'studentId': user!.uid,
                    'studentName': user.name,
                    'roomNumber': user.roomNumber,
                    'hostelBlock': user.hostelBlock,
                    'visitorName': nameCtrl.text.trim(),
                    'visitorPhone': phoneCtrl.text.trim(),
                    'purpose': purposeCtrl.text.trim(),
                    'visitTime': Timestamp.fromDate(visitTime!),
                    'status': 'pending', // pending | approved | rejected
                    'createdAt': Timestamp.now(),
                  });
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Visitor registered! Awaiting warden approval.')));
                  }
                },
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUserModel;

    return Scaffold(
      appBar: AppBar(title: const Text('Visitor Log')),
      body: Column(children: [
        TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'My Visitors'), Tab(text: 'All Visitors')],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildList(
                  FirebaseFirestore.instance
                      .collection('visitor_log')
                      .where('studentId', isEqualTo: user?.uid)
                      .orderBy('visitTime', descending: true)
                      .snapshots(),
                  isWarden: false),
              _buildList(
                  FirebaseFirestore.instance
                      .collection('visitor_log')
                      .orderBy('visitTime', descending: true)
                      .snapshots(),
                  isWarden: false),
            ],
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        icon: const Icon(Icons.person_add),
        label: const Text('Register Visitor'),
      ),
    );
  }

  Widget _buildList(Stream<QuerySnapshot> stream, {required bool isWarden}) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty)
          return const Center(child: Text('No visitors registered'));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';
            final visitTime =
                (data['visitTime'] as Timestamp?)?.toDate();
            final statusColor = status == 'approved'
                ? Colors.green
                : status == 'rejected'
                    ? Colors.red
                    : Colors.orange;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: statusColor.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.person_outline, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(data['visitorName'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
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
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12)),
                      Text(
                          'Student: ${data['studentName']} · Block ${data['hostelBlock']} Room ${data['roomNumber']}',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12)),
                      if ((data['purpose'] ?? '').isNotEmpty)
                        Text('Purpose: ${data['purpose']}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                      if (visitTime != null) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.schedule,
                              size: 14, color: Colors.deepPurple),
                          const SizedBox(width: 4),
                          Text(
                              'Visit: ${DateFormat('MMM d, h:mm a').format(visitTime)}',
                              style: const TextStyle(
                                  color: Colors.deepPurple,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
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
