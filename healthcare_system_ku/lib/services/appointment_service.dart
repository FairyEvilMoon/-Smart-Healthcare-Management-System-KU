import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthcare_system_ku/models/appointment_model.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<AppointmentModel>> getDoctorAppointments(String doctorId) async {
    final snapshots = await _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .get();

    return snapshots.docs
        .map((doc) => AppointmentModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Stream<List<AppointmentModel>> getDoctorUpcomingAppointments(
      String doctorId) {
    final now = DateTime.now();
    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('dateTime', isGreaterThanOrEqualTo: now)
        .where('status', whereIn: ['confirmed', 'pending'])
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                AppointmentModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<Map<String, int>> getDoctorAppointmentsCounts(String doctorId) {
    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) {
      int pending = 0;
      int confirmed = 0;
      int completed = 0;
      int cancelled = 0;

      for (var doc in snapshot.docs) {
        switch (doc.data()['status']) {
          case 'pending':
            pending++;
            break;
          case 'confirmed':
            confirmed++;
            break;
          case 'completed':
            completed++;
            break;
          case 'cancelled':
            cancelled++;
            break;
        }
      }

      return {
        'pending': pending,
        'confirmed': confirmed,
        'completed': completed,
        'cancelled': cancelled,
      };
    });
  }

  Future<List<AppointmentModel>> getPatientAppointments(
      String patientId) async {
    final snapshots = await _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .get();

    return snapshots.docs
        .map((doc) => AppointmentModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Stream<List<AppointmentModel>> getPatientUpcomingAppointments(
      String patientId) {
    final now = DateTime.now();
    return _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .where('dateTime', isGreaterThanOrEqualTo: now)
        .where('status', whereIn: ['confirmed', 'pending'])
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                AppointmentModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> bookAppointment(AppointmentModel appointment) async {
    await _firestore.collection('appointments').doc(appointment.id).set(
          appointment.toMap(),
        );
  }

  Future<Map<String, int>> getMonthlyAppointmentStats(
    String doctorId,
    DateTime month,
  ) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final appointments = await _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('dateTime', isGreaterThanOrEqualTo: startOfMonth)
        .where('dateTime', isLessThanOrEqualTo: endOfMonth)
        .get();

    var stats = {
      'total': 0,
      'completed': 0,
      'cancelled': 0,
      'noShow': 0,
    };

    for (var doc in appointments.docs) {
      stats['total'] = stats['total']! + 1;
      switch (doc.data()['status']) {
        case 'completed':
          stats['completed'] = stats['completed']! + 1;
          break;
        case 'cancelled':
          stats['cancelled'] = stats['cancelled']! + 1;
          break;
        case 'noShow':
          stats['noShow'] = stats['noShow']! + 1;
          break;
      }
    }

    return stats;
  }

  Future<void> updateAppointmentStatus(
    String appointmentId,
    String status, {
    String? diagnosis,
    List<String>? prescriptions,
  }) async {
    final data = {
      'status': status,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (prescriptions != null) 'prescriptions': prescriptions,
    };

    await _firestore.collection('appointments').doc(appointmentId).update(data);
  }

  Future<void> updateAppointmentDetails(
    String appointmentId,
    String diagnosis,
    String notes,
  ) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'diagnosis': diagnosis,
      'notes': notes,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addPrescriptionToAppointment(
    String appointmentId,
    List<String> prescriptions,
  ) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'prescriptions': prescriptions,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> hasAppointmentConflict(String doctorId, DateTime dateTime,
      {String? excludeAppointmentId}) async {
    // Check 30 minutes before and after the proposed time
    final startWindow = dateTime.subtract(Duration(minutes: 30));
    final endWindow = dateTime.add(Duration(minutes: 30));

    var query = _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('dateTime', isGreaterThanOrEqualTo: startWindow)
        .where('dateTime', isLessThanOrEqualTo: endWindow)
        .where('status', whereIn: ['confirmed', 'pending']);

    final conflictingAppointments = await query.get();

    return conflictingAppointments.docs
        .any((doc) => doc.id != excludeAppointmentId);
  }

  Future<void> sendAppointmentReminder(String appointmentId) async {
    final appointment =
        await _firestore.collection('appointments').doc(appointmentId).get();

    if (!appointment.exists) return;

    // Here you would typically integrate with a notification service
    // For example, Firebase Cloud Messaging (FCM)
    await _firestore.collection('notifications').add({
      'type': 'appointment_reminder',
      'appointmentId': appointmentId,
      'patientId': appointment.data()!['patientId'],
      'doctorId': appointment.data()!['doctorId'],
      'dateTime': appointment.data()!['dateTime'],
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rescheduleAppointment(
    String appointmentId,
    DateTime newDateTime,
  ) async {
    final appointment =
        await _firestore.collection('appointments').doc(appointmentId).get();

    if (!appointment.exists) throw Exception('Appointment not found');

    // Check for conflicts
    final hasConflict = await hasAppointmentConflict(
      appointment.data()!['doctorId'],
      newDateTime,
      excludeAppointmentId: appointmentId,
    );

    if (hasConflict) {
      throw Exception('Time slot is not available');
    }

    await _firestore.collection('appointments').doc(appointmentId).update({
      'dateTime': newDateTime,
      'lastUpdated': FieldValue.serverTimestamp(),
      'rescheduled': true,
      'previousDateTime': appointment.data()!['dateTime'],
    });

    // Create a notification for the rescheduled appointment
    await _firestore.collection('notifications').add({
      'type': 'appointment_rescheduled',
      'appointmentId': appointmentId,
      'patientId': appointment.data()!['patientId'],
      'doctorId': appointment.data()!['doctorId'],
      'oldDateTime': appointment.data()!['dateTime'],
      'newDateTime': newDateTime,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<AppointmentModel>> getAppointmentHistoryWithPatient(
    String doctorId,
    String patientId,
  ) {
    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('patientId', isEqualTo: patientId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                AppointmentModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }
}
