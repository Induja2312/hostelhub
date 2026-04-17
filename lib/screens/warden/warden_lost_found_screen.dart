import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/lost_found_model.dart';
import '../../providers/lost_found_provider.dart';

class WardenLostFoundScreen extends StatefulWidget {
  const WardenLostFoundScreen({Key? key}) : super(key: key);

  @override
  State<WardenLostFoundScreen> createState() => _WardenLostFoundScreenState();
}

class _WardenLostFoundScreenState extends State<WardenLostFoundScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showMarkFoundDialog(LostFoundModel item) {
    final noteCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Mark Item as Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Someone handed in "${item.itemName}" to you.',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                  labelText: 'Note for student (optional)',
                  hintText: 'e.g. Found near canteen, bring ID to collect',
                  border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.notifications_active),
              label: const Text('Notify Student to Collect'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                await context
                    .read<LostFoundProvider>()
                    .markWithWarden(item.id, noteCtrl.text.trim());
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Student notified to collect their item!'),
                      backgroundColor: Colors.orange));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Searching'),
              Tab(text: 'With Warden'),
              Tab(text: 'Collected'),
            ],
          ),
          Expanded(
            child: StreamBuilder<List<LostFoundModel>>(
              stream: context.read<LostFoundProvider>().getItemsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                final all = snapshot.data ?? [];
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(all.where((i) => i.status == 'open').toList()),
                    _buildList(all.where((i) => i.status == 'with_warden').toList()),
                    _buildList(all.where((i) => i.status == 'collected').toList()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<LostFoundModel> items) {
    if (items.isEmpty)
      return const Center(child: Text('No items in this category'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.itemName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('${item.category} · ${item.reporterName}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ]),
                ),
                if (item.status == 'with_warden')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('WITH WARDEN',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange)),
                  ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(item.location,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const Spacer(),
                Text(DateFormat('MMM d').format(item.createdAt),
                    style: TextStyle(color: Colors.grey[400], fontSize: 11)),
              ]),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(item.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
              if (item.contactInfo.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.phone_outlined, size: 14, color: Colors.deepPurple),
                  const SizedBox(width: 4),
                  Text(item.contactInfo,
                      style: const TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
              ],
              if (item.imageUrl.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(item.imageUrl,
                      height: 140, width: double.infinity, fit: BoxFit.cover),
                ),
              ],
              if (item.wardenNote != null && item.wardenNote!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Note: ${item.wardenNote}',
                    style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 12),

              // Actions
              if (item.status == 'open')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.store),
                    label: const Text('Someone handed this in'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                    onPressed: () => _showMarkFoundDialog(item),
                  ),
                ),
              if (item.status == 'with_warden')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Student Collected Item'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                    onPressed: () async {
                      await context
                          .read<LostFoundProvider>()
                          .markCollected(item.id);
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Marked as collected!'),
                                backgroundColor: Colors.green));
                    },
                  ),
                ),
            ]),
          ),
        );
      },
    );
  }
}
