// lib/models/appointment_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus { scheduled, completed, cancelled, noShow }

class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String purpose;
  final DateTime dateTime;
  final AppointmentStatus status;
  final String? notes;
  final String? specialization;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.purpose,
    required this.dateTime,
    required this.status,
    this.notes,
    this.specialization,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      purpose: data['purpose'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString() == 'AppointmentStatus.${data['status']}',
        orElse: () => AppointmentStatus.scheduled,
      ),
      notes: data['notes'],
      specialization: data['specialization'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'purpose': purpose,
      'dateTime': Timestamp.fromDate(dateTime),
      'status': status.toString().split('.').last,
      'notes': notes,
      'specialization': specialization,
    };
  }
}
