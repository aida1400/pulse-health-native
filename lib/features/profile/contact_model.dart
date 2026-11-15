import 'dart:convert';

/// Represents a private contact / space (similar to saved addresses in Snapp)
class ContactModel {
  final String id;
  String name; // e.g. "همسر", "مامان", "خواهر", "پارتنر"
  String relation; // "همسر", "مادر", "خواهر", "پارتنر", "دوست", "سایر"
  String partnerCode; // 6-character unique pairing code
  String colorHex; // Tag color
  bool isActive;
  final DateTime createdAt;

  ContactModel({
    required this.id,
    required this.name,
    required this.relation,
    required this.partnerCode,
    this.colorHex = '#FB7185',
    this.isActive = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'relation': relation,
    'partnerCode': partnerCode,
    'colorHex': colorHex,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ContactModel.fromJson(Map<String, dynamic> json) => ContactModel(
    id: json['id'] ?? '',
    name: json['name'] ?? 'مخاطب',
    relation: json['relation'] ?? 'همسر',
    partnerCode: json['partnerCode'] ?? '',
    colorHex: json['colorHex'] ?? '#FB7185',
    isActive: json['isActive'] ?? false,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
  );
}

/// Represents the owner user profile
class UserProfileModel {
  String name;
  String phone;
  final String myCode;

  UserProfileModel({
    required this.name,
    required this.phone,
    required this.myCode,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'myCode': myCode,
  };

  factory UserProfileModel.fromJson(Map<String, dynamic> json, String defaultCode) => UserProfileModel(
    name: json['name'] ?? 'آیدا شفیع‌خانی',
    phone: json['phone'] ?? '۰۹۱۲۳۴۵۶۷۸۹',
    myCode: json['myCode'] ?? defaultCode,
  );
}
