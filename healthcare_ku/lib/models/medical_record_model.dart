import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalRecord {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime dateCreated;
  final DateTime lastUpdated;
  final String diagnosis;
  final String symptoms;
  final List<Prescription> prescriptions;
  final List<String> attachmentUrls;
  final String treatmentPlan;
  final Map<String, dynamic> labResults;
  final List<String> allergies;
  final List<String> existingConditions;
  final String notes;
  final VitalSigns vitalSigns;

  MedicalRecord({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.dateCreated,
    required this.lastUpdated,
    required this.diagnosis,
    required this.symptoms,
    required this.prescriptions,
    required this.attachmentUrls,
    required this.treatmentPlan,
    required this.labResults,
    required this.allergies,
    required this.existingConditions,
    required this.notes,
    required this.vitalSigns,
  });

  factory MedicalRecord.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return MedicalRecord(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      dateCreated: (data['dateCreated'] as Timestamp).toDate(),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      diagnosis: data['diagnosis'] ?? '',
      symptoms: data['symptoms'] ?? '',
      prescriptions: List<Prescription>.from(
        (data['prescriptions'] ?? []).map(
          (x) => Prescription.fromMap(x as Map<String, dynamic>),
        ),
      ),
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      treatmentPlan: data['treatmentPlan'] ?? '',
      labResults: Map<String, dynamic>.from(data['labResults'] ?? {}),
      allergies: List<String>.from(data['allergies'] ?? []),
      existingConditions: List<String>.from(data['existingConditions'] ?? []),
      notes: data['notes'] ?? '',
      vitalSigns: VitalSigns.fromMap(data['vitalSigns'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'dateCreated': Timestamp.fromDate(dateCreated),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'diagnosis': diagnosis,
      'symptoms': symptoms,
      'prescriptions': prescriptions.map((x) => x.toMap()).toList(),
      'attachmentUrls': attachmentUrls,
      'treatmentPlan': treatmentPlan,
      'labResults': labResults,
      'allergies': allergies,
      'existingConditions': existingConditions,
      'notes': notes,
      'vitalSigns': vitalSigns.toMap(),
    };
  }
}

class Prescription {
  final String medication;
  final String dosage;
  final String frequency;
  final String duration;
  final String instructions;
  final DateTime prescribedDate;

  Prescription({
    required this.medication,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.instructions,
    required this.prescribedDate,
  });

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      medication: map['medication'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      duration: map['duration'] ?? '',
      instructions: map['instructions'] ?? '',
      prescribedDate: (map['prescribedDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medication': medication,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
      'prescribedDate': Timestamp.fromDate(prescribedDate),
    };
  }
}

class VitalSigns {
  final double? temperature;
  final int? heartRate;
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final int? respiratoryRate;
  final double? oxygenSaturation;
  final double? height;
  final double? weight;

  VitalSigns({
    this.temperature,
    this.heartRate,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.respiratoryRate,
    this.oxygenSaturation,
    this.height,
    this.weight,
  });

  factory VitalSigns.fromMap(Map<String, dynamic> map) {
    return VitalSigns(
      temperature: map['temperature']?.toDouble(),
      heartRate: map['heartRate']?.toInt(),
      bloodPressureSystolic: map['bloodPressureSystolic']?.toInt(),
      bloodPressureDiastolic: map['bloodPressureDiastolic']?.toInt(),
      respiratoryRate: map['respiratoryRate']?.toInt(),
      oxygenSaturation: map['oxygenSaturation']?.toDouble(),
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'heartRate': heartRate,
      'bloodPressureSystolic': bloodPressureSystolic,
      'bloodPressureDiastolic': bloodPressureDiastolic,
      'respiratoryRate': respiratoryRate,
      'oxygenSaturation': oxygenSaturation,
      'height': height,
      'weight': weight,
    };
  }
}
