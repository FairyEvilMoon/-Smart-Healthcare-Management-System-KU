import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<AppointmentModel>> getUpcomingAppointments(String patientId) {
    final now = DateTime.now();

    return _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('status', isEqualTo: 'scheduled') // Changed this line
        .orderBy('dateTime')
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> createAppointment({
    required String patientId,
    required String doctorId,
    required String doctorName,
    required String purpose,
    required DateTime dateTime,
  }) async {
    try {
      // Get the currently authenticated user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != patientId) {
        throw 'Authentication error';
      }

      // Create appointment data
      final appointmentData = {
        'patientId': patientId,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'purpose': purpose,
        'dateTime': Timestamp.fromDate(dateTime),
        'status': 'scheduled',
        'createdAt': Timestamp.now(),
        'createdBy': patientId, // Add this to track who created the appointment
      };

      // Start a batch write
      WriteBatch batch = _firestore.batch();

      // Create new appointment document
      DocumentReference appointmentRef =
          _firestore.collection('appointments').doc();
      batch.set(appointmentRef, appointmentData);

      // Update doctor's availability
      DocumentReference doctorRef =
          _firestore.collection('users').doc(doctorId);
      String timeSlot = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
      batch.update(doctorRef, {
        'availability': FieldValue.arrayRemove([timeSlot])
      });

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error creating appointment: $e');
      throw 'Failed to book appointment. Please try again.';
    }
  }

  Stream<List<AppointmentModel>> getPastAppointments(String patientId) {
    final now = DateTime.now();

    return _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .where('dateTime', isLessThan: now)
        .orderBy('dateTime', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> cancelAppointment(String appointmentId) {
    return _firestore.collection('appointments').doc(appointmentId).update(
        {'status': AppointmentStatus.cancelled.toString().split('.').last});
  }
}
