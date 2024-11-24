class HealthMetric {
  final DateTime timestamp;
  final double heartRate;
  final double systolicPressure;
  final double diastolicPressure;
  final double weight;

  HealthMetric({
    required this.timestamp,
    required this.heartRate,
    required this.systolicPressure,
    required this.diastolicPressure,
    required this.weight,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'heartRate': heartRate,
      'systolicPressure': systolicPressure,
      'diastolicPressure': diastolicPressure,
      'weight': weight,
    };
  }

  factory HealthMetric.fromMap(Map<String, dynamic> map) {
    return HealthMetric(
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      heartRate: map['heartRate']?.toDouble() ?? 0.0,
      systolicPressure: map['systolicPressure']?.toDouble() ?? 0.0,
      diastolicPressure: map['diastolicPressure']?.toDouble() ?? 0.0,
      weight: map['weight']?.toDouble() ?? 0.0,
    );
  }
}
