import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/service_request_model.dart';
import '../../providers/service_provider.dart';
import '../../core/utils/helpers.dart';

class ManageServicesScreen extends StatelessWidget {
  const ManageServicesScreen({Key? key}) : super(key: key);

  void _showAssignDialog(BuildContext context, ServiceRequestModel r) {
    String? selectedStaff;
    DateTime? scheduledTime = r.scheduledTime;

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
              Text('Assign: ${r.serviceType}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', whereIn: ['warden', 'admin'])
                    .snapshots(),
                builder: (ctx, snap) {
                  final docs = snap.data?.docs ?? [];
                  return DropdownButtonFormField<String>(
                    value: selectedStaff,
                    decoration: const InputDecoration(
                        labelText: 'Assign Staff *',
                        border: OutlineInputBorder()),
                    items: docs.map((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: data['name'] as String,
                        child: Text('${data['name']} (${data['role']})'),
                      );
                    }).toList(),
                    onChanged: (v) => setModal(() => selectedStaff = v),
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.schedule),
                label: Text(scheduledTime == null
                    ? 'Select scheduled time'
                    : DateFormat('MMM d, h:mm a').format(scheduledTime!)),
                onPressed: () async {
                  final date = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(hours: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)));
                  if (date == null) return;
                  final time = await showTimePicker(
                      context: ctx, initialTime: TimeOfDay.now());
                  if (time == null) return;
                  setModal(() => scheduledTime = DateTime(
                      date.year, date.month, date.day, time.hour, time.minute));
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (selectedStaff == null || scheduledTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Select staff and scheduled time')));
                    return;
                  }
                  await context.read<ServiceProvider>().assignService(
                      r.id, selectedStaff!, scheduledTime!);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Assign & Schedule'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ServiceRequestModel>>(
      stream: context.read<ServiceProvider>().getAllServices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final requests = snapshot.data ?? [];
        if (requests.isEmpty)
          return const Center(child: Text('No service requests'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, i) {
            final r = requests[i];
            final statusColor = r.status == 'completed'
                ? Colors.green
                : r.status == 'assigned'
                    ? Colors.blue
                    : Colors.orange;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(r.serviceType.toUpperCase(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      Chip(
                        label: Text(r.status.toUpperCase(),
                            style: const TextStyle(fontSize: 10)),
                        backgroundColor: statusColor.withOpacity(0.15),
                        side: BorderSide(color: statusColor.withOpacity(0.4)),
                      ),
                    ]),
                    Text(r.description,
                        style: TextStyle(color: Colors.grey[700])),
                    const SizedBox(height: 6),
                    Text('${r.studentName} · Room ${r.roomNumber}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    if (r.scheduledTime != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.schedule, size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                            'Scheduled: ${DateFormat('MMM d, h:mm a').format(r.scheduledTime!)}',
                            style: const TextStyle(
                                color: Colors.blue, fontSize: 12)),
                      ]),
                    ],
                    if (r.assignedStaff.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Staff: ${r.assignedStaff}',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 12)),
                    ],
                    const SizedBox(height: 12),
                    Row(children: [
                      if (r.status != 'completed') ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showAssignDialog(context, r),
                            child: const Text('Assign & Schedule'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => context
                                .read<ServiceProvider>()
                                .updateServiceStatus(r.id, 'completed'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            child: const Text('Complete'),
                          ),
                        ),
                      ],
                    ]),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
