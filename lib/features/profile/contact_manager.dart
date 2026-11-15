import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../pairing/pairing_manager.dart';
import 'contact_model.dart';

class ContactManager {
  static const String _keyContactsList = 'pulse_contacts_list_v1';
  static const String _keyUserProfile = 'pulse_user_profile_v1';

  static List<ContactModel> _contacts = [];
  static ContactModel? _activeContact;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyContactsList);

    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(raw);
        _contacts = list.map((e) => ContactModel.fromJson(e)).toList();
      } catch (_) {
        _contacts = [];
      }
    }

    if (_contacts.isEmpty) {
      final existingPartnerCode = await PairingManager.getPartnerCode() ?? '';
      final defaultContact = ContactModel(
        id: 'contact_default',
        name: 'همسر / پارتنر',
        relation: 'همسر',
        partnerCode: existingPartnerCode,
        colorHex: '#E11D48',
        avatarEmoji: '❤️',
        isActive: true,
      );
      _contacts.add(defaultContact);
      await _persistContacts();
    }

    _activeContact = _contacts.firstWhere(
      (e) => e.isActive,
      orElse: () {
        _contacts.first.isActive = true;
        return _contacts.first;
      },
    );

    if (_activeContact != null && _activeContact!.partnerCode.isNotEmpty) {
      await PairingManager.pairWithPartner(_activeContact!.partnerCode);
    }
  }

  static List<ContactModel> getAllContacts() {
    return List.unmodifiable(_contacts);
  }

  static ContactModel? getActiveContact() {
    if (_activeContact == null && _contacts.isNotEmpty) {
      _activeContact = _contacts.firstWhere((e) => e.isActive, orElse: () => _contacts.first);
    }
    return _activeContact;
  }

  static Future<void> switchActiveContact(String contactId) async {
    for (var c in _contacts) {
      c.isActive = (c.id == contactId);
      if (c.isActive) {
        _activeContact = c;
      }
    }
    await _persistContacts();

    if (_activeContact != null && _activeContact!.partnerCode.isNotEmpty) {
      await PairingManager.pairWithPartner(_activeContact!.partnerCode);
    }
  }

  static Future<ContactModel> addContact({
    required String name,
    required String relation,
    required String partnerCode,
    String colorHex = '#E11D48',
    String avatarEmoji = '❤️',
  }) async {
    final newContact = ContactModel(
      id: 'contact_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      relation: relation.trim(),
      partnerCode: partnerCode.trim().toUpperCase(),
      colorHex: colorHex,
      avatarEmoji: avatarEmoji,
      isActive: false,
    );

    _contacts.add(newContact);
    await _persistContacts();
    return newContact;
  }

  static Future<void> updateContact({
    required String id,
    String? name,
    String? relation,
    String? partnerCode,
    String? colorHex,
    String? avatarEmoji,
  }) async {
    final idx = _contacts.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      if (name != null) _contacts[idx].name = name.trim();
      if (relation != null) _contacts[idx].relation = relation.trim();
      if (partnerCode != null) _contacts[idx].partnerCode = partnerCode.trim().toUpperCase();
      if (colorHex != null) _contacts[idx].colorHex = colorHex;
      if (avatarEmoji != null) _contacts[idx].avatarEmoji = avatarEmoji;

      if (_contacts[idx].isActive) {
        _activeContact = _contacts[idx];
        if (partnerCode != null) {
          await PairingManager.pairWithPartner(_contacts[idx].partnerCode);
        }
      }
      await _persistContacts();
    }
  }

  static Future<bool> deleteContact(String id) async {
    if (_contacts.length <= 1) {
      return false;
    }

    final target = _contacts.firstWhere((e) => e.id == id, orElse: () => _contacts.first);
    final wasActive = target.isActive;

    _contacts.removeWhere((e) => e.id == id);

    if (wasActive && _contacts.isNotEmpty) {
      _contacts.first.isActive = true;
      _activeContact = _contacts.first;
      if (_activeContact!.partnerCode.isNotEmpty) {
        await PairingManager.pairWithPartner(_activeContact!.partnerCode);
      }
    }

    await _persistContacts();
    return true;
  }

  static ContactModel? findContactByCode(String code) {
    final cleaned = code.trim().toUpperCase();
    try {
      return _contacts.firstWhere((c) => c.partnerCode == cleaned);
    } catch (_) {
      return null;
    }
  }

  static Future<UserProfileModel> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final myCode = await PairingManager.getOrCreateMyCode();
    final raw = prefs.getString(_keyUserProfile);

    if (raw != null && raw.isNotEmpty) {
      try {
        final json = jsonDecode(raw);
        return UserProfileModel.fromJson(json, myCode);
      } catch (_) {}
    }

    return UserProfileModel(
      name: 'آیدا شفیع‌خانی',
      phone: '۰۹۱۲۳۴۵۶۷۸۹',
      myCode: myCode,
      avatarEmoji: '👑',
    );
  }

  static Future<void> updateUserProfile({String? name, String? phone, String? avatarEmoji}) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getUserProfile();

    if (name != null) current.name = name.trim();
    if (phone != null) current.phone = phone.trim();
    if (avatarEmoji != null) current.avatarEmoji = avatarEmoji;

    await prefs.setString(_keyUserProfile, jsonEncode(current.toJson()));
  }

  static Future<void> _persistContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_contacts.map((e) => e.toJson()).toList());
      await prefs.setString(_keyContactsList, data);
    } catch (_) {}
  }
}
