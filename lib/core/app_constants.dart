/// Pulse Application Constants & Configurations
class AppConstants {
  static const String appName = 'Pulse Health';
  static const String appVersion = 'v2.4.1';
  static const String stealthPackage = 'com.pulse.health';

  // Camouflage Notification Decoys
  static const String decoyNotificationTitle = 'پایشگر سلامت پالس';
  static const String decoyNotificationBody = 'ثبت وضعیت جدید شاخص ریتم قلب';
  static const String notificationChannelId = 'pulse_health_critical_channel';
  static const String notificationChannelName = 'پایش حیاتی سلامت';
  static const String notificationChannelDescription = 'اعلان‌های سیستمی و هشدارهای پایش مداوم ضربان';

  // Shared Preferences Keys
  static const String keyIsFirstRun = 'is_first_run';
  static const String keyPairingCode = 'my_pairing_code';
  static const String keyPartnerCode = 'partner_pairing_code';
  static const String keyIsPaired = 'is_paired';
  static const String keyDecoyMode = 'decoy_mode_active';
  static const String keyStoredMessages = 'stored_messages_vault';

  // Sensor Thresholds
  static const double shakeThreshold = 14.0; // Acceleration for double-shake panic
  static const double flipPitchThreshold = -1.2; // Pitch angle indicating face down
}
