import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DoctorAppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'appointments';

  Future<void> scheduleAppointment({
    required String patientId,
    required String doctorId,
    required DateTime dateTime,
    required String purpose,
    String? notes,
    bool sendNotification = true,
  }) async {
    // Validate the appointment time
    final now = DateTime.now();
    if (dateTime.isBefore(now)) {
      throw 'Cannot schedule appointments in the past';
    }

    // Check for conflicts
    final conflicts = await _checkForConflicts(doctorId, dateTime);
    if (conflicts) {
      throw 'Time slot is not available';
    }

    // Create appointment document
    final appointment = {
      'patientId': patientId,
      'doctorId': doctorId,
      'dateTime': Timestamp.fromDate(dateTime),
      'status': 'scheduled',
      'purpose': purpose,
      'notes': notes,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };

    // Create the appointment in a transaction
    await _firestore.runTransaction((transaction) async {
      // Double check for conflicts within transaction
      final conflictSnapshot = await _firestore
          .collection(collectionName)
          .where('doctorId', isEqualTo: doctorId)
          .where('dateTime', isEqualTo: Timestamp.fromDate(dateTime))
          .where('status', isEqualTo: 'scheduled')
          .get();

      if (conflictSnapshot.docs.isNotEmpty) {
        throw 'Time slot was just taken';
      }

      // Create appointment
      final docRef = _firestore.collection(collectionName).doc();
      await transaction.set(docRef, appointment);

      // Update availability slot
      final availabilityRef = _firestore
          .collection('availability_slots')
          .doc('${doctorId}_${DateFormat('yyyy-MM-dd').format(dateTime)}');

      final availabilityDoc = await transaction.get(availabilityRef);

      if (availabilityDoc.exists) {
        final currentSlots =
            (availabilityDoc.data()?['bookedSlots'] as List<dynamic>?) ?? [];
        final newSlot = dateTime.hour * 60 + dateTime.minute;

        if (!currentSlots.contains(newSlot)) {
          await transaction.update(availabilityRef, {
            'bookedSlots': FieldValue.arrayUnion([newSlot])
          });
        }
      } else {
        await transaction.set(availabilityRef, {
          'doctorId': doctorId,
          'date': Timestamp.fromDate(
              DateTime(dateTime.year, dateTime.month, dateTime.day)),
          'bookedSlots': [dateTime.hour * 60 + dateTime.minute]
        });
      }
    });

    // Send notifications if enabled
    if (sendNotification) {
      // Implement notification logic here
    }
  }

  Future<bool> _checkForConflicts(String doctorId, DateTime dateTime) async {
    final querySnapshot = await _firestore
        .collection(collectionName)
        .where('doctorId', isEqualTo: doctorId)
        .where('dateTime', isEqualTo: Timestamp.fromDate(dateTime))
        .where('status', isEqualTo: 'scheduled')
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Future<void> cancelAppointment(String appointmentId, {String? reason}) async {
    final appointmentRef =
        _firestore.collection(collectionName).doc(appointmentId);

    await _firestore.runTransaction((transaction) async {
      final appointmentDoc = await transaction.get(appointmentRef);

      if (!appointmentDoc.exists) {
        throw 'Appointment not found';
      }

      await transaction.update(appointmentRef, {
        'status': 'cancelled',
        'cancellationReason': reason,
        'updatedAt': Timestamp.now(),
      });

      // Free up the availability slot
      final appointmentData = appointmentDoc.data()!;
      final dateTime = (appointmentData['dateTime'] as Timestamp).toDate();
      final doctorId = appointmentData['doctorId'];

      final availabilityRef = _firestore
          .collection('availability_slots')
          .doc('${doctorId}_${DateFormat('yyyy-MM-dd').format(dateTime)}');

      final availabilityDoc = await transaction.get(availabilityRef);

      if (availabilityDoc.exists) {
        final slot = dateTime.hour * 60 + dateTime.minute;
        await transaction.update(availabilityRef, {
          'bookedSlots': FieldValue.arrayRemove([slot])
        });
      }
    });
  }

  Future<void> rescheduleAppointment(
    String appointmentId,
    DateTime newDateTime,
  ) async {
    final appointmentRef =
        _firestore.collection(collectionName).doc(appointmentId);

    await _firestore.runTransaction((transaction) async {
      // Get the current appointment
      final appointmentDoc = await transaction.get(appointmentRef);

      if (!appointmentDoc.exists) {
        throw 'Appointment not found';
      }

      final appointmentData = appointmentDoc.data()!;
      final oldDateTime = (appointmentData['dateTime'] as Timestamp).toDate();
      final doctorId = appointmentData['doctorId'];

      // Check for conflicts at new time
      final conflictSnapshot = await _firestore
          .collection(collectionName)
          .where('doctorId', isEqualTo: doctorId)
          .where('dateTime', isEqualTo: Timestamp.fromDate(newDateTime))
          .where('status', isEqualTo: 'scheduled')
          .get();

      if (conflictSnapshot.docs.isNotEmpty) {
        throw 'New time slot is not available';
      }

      // Update the appointment
      await transaction.update(appointmentRef, {
        'dateTime': Timestamp.fromDate(newDateTime),
        'updatedAt': Timestamp.now(),
        'rescheduled': true,
      });

      // Remove old availability slot
      final oldAvailabilityRef = _firestore
          .collection('availability_slots')
          .doc('${doctorId}_${DateFormat('yyyy-MM-dd').format(oldDateTime)}');

      final oldAvailabilityDoc = await transaction.get(oldAvailabilityRef);

      if (oldAvailabilityDoc.exists) {
        final oldSlot = oldDateTime.hour * 60 + oldDateTime.minute;
        await transaction.update(oldAvailabilityRef, {
          'bookedSlots': FieldValue.arrayRemove([oldSlot])
        });
      }

      // Add new availability slot
      final newAvailabilityRef = _firestore
          .collection('availability_slots')
          .doc('${doctorId}_${DateFormat('yyyy-MM-dd').format(newDateTime)}');

      final newAvailabilityDoc = await transaction.get(newAvailabilityRef);

      if (newAvailabilityDoc.exists) {
        final newSlot = newDateTime.hour * 60 + newDateTime.minute;
        await transaction.update(newAvailabilityRef, {
          'bookedSlots': FieldValue.arrayUnion([newSlot])
        });
      } else {
        await transaction.set(newAvailabilityRef, {
          'doctorId': doctorId,
          'date': Timestamp.fromDate(
              DateTime(newDateTime.year, newDateTime.month, newDateTime.day)),
          'bookedSlots': [newDateTime.hour * 60 + newDateTime.minute]
        });
      }
    });
  }

  Stream<QuerySnapshot> getDoctorAppointments(String doctorId) {
    return _firestore
        .collection(collectionName)
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'scheduled')
        .orderBy('dateTime')
        .snapshots();
  }
}
