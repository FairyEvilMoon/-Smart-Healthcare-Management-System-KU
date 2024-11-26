class HealthMetric {
  final String patientId;
  final String doctorId;
  final DateTime timestamp;
  final double heartRate;
  final double systolicPressure;
  final double diastolicPressure;
  final double weight;

  HealthMetric({
    required this.patientId,
    required this.doctorId,
    required this.timestamp,
    required this.heartRate,
    required this.systolicPressure,
    required this.diastolicPressure,
    required this.weight,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'heartRate': heartRate,
      'systolicPressure': systolicPressure,
      'diastolicPressure': diastolicPressure,
      'weight': weight,
    };
  }

  factory HealthMetric.fromMap(Map<String, dynamic> map) {
    return HealthMetric(
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      heartRate: map['heartRate']?.toDouble() ?? 0.0,
      systolicPressure: map['systolicPressure']?.toDouble() ?? 0.0,
      diastolicPressure: map['diastolicPressure']?.toDouble() ?? 0.0,
      weight: map['weight']?.toDouble() ?? 0.0,
    );
  }
}
