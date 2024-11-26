import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/availability_slot_model.dart';

class AvailabilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get doctor's availability slots
  Stream<List<AvailabilitySlotModel>> getDoctorAvailability(String doctorId) {
    return _firestore
        .collection('users')
        .doc(doctorId)
        .collection('availability')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AvailabilitySlotModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Add new availability slot
  Future<void> addAvailabilitySlot(
      String doctorId, AvailabilitySlotModel slot) async {
    await _firestore
        .collection('users')
        .doc(doctorId)
        .collection('availability')
        .add(slot.toMap());
  }

  // Update availability slot
  Future<void> updateAvailabilitySlot(
      String doctorId, AvailabilitySlotModel slot) async {
    await _firestore
        .collection('users')
        .doc(doctorId)
        .collection('availability')
        .doc(slot.id)
        .update(slot.toMap());
  }

  // Delete availability slot
  Future<void> deleteAvailabilitySlot(String doctorId, String slotId) async {
    await _firestore
        .collection('users')
        .doc(doctorId)
        .collection('availability')
        .doc(slotId)
        .delete();
  }

  // Generate time slots for a specific date
  List<DateTime> generateTimeSlots(
      DateTime date, List<AvailabilitySlotModel> availabilitySlots) {
    List<DateTime> slots = [];
    final targetDate = DateTime(date.year, date.month, date.day);

    for (var slot in availabilitySlots) {
      if (slot.isAvailable) {
        if (slot.isRecurring) {
          String weekday = DateFormat('EEEE').format(targetDate);
          if (slot.recurringDays.contains(weekday)) {
            slots.addAll(_generateSlotsForTimeRange(
              targetDate,
              TimeOfDay.fromDateTime(slot.startTime),
              TimeOfDay.fromDateTime(slot.endTime),
            ));
          }
        } else {
          if (_isSameDate(slot.startTime, targetDate)) {
            slots.addAll(_generateSlotsForTimeRange(
              targetDate,
              TimeOfDay.fromDateTime(slot.startTime),
              TimeOfDay.fromDateTime(slot.endTime),
            ));
          }
        }
      }
    }

    return slots..sort();
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  List<DateTime> _generateSlotsForTimeRange(
      DateTime date, TimeOfDay start, TimeOfDay end) {
    List<DateTime> slots = [];
    DateTime current =
        DateTime(date.year, date.month, date.day, start.hour, start.minute);
    final endTime =
        DateTime(date.year, date.month, date.day, end.hour, end.minute);

    while (current.isBefore(endTime)) {
      slots.add(current);
      current = current.add(Duration(minutes: 30)); // 30-minute slots
    }

    return slots;
  }
}
