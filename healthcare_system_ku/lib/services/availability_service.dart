import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AvailabilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateDoctorAvailability(
    String doctorId,
    Map<String, List<String>> availability,
  ) async {
    await _firestore
        .collection('doctors')
        .doc(doctorId)
        .update({'availability': availability});
  }

  Future<List<String>> getAvailableSlots(
    String doctorId,
    DateTime date,
  ) async {
    // Get doctor's general availability for the day
    final doctorDoc =
        await _firestore.collection('doctors').doc(doctorId).get();
    final availability =
        Map<String, List<String>>.from(doctorDoc.data()?['availability'] ?? {});

    final dayName = DateFormat('EEEE').format(date).toLowerCase();
    final availableSlots = availability[dayName] ?? [];

    // Get booked appointments for the date
    final bookedSlots = await _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('date', isEqualTo: DateTime(date.year, date.month, date.day))
        .get();

    // Remove booked slots from available slots
    final bookedTimes = bookedSlots.docs
        .map((doc) => DateFormat('HH:mm')
            .format((doc.data()['dateTime'] as Timestamp).toDate()))
        .toList();

    return availableSlots.where((slot) => !bookedTimes.contains(slot)).toList();
  }
}
