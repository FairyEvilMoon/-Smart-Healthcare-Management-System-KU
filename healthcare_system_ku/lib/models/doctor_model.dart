import 'package:healthcare_system_ku/models/user_model.dart';

class DoctorModel extends UserModel {
  final String specialization;
  final List<String> qualifications;
  final String licenseNumber;
  final Map<String, List<String>> availability; // Day -> List of time slots

  DoctorModel({
    required String uid,
    required String email,
    required String name,
    required String phoneNumber,
    String? profileImageUrl,
    required this.specialization,
    required this.qualifications,
    required this.licenseNumber,
    required this.availability,
  }) : super(
          uid: uid,
          email: email,
          name: name,
          role: 'doctor',
          phoneNumber: phoneNumber,
          profileImageUrl: profileImageUrl,
        );

  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    return DoctorModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      specialization: map['specialization'] ?? '',
      qualifications: List<String>.from(map['qualifications'] ?? []),
      licenseNumber: map['licenseNumber'] ?? '',
      availability: Map<String, List<String>>.from(
        map['availability']?.map((key, value) => MapEntry(
                  key,
                  List<String>.from(value),
                )) ??
            {},
      ),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = super.toMap();
    data.addAll({
      'specialization': specialization,
      'qualifications': qualifications,
      'licenseNumber': licenseNumber,
      'availability': availability,
    });
    return data;
  }
}
