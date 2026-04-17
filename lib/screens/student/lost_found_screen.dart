import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/lost_found_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lost_found_provider.dart';

const _categories = [
  'Electronics', 'Clothing', 'Books & Stationery',
  'Keys', 'Wallet / Purse', 'ID / Cards',
  'Bag / Backpack', 'Jewellery', 'Sports Equipment', 'Other',
];

const _locations = [
  'Block A', 'Block B', 'Block C', 'Block D',
  'Canteen', 'Common Room', 'Gym', 'Library',
  'Parking Area', 'Washroom', 'Other',
];

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({Key? key}) : super(key: key);

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';
  String _filterCategory = 'All';

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

  Future<String> _encodeImage(File file, XFile xfile) async {
    try {
      List<int> bytes;
      if (kIsWeb) {
        bytes = await xfile.readAsBytes();
      } else {
        final compressed = await FlutterImageCompress.compressWithFile(
          file.absolute.path,
          quality: 20,
          minWidth: 200,
          minHeight: 200,
          keepExif: false,
        );
        bytes = compressed ?? await file.readAsBytes();
      }
      debugPrint('Image size: ${bytes.length} bytes');
      if (bytes.length > 700000) return '';
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } catch (e) {
      debugPrint('Image encode error: $e');
      return '';
    }
  }

  void _showReportSheet() {
    String? category;
    String? location;
    DateTime? dateLost;
    final itemCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    File? pickedImage;
    XFile? pickedXFile;
    bool uploading = false;
    final user = context.read<AuthProvider>().currentUserModel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => SingleChildScrollView(
          padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Report Lost Item',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(
                    labelText: 'Category *', border: OutlineInputBorder()),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setModal(() => category = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: itemCtrl,
                decoration: const InputDecoration(
                    labelText: 'Item Name *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: location,
                decoration: const InputDecoration(
                    labelText: 'Last Seen Location *',
                    border: OutlineInputBorder()),
                items: _locations
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setModal(() => location = v),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(dateLost == null
                    ? 'When did you lose it? (optional)'
                    : 'Lost on: ${DateFormat('MMM d, yyyy').format(dateLost!)}'),
                onPressed: () async {
                  final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now());
                  if (d != null) setModal(() => dateLost = d);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Description — color, brand, marks (optional)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactCtrl,
                decoration: const InputDecoration(
                    labelText: 'Your contact (phone / room no.)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              // Photo picker
              GestureDetector(
                onTap: pickedXFile != null
                    ? () => setModal(() { pickedImage = null; pickedXFile = null; })
                    : () async {
                        final source =
                            await showModalBottomSheet<ImageSource>(
                          context: ctx,
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16))),
                          builder: (_) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 8),
                                const Text('Add Photo',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const Divider(),
                                ListTile(
                                  leading: const Icon(Icons.camera_alt_outlined),
                                  title: const Text('Take a photo'),
                                  onTap: () => Navigator.pop(
                                      ctx, ImageSource.camera),
                                ),
                                ListTile(
                                  leading: const Icon(
                                      Icons.photo_library_outlined),
                                  title: const Text('Choose from gallery'),
                                  onTap: () => Navigator.pop(
                                      ctx, ImageSource.gallery),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.close,
                                      color: Colors.grey),
                                  title: const Text('Skip — no photo',
                                      style:
                                          TextStyle(color: Colors.grey)),
                                  onTap: () => Navigator.pop(ctx, null),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        );
                        if (source == null) return;
                        final picked = await ImagePicker().pickImage(
                            source: source, imageQuality: 20, maxWidth: 400, maxHeight: 400);
                        if (picked != null)
                          setModal(() {
                            pickedXFile = picked;
                            pickedImage = kIsWeb ? null : File(picked.path);
                          });
                      },
                child: Container(
                  height: pickedXFile != null ? 150 : 80,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: pickedXFile != null
                            ? Colors.green
                            : Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade50,
                  ),
                  child: pickedXFile != null
                      ? Stack(fit: StackFit.expand, children: [
                          ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb
                                  ? Image.network(pickedXFile!.path, fit: BoxFit.cover)
                                  : Image.file(pickedImage!, fit: BoxFit.cover)),
                          Positioned(
                            top: 6, right: 6,
                            child: Container(
                              decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ])
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined,
                                      color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text('Add Photo',
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w600)),
                                ]),
                            const SizedBox(height: 4),
                            Text('Camera or Gallery  •  optional',
                                style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 11)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: uploading
                    ? null
                    : () async {
                        if (itemCtrl.text.isEmpty ||
                            category == null ||
                            location == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Fill item name, category and location')));
                          return;
                        }
                        setModal(() => uploading = true);
                        try {
                          String imageUrl = '';
                          if (pickedXFile != null) {
                            imageUrl = await _encodeImage(
                              pickedImage ?? File(pickedXFile!.path),
                              pickedXFile!,
                            );
                            debugPrint('imageUrl length: ${imageUrl.length}');
                            if (imageUrl.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Image too large, submitting without photo.')));
                            }
                          }
                          await context
                              .read<LostFoundProvider>()
                              .addItem(LostFoundModel(
                                id: '',
                                reportedBy: user!.uid,
                                reporterName: user.name,
                                contactInfo: contactCtrl.text.trim(),
                                category: category!,
                                itemName: itemCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                location: location!,
                                status: 'open',
                                imageUrl: imageUrl,
                                dateLost: dateLost,
                                createdAt: DateTime.now(),
                              ));
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Report submitted!')));
                          }
                        } catch (e) {
                          if (ctx.mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                        } finally {
                          setModal(() => uploading = false);
                        }
                      },
                child: uploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit Report'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUserModel;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _filterCategory,
                underline: const SizedBox(),
                items: ['All', ..._categories]
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c,
                            style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) => setState(() => _filterCategory = v!),
              ),
            ]),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [Tab(text: 'All Reports'), Tab(text: 'My Reports')],
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
                    _buildList(
                        all.where((i) => i.status != 'collected').toList(),
                        currentUser),
                    _buildList(
                        all
                            .where((i) => i.reportedBy == currentUser?.uid)
                            .toList(),
                        currentUser),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'lost_found_fab',
        onPressed: _showReportSheet,
        icon: const Icon(Icons.add),
        label: const Text('Report Lost Item'),
      ),
    );
  }

  Widget _buildList(List<LostFoundModel> items, currentUser) {
    var filtered = items;
    if (_filterCategory != 'All')
      filtered =
          filtered.where((i) => i.category == _filterCategory).toList();
    if (_search.isNotEmpty)
      filtered = filtered
          .where((i) =>
              i.itemName.toLowerCase().contains(_search) ||
              i.description.toLowerCase().contains(_search) ||
              i.location.toLowerCase().contains(_search))
          .toList();

    if (filtered.isEmpty)
      return const Center(child: Text('No items found'));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final item = filtered[i];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + i * 50),
          curve: Curves.easeOut,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
                offset: Offset(0, 16 * (1 - value)), child: child),
          ),
          child: _ItemCard(item: item, isOwner: item.reportedBy == currentUser?.uid),
        );
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  final LostFoundModel item;
  final bool isOwner;
  const _ItemCard({required this.item, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final statusConfig = {
      'open': (Colors.blue, 'Searching', Icons.search),
      'with_warden': (Colors.orange, 'With Warden', Icons.store),
      'collected': (Colors.green, 'Collected', Icons.check_circle),
    };
    final (color, label, icon) =
        statusConfig[item.status] ?? (Colors.grey, 'Unknown', Icons.help);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.itemName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                Text(item.category,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Text(label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(item.location,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const Spacer(),
            const Icon(Icons.person_outline, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(isOwner ? 'You' : item.reporterName,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ]),
          if (item.dateLost != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.event, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                  'Lost on: ${DateFormat('MMM d, yyyy').format(item.dateLost!)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ]),
          ],
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.description,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
          if (item.imageUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.imageUrl.startsWith('data:image')
                  ? Image.memory(
                      base64Decode(item.imageUrl.split(',').last),
                      height: 160, width: double.infinity, fit: BoxFit.cover)
                  : Image.network(item.imageUrl,
                      height: 160, width: double.infinity, fit: BoxFit.cover),
            ),
          ],

          // With warden banner
          if (item.status == 'with_warden') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.store, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Text('Item is with the Warden!',
                      style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ]),
                if (item.wardenNote != null && item.wardenNote!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Note: ${item.wardenNote}',
                      style: const TextStyle(
                          color: Colors.orange, fontSize: 12)),
                ],
                if (isOwner) ...[
                  const SizedBox(height: 6),
                  const Text(
                      'Please visit the warden\'s office to collect your item.',
                      style: TextStyle(
                          color: Colors.deepOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ]),
            ),
          ],

          if (!isOwner && item.contactInfo.isNotEmpty) ...[
            const Divider(height: 16),
            Row(children: [
              const Icon(Icons.phone_outlined,
                  size: 14, color: Colors.deepPurple),
              const SizedBox(width: 6),
              Text('Contact: ${item.contactInfo}',
                  style: const TextStyle(
                      color: Colors.deepPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
          ],

          const SizedBox(height: 8),
          Text(DateFormat('MMM d, yyyy').format(item.createdAt),
              style: TextStyle(color: Colors.grey[400], fontSize: 11)),
        ]),
      ),
    );
  }
}
