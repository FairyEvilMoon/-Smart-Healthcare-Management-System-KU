import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/doctor_model.dart';

class DoctorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<String>> getSpecializations() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) {
      final specializations = snapshot.docs
          .map((doc) => doc.data()['specialization'] as String)
          .toSet()
          .toList();
      specializations.sort();
      return specializations;
    });
  }

  Stream<List<DoctorModel>> getDoctorsBySpecialization(String specialization) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('status', isEqualTo: 'active')
        .where('specialization', isEqualTo: specialization)
        .snapshots()
        .map((snapshot) {
      print('Found ${snapshot.docs.length} doctors'); // Debug print
      return snapshot.docs.map((doc) {
        print('Doctor data: ${doc.data()}'); // Debug print
        return DoctorModel.fromMap({
          ...doc.data(),
          'uid': doc.id,
        });
      }).toList();
    });
  }

  Stream<List<String>> getAvailableTimeSlots(
    String doctorId,
    DateTime date,
  ) {
    return _firestore.collection('users').doc(doctorId).snapshots().map((doc) {
      final DoctorModel doctor = DoctorModel.fromMap({
        ...doc.data()!,
        'uid': doc.id,
      });

      final dateString = DateFormat('yyyy-MM-dd').format(date);
      return doctor.availability
          .where((slot) => slot.startsWith(dateString))
          .map((slot) => slot.split(' ')[1])
          .toList();
    });
  }

  Future<bool> checkDoctorsExist(String specialization) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('status', isEqualTo: 'active')
        .where('specialization', isEqualTo: specialization)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<void> saveNote({
    required String doctorId,
    required String patientId,
    required String notes,
    String? diagnosis,
    Map<String, dynamic>? vitalSigns,
  }) async {
    try {
      await _firestore.collection('doctor_notes').add({
        'doctorId': doctorId,
        'patientId': patientId,
        'notes': notes,
        'diagnosis': diagnosis,
        'vitalSigns': vitalSigns,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw 'Error saving note: $e';
    }
  }

  Stream<QuerySnapshot> getDoctorNotes(String doctorId, String patientId) {
    return _firestore
        .collection('doctor_notes')
        .where('doctorId', isEqualTo: doctorId)
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> savePrescription({
    required String doctorId,
    required String patientId,
    required String medication,
    required String dosage,
    required String frequency,
    required String duration,
    String? instructions,
  }) async {
    try {
      await _firestore.collection('prescriptions').add({
        'doctorId': doctorId,
        'patientId': patientId,
        'medication': medication,
        'dosage': dosage,
        'frequency': frequency,
        'duration': duration,
        'instructions': instructions,
        'prescribedDate': Timestamp.now(),
        'status': 'active'
      });
    } catch (e) {
      throw 'Error saving prescription: $e';
    }
  }

  Stream<QuerySnapshot> getPatientPrescriptions(String patientId) {
    return _firestore
        .collection('prescriptions')
        .where('patientId', isEqualTo: patientId)
        .orderBy('prescribedDate', descending: true)
        .snapshots();
  }
}
