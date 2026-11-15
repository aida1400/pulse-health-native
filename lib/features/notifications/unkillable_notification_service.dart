import 'dart:typed_data';
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

    // Create High-Priority Notification Channel v4 (Guaranteed Vibration & System Alert)
    final Int64List vibrationPattern = Int64List.fromList([0, 350, 200, 350]);

    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      showBadge: true,
    );

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(channel);

    // Proactively request runtime notification permission on Android 13+ (API 33+)
    await requestNotificationPermission();
  }

  /// Requests Android 13+ runtime POST_NOTIFICATIONS permission
  static Future<bool> requestNotificationPermission() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestIgnoreBatteryOptimization() async {
    // Android battery optimization bypass hook
  }

  /// Dispatches the disguised notification that looks like a health update
  static Future<void> showCamouflagedNotification({
    required int id,
    String category = 'romantic',
    String? customDecoyText,
  }) async {
    final catInfo = AppConstants.categoryNotifications[category] ??
        AppConstants.categoryNotifications['romantic']!;

    final title = catInfo['title'] ?? 'پایشگر پالس سلامت';
    final body = customDecoyText ?? catInfo['body'] ?? 'ثبت وضعیت جدید شاخص ریتم قلب';

    final Int64List vibrationPattern = Int64List.fromList([0, 350, 200, 350]);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'هشدار سلامت پالس',
      visibility: NotificationVisibility.public, // Visible as medical alert on lockscreen
      playSound: true,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      color: const Color(0xFFE11D48),
      ongoing: false,
      autoCancel: true,
      channelShowBadge: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
    );
  }

  /// Instant test notification for user to verify on physical phone
  static Future<void> testNotification() async {
    await requestNotificationPermission();
    await showCamouflagedNotification(
      id: 8888,
      category: 'romantic',
      customDecoyText: 'تست موفقیت‌آمیز اعلان پزشکی: اتصال و پایش بلادرنگ فعال است',
    );
  }
}
