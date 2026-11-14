import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_constants.dart';

class PairingManager {
  static const String _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Generates or retrieves the local unique 6-character code
  static Future<String> getOrCreateMyCode() async {
    final prefs = await SharedPreferences.getInstance();
    String? code = prefs.getString(AppConstants.keyPairingCode);
    if (code == null || code.isEmpty) {
      final rand = Random.secure();
      final buffer = StringBuffer();
      for (int i = 0; i < 6; i++) {
        buffer.write(_chars[rand.nextInt(_chars.length)]);
      }
      code = buffer.toString();
      await prefs.setString(AppConstants.keyPairingCode, code);
    }
    return code;
  }

  /// Pairs strictly with one partner and locks the room
  static Future<bool> pairWithPartner(String partnerCode) async {
    final cleaned = partnerCode.trim().toUpperCase();
    if (cleaned.length != 6) return false;

    final prefs = await SharedPreferences.getInstance();
    final myCode = await getOrCreateMyCode();

    if (cleaned == myCode) {
      // Cannot pair with self
      return false;
    }

    await prefs.setString(AppConstants.keyPartnerCode, cleaned);
    await prefs.setBool(AppConstants.keyIsPaired, true);
    return true;
  }

  static Future<bool> isPaired() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyIsPaired) ?? false;
  }

  static Future<String?> getPartnerCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyPartnerCode);
  }

  /// Derives symmetric AES-256 key between the pair
  static Future<String> deriveSharedSecretKey() async {
    final myCode = await getOrCreateMyCode();
    final partnerCode = await getPartnerCode() ?? 'DEFAULT_PAIR';
    
    // Lexicographically sort both codes so both sides generate identical shared secret
    final combined = [myCode, partnerCode]..sort();
    final bytes = utf8.encode(combined.join(':'));
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
