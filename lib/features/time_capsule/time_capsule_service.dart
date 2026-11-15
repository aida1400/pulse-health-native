import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_constants.dart';
import '../../core/persian_date_helper.dart';

class PulseMessageModel {
  final String id;
  String content;
  String category;
  String themeId;
  String customBgColor;
  String particleType; // 'heart', 'candle', 'rose', 'star', 'fire'
  DateTime scheduledUnlockTime;
  String status; // 'sent', 'delivered', 'seen', 'recalled'
  final String senderCode;
  final bool isSender;
  final DateTime createdAt;
  DateTime? seenAt;
  List<String> reactions;

  PulseMessageModel({
    required this.id,
    required this.content,
    this.category = 'romantic',
    this.themeId = 'hearts',
    this.customBgColor = '#2D0B1E',
    this.particleType = 'heart',
    required this.scheduledUnlockTime,
    this.status = 'sent',
    required this.senderCode,
    required this.isSender,
    required this.createdAt,
    this.seenAt,
    List<String>? reactions,
  }) : reactions = reactions ?? [];

  bool get isLocked => DateTime.now().isBefore(scheduledUnlockTime) && status != 'recalled';
  bool get canBeEditedOrRecalled => isSender && status == 'sent';

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'category': category,
    'themeId': themeId,
    'customBgColor': customBgColor,
    'particleType': particleType,
    'scheduledUnlockTime': scheduledUnlockTime.toIso8601String(),
    'status': status,
    'senderCode': senderCode,
    'isSender': isSender,
    'createdAt': createdAt.toIso8601String(),
    'seenAt': seenAt?.toIso8601String(),
    'reactions': reactions,
  };

  factory PulseMessageModel.fromJson(Map<String, dynamic> json, {bool? overrideIsSender}) => PulseMessageModel(
    id: json['id'],
    content: json['content'] ?? '',
    category: json['category'] ?? 'romantic',
    themeId: json['themeId'] ?? 'hearts',
    customBgColor: json['customBgColor'] ?? '#2D0B1E',
    particleType: json['particleType'] ?? 'heart',
    scheduledUnlockTime: DateTime.parse(json['scheduledUnlockTime'] ?? DateTime.now().toIso8601String()),
    status: json['status'] ?? 'sent',
    senderCode: json['senderCode'] ?? '',
    isSender: overrideIsSender ?? (json['isSender'] ?? true),
    createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    seenAt: json['seenAt'] != null ? DateTime.parse(json['seenAt']) : null,
    reactions: (json['reactions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
  );
}

class TimeCapsuleService {
  static final List<PulseMessageModel> _vault = [];

  static Future<void> loadVault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.keyStoredMessages);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _vault.clear();
        for (var item in list) {
          _vault.add(PulseMessageModel.fromJson(item));
        }
      }
    } catch (_) {}
  }

  static Future<void> saveToVault(PulseMessageModel message) async {
    final idx = _vault.indexWhere((e) => e.id == message.id);
    if (idx >= 0) {
      _vault[idx] = message;
    } else {
      _vault.add(message);
    }
    await _persist();
  }

  static Future<void> updateMessageStatus(String id, String newStatus, {DateTime? seenAt}) async {
    final idx = _vault.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _vault[idx].status = newStatus;
      if (seenAt != null) {
        _vault[idx].seenAt = seenAt;
      }
      await _persist();
    }
  }

  static Future<void> addReaction(String id, String reactionEmoji) async {
    final idx = _vault.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      if (!_vault[idx].reactions.contains(reactionEmoji)) {
        _vault[idx].reactions.add(reactionEmoji);
        await _persist();
      }
    }
  }

  static Future<bool> recallCapsule({required String id}) async {
    final index = _vault.indexWhere((e) => e.id == id);
    if (index == -1) return false;

    final capsule = _vault[index];
    if (!capsule.canBeEditedOrRecalled) return false;

    capsule.status = 'recalled';
    _vault.removeAt(index);
    await _persist();
    return true;
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
    if (!capsule.canBeEditedOrRecalled) return false;

    capsule.content = newContent;
    capsule.themeId = newThemeId;
    capsule.scheduledUnlockTime = newTime;
    await _persist();
    return true;
  }

  static List<PulseMessageModel> getAllMessages() {
    final list = List<PulseMessageModel>.from(_vault);
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  /// Groups messages by Jalali solar date string for Persian calendar timeline
  static Map<String, List<PulseMessageModel>> getMessagesGroupedByDate() {
    final messages = getAllMessages();
    final Map<String, List<PulseMessageModel>> grouped = {};

    for (var msg in messages) {
      final header = PersianDateHelper.formatJalaliHeader(msg.createdAt);
      grouped.putIfAbsent(header, () => []).add(msg);
    }
    return grouped;
  }

  /// Returns sorted distinct Jalali date labels with their corresponding index
  static List<String> getDistinctJalaliDates() {
    return getMessagesGroupedByDate().keys.toList();
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_vault.map((e) => e.toJson()).toList());
      await prefs.setString(AppConstants.keyStoredMessages, data);
    } catch (_) {}
  }
}
