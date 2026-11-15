import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/app_constants.dart';

class UnkillableNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static const String _channelId = 'pulse_health_alert_v6';
  static const String _channelName = 'پایشگر حیاتی ضربان و سلامت';
  static const String _channelDesc = 'اعلان‌های مهم و بلادرنگ وضعیت سلامت';

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

    // Create High-Priority Heads-Up Channel with Max Importance and Loud Sound
    final Int64List vibrationPattern = Int64List(4);
    vibrationPattern[0] = 0;
    vibrationPattern[1] = 500;
    vibrationPattern[2] = 200;
    vibrationPattern[3] = 500;

    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      enableLights: true,
      showBadge: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Explicitly request notification permission for Android 13+
    await requestNotificationPermission();
  }

  /// Explicitly triggers the Android 13/14 POST_NOTIFICATIONS runtime permission dialog
  static Future<bool?> requestNotificationPermission() async {
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await androidImpl?.requestNotificationsPermission();
  }

  static Future<void> requestIgnoreBatteryOptimization() async {}

  /// Dispatches the disguised notification that looks like an emergency health update
  /// Pops up as a heads-up banner on top of the screen with sound and vibration!
  static Future<void> showCamouflagedNotification({
    required int id,
    String category = 'romantic',
    String? customDecoyText,
  }) async {
    final catInfo = AppConstants.categoryNotifications[category] ??
        AppConstants.categoryNotifications['romantic']!;

    final title = catInfo['title'] ?? 'پایشگر پالس سلامت';
    final body = customDecoyText ?? catInfo['body'] ?? 'ثبت وضعیت جدید شاخص ریتم قلب';

    final Int64List vibrationPattern = Int64List(4);
    vibrationPattern[0] = 0;
    vibrationPattern[1] = 500;
    vibrationPattern[2] = 200;
    vibrationPattern[3] = 500;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'پایش سلامت',
      visibility: NotificationVisibility.public, // Visible on lock screen!
      playSound: true,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      enableLights: true,
      color: const Color(0xFFE11D48),
      ledColor: const Color(0xFFE11D48),
      ledOnMs: 1000,
      ledOffMs: 500,
      fullScreenIntent: true, // Forces heads-up banner display!
      category: AndroidNotificationCategory.alarm,
      ongoing: false,
      autoCancel: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
    );
  }

  /// Immediate self-test notification to let user confirm sound and vibration works!
  static Future<void> testNotification() async {
    await requestNotificationPermission();
    await showCamouflagedNotification(
      id: 99999,
      category: 'romantic',
      customDecoyText: 'تست موفقیت‌آمیز: نوتیفیکیشن با صدا و ویبره فعال است (۹۴ BPM)',
    );
  }
}
