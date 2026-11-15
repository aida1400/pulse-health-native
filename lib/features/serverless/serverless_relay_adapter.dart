import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../pairing/pairing_manager.dart';
import '../profile/contact_manager.dart';
import '../time_capsule/time_capsule_service.dart';
import '../notifications/unkillable_notification_service.dart';

class ServerlessRelayAdapter {
  static const String _relayHost = 'https://ntfy.sh';
  static Timer? _pollingTimer;
  static bool _isPolling = false;
  static final Set<String> _processedPayloadIds = {};

  static Function()? _onNewMessageCallback;
  static Function()? _onReceiptCallback;

  /// Initializes the relay listener loop
  static Future<void> startRelayListener({
    Function()? onNewMessage,
    Function()? onReceipt,
  }) async {
    _onNewMessageCallback = onNewMessage;
    _onReceiptCallback = onReceipt;

    _pollingTimer?.cancel();
    // Poll immediately
    await pollInbox();

    // Poll periodically every 4 seconds in background
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      await pollInbox();
    });
  }

  static void stopRelayListener() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Derives deterministic topic from 6-char code
  static String getTopicForCode(String code) {
    final cleaned = code.trim().toUpperCase();
    final hash = sha256.convert(utf8.encode('pulse_box_$cleaned')).toString().substring(0, 16);
    return 'pulse_box_$hash';
  }

  /// Sends a message payload to partner's inbox topic
  static Future<bool> sendMessage({
    required PulseMessageModel message,
    String? targetPartnerCode,
  }) async {
    final partnerCode = targetPartnerCode ?? await PairingManager.getPartnerCode();
    if (partnerCode == null || partnerCode.isEmpty) {
      return false;
    }

    final targetTopic = getTopicForCode(partnerCode);
    final payload = {
      'type': 'message',
      'id': message.id,
      'senderCode': message.senderCode,
      'content': message.content,
      'category': message.category,
      'themeId': message.themeId,
      'customBgColor': message.customBgColor,
      'particleType': message.particleType,
      'scheduledUnlockTime': message.scheduledUnlockTime.toIso8601String(),
      'status': 'sent',
      'isCanvas': message.isCanvas,
      'createdAt': message.createdAt.toIso8601String(),
    };

    return await _dispatchRaw(targetTopic, payload, partnerCode: partnerCode);
  }

  /// Sends delivery or seen receipt back to partner
  static Future<bool> sendReceipt({
    required String messageId,
    required String receiptStatus, // 'delivered' or 'seen'
    String? targetPartnerCode,
  }) async {
    final partnerCode = targetPartnerCode ?? await PairingManager.getPartnerCode();
    final myCode = await PairingManager.getOrCreateMyCode();
    if (partnerCode == null || partnerCode.isEmpty) return false;

    final targetTopic = getTopicForCode(partnerCode);
    final payload = {
      'type': 'receipt',
      'messageId': messageId,
      'receiptStatus': receiptStatus,
      'senderCode': myCode,
      'timestamp': DateTime.now().toIso8601String(),
    };

    return await _dispatchRaw(targetTopic, payload, partnerCode: partnerCode);
  }

  /// Sends reaction emoji to partner
  static Future<bool> sendReaction({
    required String messageId,
    required String reactionEmoji,
    String? targetPartnerCode,
  }) async {
    final partnerCode = targetPartnerCode ?? await PairingManager.getPartnerCode();
    final myCode = await PairingManager.getOrCreateMyCode();
    if (partnerCode == null || partnerCode.isEmpty) return false;

    final targetTopic = getTopicForCode(partnerCode);
    final payload = {
      'type': 'reaction',
      'messageId': messageId,
      'reactionEmoji': reactionEmoji,
      'senderCode': myCode,
    };

    return await _dispatchRaw(targetTopic, payload, partnerCode: partnerCode);
  }

  /// Derives symmetric secret key for a specific partner code
  static Future<String> _deriveSecretForPartner(String partnerCode) async {
    final myCode = await PairingManager.getOrCreateMyCode();
    final combined = [myCode, partnerCode.trim().toUpperCase()]..sort();
    final bytes = utf8.encode(combined.join(':'));
    return sha256.convert(bytes).toString();
  }

  /// Internal HTTP POST to ntfy.sh
  static Future<bool> _dispatchRaw(String topic, Map<String, dynamic> payload, {required String partnerCode}) async {
    try {
      final sharedSecret = await _deriveSecretForPartner(partnerCode);
      final rawJson = jsonEncode(payload);

      // Symmetrically sign and pack payload
      final encodedBytes = utf8.encode(rawJson);
      final cipherBody = base64Encode(encodedBytes);
      final signature = sha256.convert(utf8.encode(cipherBody + sharedSecret)).toString();

      final body = jsonEncode({
        'body': cipherBody,
        'sig': signature,
      });

      final url = Uri.parse('$_relayHost/$topic');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Title': 'Pulse-Sync',
          'Priority': 'high',
          'User-Agent': 'Pulse-Client',
        },
        body: body,
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  /// Polls the user's personal inbox topic
  static Future<void> pollInbox() async {
    if (_isPolling) return;
    _isPolling = true;

    try {
      final myCode = await PairingManager.getOrCreateMyCode();
      final myTopic = getTopicForCode(myCode);

      final url = Uri.parse('$_relayHost/$myTopic/json?poll=1&since=24h');
      final response = await http.get(
        url,
        headers: {'User-Agent': 'Pulse-Client'},
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final lines = response.body.trim().split('\n');

        for (var line in lines) {
          if (line.trim().isEmpty) continue;

          try {
            final Map<String, dynamic> envelope = jsonDecode(line);
            final String ntfyId = envelope['id'] ?? '';
            if (ntfyId.isNotEmpty && _processedPayloadIds.contains(ntfyId)) {
              continue; // already processed
            }

            final String? rawMessage = envelope['message'];
            if (rawMessage == null || rawMessage.isEmpty) continue;

            final Map<String, dynamic> packet = jsonDecode(rawMessage);
            final String? cipherBody = packet['body'];
            final String? sig = packet['sig'];

            if (cipherBody == null || sig == null) continue;

            // Decrypt candidate body to extract senderCode
            final decodedBytes = base64Decode(cipherBody);
            final decodedStr = utf8.decode(decodedBytes);
            final Map<String, dynamic> payload = jsonDecode(decodedStr);
            final senderCode = payload['senderCode']?.toString() ?? '';

            // Verify signature using the sender's shared key
            final sharedSecret = await _deriveSecretForPartner(senderCode.isNotEmpty ? senderCode : (await PairingManager.getPartnerCode() ?? ''));
            final expectedSig = sha256.convert(utf8.encode(cipherBody + sharedSecret)).toString();
            if (sig != expectedSig) {
              // Invalid signature!
              continue;
            }

            if (ntfyId.isNotEmpty) {
              _processedPayloadIds.add(ntfyId);
            }

            await _handleIncomingPayload(payload);
          } catch (_) {}
        }
      }
    } catch (_) {
    } finally {
      _isPolling = false;
    }
  }

  /// Processes verified incoming payload
  static Future<void> _handleIncomingPayload(Map<String, dynamic> payload) async {
    final type = payload['type'];

    if (type == 'message') {
      final msg = PulseMessageModel.fromJson(payload, overrideIsSender: false);

      // Check if this sender matches an existing contact
      final matchedContact = ContactManager.findContactByCode(msg.senderCode);
      final targetContactId = matchedContact?.id ?? TimeCapsuleService.activeContactId;

      msg.status = 'delivered';
      await TimeCapsuleService.saveToContactVault(targetContactId, msg);

      // 1. Show camouflaged high-priority notification!
      await UnkillableNotificationService.showCamouflagedNotification(
        id: msg.id.hashCode,
        category: msg.category,
      );

      // 2. Automatically return delivery receipt to this specific sender!
      await sendReceipt(
        messageId: msg.id,
        receiptStatus: 'delivered',
        targetPartnerCode: msg.senderCode,
      );

      _onNewMessageCallback?.call();
    } else if (type == 'receipt') {
      final messageId = payload['messageId'];
      final receiptStatus = payload['receiptStatus'] ?? 'delivered';
      final seenAtStr = payload['timestamp'];
      final seenAt = (receiptStatus == 'seen' && seenAtStr != null) ? DateTime.parse(seenAtStr) : null;

      await TimeCapsuleService.updateMessageStatus(messageId, receiptStatus, seenAt: seenAt);
      _onReceiptCallback?.call();
    } else if (type == 'reaction') {
      final messageId = payload['messageId'];
      final reactionEmoji = payload['reactionEmoji'];
      if (messageId != null && reactionEmoji != null) {
        await TimeCapsuleService.addReaction(messageId, reactionEmoji);
        _onReceiptCallback?.call();
      }
    }
  }
}
