import 'package:cloud_firestore/cloud_firestore.dart';

class AvailabilitySlotModel {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final bool isRecurring;
  final List<String> recurringDays; // ["Monday", "Tuesday", etc.]
  final bool isAvailable;

  AvailabilitySlotModel({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.isRecurring = false,
    this.recurringDays = const [],
    this.isAvailable = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'isRecurring': isRecurring,
      'recurringDays': recurringDays,
      'isAvailable': isAvailable,
    };
  }

  factory AvailabilitySlotModel.fromMap(Map<String, dynamic> map, String id) {
    return AvailabilitySlotModel(
      id: id,
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      isRecurring: map['isRecurring'] ?? false,
      recurringDays: List<String>.from(map['recurringDays'] ?? []),
      isAvailable: map['isAvailable'] ?? true,
    );
  }
}
