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
  String particleType; // 'heart', 'candle', 'rose', 'star', 'fire', 'none'
  DateTime scheduledUnlockTime;
  String status; // 'sent', 'delivered', 'seen', 'recalled'
  final String senderCode;
  final bool isSender;
  final DateTime createdAt;
  DateTime? seenAt;
  List<String> reactions;
  bool isCanvas; // Distinctly marks Canvas Cards vs Plain Chat Bubbles
  String? replyToId;
  String? replyToContent;
  String? replyToSender;

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
    bool? isCanvas,
    this.replyToId,
    this.replyToContent,
    this.replyToSender,
  })  : reactions = reactions ?? [],
        isCanvas = isCanvas ?? (particleType != 'none' && themeId != 'chat_text');

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
    'isCanvas': isCanvas,
    'replyToId': replyToId,
    'replyToContent': replyToContent,
    'replyToSender': replyToSender,
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
    isCanvas: json['isCanvas'] ?? (json['themeId'] != 'chat_text' && (json['particleType'] ?? 'heart') != 'none'),
    replyToId: json['replyToId'],
    replyToContent: json['replyToContent'],
    replyToSender: json['replyToSender'],
  );
}

class TimeCapsuleService {
  static final List<PulseMessageModel> _vault = [];
  static String _activeContactId = 'contact_default';

  static String get activeContactId => _activeContactId;

  static String _getVaultKey(String contactId) => 'pulse_messages_vault_v2_$contactId';

  static Future<void> switchContact(String contactId) async {
    _activeContactId = contactId;
    await loadVault();
  }

  static Future<void> loadVault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? raw = prefs.getString(_getVaultKey(_activeContactId));

      // Fallback/migration for the default partner if new key doesn't exist yet
      if ((raw == null || raw.isEmpty) && _activeContactId == 'contact_default') {
        raw = prefs.getString(AppConstants.keyStoredMessages);
      }

      _vault.clear();
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
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

  /// Saves a message directly into a specific contact's vault (even if not currently active on screen)
  static Future<void> saveToContactVault(String contactId, PulseMessageModel message) async {
    if (contactId == _activeContactId) {
      await saveToVault(message);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getVaultKey(contactId);
      final raw = prefs.getString(key);
      List<PulseMessageModel> targetList = [];
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        targetList = list.map((e) => PulseMessageModel.fromJson(e)).toList();
      }

      final idx = targetList.indexWhere((e) => e.id == message.id);
      if (idx >= 0) {
        targetList[idx] = message;
      } else {
        targetList.add(message);
      }

      await prefs.setString(key, jsonEncode(targetList.map((e) => e.toJson()).toList()));
    } catch (_) {}
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
      await prefs.setString(_getVaultKey(_activeContactId), data);
      if (_activeContactId == 'contact_default') {
        await prefs.setString(AppConstants.keyStoredMessages, data);
      }
    } catch (_) {}
  }
}
