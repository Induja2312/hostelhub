import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../core/utils/helpers.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({Key? key}) : super(key: key);

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  String _filter = 'all';

  final _roles = ['all', 'student', 'warden', 'doctor', 'admin'];

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':   return const Color(0xFFF472B6);
      case 'warden':  return const Color(0xFF818CF8);
      case 'doctor':  return const Color(0xFF34D399);
      default:        return const Color(0xFF60A5FA);
    }
  }

  void _showUserDetail(BuildContext context, UserModel u) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1040),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _roleColor(u.role).withOpacity(0.15),
                border: Border.all(color: _roleColor(u.role).withOpacity(0.5), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(u.name[0].toUpperCase(),
                  style: GoogleFonts.inter(color: _roleColor(u.role), fontSize: 20, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(u.name, style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                Text(u.email, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _roleColor(u.role).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _roleColor(u.role).withOpacity(0.4)),
              ),
              child: Text(u.role, style: GoogleFonts.inter(color: _roleColor(u.role), fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 20),
          _InfoRow(Icons.meeting_room_outlined, 'Room', u.roomNumber),
          const SizedBox(height: 10),
          _InfoRow(Icons.apartment_outlined, 'Block', u.hostelBlock),
          const SizedBox(height: 10),
          _InfoRow(Icons.phone_outlined, 'Phone', u.phone.isEmpty ? 'N/A' : u.phone),
          const SizedBox(height: 10),
          _InfoRow(Icons.calendar_today_outlined, 'Joined', Helpers.formatDate(u.createdAt)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1040),
                    title: Text('Delete User', style: GoogleFonts.inter(color: Colors.white)),
                    content: Text('Remove ${u.name} from the system?',
                        style: GoogleFonts.inter(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54))),
                      TextButton(onPressed: () => Navigator.pop(ctx, true),
                          child: Text('Delete', style: GoogleFonts.inter(color: const Color(0xFFFF4444)))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await FirebaseFirestore.instance.collection('users').doc(u.uid).delete();
                  if (context.mounted) Helpers.showSnackBar(context, 'User removed');
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF4444), width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.delete_outline, color: Color(0xFFFF4444), size: 18),
              label: Text('Remove User', style: GoogleFonts.inter(color: const Color(0xFFFF4444), fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Role filter chips
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _roles.length,
            itemBuilder: (context, i) {
              final r = _roles[i];
              final selected = _filter == r;
              final color = r == 'all' ? const Color(0xFFF472B6) : _roleColor(r);
              return GestureDetector(
                onTap: () => setState(() => _filter = r),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? color.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? color : Colors.white.withOpacity(0.2)),
                  ),
                  child: Text(r == 'all' ? 'All' : r[0].toUpperCase() + r.substring(1),
                      style: GoogleFonts.inter(
                          color: selected ? color : Colors.white54,
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFF472B6)));
              }
              final docs = snapshot.data?.docs ?? [];
              var users = docs.map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>)).toList();
              if (_filter != 'all') users = users.where((u) => u.role == _filter).toList();

              if (users.isEmpty) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.people_outline, color: Colors.white24, size: 52),
                    const SizedBox(height: 12),
                    Text('No users found', style: GoogleFonts.inter(color: Colors.white38)),
                  ]),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, i) {
                  final u = users[i];
                  final color = _roleColor(u.role);
                  return GestureDetector(
                    onTap: () => _showUserDetail(context, u),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1040),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.15),
                            border: Border.all(color: color.withOpacity(0.4)),
                          ),
                          alignment: Alignment.center,
                          child: Text(u.name[0].toUpperCase(),
                              style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(u.name,
                                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                            Text(u.email,
                                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                            if (u.roomNumber.isNotEmpty)
                              Text('Block ${u.hostelBlock} · Room ${u.roomNumber}',
                                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                          ]),
                        ),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(u.role,
                                style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 4),
                          const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
                        ]),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: Colors.white38, size: 16),
      const SizedBox(width: 10),
      Text('$label: ', style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
      Text(value, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
    ]);
  }
}
