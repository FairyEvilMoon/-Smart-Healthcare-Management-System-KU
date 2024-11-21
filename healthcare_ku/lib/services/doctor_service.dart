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
        .collection('users') // Changed from 'doctors' to 'users'
        .where('role', isEqualTo: 'doctor')
        .where('status', isEqualTo: 'active')
        .where('specialization', isEqualTo: specialization)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DoctorModel.fromMap({
                ...doc.data(),
                'uid': doc.id,
              }))
          .toList();
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
}