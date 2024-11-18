class HealthMetric {
  final DateTime timestamp;
  final double heartRate;
  final double systolicPressure;
  final double diastolicPressure;

  HealthMetric({
    required this.timestamp,
    required this.heartRate,
    required this.systolicPressure,
    required this.diastolicPressure,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'heartRate': heartRate,
      'systolicPressure': systolicPressure,
      'diastolicPressure': diastolicPressure,
    };
  }

  factory HealthMetric.fromMap(Map<String, dynamic> map) {
    return HealthMetric(
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      heartRate: map['heartRate']?.toDouble() ?? 0.0,
      systolicPressure: map['systolicPressure']?.toDouble() ?? 0.0,
      diastolicPressure: map['diastolicPressure']?.toDouble() ?? 0.0,
    );
  }
}
