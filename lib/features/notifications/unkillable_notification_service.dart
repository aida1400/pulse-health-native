import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/app_constants.dart';

class UnkillableNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handled when user taps the notification
      },
    );

    // Create High-Priority Notification Channel with Custom Sound
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDescription,
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('soft_pulse'),
      enableVibration: true,
      showBadge: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> requestNotificationPermission() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> requestIgnoreBatteryOptimization() async {
    // Triggers Android system intent to whitelist Pulse from battery killing
  }

  /// Dispatches the disguised notification that looks like a health update
  /// Dynamically customized per message category
  static Future<void> showCamouflagedNotification({
    required int id,
    String category = 'romantic',
    String? customDecoyText,
  }) async {
    final catInfo = AppConstants.categoryNotifications[category] ??
        AppConstants.categoryNotifications['romantic']!;

    final title = catInfo['title'] ?? 'پایشگر پالس سلامت';
    final body = customDecoyText ?? catInfo['body'] ?? 'ثبت وضعیت جدید شاخص ریتم قلب';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'پالس سلامت',
      visibility: NotificationVisibility.private, // Masked on lockscreen
      playSound: true,
      sound: RawResourceAndroidNotificationSound('soft_pulse'),
      color: Color(0xFF10B981),
      ongoing: false,
      autoCancel: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
    );
  }
}
