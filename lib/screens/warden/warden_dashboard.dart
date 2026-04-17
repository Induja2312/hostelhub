import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../core/widgets/aurora_background.dart';
import 'manage_complaints_screen.dart';
import 'manage_services_screen.dart';
import 'post_announcement_screen.dart';
import 'emergency_alerts_screen.dart';
import 'warden_lost_found_screen.dart';
import '../../screens/admin/parcel_management_screen.dart';

class WardenDashboard extends StatefulWidget {
  const WardenDashboard({Key? key}) : super(key: key);

  @override
  State<WardenDashboard> createState() => _WardenDashboardState();
}

class _WardenDashboardState extends State<WardenDashboard> {
  int _currentIndex = 0;

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1040),
        title: Text('Logout', style: GoogleFonts.inter(color: Colors.white)),
        content: Text('Are you sure you want to logout?',
            style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Logout',
                  style: GoogleFonts.inter(color: const Color(0xFFF472B6)))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUserModel;

    final tabs = [
      _HomeTab(
        wardenName: user?.name ?? 'Warden',
        onEmergencyTap: () => setState(() => _currentIndex = 6),
      ),
      const ManageComplaintsScreen(),
      const ManageServicesScreen(),
      const WardenLostFoundScreen(),
      const PostAnnouncementScreen(),
      const ParcelManagementScreen(),
      const EmergencyAlertsScreen(),
    ];

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF818CF8).withOpacity(0.2),
                ),
                child: const Icon(Icons.shield_outlined,
                    color: Color(0xFF818CF8), size: 20),
              ),
              const SizedBox(width: 10),
              Text('HostelHub Warden',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              onPressed: _logout,
            ),
          ],
        ),
        body: IndexedStack(index: _currentIndex, children: tabs),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D2B),
            border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5)),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            backgroundColor: Colors.transparent,
            indicatorColor: const Color(0xFF818CF8).withOpacity(0.25),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined, color: Colors.white54),
                  selectedIcon: Icon(Icons.home, color: Color(0xFF818CF8)),
                  label: 'Home'),
              NavigationDestination(
                  icon: Icon(Icons.report_problem_outlined, color: Colors.white54),
                  selectedIcon: Icon(Icons.report_problem, color: Color(0xFF818CF8)),
                  label: 'Complaints'),
              NavigationDestination(
                  icon: Icon(Icons.build_outlined, color: Colors.white54),
                  selectedIcon: Icon(Icons.build, color: Color(0xFF818CF8)),
                  label: 'Services'),
              NavigationDestination(
                  icon: Icon(Icons.search_outlined, color: Colors.white54),
                  selectedIcon: Icon(Icons.search, color: Color(0xFF818CF8)),
                  label: 'Lost & Found'),
              NavigationDestination(
                  icon: Icon(Icons.campaign_outlined, color: Colors.white54),
                  selectedIcon: Icon(Icons.campaign, color: Color(0xFF818CF8)),
                  label: 'Announce'),
              NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined, color: Colors.white54),
                  selectedIcon: Icon(Icons.inventory_2, color: Color(0xFF818CF8)),
                  label: 'Parcels'),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final String wardenName;
  final VoidCallback onEmergencyTap;
  const _HomeTab({required this.wardenName, required this.onEmergencyTap});

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
              colors: [Color(0xFF3730A3), Color(0xFF6D28D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                ),
                child: const Icon(Icons.shield, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back,',
                        style: GoogleFonts.inter(
                            color: Colors.white70, fontSize: 13)),
                    Text(wardenName,
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    Text('Hostel Warden',
                        style: GoogleFonts.inter(
                            color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Live stats
        Text('Live Overview',
            style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard('complaints', 'Complaints', const Color(0xFFF472B6), Icons.report_problem_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard('service_requests', 'Services', const Color(0xFF818CF8), Icons.build_outlined)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard('emergency_alerts', 'Emergencies', const Color(0xFFFF4444), Icons.warning_amber_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard('announcements', 'Announcements', const Color(0xFF34D399), Icons.campaign_outlined)),
          ],
        ),
        const SizedBox(height: 20),

        // Emergency alert shortcut
        _EmergencyBanner(onTap: onEmergencyTap),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String collection;
  final String label;
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
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 10),
              Text('$count',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700)),
              Text(label,
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _EmergencyBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('emergency_alerts')
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4444).withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFF4444).withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF4444), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$count Active Emergency Alert${count > 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                              color: const Color(0xFFFF4444),
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      Text('Tap to view and resolve',
                          style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
          ),
        );
      },
    );
  }
}
