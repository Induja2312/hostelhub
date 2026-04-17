import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../core/widgets/aurora_background.dart';
import 'manage_users_screen.dart';
import 'reports_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _index = 0;

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1040),
        title: Text('Logout', style: GoogleFonts.inter(color: Colors.white)),
        content: Text('Are you sure?', style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Logout', style: GoogleFonts.inter(color: const Color(0xFFF472B6)))),
        ],
      ),
    );
    if (confirm == true && mounted) await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUserModel;

    final tabs = [
      _HomeTab(adminName: user?.name ?? 'Admin'),
      const ManageUsersScreen(),
      const ReportsScreen(),
    ];

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF472B6).withOpacity(0.2),
              ),
              child: const Icon(Icons.admin_panel_settings, color: Color(0xFFF472B6), size: 20),
            ),
            const SizedBox(width: 10),
            Text('Admin Panel',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          ]),
          actions: [
            IconButton(icon: const Icon(Icons.logout, color: Colors.white70), onPressed: _logout),
          ],
        ),
        body: IndexedStack(index: _index, children: tabs),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D2B),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5)),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            backgroundColor: Colors.transparent,
            indicatorColor: const Color(0xFFF472B6).withOpacity(0.25),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined, color: Colors.white54),
                  selectedIcon: Icon(Icons.home, color: Color(0xFFF472B6)),
                  label: 'Home'),
              NavigationDestination(
                  icon: Icon(Icons.people_outline, color: Colors.white54),
                  selectedIcon: Icon(Icons.people, color: Color(0xFFF472B6)),
                  label: 'Users'),
              NavigationDestination(
                  icon: Icon(Icons.analytics_outlined, color: Colors.white54),
                  selectedIcon: Icon(Icons.analytics, color: Color(0xFFF472B6)),
                  label: 'Reports'),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final String adminName;
  const _HomeTab({required this.adminName});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // Welcome card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
              child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Welcome back,', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                Text(adminName,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                Text('System Administrator',
                    style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        Text('System Overview',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13,
                fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 12),

        // Stats grid
        Row(children: [
          Expanded(child: _StatCard('users', 'Total Users', const Color(0xFF818CF8), Icons.people_outline)),
          const SizedBox(width: 12),
          Expanded(child: _StatCard('complaints', 'Complaints', const Color(0xFFF472B6), Icons.report_problem_outlined)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _StatCard('announcements', 'Announcements', const Color(0xFF34D399), Icons.campaign_outlined)),
          const SizedBox(width: 12),
          Expanded(child: _StatCard('service_requests', 'Services', const Color(0xFF60A5FA), Icons.build_outlined)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _StatCard('medical_visits', 'Medical', const Color(0xFFFF6B6B), Icons.medical_services_outlined)),
          const SizedBox(width: 12),
          Expanded(child: _StatCard('lost_found', 'Lost & Found', const Color(0xFFFBBF24), Icons.search_outlined)),
        ]),
        const SizedBox(height: 20),

        // Recent activity
        Text('Recent Users',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13,
                fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        _RecentUsers(),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String collection, label;
  final Color color;
  final IconData icon;
  const _StatCard(this.collection, this.label, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1040),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text('$count',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
            Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
          ]),
        );
      },
    );
  }
}

class _RecentUsers extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();
        return Column(
          children: docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            final role = data['role'] ?? 'student';
            final roleColor = role == 'admin'
                ? const Color(0xFFF472B6)
                : role == 'warden'
                    ? const Color(0xFF818CF8)
                    : role == 'doctor'
                        ? const Color(0xFF34D399)
                        : const Color(0xFF60A5FA);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1040),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: roleColor.withOpacity(0.15),
                    border: Border.all(color: roleColor.withOpacity(0.4)),
                  ),
                  alignment: Alignment.center,
                  child: Text((data['name'] ?? 'U')[0].toUpperCase(),
                      style: GoogleFonts.inter(color: roleColor, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(data['name'] ?? '',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(data['email'] ?? '',
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(role,
                      style: GoogleFonts.inter(color: roleColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ]),
            );
          }).toList(),
        );
      },
    );
  }
}
