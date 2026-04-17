import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/complaint_model.dart';
import '../../models/complaint_message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';

const _categories = [
  'Electricity', 'Water', 'WiFi', 'Furniture',
  'Plumbing', 'Cleanliness', 'Pest Control', 'Other'
];

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({Key? key}) : super(key: key);

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  String _search = '';
  String _filterStatus = 'All';

  void _showAddDialog() {
    String? category;
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
              const Text('New Complaint',
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
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Description *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (category == null || descCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Fill category and description')));
                    return;
                  }
                  await context.read<ComplaintProvider>().addComplaint(
                        ComplaintModel(
                          id: '',
                          studentId: user!.uid,
                          studentName: user.name,
                          category: category!,
                          description: descCtrl.text.trim(),
                          status: 'pending',
                          assignedTo: '',
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                      );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Complaint submitted!')));
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openChat(ComplaintModel c) {
    final user = context.read<AuthProvider>().currentUserModel;
    final msgCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.75,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Icon(Icons.chat_bubble_outline),
              const SizedBox(width: 8),
              Text('Chat — ${c.category}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16)),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<ComplaintMessage>>(
              stream: ctx.read<ComplaintProvider>().getMessages(c.id),
              builder: (context, snap) {
                final msgs = snap.data ?? [];
                if (msgs.isEmpty)
                  return const Center(
                      child: Text('No messages yet.\nSend a message to the warden.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey)));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) => _ChatBubble(
                      msg: msgs[i], isMe: msgs[i].senderId == user?.uid),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
                top: 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: msgCtrl,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: () async {
                    if (msgCtrl.text.trim().isEmpty) return;
                    await ctx.read<ComplaintProvider>().sendMessage(
                          c.id,
                          ComplaintMessage(
                            id: '',
                            senderId: user!.uid,
                            senderName: user.name,
                            senderRole: 'student',
                            text: msgCtrl.text.trim(),
                            sentAt: DateTime.now(),
                          ),
                        );
                    msgCtrl.clear();
                  },
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUserModel;
    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search complaints...',
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
              value: _filterStatus,
              underline: const SizedBox(),
              items: ['All', 'pending', 'in_progress', 'resolved']
                  .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s == 'All' ? 'All' : s.replaceAll('_', ' '),
                          style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) => setState(() => _filterStatus = v!),
            ),
          ]),
        ),
        Expanded(
          child: StreamBuilder<List<ComplaintModel>>(
            stream: context
                .read<ComplaintProvider>()
                .getStudentComplaints(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError)
                return Center(child: Text('Error: ${snapshot.error}'));

              var complaints = snapshot.data ?? [];
              if (_filterStatus != 'All')
                complaints = complaints
                    .where((c) => c.status == _filterStatus)
                    .toList();
              if (_search.isNotEmpty)
                complaints = complaints
                    .where((c) =>
                        c.category.toLowerCase().contains(_search) ||
                        c.description.toLowerCase().contains(_search))
                    .toList();

              if (complaints.isEmpty)
                return const Center(child: Text('No complaints found'));

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: complaints.length,
                itemBuilder: (context, index) {
                  final c = complaints[index];
                  final statusColor = c.status == 'resolved'
                      ? Colors.green
                      : c.status == 'in_progress'
                          ? Colors.blue
                          : Colors.orange;

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 300 + index * 50),
                    curve: Curves.easeOut,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                          offset: Offset(0, 16 * (1 - value)), child: child),
                    ),
                    child: Card(
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
                                  child: Text(c.category.toUpperCase(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: statusColor.withOpacity(0.4)),
                                  ),
                                  child: Text(
                                      c.status
                                          .replaceAll('_', ' ')
                                          .toUpperCase(),
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor)),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              Text(c.description,
                                  style: TextStyle(color: Colors.grey[600])),
                              const SizedBox(height: 8),
                              Row(children: [
                                Text(
                                    DateFormat('MMM d, yyyy')
                                        .format(c.createdAt),
                                    style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 11)),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: () => _openChat(c),
                                  icon: const Icon(
                                      Icons.chat_bubble_outline,
                                      size: 14),
                                  label: const Text('Chat',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ]),
                            ]),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ComplaintMessage msg;
  final bool isMe;
  const _ChatBubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).primaryColor
              : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(isMe ? 'You' : msg.senderName,
                style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey[600],
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(msg.text,
                style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 13)),
            const SizedBox(height: 2),
            Text(DateFormat('h:mm a').format(msg.sentAt),
                style: TextStyle(
                    color: isMe
                        ? Colors.white.withOpacity(0.5)
                        : Colors.grey[400],
                    fontSize: 9)),
          ],
        ),
      ),
    );
  }
}
