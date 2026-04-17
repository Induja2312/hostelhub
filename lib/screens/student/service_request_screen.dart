import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/service_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_provider.dart';

const _predefinedServices = [
  'Cleaning - Bathroom',
  'Cleaning - Room',
  'Water Service',
  'Electrical Repair',
  'Plumbing Repair',
  'Furniture Repair',
  'Internet/WiFi Issue',
  'Pest Control',
  'Other',
];

class ServiceRequestScreen extends StatefulWidget {
  const ServiceRequestScreen({Key? key}) : super(key: key);

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  void _showAddSheet() {
    String? selectedService;
    final customCtrl = TextEditingController();
    final descCtrl = TextEditingController();
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
              const Text('Request Service',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedService,
                decoration: const InputDecoration(
                    labelText: 'Service Type', border: OutlineInputBorder()),
                items: _predefinedServices
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setModal(() => selectedService = v),
              ),
              if (selectedService == 'Other') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: customCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Service Name', border: OutlineInputBorder()),
                ),
              ],
              if (selectedService != null) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder()),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (selectedService == null) return;
                  final type = selectedService == 'Other'
                      ? customCtrl.text.trim()
                      : selectedService!;
                  if (type.isEmpty) return;
                  await context.read<ServiceProvider>().addServiceRequest(
                        ServiceRequestModel(
                          id: '',
                          studentId: user!.uid,
                          studentName: user.name,
                          roomNumber: user.roomNumber,
                          serviceType: type,
                          description: descCtrl.text.trim(),
                          status: 'pending',
                          assignedStaff: '',
                          createdAt: DateTime.now(),
                        ),
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancel(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<ServiceProvider>().updateServiceStatus(id, 'cancelled');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUserModel;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Service Requests')),
      body: StreamBuilder<List<ServiceRequestModel>>(
        stream: context.read<ServiceProvider>().getStudentServices(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final requests = snapshot.data ?? [];
          if (requests.isEmpty)
            return const Center(child: Text('No service requests yet'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, i) {
              final r = requests[i];
              final statusColor = r.status == 'completed'
                  ? Colors.green
                  : r.status == 'assigned'
                      ? Colors.blue
                      : r.status == 'cancelled'
                          ? Colors.grey
                          : Colors.orange;

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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(r.serviceType,
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
                        if (r.description.isNotEmpty)
                          Text(r.description,
                              style: TextStyle(color: Colors.grey[700])),
                        if (r.status == 'assigned') ...[
                          const Divider(height: 16),
                          if (r.scheduledTime != null)
                            Row(children: [
                              const Icon(Icons.schedule, size: 16, color: Colors.blue),
                              const SizedBox(width: 6),
                              Text(
                                  'Scheduled: ${DateFormat('MMM d, h:mm a').format(r.scheduledTime!)}',
                                  style: const TextStyle(
                                      color: Colors.blue, fontWeight: FontWeight.w600)),
                            ]),
                          if (r.assignedStaff.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.person, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text('Staff: ${r.assignedStaff}',
                                  style: TextStyle(color: Colors.grey[600])),
                            ]),
                          ],
                        ],
                        if (r.status == 'pending') ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _cancel(r.id),
                              icon: const Icon(Icons.cancel_outlined,
                                  color: Colors.red, size: 16),
                              label: const Text('Cancel',
                                  style: TextStyle(color: Colors.red)),
                            ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Request'),
      ),
    );
  }
}
