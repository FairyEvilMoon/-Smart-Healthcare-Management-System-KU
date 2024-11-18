import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient_model.dart';

class PatientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<PatientModel>> getDoctorPatients(String doctorId) {
    return _firestore
        .collection('patients')
        .where('doctorIds', arrayContains: doctorId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PatientModel.fromMap({...doc.data(), 'uid': doc.id}))
            .toList());
  }

  Future<PatientModel?> getPatient(String patientId) async {
    final doc = await _firestore.collection('patients').doc(patientId).get();
    if (!doc.exists) return null;
    return PatientModel.fromMap({...doc.data()!, 'uid': doc.id});
  }

  Future<void> updateVitalSigns(
      String patientId, Map<String, dynamic> vitalSigns) async {
    await _firestore.collection('patients').doc(patientId).update({
      'vitalSigns': vitalSigns,
    });
  }

  Future<void> addMedicalRecord(
    String patientId,
    Map<String, dynamic> recordData,
  ) async {
    await _firestore
        .collection('patients')
        .doc(patientId)
        .collection('medicalRecords')
        .add({
      ...recordData,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getMedicalRecords(String patientId) {
    return _firestore
        .collection('patients')
        .doc(patientId)
        .collection('medicalRecords')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }
}
