import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/widgets/sparkle_overlay.dart';
import 'core/widgets/offline_indicator.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/aurora_theme.dart';

import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';

// Student
import 'screens/student/student_dashboard.dart';
import 'screens/student/profile_screen.dart';
import 'screens/student/complaint_screen.dart';
import 'screens/student/resource_sharing_screen.dart';
import 'screens/student/service_request_screen.dart';
import 'screens/student/medical_help_screen.dart';
import 'screens/student/emergency_screen.dart';
import 'screens/student/lost_found_screen.dart';
import 'screens/student/announcements_screen.dart';
import 'screens/student/parcel_screen.dart';

// Warden
import 'screens/warden/warden_dashboard.dart';
import 'screens/warden/manage_complaints_screen.dart';
import 'screens/warden/manage_services_screen.dart';
import 'screens/warden/post_announcement_screen.dart';
import 'screens/warden/emergency_alerts_screen.dart';

// Doctor
import 'screens/doctor/doctor_dashboard.dart';

// Admin
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/manage_users_screen.dart';
import 'screens/admin/reports_screen.dart';

class HostelHubApp extends StatefulWidget {
  const HostelHubApp({Key? key}) : super(key: key);

  @override
  State<HostelHubApp> createState() => _HostelHubAppState();
}

class _HostelHubAppState extends State<HostelHubApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _router = GoRouter(
      initialLocation: AppRoutes.login,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        if (auth.isLoading) return null;
        final isLoggedIn = auth.user != null;
        final isLoggingIn = state.uri.toString() == AppRoutes.login ||
            state.uri.toString() == AppRoutes.register ||
            state.uri.toString() == AppRoutes.forgotPassword;

        if (!isLoggedIn && !isLoggingIn) return AppRoutes.login;

        if (isLoggedIn && isLoggingIn) {
          final role = auth.currentUserModel?.role;
          if (role == 'student') return AppRoutes.studentDashboard;
          if (role == 'warden') return AppRoutes.wardenDashboard;
          if (role == 'doctor') return AppRoutes.doctorDashboard;
          if (role == 'admin') return AppRoutes.adminDashboard;
          return AppRoutes.studentDashboard;
        }
        return null;
      },
      routes: [
        GoRoute(path: AppRoutes.login,                pageBuilder: (c, s) => _page(s, const LoginScreen())),
        GoRoute(path: AppRoutes.register,             pageBuilder: (c, s) => _page(s, const RegisterScreen())),
        GoRoute(path: AppRoutes.forgotPassword,       pageBuilder: (c, s) => _page(s, const ForgotPasswordScreen())),
        GoRoute(path: AppRoutes.studentDashboard,     pageBuilder: (c, s) => _page(s, const StudentDashboard())),
        GoRoute(path: AppRoutes.studentProfile,       pageBuilder: (c, s) => _page(s, const ProfileScreen())),
        GoRoute(path: AppRoutes.studentComplaints,    pageBuilder: (c, s) => _page(s, const ComplaintScreen())),
        GoRoute(path: AppRoutes.studentResources,     pageBuilder: (c, s) => _page(s, const ResourceSharingScreen())),
        GoRoute(path: AppRoutes.studentServices,      pageBuilder: (c, s) => _page(s, const ServiceRequestScreen())),
        GoRoute(path: AppRoutes.studentMedical,       pageBuilder: (c, s) => _page(s, const MedicalHelpScreen())),
        GoRoute(path: AppRoutes.studentEmergency,     pageBuilder: (c, s) => _page(s, const EmergencyScreen())),
        GoRoute(path: AppRoutes.studentLostFound,     pageBuilder: (c, s) => _page(s, const LostFoundScreen())),
        GoRoute(path: AppRoutes.studentAnnouncements, pageBuilder: (c, s) => _page(s, const AnnouncementsScreen())),
        GoRoute(path: AppRoutes.studentParcels,       pageBuilder: (c, s) => _page(s, const ParcelScreen())),
        GoRoute(path: AppRoutes.wardenDashboard,      pageBuilder: (c, s) => _page(s, const WardenDashboard())),
        GoRoute(path: AppRoutes.wardenComplaints,     pageBuilder: (c, s) => _page(s, const ManageComplaintsScreen())),
        GoRoute(path: AppRoutes.wardenServices,       pageBuilder: (c, s) => _page(s, const ManageServicesScreen())),
        GoRoute(path: AppRoutes.wardenAnnouncements,  pageBuilder: (c, s) => _page(s, const PostAnnouncementScreen())),
        GoRoute(path: AppRoutes.wardenEmergency,      pageBuilder: (c, s) => _page(s, const EmergencyAlertsScreen())),
        GoRoute(path: AppRoutes.doctorDashboard,      pageBuilder: (c, s) => _page(s, const DoctorDashboard())),
        GoRoute(path: AppRoutes.adminDashboard,       pageBuilder: (c, s) => _page(s, const AdminDashboard())),
        GoRoute(path: AppRoutes.adminUsers,           pageBuilder: (c, s) => _page(s, const ManageUsersScreen())),
        GoRoute(path: AppRoutes.adminReports,         pageBuilder: (c, s) => _page(s, const ReportsScreen())),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SparkleOverlay(
      child: OfflineIndicator(
        child: MaterialApp.router(
          title: 'HostelHub',
          debugShowCheckedModeBanner: false,
          theme: AuroraTheme.theme,
          routerConfig: _router,
        ),
      ),
    );
  }

  static CustomTransitionPage _page(GoRouterState state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
        final slide = Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        final oldFade = Tween<double>(begin: 1.0, end: 0.0)
            .animate(CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeIn));
        return FadeTransition(
          opacity: oldFade,
          child: FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          ),
        );
      },
    );
  }
}
