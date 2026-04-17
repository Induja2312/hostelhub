import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/helpers.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({Key? key}) : super(key: key);

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF0D0D2B),
          child: TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            indicatorColor: const Color(0xFF818CF8),
            labelColor: const Color(0xFF818CF8),
            unselectedLabelColor: Colors.white38,
            labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Complaints'),
              Tab(text: 'Services'),
              Tab(text: 'Medical'),
              Tab(text: 'Resources'),
              Tab(text: 'Lost & Found'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _ActivityFeed(
                collection: 'complaints',
                titleField: 'category',
                subtitleField: 'description',
                nameField: 'studentName',
                roomField: 'roomNumber',
                statusField: 'status',
                icon: Icons.report_problem_outlined,
                color: const Color(0xFFF472B6),
              ),
              _ActivityFeed(
                collection: 'service_requests',
                titleField: 'serviceType',
                subtitleField: 'description',
                nameField: 'studentName',
                roomField: 'roomNumber',
                statusField: 'status',
                icon: Icons.build_outlined,
                color: const Color(0xFF818CF8),
              ),
              _ActivityFeed(
                collection: 'medical_visits',
                titleField: 'urgency',
                subtitleField: 'symptoms',
                nameField: 'studentName',
                roomField: 'roomNumber',
                statusField: 'status',
                icon: Icons.medical_services_outlined,
                color: const Color(0xFF34D399),
              ),
              _ActivityFeed(
                collection: 'resources',
                titleField: 'itemName',
                subtitleField: 'description',
                nameField: 'requesterName',
                roomField: 'status',
                statusField: 'status',
                icon: Icons.swap_horiz_outlined,
                color: const Color(0xFF60A5FA),
              ),
              _ActivityFeed(
                collection: 'lost_found',
                titleField: 'itemName',
                subtitleField: 'description',
                nameField: 'reportedBy',
                roomField: 'location',
                statusField: 'type',
                icon: Icons.search_outlined,
                color: const Color(0xFFFBBF24),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityFeed extends StatelessWidget {
  final String collection;
  final String titleField;
  final String subtitleField;
  final String nameField;
  final String roomField;
  final String statusField;
  final IconData icon;
  final Color color;

  const _ActivityFeed({
    required this.collection,
    required this.titleField,
    required this.subtitleField,
    required this.nameField,
    required this.roomField,
    required this.statusField,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF818CF8)));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white24, size: 48),
                const SizedBox(height: 12),
                Text('No records found',
                    style: GoogleFonts.inter(color: Colors.white38)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final title = (data[titleField] ?? '').toString().toUpperCase();
            final subtitle = (data[subtitleField] ?? '').toString();
            final name = (data[nameField] ?? 'Unknown').toString();
            final room = (data[roomField] ?? '').toString();
            final status = (data[statusField] ?? '').toString();
            DateTime? createdAt;
            if (data['createdAt'] is Timestamp) {
              createdAt = (data['createdAt'] as Timestamp).toDate();
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1040),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.25), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: color, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(title,
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ),
                      _StatusChip(status, color),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          color: Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Text(name,
                          style: GoogleFonts.inter(
                              color: Colors.white54, fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on_outlined,
                          color: Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Text(room,
                          style: GoogleFonts.inter(
                              color: Colors.white54, fontSize: 12)),
                      const Spacer(),
                      if (createdAt != null)
                        Text(Helpers.formatDate(createdAt),
                            style: GoogleFonts.inter(
                                color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color baseColor;
  const _StatusChip(this.status, this.baseColor);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'completed':
      case 'fulfilled':
        color = const Color(0xFF34D399);
        break;
      case 'in_progress':
      case 'offered':
      case 'assigned':
        color = const Color(0xFFFBBF24);
        break;
      case 'active':
      case 'urgent':
      case 'critical':
        color = const Color(0xFFFF4444);
        break;
      default:
        color = baseColor;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(status,
          style: GoogleFonts.inter(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
