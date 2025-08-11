import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../Models/notification/notification.dart';
import '../main.dart';
import '../providers/notification_provider.dart';

class PushNotificationService {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Yêu cầu quyền gửi notification từ người dùng
  Future<void> requestNotificationPermission() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  /// Đăng ký nhận topic general (all)
  Future<void> subscribeToGeneralTopic() async {
    try {
      await messaging.subscribeToTopic("all");
      debugPrint("Đã subscribe vào topic 'all'");
    } catch (e) {
      debugPrint("Lỗi khi subscribe vào topic: $e");
    }
  }

  /// Khởi tạo local notification, chỉ gọi 1 lần khi start app
  Future<void> initLocalNotification() async {
    if (_initialized) return;
    _initialized = true;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'HIGH_PRIORITY_NOTIFICATION',
      'High Importance Notification',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    var androidInitializationSettings =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var iosInitializationSettings = const DarwinInitializationSettings();

    var initializationSettings = InitializationSettings(
        android: androidInitializationSettings, iOS: iosInitializationSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        final route = details.payload;
        if (route != null && navigatorKey.currentContext != null) {
          navigateTo(route);
        }
      },
    );
  }

  void navigateTo(String route, {BuildContext? context}) {
    final ctx = context ?? navigatorKey.currentContext;
    if (ctx != null) {
      GoRouter.of(ctx).go(route);
    }
  }

  /// Lắng nghe firebase message (foreground & khi mở app từ notification)
  void firebaseInit(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');
      if (message.notification != null &&
          message.notification!.title != null &&
          message.notification!.body != null) {
        debugPrint(
            'Message also contained a notification: ${message.notification}');
        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          UserNotification item = UserNotification(
              id: 'newNotification',
              title: message.notification!.title!,
              content: message.notification!.body!,
              createdAt: DateTime.now().toLocal());
          NotificationProvider.of(ctx, listen: false)
              .increaseNotification(item);
        }
        showNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleMessage(context, message);
    });
  }

  /// Xử lý khi mở app từ notification
  void handleMessage(BuildContext context, RemoteMessage message) {
    context.push('/notification');
  }

  /// Hiện local notification
  Future<void> showNotification(RemoteMessage message) async {
    if (message.notification == null) return;

    const String channelId = 'HIGH_PRIORITY_NOTIFICATION';
    const String channelName = 'High Importance Notification';

    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(channelId, channelName,
            channelDescription: 'channel description',
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'ticker',
            icon: '@mipmap/ic_launcher');

    DarwinNotificationDetails darwinNotificationDetails =
        const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails, iOS: darwinNotificationDetails);

    final String route = message.data['route'] as String? ?? '/notification';

    await _flutterLocalNotificationsPlugin.show(0, message.notification!.title!,
        message.notification!.body!, notificationDetails,
        payload: route);
  }
}
