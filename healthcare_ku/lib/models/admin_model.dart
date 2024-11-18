// lib/models/admin_model.dart
import 'user_model.dart';

class AdminModel extends UserModel {
  final List<String> permissions;
  final DateTime? lastLogin;

  AdminModel({
    required String uid,
    required String email,
    required String name,
    String? phoneNumber,
    String? profileImageUrl,
    this.permissions = const ['all'],
    this.lastLogin,
  }) : super(
          uid: uid,
          email: email,
          name: name,
          role: 'admin',
          phoneNumber: phoneNumber,
          profileImageUrl: profileImageUrl,
        );

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = super.toMap();
    data.addAll({
      'permissions': permissions,
      'lastLogin': lastLogin?.millisecondsSinceEpoch,
    });
    return data;
  }

  factory AdminModel.fromMap(Map<String, dynamic> map) {
    return AdminModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      permissions: List<String>.from(map['permissions'] ?? ['all']),
      lastLogin: map['lastLogin'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastLogin'])
          : null,
    );
  }
}
