import 'package:cloud_firestore/cloud_firestore.dart';

class PrescriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createPrescription(Map<String, dynamic> prescriptionData) async {
    await _firestore.collection('prescriptions').add({
      ...prescriptionData,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'active',
    });
  }

  Stream<List<Map<String, dynamic>>> getPatientPrescriptions(String patientId) {
    return _firestore
        .collection('prescriptions')
        .where('patientId', isEqualTo: patientId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  Future<void> updatePrescriptionStatus(
    String prescriptionId,
    String status,
  ) async {
    await _firestore
        .collection('prescriptions')
        .doc(prescriptionId)
        .update({'status': status});
  }
}
