import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final plugin = FlutterLocalNotificationsPlugin();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(const InitializationSettings(android: android));
  await _showLocal(plugin, message);
}

Future<void> _showLocal(FlutterLocalNotificationsPlugin plugin, RemoteMessage message) async {
  final notification = message.notification;
  if (notification == null) return;
  await plugin.show(
    notification.hashCode,
    notification.title,
    notification.body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'hostelhub_channel', 'HostelHub Notifications',
        channelDescription: 'Notifications for HostelHub app',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Local notifications setup
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (details) {},
    );

    // FCM permissions
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground handler
    FirebaseMessaging.onMessage.listen((message) {
      _showLocal(_local, message);
    });
  }

  /// Save FCM token to Firestore for a user so server can target them
  Future<void> saveToken(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'fcmToken': token});
      }
    } catch (e) {
      debugPrint('FCM token save failed: $e');
    }
  }

  /// Show a local notification immediately (for in-app triggers)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _local.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'hostelhub_channel', 'HostelHub Notifications',
          channelDescription: 'Notifications for HostelHub app',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// Listen to Firestore for new emergency alerts, announcements, parcels and lost & found
  void listenForAlerts(String uid) {
    // Emergency alerts
    FirebaseFirestore.instance
        .collection('emergency_alerts')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data()!;
          showNotification(
            id: change.doc.id.hashCode,
            title: '🚨 Emergency Alert',
            body: data['message'] ?? 'Emergency declared in Room ${data['roomNumber']}',
          );
        }
      }
    });

    // Announcements
    FirebaseFirestore.instance
        .collection('announcements')
        .snapshots()
        .listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data()!;
          showNotification(
            id: change.doc.id.hashCode,
            title: '📢 ${data['title'] ?? 'New Announcement'}',
            body: data['body'] ?? '',
          );
        }
      }
    });

    // Parcels for this student
    FirebaseFirestore.instance
        .collection('parcels')
        .where('studentId', isEqualTo: uid)
        .where('status', isEqualTo: 'arrived')
        .snapshots()
        .listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data()!;
          showNotification(
            id: change.doc.id.hashCode,
            title: '📦 Parcel Arrived!',
            body: 'A parcel from ${data['senderName'] ?? 'unknown'} is waiting at the warden office.',
          );
        }
      }
    });

    // Lost & found — notify owner when item is with warden
    FirebaseFirestore.instance
        .collection('lost_found')
        .where('reportedBy', isEqualTo: uid)
        .where('status', isEqualTo: 'with_warden')
        .snapshots()
        .listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data()!;
          showNotification(
            id: change.doc.id.hashCode,
            title: '🎉 Lost Item Found!',
            body: 'Your "${data['itemName']}" is with the warden. Please collect it.',
          );
        }
      }
    });

    // Complaint status updates for this student
    FirebaseFirestore.instance
        .collection('complaints')
        .where('studentId', isEqualTo: uid)
        .snapshots()
        .listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data()!;
          showNotification(
            id: change.doc.id.hashCode,
            title: '📋 Complaint Updated',
            body: 'Your complaint "${data['category']}" is now ${data['status']}.',
          );
        }
      }
    });
  }

  Future<void> cancelAll() async => _local.cancelAll();
}
