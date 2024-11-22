import 'package:cloud_firestore/cloud_firestore.dart';

class Medication {
  final String name;
  final String dosage;
  final String frequency;
  final String instructions;

  Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.instructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'instructions': instructions,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      instructions: map['instructions'] ?? '',
    );
  }
}

class PrescriptionModel {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime prescriptionDate;
  final List<Medication> medications;
  final DateTime endDate;
  final String status; // Active or Completed
  final String notes;
  final String? appointmentId;

  PrescriptionModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.prescriptionDate,
    required this.medications,
    required this.endDate,
    required this.status,
    required this.notes,
    this.appointmentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'prescriptionDate': Timestamp.fromDate(prescriptionDate),
      'medications': medications.map((med) => med.toMap()).toList(),
      'endDate': Timestamp.fromDate(endDate),
      'status': status,
      'notes': notes,
      'appointmentId': appointmentId,
    };
  }

  factory PrescriptionModel.fromMap(Map<String, dynamic> map) {
    return PrescriptionModel(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      prescriptionDate: (map['prescriptionDate'] as Timestamp).toDate(),
      medications: List<Medication>.from(
        (map['medications'] as List).map(
          (med) => Medication.fromMap(med),
        ),
      ),
      endDate: (map['endDate'] as Timestamp).toDate(),
      status: map['status'] ?? 'Active',
      notes: map['notes'] ?? '',
      appointmentId: map['appointmentId'],
    );
  }
}
