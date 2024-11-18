import 'package:healthcare_system_ku/models/user_model.dart';

class PatientModel extends UserModel {
  final String bloodGroup;
  final List<String> allergies;
  final List<String> chronicConditions;
  final Map<String, dynamic> vitalSigns; // Store latest vital signs

  PatientModel({
    required String uid,
    required String email,
    required String name,
    required String phoneNumber,
    String? profileImageUrl,
    required this.bloodGroup,
    required this.allergies,
    required this.chronicConditions,
    required this.vitalSigns,
  }) : super(
          uid: uid,
          email: email,
          name: name,
          role: 'patient',
          phoneNumber: phoneNumber,
          profileImageUrl: profileImageUrl,
        );

  factory PatientModel.fromMap(Map<String, dynamic> map) {
    return PatientModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      bloodGroup: map['bloodGroup'] ?? '',
      allergies: List<String>.from(map['allergies'] ?? []),
      chronicConditions: List<String>.from(map['chronicConditions'] ?? []),
      vitalSigns: Map<String, dynamic>.from(map['vitalSigns'] ?? {}),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = super.toMap();
    data.addAll({
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'chronicConditions': chronicConditions,
      'vitalSigns': vitalSigns,
    });
    return data;
  }
}
