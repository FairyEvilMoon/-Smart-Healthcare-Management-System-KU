import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prescription_model.dart';

class PrescriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all prescriptions for a patient
  Stream<List<PrescriptionModel>> getPrescriptionsForPatient(String patientId) {
    return _firestore
        .collection('prescriptions')
        .where('patientId', isEqualTo: patientId)
        .orderBy('prescriptionDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PrescriptionModel.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    });
  }

  // Get a single prescription by ID
  Future<PrescriptionModel?> getPrescriptionById(String prescriptionId) async {
    final doc =
        await _firestore.collection('prescriptions').doc(prescriptionId).get();

    if (!doc.exists) return null;

    return PrescriptionModel.fromMap({
      'id': doc.id,
      ...doc.data()!,
    });
  }
}
