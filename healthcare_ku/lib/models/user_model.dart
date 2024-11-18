class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'admin', 'doctor', 'patient'
  final String? phoneNumber;
  final String? profileImageUrl;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.phoneNumber,
    this.profileImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      name: map['name'],
      role: map['role'],
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
    );
  }
}
