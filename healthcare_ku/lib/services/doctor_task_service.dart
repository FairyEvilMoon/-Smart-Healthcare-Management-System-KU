import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorTaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<Map<String, int>> getPendingTasksCounts(String doctorId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
        .where('dateTime', isLessThan: endOfDay)
        .snapshots()
        .asyncMap((appointmentsSnapshot) async {
      final appointments = appointmentsSnapshot.docs;
      int pendingMedicalRecords = 0;
      int pendingPrescriptions = 0;
      int pendingPatientInfo = 0;

      for (var appointment in appointments) {
        final appointmentData = appointment.data();
        final patientId = appointmentData['patientId'];

        // Check for medical records
        final medicalRecords = await _firestore
            .collection('medical_records')
            .where('patientId', isEqualTo: patientId)
            .where('doctorId', isEqualTo: doctorId)
            .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
            .where('dateTime', isLessThan: endOfDay)
            .get();
        if (medicalRecords.docs.isEmpty) {
          pendingMedicalRecords++;
        }

        // Check for prescriptions
        final prescriptions = await _firestore
            .collection('prescriptions')
            .where('patientId', isEqualTo: patientId)
            .where('doctorId', isEqualTo: doctorId)
            .where('prescriptionDate', isGreaterThanOrEqualTo: startOfDay)
            .where('prescriptionDate', isLessThan: endOfDay)
            .get();
        if (prescriptions.docs.isEmpty) {
          pendingPrescriptions++;
        }

        // Check for incomplete patient information
        final patientDoc =
            await _firestore.collection('users').doc(patientId).get();

        final patientData = patientDoc.data() ?? {};
        if (patientData['bloodGroup'] == null ||
            patientData['bloodGroup'].toString().isEmpty ||
            patientData['allergies'] == null ||
            (patientData['allergies'] as List).isEmpty ||
            patientData['medicalHistory'] == null ||
            (patientData['medicalHistory'] as List).isEmpty) {
          pendingPatientInfo++;
        }
      }

      return {
        'medicalRecords': pendingMedicalRecords,
        'prescriptions': pendingPrescriptions,
        'patientInfo': pendingPatientInfo,
      };
    });
  }

  Stream<List<Map<String, dynamic>>> getPendingTasks(String doctorId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
        .where('dateTime', isLessThan: endOfDay)
        .snapshots()
        .asyncMap((appointmentsSnapshot) async {
      List<Map<String, dynamic>> tasks = [];

      for (var appointment in appointmentsSnapshot.docs) {
        final appointmentData = appointment.data();
        final patientId = appointmentData['patientId'];
        final patientDoc =
            await _firestore.collection('users').doc(patientId).get();

        // Get patient details
        final patientData = patientDoc.data() ?? {};
        final patientName = patientData['name'] ?? 'Unknown Patient';

        // Check medical records
        final medicalRecords = await _firestore
            .collection('medical_records')
            .where('patientId', isEqualTo: patientId)
            .where('doctorId', isEqualTo: doctorId)
            .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
            .where('dateTime', isLessThan: endOfDay)
            .get();

        if (medicalRecords.docs.isEmpty) {
          tasks.add({
            'type': 'medical_record',
            'patientId': patientId,
            'patientName': patientName,
            'appointmentId': appointment.id,
            'appointmentTime': appointmentData['dateTime'],
            'description': 'Medical record pending',
          });
        }

        // Check prescriptions
        final prescriptions = await _firestore
            .collection('prescriptions')
            .where('patientId', isEqualTo: patientId)
            .where('doctorId', isEqualTo: doctorId)
            .where('prescriptionDate', isGreaterThanOrEqualTo: startOfDay)
            .where('prescriptionDate', isLessThan: endOfDay)
            .get();

        if (prescriptions.docs.isEmpty) {
          tasks.add({
            'type': 'prescription',
            'patientId': patientId,
            'patientName': patientName,
            'appointmentId': appointment.id,
            'appointmentTime': appointmentData['dateTime'],
            'description': 'Prescription pending',
          });
        }

        // Check incomplete patient information
        if (patientData['bloodGroup'] == null ||
            patientData['bloodGroup'].toString().isEmpty ||
            patientData['allergies'] == null ||
            (patientData['allergies'] as List).isEmpty ||
            patientData['medicalHistory'] == null ||
            (patientData['medicalHistory'] as List).isEmpty) {
          tasks.add({
            'type': 'patient_info',
            'patientId': patientId,
            'patientName': patientName,
            'appointmentId': appointment.id,
            'appointmentTime': appointmentData['dateTime'],
            'description': 'Patient information incomplete',
          });
        }
      }

      // Sort tasks by appointment time
      tasks.sort((a, b) => (a['appointmentTime'] as Timestamp)
          .compareTo(b['appointmentTime'] as Timestamp));

      return tasks;
    });
  }
}
