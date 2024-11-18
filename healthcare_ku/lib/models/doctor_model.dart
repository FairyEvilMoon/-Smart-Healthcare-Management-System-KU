// lib/models/doctor_model.dart
import 'user_model.dart';

class DoctorModel extends UserModel {
  final String? specialization;
  final String? licenseNumber;
  final String status;
  final List<String> availability;

  DoctorModel({
    required String uid,
    required String email,
    required String name,
    String? phoneNumber,
    String? profileImageUrl,
    this.specialization,
    this.licenseNumber,
    this.status = 'pending',
    this.availability = const [],
  }) : super(
          uid: uid,
          email: email,
          name: name,
          role: 'doctor',
          phoneNumber: phoneNumber,
          profileImageUrl: profileImageUrl,
        );

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = super.toMap();
    data.addAll({
      'specialization': specialization,
      'licenseNumber': licenseNumber,
      'status': status,
      'availability': availability,
    });
    return data;
  }

  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    return DoctorModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      specialization: map['specialization'],
      licenseNumber: map['licenseNumber'],
      status: map['status'] ?? 'pending',
      availability: List<String>.from(map['availability'] ?? []),
    );
  }
}
