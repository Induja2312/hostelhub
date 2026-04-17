import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/resource_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/resource_provider.dart';
import '../../core/widgets/aurora_scaffold.dart';
import '../../core/widgets/glass_card.dart';
import 'package:intl/intl.dart';

class ResourceSharingScreen extends StatefulWidget {
  const ResourceSharingScreen({Key? key}) : super(key: key);

  @override
  State<ResourceSharingScreen> createState() => _ResourceSharingScreenState();
}

class _ResourceSharingScreenState extends State<ResourceSharingScreen>
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

  void _showRequestDialog() {
    final itemCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? neededBy;
    final user = context.read<AuthProvider>().currentUserModel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Request an Item',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: itemCtrl,
                decoration: const InputDecoration(
                    labelText: 'Item Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(neededBy == null
                    ? 'Select time needed by'
                    : DateFormat('MMM d, h:mm a').format(neededBy!)),
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
                  setModalState(() => neededBy = DateTime(
                      date.year, date.month, date.day, time.hour, time.minute));
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (itemCtrl.text.isEmpty || neededBy == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Fill item name and needed-by time')));
                    return;
                  }
                  await context.read<ResourceProvider>().addRequest(ResourceModel(
                        id: '',
                        requesterId: user!.uid,
                        requesterName: user.name,
                        itemName: itemCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        neededBy: neededBy!,
                        status: 'open',
                        createdAt: DateTime.now(),
                      ));
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Request posted!')));
                  }
                },
                child: const Text('Post Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOfferDialog(ResourceModel res) {
    final locationCtrl = TextEditingController();
    DateTime? meetingTime;
    final user = context.read<AuthProvider>().currentUserModel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Offer "${res.itemName}"',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: locationCtrl,
                decoration: const InputDecoration(
                    labelText: 'Meeting Location',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(meetingTime == null
                    ? 'Select meeting time'
                    : DateFormat('MMM d, h:mm a').format(meetingTime!)),
                onPressed: () async {
                  final date = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(hours: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 7)));
                  if (date == null) return;
                  final time = await showTimePicker(
                      context: ctx, initialTime: TimeOfDay.now());
                  if (time == null) return;
                  setModalState(() => meetingTime = DateTime(
                      date.year, date.month, date.day, time.hour, time.minute));
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (locationCtrl.text.isEmpty || meetingTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Fill location and meeting time')));
                    return;
                  }
                  await context.read<ResourceProvider>().offerItem(
                      res.id, user!.uid, user.name,
                      locationCtrl.text.trim(), meetingTime!);
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Offer sent!')));
                  }
                },
                child: const Text('Confirm Offer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelRequest(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Cancel this resource request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<ResourceProvider>().cancelRequest(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUserModel;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [Tab(text: 'Open Requests'), Tab(text: 'My Requests')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllRequests(user),
                _buildMyRequests(user),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'resource_fab',
        onPressed: _showRequestDialog,
        icon: const Icon(Icons.add),
        label: const Text('Request Item'),
      ),
    );
  }

  Widget _buildAllRequests(user) {
    return StreamBuilder<List<ResourceModel>>(
      stream: context.read<ResourceProvider>().getResourcesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final items = (snapshot.data ?? [])
            .where((r) => r.status == 'open' && r.requesterId != user?.uid)
            .toList();
        if (items.isEmpty)
          return const Center(child: Text('No open requests'));
        return _animatedList(items, user, showOffer: true);
      },
    );
  }

  Widget _buildMyRequests(user) {
    return StreamBuilder<List<ResourceModel>>(
      stream: context.read<ResourceProvider>().getResourcesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final items = (snapshot.data ?? [])
            .where((r) => r.requesterId == user?.uid)
            .toList();
        if (items.isEmpty)
          return const Center(child: Text('You have no requests'));
        return _animatedList(items, user, showOffer: false);
      },
    );
  }

  Widget _animatedList(List<ResourceModel> items, user,
      {required bool showOffer}) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final r = items[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + index * 60),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(r.itemName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      _statusChip(r.status),
                    ],
                  ),
                  if (r.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(r.description,
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.person_outline, size: 14,
                        color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(r.requesterName,
                        style: const TextStyle(fontSize: 12)),
                    const Spacer(),
                    const Icon(Icons.schedule, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Needed by ${DateFormat('MMM d, h:mm a').format(r.neededBy)}',
                        style: const TextStyle(fontSize: 12)),
                  ]),
                  if (r.status == 'offered' && r.meetingLocation != null) ...[
                    const Divider(height: 16),
                    Row(children: [
                      const Icon(Icons.location_on, size: 14,
                          color: Colors.deepPurple),
                      const SizedBox(width: 4),
                      Text(r.meetingLocation!,
                          style: const TextStyle(fontSize: 12)),
                      const Spacer(),
                      const Icon(Icons.access_time, size: 14,
                          color: Colors.deepPurple),
                      const SizedBox(width: 4),
                      Text(
                          DateFormat('MMM d, h:mm a').format(r.meetingTime!),
                          style: const TextStyle(fontSize: 12)),
                    ]),
                    Text('Offered by ${r.offererName}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.deepPurple)),
                  ],
                  if (showOffer && r.status == 'open') ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => _showOfferDialog(r),
                        child: const Text('I have this'),
                      ),
                    ),
                  ],
                  if (!showOffer &&
                      r.status == 'offered' &&
                      r.requesterId == user?.uid) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => context
                            .read<ResourceProvider>()
                            .markFulfilled(r.id),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        child: const Text('Mark as Received'),
                      ),
                    ),
                  ],
                  if (!showOffer && r.status == 'open') ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _cancelRequest(r.id),
                        icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 16),
                        label: const Text('Cancel', style: TextStyle(color: Colors.red)),
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
  }

  Widget _statusChip(String status) {
    final colors = {
      'open': Colors.blue,
      'offered': Colors.orange,
      'fulfilled': Colors.green,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (colors[status] ?? Colors.grey).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: colors[status] ?? Colors.grey)),
    );
  }
}
