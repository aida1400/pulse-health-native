import 'dart:convert';

class ContactModel {
  final String id;
  String name;
  String relation; // "همسر", "مادر", "خواهر", "پارتنر", "دوست", "سایر"
  String partnerCode;
  String colorHex;
  String avatarEmoji; // Profile picture emoji / badge
  bool isActive;
  final DateTime createdAt;

  ContactModel({
    required this.id,
    required this.name,
    required this.relation,
    required this.partnerCode,
    this.colorHex = '#E11D48',
    this.avatarEmoji = '❤️',
    this.isActive = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'relation': relation,
    'partnerCode': partnerCode,
    'colorHex': colorHex,
    'avatarEmoji': avatarEmoji,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ContactModel.fromJson(Map<String, dynamic> json) => ContactModel(
    id: json['id'] ?? '',
    name: json['name'] ?? 'مخاطب',
    relation: json['relation'] ?? 'همسر',
    partnerCode: json['partnerCode'] ?? '',
    colorHex: json['colorHex'] ?? '#E11D48',
    avatarEmoji: json['avatarEmoji'] ?? '❤️',
    isActive: json['isActive'] ?? false,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
  );
}

class UserProfileModel {
  String name;
  String phone;
  final String myCode;
  String avatarEmoji; // Profile picture emoji / badge (e.g. 👑, 🌹, 💖, 🧕, 💍, 🦋)

  UserProfileModel({
    required this.name,
    required this.phone,
    required this.myCode,
    this.avatarEmoji = '👑',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'myCode': myCode,
    'avatarEmoji': avatarEmoji,
  };

  factory UserProfileModel.fromJson(Map<String, dynamic> json, String defaultCode) => UserProfileModel(
    name: json['name'] ?? 'آیدا شفیع‌خانی',
    phone: json['phone'] ?? '۰۹۱۲۳۴۵۶۷۸۹',
    myCode: json['myCode'] ?? defaultCode,
    avatarEmoji: json['avatarEmoji'] ?? '👑',
  );
}
