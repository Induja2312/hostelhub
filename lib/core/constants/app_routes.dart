class AppRoutes {
  // Splash & Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Student Routes
  static const String studentDashboard = '/student';
  static const String studentComplaints = '/student/complaints';
  static const String studentResources = '/student/resources';
  static const String studentServices = '/student/services';
  static const String studentMedical = '/student/medical';
  static const String studentEmergency = '/student/emergency';
  static const String studentLostFound = '/student/lost-found';
  static const String studentAnnouncements = '/student/announcements';
  static const String studentParcels = '/student/parcels';
  static const String studentProfile = '/student/profile';
  static const String studentVisitors = '/student/visitors';

  // Warden Routes
  static const String wardenDashboard = '/warden';
  static const String wardenComplaints = '/warden/manage-complaints';
  static const String wardenServices = '/warden/manage-services';
  static const String wardenAnnouncements = '/warden/post-announcement';
  static const String wardenEmergency = '/warden/emergency-alerts';

  // Admin Routes
  static const String adminDashboard = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminParcels = '/admin/parcels';
  static const String adminReports = '/admin/reports';

  // Doctor Routes
  static const String doctorDashboard = '/doctor';
}
