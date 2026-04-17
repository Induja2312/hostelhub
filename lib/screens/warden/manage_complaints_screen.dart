import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/complaint_model.dart';
import '../../models/complaint_message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../core/utils/helpers.dart';
import 'package:intl/intl.dart';

String _friendlyError(String e) {
  if (e.contains('permission-denied')) return 'You don\'t have permission to do this.';
  if (e.contains('network')) return 'No internet connection. Please try again.';
  if (e.contains('not-found')) return 'This item no longer exists.';
  return 'Something went wrong. Please try again.';
}

class ManageComplaintsScreen extends StatelessWidget {
  const ManageComplaintsScreen({Key? key}) : super(key: key);

  void _openChat(BuildContext context, ComplaintModel c) {
    final user = context.read<AuthProvider>().currentUserModel;
    final msgCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1040),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Chat — ${c.category}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            Expanded(
              child: StreamBuilder<List<ComplaintMessage>>(
                stream: ctx.read<ComplaintProvider>().getMessages(c.id),
                builder: (context, snap) {
                  final msgs = snap.data ?? [];
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) => _ChatBubble(msg: msgs[i], isMe: msgs[i].senderId == user?.uid),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 12, right: 12, bottom: MediaQuery.of(ctx).viewInsets.bottom + 12, top: 8),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: msgCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true, fillColor: const Color(0xFF0F0A2A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF818CF8),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () async {
                      if (msgCtrl.text.trim().isEmpty) return;
                      await ctx.read<ComplaintProvider>().sendMessage(c.id, ComplaintMessage(
                        id: '', senderId: user!.uid, senderName: user.name,
                        senderRole: 'warden', text: msgCtrl.text.trim(), sentAt: DateTime.now(),
                      ));
                      msgCtrl.clear();
                    },
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _updateStatus(BuildContext context, ComplaintModel c) async {
    String? selected;
    final statuses = ['in_progress', 'resolved', 'pending']
        .where((s) => s != c.status)
        .toList();

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: const Color(0xFF1A1040),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Update Status',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selected,
                dropdownColor: const Color(0xFF1A1040),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'New Status',
                  labelStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                ),
                items: statuses
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.replaceAll('_', ' ').toUpperCase()),
                        ))
                    .toList(),
                onChanged: (v) => setModal(() => selected = v),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (selected == null) return;
                  Navigator.pop(ctx);
                  try {
                    await context.read<ComplaintProvider>().updateComplaintStatus(
                        c.id, selected!, c.studentId);
                    if (context.mounted)
                      Helpers.showSnackBar(context, 'Status updated to $selected');
                  } catch (e) {
                    if (context.mounted)
                      Helpers.showSnackBar(context, _friendlyError(e.toString()), isError: true);
                  }
                },
                child: const Text('Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ComplaintModel>>(
      stream: context.read<ComplaintProvider>().getAllComplaints(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF818CF8)));
        }
        final complaints = snapshot.data ?? [];
        if (complaints.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Color(0xFF34D399), size: 56),
                const SizedBox(height: 12),
                Text('No complaints — all clear!',
                    style: GoogleFonts.inter(color: Colors.white54)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: complaints.length,
          itemBuilder: (context, i) {
            final c = complaints[i];
            final statusColor = c.status == 'resolved'
                ? const Color(0xFF34D399)
                : c.status == 'in_progress'
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFFF472B6);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1040),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: statusColor.withOpacity(0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF472B6).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.report_problem_outlined,
                            color: Color(0xFFF472B6), size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(c.category.toUpperCase(),
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: statusColor.withOpacity(0.4)),
                        ),
                        child: Text(c.status,
                            style: GoogleFonts.inter(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(c.description,
                      style: GoogleFonts.inter(
                          color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          color: Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Text(c.studentName,
                          style: GoogleFonts.inter(
                              color: Colors.white54, fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.badge_outlined,
                          color: Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Text(c.studentId,
                          style: GoogleFonts.inter(
                              color: Colors.white54, fontSize: 12)),
                      const Spacer(),
                      Text(Helpers.formatDate(c.createdAt),
                          style: GoogleFonts.inter(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                  if (c.status != 'resolved') ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: OutlinedButton(
                            onPressed: () => _updateStatus(context, c),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: statusColor.withOpacity(0.6)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text('Update Status',
                                style: GoogleFonts.inter(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 38,
                        child: OutlinedButton.icon(
                          onPressed: () => _openChat(context, c),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline, size: 15, color: Colors.white54),
                          label: Text('Chat', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                        ),
                      ),
                    ]),
                  ],
                ],
              ),
            );
          },
        );
      },
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
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF818CF8) : const Color(0xFF2A1F5A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(msg.senderName,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 13)),
            const SizedBox(height: 2),
            Text(DateFormat('h:mm a').format(msg.sentAt),
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9)),
          ],
        ),
      ),
    );
  }
}
