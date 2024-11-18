class AppointmentModel {
  final String id;
  final String doctorId;
  final String patientId;
  final DateTime dateTime;
  final String status; // 'pending', 'approved', 'completed', 'cancelled'
  final String? notes;

  AppointmentModel({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.dateTime,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'patientId': patientId,
      'dateTime': dateTime.millisecondsSinceEpoch,
      'status': status,
      'notes': notes,
    };
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: map['id'],
      doctorId: map['doctorId'],
      patientId: map['patientId'],
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['dateTime']),
      status: map['status'],
      notes: map['notes'],
    );
  }
}
