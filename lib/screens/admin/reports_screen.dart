import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/helpers.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader('Activity Summary'),
        const SizedBox(height: 12),
        _ActivityReport(
          collection: 'complaints',
          label: 'Complaints',
          icon: Icons.report_problem_outlined,
          color: const Color(0xFFF472B6),
          statusField: 'status',
          statuses: ['pending', 'in_progress', 'resolved'],
        ),
        const SizedBox(height: 12),
        _ActivityReport(
          collection: 'service_requests',
          label: 'Service Requests',
          icon: Icons.build_outlined,
          color: const Color(0xFF818CF8),
          statusField: 'status',
          statuses: ['pending', 'assigned', 'completed'],
        ),
        const SizedBox(height: 12),
        _ActivityReport(
          collection: 'medical_visits',
          label: 'Medical Visits',
          icon: Icons.medical_services_outlined,
          color: const Color(0xFF34D399),
          statusField: 'status',
          statuses: ['pending', 'accepted', 'completed'],
        ),
        const SizedBox(height: 12),
        _ActivityReport(
          collection: 'parcels',
          label: 'Parcels',
          icon: Icons.inventory_2_outlined,
          color: const Color(0xFFFBBF24),
          statusField: 'status',
          statuses: ['arrived', 'collected'],
        ),
        const SizedBox(height: 12),
        _ActivityReport(
          collection: 'emergency_alerts',
          label: 'Emergency Alerts',
          icon: Icons.warning_amber_outlined,
          color: const Color(0xFFFF4444),
          statusField: 'status',
          statuses: ['active', 'resolved'],
        ),
        const SizedBox(height: 20),
        _SectionHeader('User Distribution'),
        const SizedBox(height: 12),
        _UserDistribution(),
        const SizedBox(height: 20),
        _SectionHeader('Recent Announcements'),
        const SizedBox(height: 12),
        _RecentAnnouncements(),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Text(title,
      style: GoogleFonts.inter(
          color: Colors.white70, fontSize: 13,
          fontWeight: FontWeight.w600, letterSpacing: 0.5));
}

class _ActivityReport extends StatelessWidget {
  final String collection, label, statusField;
  final IconData icon;
  final Color color;
  final List<String> statuses;

  const _ActivityReport({
    required this.collection,
    required this.label,
    required this.icon,
    required this.color,
    required this.statusField,
    required this.statuses,
  });

  Color _statusColor(String s) {
    if (s == 'resolved' || s == 'completed' || s == 'collected') return const Color(0xFF34D399);
    if (s == 'in_progress' || s == 'assigned' || s == 'accepted' || s == 'arrived') return const Color(0xFFFBBF24);
    if (s == 'active') return const Color(0xFFFF4444);
    return const Color(0xFF818CF8);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final total = docs.length;
        final counts = {for (var s in statuses) s: docs.where((d) => (d.data() as Map)[statusField] == s).length};

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1040),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(label,
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              const Spacer(),
              Text('$total total',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
            ]),
            const SizedBox(height: 14),
            // Progress bars
            ...statuses.map((s) {
              final count = counts[s] ?? 0;
              final pct = total == 0 ? 0.0 : count / total;
              final sc = _statusColor(s);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(s, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                    const Spacer(),
                    Text('$count', style: GoogleFonts.inter(color: sc, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(sc),
                      minHeight: 6,
                    ),
                  ),
                ]),
              );
            }),
          ]),
        );
      },
    );
  }
}

class _UserDistribution extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final total = docs.length;
        final roles = ['student', 'warden', 'doctor', 'admin'];
        final colors = {
          'student': const Color(0xFF60A5FA),
          'warden':  const Color(0xFF818CF8),
          'doctor':  const Color(0xFF34D399),
          'admin':   const Color(0xFFF472B6),
        };

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1040),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF818CF8).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people_outline, color: Color(0xFF818CF8), size: 18),
              ),
              const SizedBox(width: 10),
              Text('Users', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              const Spacer(),
              Text('$total total', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
            ]),
            const SizedBox(height: 14),
            ...roles.map((r) {
              final count = docs.where((d) => (d.data() as Map)['role'] == r).length;
              final pct = total == 0 ? 0.0 : count / total;
              final c = colors[r]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(r[0].toUpperCase() + r.substring(1),
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                    const Spacer(),
                    Text('$count', style: GoogleFonts.inter(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(c),
                      minHeight: 6,
                    ),
                  ),
                ]),
              );
            }),
          ]),
        );
      },
    );
  }
}

class _RecentAnnouncements extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(child: Text('No announcements yet',
              style: GoogleFonts.inter(color: Colors.white38)));
        }
        return Column(
          children: docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            final priority = data['priority'] ?? 'normal';
            final pColor = priority == 'critical'
                ? const Color(0xFFFF4444)
                : priority == 'urgent'
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFF34D399);
            DateTime? createdAt;
            if (data['createdAt'] is Timestamp) {
              createdAt = (data['createdAt'] as Timestamp).toDate();
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1040),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: pColor.withOpacity(0.25)),
              ),
              child: Row(children: [
                Container(width: 3, height: 40,
                    decoration: BoxDecoration(color: pColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(data['title'] ?? '',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    if (createdAt != null)
                      Text(Helpers.formatDateTime(createdAt),
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: pColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(priority,
                      style: GoogleFonts.inter(color: pColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ]),
            );
          }).toList(),
        );
      },
    );
  }
}
