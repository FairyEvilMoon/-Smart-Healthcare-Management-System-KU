import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime dateTime;
  final String status; // 'pending', 'approved', 'completed', 'cancelled'
  final String? notes;
  final String? diagnosis;
  final List<String>? prescriptions;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.dateTime,
    required this.status,
    this.notes,
    this.diagnosis,
    this.prescriptions,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      notes: map['notes'],
      diagnosis: map['diagnosis'],
      prescriptions: List<String>.from(map['prescriptions'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'dateTime': Timestamp.fromDate(dateTime),
      'status': status,
      'notes': notes,
      'diagnosis': diagnosis,
      'prescriptions': prescriptions,
    };
  }
}
