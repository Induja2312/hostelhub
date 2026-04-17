import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/aurora_background.dart';
import '../../core/widgets/staggered_animation.dart';
import '../../providers/auth_provider.dart';
import 'complaint_screen.dart';
import 'resource_sharing_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),  child: const Text('Logout')),
        ],
      ),
    );
    if (confirm == true && mounted) await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUserModel;
    final name = (user?.name.isNotEmpty == true) ? user!.name : 'Student';

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: false,
        appBar: _buildGlassAppBar(name),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0, 0.03), end: Offset.zero)
                  .animate(anim),
              child: child,
            ),
          ),
          child: IndexedStack(
            key: ValueKey(_currentIndex),
            index: _currentIndex,
            children: [
              _buildHomeView(name),
              const ComplaintScreen(),
              const ResourceSharingScreen(),
            ],
          ),
        ),
        bottomNavigationBar: _buildGlassNavBar(),
      ),
    );
  }

  PreferredSizeWidget _buildGlassAppBar(String name) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AppBar(
            backgroundColor: const Color(0xFFFFFFFF).withOpacity(0.05),
            elevation: 0,
            centerTitle: true,
            title: _currentIndex == 0
                ? FadeTransition(
                    opacity: _fadeAnim,
                    child: Text('Hi, $name 👋',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)))
                : Text(
                    _currentIndex == 1 ? 'Complaints' : 'Resource Sharing',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
            actions: [
              IconButton(
                  icon: const Icon(Icons.person_outline, color: Colors.white),
                  onPressed: () => context.push(AppRoutes.studentProfile)),
              IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: _logout),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0.5),
              child: Container(
                  height: 0.5,
                  color: const Color(0xFFFFFFFF).withOpacity(0.12)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassNavBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF).withOpacity(0.05),
            border: Border(
                top: BorderSide(
                    color: const Color(0xFFFFFFFF).withOpacity(0.12),
                    width: 0.5)),
          ),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined),          selectedIcon: Icon(Icons.home),          label: 'Home'),
              NavigationDestination(icon: Icon(Icons.report_problem_outlined), selectedIcon: Icon(Icons.report_problem), label: 'Complaints'),
              NavigationDestination(icon: Icon(Icons.swap_horiz_outlined),    selectedIcon: Icon(Icons.swap_horiz),    label: 'Resources'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeView(String name) {
    final modules = [
      _Mod(Icons.announcement_outlined,   'Announcements', const Color(0xFF818CF8), () => context.push(AppRoutes.studentAnnouncements)),
      _Mod(Icons.local_shipping_outlined,  'Parcels',       const Color(0xFF34D399), () => context.push(AppRoutes.studentParcels)),
      _Mod(Icons.warning_amber_outlined,   'Emergency',     const Color(0xFFFF6B6B), () => context.push(AppRoutes.studentEmergency)),
      _Mod(Icons.medical_services_outlined,'Medical Help',  const Color(0xFFF472B6), () => context.push(AppRoutes.studentMedical)),
      _Mod(Icons.search_outlined,          'Lost & Found',  const Color(0xFFFBBF24), () => context.push(AppRoutes.studentLostFound)),
      _Mod(Icons.build_outlined,           'Services',      const Color(0xFF60A5FA), () => context.push(AppRoutes.studentServices)),
    ];

    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          StaggeredAnimation(
            delay: const Duration(milliseconds: 100),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1040),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF472B6).withOpacity(0.3), width: 1),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF472B6).withOpacity(0.18),
                    border: Border.all(color: const Color(0xFFF472B6).withOpacity(0.4), width: 1),
                  ),
                  child: const Icon(Icons.person_outline, color: Color(0xFFF472B6), size: 22),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Welcome back,', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12,
              mainAxisSpacing: 12, childAspectRatio: 1.15,
            ),
            itemCount: modules.length,
            itemBuilder: (context, i) {
              final m = modules[i];
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 400 + i * 80),
                curve: Curves.easeOutBack,
                builder: (_, v, child) => Transform.scale(
                  scale: v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
                child: _buildModuleCard(m),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(_Mod m) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFF1E1040),
          border: Border.all(color: m.color.withOpacity(0.35), width: 1),
          boxShadow: [
            BoxShadow(color: m.color.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: m.color.withOpacity(0.2),
          highlightColor: m.color.withOpacity(0.08),
          onTap: m.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: m.color.withOpacity(0.2),
                  border: Border.all(color: m.color.withOpacity(0.5), width: 1),
                ),
                child: Icon(m.icon, color: m.color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(m.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Mod {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Mod(this.icon, this.label, this.color, this.onTap);
}
