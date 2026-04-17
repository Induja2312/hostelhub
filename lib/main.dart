import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/complaint_provider.dart';
import 'providers/resource_provider.dart';
import 'providers/service_provider.dart';
import 'providers/lost_found_provider.dart';
import 'providers/announcement_provider.dart';
import 'providers/parcel_provider.dart';
import 'providers/medical_provider.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initialize();

  FlutterError.onError = (details) {
    debugPrint('Flutter error: ${details.exceptionAsString()}');
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthService(), FirestoreService())),
        ChangeNotifierProvider(create: (_) => ComplaintProvider(FirestoreService())),
        ChangeNotifierProvider(create: (_) => ResourceProvider(FirestoreService())),
        ChangeNotifierProvider(create: (_) => ServiceProvider(FirestoreService())),
        ChangeNotifierProvider(create: (_) => LostFoundProvider(FirestoreService())),
        ChangeNotifierProvider(create: (_) => AnnouncementProvider(FirestoreService())),
        ChangeNotifierProvider(create: (_) => ParcelProvider(FirestoreService())),
        ChangeNotifierProvider(create: (_) => MedicalProvider()),
      ],
      child: const _ErrorBoundary(child: HostelHubApp()),
    ),
  );
}

class _ErrorBoundary extends StatefulWidget {
  final Widget child;
  const _ErrorBoundary({required this.child});

  @override
  State<_ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<_ErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0D0D2B),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, color: Color(0xFFF472B6), size: 64),
                const SizedBox(height: 16),
                const Text('Something went wrong',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Please restart the app. If the problem persists, contact support.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 14)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => setState(() => _error = null),
                  child: const Text('Try Again'),
                ),
              ]),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
