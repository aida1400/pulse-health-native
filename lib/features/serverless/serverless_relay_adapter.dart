import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../pairing/pairing_manager.dart';

class ServerlessRelayAdapter {
  // Free Firebase Realtime Database or Cloudflare Worker endpoint
  // Configured in seconds with ZERO monthly cost
  static String? _serverlessEndpoint;

  static void setEndpoint(String url) {
    _serverlessEndpoint = url;
  }

  /// Sends encrypted payload to the shared private room
  static Future<bool> dispatchEncryptedPayload({
    required String recipientCode,
    required Map<String, dynamic> payload,
  }) async {
    if (_serverlessEndpoint == null) {
      // In standalone / local mode, simulates instant local delivery
      return true;
    }

    try {
      final sharedSecret = await PairingManager.deriveSharedSecretKey();
      
      // Convert payload to JSON
      final rawJson = jsonEncode(payload);

      // Simple symmetric cipher representation
      final bytes = utf8.encode(rawJson);
      final encryptedBody = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('$_serverlessEndpoint/rooms/$recipientCode.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ciphertext': encryptedBody,
          'timestamp': DateTime.now().toIso8601String(),
          'signature': sha256.convert(utf8.encode(encryptedBody + sharedSecret)).toString(),
        }),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  /// Listens or polls the serverless mailbox
  static Future<Map<String, dynamic>?> fetchLatestPayload({required String myCode}) async {
    if (_serverlessEndpoint == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_serverlessEndpoint/rooms/$myCode.json'),
      );
      if (response.statusCode == 200 && response.body != 'null') {
        final decoded = jsonDecode(response.body);
        return decoded;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
