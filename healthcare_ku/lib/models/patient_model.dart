// lib/models/patient_model.dart
import 'user_model.dart';
import 'health_metric.dart';

class PatientModel extends UserModel {
  final List<String> allergies;
  final String bloodGroup;
  final List<String> medicalHistory;
  final String emergencyContact;
  final String status;

  PatientModel({
    required String uid,
    required String email,
    required String name,
    String? phoneNumber,
    String? profileImageUrl,
    this.allergies = const [],
    this.bloodGroup = '',
    this.medicalHistory = const [],
    this.emergencyContact = '',
    this.status = 'active',
  }) : super(
          uid: uid,
          email: email,
          name: name,
          role: 'patient',
          phoneNumber: phoneNumber,
          profileImageUrl: profileImageUrl,
        );

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = super.toMap();
    data.addAll({
      'allergies': allergies,
      'bloodGroup': bloodGroup,
      'medicalHistory': medicalHistory,
      'emergencyContact': emergencyContact,
      'status': status,
    });
    return data;
  }

  factory PatientModel.fromMap(Map<String, dynamic> map) {
    return PatientModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      allergies: List<String>.from(map['allergies'] ?? []),
      bloodGroup: map['bloodGroup'] ?? '',
      medicalHistory: List<String>.from(map['medicalHistory'] ?? []),
      emergencyContact: map['emergencyContact'] ?? '',
      status: map['status'] ?? 'active',
    );
  }
}
