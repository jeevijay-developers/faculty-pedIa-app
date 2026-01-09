// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/material.dart';
//
// class NotificationService {
//   static final FlutterLocalNotificationsPlugin _localNotifications =
//       FlutterLocalNotificationsPlugin();
//   static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//
//   static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
//     'faculty_pedia_channel',
//     'Faculty Pedia Notifications',
//     description: 'Notifications from Faculty Pedia app',
//     importance: Importance.high,
//   );
//
//   static Future<void> init() async {
//     // Request permission for iOS
//     await _firebaseMessaging.requestPermission(
//       alert: true,
//       announcement: false,
//       badge: true,
//       carPlay: false,
//       criticalAlert: false,
//       provisional: false,
//       sound: true,
//     );
//
//     // Initialize local notifications
//     const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const iosSettings = DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );
//
//     const initSettings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );
//
//     await _localNotifications.initialize(
//       initSettings,
//       onDidReceiveNotificationResponse: _onNotificationTapped,
//     );
//
//     // Create notification channel for Android
//     await _localNotifications
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(_channel);
//
//     // Handle foreground messages
//     FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
//
//     // Handle background messages
//     FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
//
//     // Handle notification tap when app is in background/terminated
//     FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);
//   }
//
//   static Future<String?> getToken() async {
//     return await _firebaseMessaging.getToken();
//   }
//
//   static Future<void> subscribeToTopic(String topic) async {
//     await _firebaseMessaging.subscribeToTopic(topic);
//   }
//
//   static Future<void> unsubscribeFromTopic(String topic) async {
//     await _firebaseMessaging.unsubscribeFromTopic(topic);
//   }
//
//   static Future<void> _handleForegroundMessage(RemoteMessage message) async {
//     debugPrint('Foreground message received: ${message.notification?.title}');
//
//     final notification = message.notification;
//     final android = message.notification?.android;
//
//     if (notification != null) {
//       await _localNotifications.show(
//         notification.hashCode,
//         notification.title,
//         notification.body,
//         NotificationDetails(
//           android: AndroidNotificationDetails(
//             _channel.id,
//             _channel.name,
//             channelDescription: _channel.description,
//             icon: android?.smallIcon ?? '@mipmap/ic_launcher',
//             importance: Importance.high,
//             priority: Priority.high,
//           ),
//           iOS: const DarwinNotificationDetails(
//             presentAlert: true,
//             presentBadge: true,
//             presentSound: true,
//           ),
//         ),
//         payload: message.data.toString(),
//       );
//     }
//   }
//
//   static void _handleNotificationOpen(RemoteMessage message) {
//     debugPrint('Notification opened: ${message.data}');
//     // Handle navigation based on message data
//   }
//
//   static void _onNotificationTapped(NotificationResponse response) {
//     debugPrint('Notification tapped: ${response.payload}');
//     // Handle navigation based on payload
//   }
//
//   // Show local notification
//   static Future<void> showLocalNotification({
//     required String title,
//     required String body,
//     String? payload,
//   }) async {
//     await _localNotifications.show(
//       DateTime.now().millisecondsSinceEpoch.remainder(100000),
//       title,
//       body,
//       NotificationDetails(
//         android: AndroidNotificationDetails(
//           _channel.id,
//           _channel.name,
//           channelDescription: _channel.description,
//           importance: Importance.high,
//           priority: Priority.high,
//         ),
//         iOS: const DarwinNotificationDetails(
//           presentAlert: true,
//           presentBadge: true,
//           presentSound: true,
//         ),
//       ),
//       payload: payload,
//     );
//   }
// }
//
// // Background message handler (must be top-level function)
// @pragma('vm:entry-point')
// Future<void> _handleBackgroundMessage(RemoteMessage message) async {
//   debugPrint('Background message received: ${message.notification?.title}');
// }
