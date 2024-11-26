import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient_model.dart';

class PatientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'users';

  Future<List<PatientModel>> searchPatients(String searchTerm) async {
    try {
      // Convert search term to lowercase for case-insensitive search
      final searchTermLower = searchTerm.toLowerCase();

      // Query users with role 'patient'
      final querySnapshot = await _firestore
          .collection(collectionName)
          .where('role', isEqualTo: 'patient')
          .get();

      // Filter and map results
      return querySnapshot.docs
          .map((doc) => PatientModel.fromMap({
                ...doc.data(),
                'uid': doc.id,
              }))
          .where((patient) =>
              patient.name.toLowerCase().contains(searchTermLower) ||
              patient.email.toLowerCase().contains(searchTermLower) ||
              (patient.phoneNumber?.toLowerCase().contains(searchTermLower) ??
                  false))
          .toList();
    } catch (e) {
      print('Error searching patients: $e');
      return [];
    }
  }

  Future<PatientModel?> getPatientById(String patientId) async {
    try {
      final docSnapshot =
          await _firestore.collection(collectionName).doc(patientId).get();

      if (!docSnapshot.exists) {
        return null;
      }

      return PatientModel.fromMap({
        ...docSnapshot.data()!,
        'uid': docSnapshot.id,
      });
    } catch (e) {
      print('Error getting patient by ID: $e');
      return null;
    }
  }

  Stream<List<PatientModel>> getDoctorPatients(String doctorId) {
    // Get patients who have appointments with this doctor
    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .asyncMap((appointmentSnapshot) async {
      // Get unique patient IDs
      final patientIds = appointmentSnapshot.docs
          .map((doc) => doc['patientId'] as String)
          .toSet()
          .toList();

      if (patientIds.isEmpty) {
        return [];
      }

      // Get patient documents
      final patientSnapshots = await Future.wait(
        patientIds
            .map((id) => _firestore.collection(collectionName).doc(id).get()),
      );

      // Convert to PatientModel objects
      return patientSnapshots
          .where((doc) => doc.exists)
          .map((doc) => PatientModel.fromMap({
                ...doc.data()!,
                'uid': doc.id,
              }))
          .toList();
    });
  }

  Future<List<PatientModel>> getRecentPatients(String doctorId,
      {int limit = 5}) async {
    try {
      // Get recent appointments
      final appointmentSnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('dateTime', descending: true)
          .limit(limit)
          .get();

      // Get unique patient IDs
      final patientIds = appointmentSnapshot.docs
          .map((doc) => doc['patientId'] as String)
          .toSet()
          .toList();

      if (patientIds.isEmpty) {
        return [];
      }

      // Get patient documents
      final patientSnapshots = await Future.wait(
        patientIds
            .map((id) => _firestore.collection(collectionName).doc(id).get()),
      );

      // Convert to PatientModel objects
      return patientSnapshots
          .where((doc) => doc.exists)
          .map((doc) => PatientModel.fromMap({
                ...doc.data()!,
                'uid': doc.id,
              }))
          .toList();
    } catch (e) {
      print('Error getting recent patients: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getPatientStatistics(String patientId) async {
    try {
      // Get appointments
      final appointmentSnapshot = await _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .get();

      // Get medical records
      final recordSnapshot = await _firestore
          .collection('medical_records')
          .where('patientId', isEqualTo: patientId)
          .get();

      // Get prescriptions (from medical records)
      int totalPrescriptions = 0;
      recordSnapshot.docs.forEach((doc) {
        final data = doc.data();
        if (data.containsKey('prescriptions')) {
          totalPrescriptions += (data['prescriptions'] as List).length;
        }
      });

      return {
        'totalAppointments': appointmentSnapshot.docs.length,
        'totalMedicalRecords': recordSnapshot.docs.length,
        'totalPrescriptions': totalPrescriptions,
        'lastVisit': appointmentSnapshot.docs.isNotEmpty
            ? appointmentSnapshot.docs
                .map((doc) => (doc['dateTime'] as Timestamp).toDate())
                .reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
      };
    } catch (e) {
      print('Error getting patient statistics: $e');
      return {};
    }
  }

  // Add indexes for efficient querying
  Future<void> setupIndexes() async {
    // You'll need to set up these indexes in Firebase Console:
    // Collection: users
    // Fields indexed: role (Ascending), name (Ascending)
    // Fields indexed: role (Ascending), email (Ascending)
  }
}
