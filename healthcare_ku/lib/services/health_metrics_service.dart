import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/health_metric.dart';

class HealthMetricsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> addHealthMetric(HealthMetric metric) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('health_metrics')
        .add(metric.toMap());
  }

  Stream<List<HealthMetric>> getHealthMetrics() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('health_metrics')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HealthMetric.fromMap(doc.data()))
            .toList());
  }
}
