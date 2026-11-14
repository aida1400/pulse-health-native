import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_constants.dart';

enum CapsuleStatus { pendingLocked, unlocked, recalled }

class TimeCapsuleModel {
  final String id;
  String content;
  String themeId;
  DateTime scheduledUnlockTime;
  CapsuleStatus status;
  final String senderCode;
  final DateTime createdAt;

  TimeCapsuleModel({
    required this.id,
    required this.content,
    required this.themeId,
    required this.scheduledUnlockTime,
    required this.status,
    required this.senderCode,
    required this.createdAt,
  });

  bool get isLocked => DateTime.now().isBefore(scheduledUnlockTime) && status == CapsuleStatus.pendingLocked;
  bool get canBeEditedOrRecalled => status == CapsuleStatus.pendingLocked;

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'themeId': themeId,
    'scheduledUnlockTime': scheduledUnlockTime.toIso8601String(),
    'status': status.name,
    'senderCode': senderCode,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TimeCapsuleModel.fromJson(Map<String, dynamic> json) => TimeCapsuleModel(
    id: json['id'],
    content: json['content'],
    themeId: json['themeId'],
    scheduledUnlockTime: DateTime.parse(json['scheduledUnlockTime']),
    status: CapsuleStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => CapsuleStatus.pendingLocked),
    senderCode: json['senderCode'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class TimeCapsuleService {
  static final List<TimeCapsuleModel> _vault = [];

  static Future<void> saveToVault(TimeCapsuleModel capsule) async {
    _vault.removeWhere((e) => e.id == capsule.id);
    _vault.add(capsule);
    await _persist();
  }

  static Future<bool> editCapsuleBeforeUnlock({
    required String id,
    required String newContent,
    required String newThemeId,
    required DateTime newTime,
  }) async {
    final index = _vault.indexWhere((e) => e.id == id);
    if (index == -1) return false;

    final capsule = _vault[index];
    if (!capsule.canBeEditedOrRecalled) {
      // Cannot edit after already opened
      return false;
    }

    capsule.content = newContent;
    capsule.themeId = newThemeId;
    capsule.scheduledUnlockTime = newTime;
    await _persist();
    return true;
  }

  static Future<bool> recallCapsule({required String id}) async {
    final index = _vault.indexWhere((e) => e.id == id);
    if (index == -1) return false;

    final capsule = _vault[index];
    if (!capsule.canBeEditedOrRecalled) return false;

    capsule.status = CapsuleStatus.recalled;
    _vault.removeAt(index); // completely eliminate from local vault
    await _persist();
    return true;
  }

  static List<TimeCapsuleModel> getAllMessages() => List.unmodifiable(_vault);

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_vault.map((e) => e.toJson()).toList());
    await prefs.setString(AppConstants.keyStoredMessages, data);
  }

  static Future<void> loadVault() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(AppConstants.keyStoredMessages);
    if (data != null && data.isNotEmpty) {
      final List decoded = jsonDecode(data);
      _vault.clear();
      _vault.addAll(decoded.map((e) => TimeCapsuleModel.fromJson(e)));
    }
  }
}
