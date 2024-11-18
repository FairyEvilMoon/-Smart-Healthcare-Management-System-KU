import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthcare_ku/models/admin_model.dart';
import 'package:healthcare_ku/models/doctor_model.dart';
import 'package:healthcare_ku/models/patient_model.dart';
import '../models/user_model.dart';
import '../models/appointment_model.dart';
import '../models/health_metric.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Authentication
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await getUserData(result.user!.uid);
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      print('Fetching user data for uid: $uid');
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        print('User data fetched: $data');

        final role = data['role'] as String;
        UserModel? user;

        switch (role) {
          case 'patient':
            user = PatientModel.fromMap(data);
            break;
          case 'doctor':
            user = DoctorModel.fromMap(data);
            break;
          case 'admin':
            user = AdminModel.fromMap(data);
            break;
          default:
            user = UserModel.fromMap(data);
        }

        return user;
      } else {
        print('No user document found');
        return null;
      }
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
    required String role,
    String? phoneNumber,
  }) async {
    try {
      final userData = {
        'uid': uid,
        'name': name,
        'email': email,
        'role': role,
        'phoneNumber': phoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'status': role == 'doctor' ? 'pending' : 'active',
      };

      if (role == 'patient') {
        // Additional patient-specific data
        userData.addAll({
          'allergies': [],
          'bloodGroup': '',
          'emergencyContact': '',
          'medicalHistory': [],
        });
      } else if (role == 'doctor') {
        // Additional doctor-specific data
        userData.addAll({
          'specialization': '',
          'licenseNumber': '',
          'availability': [],
          'rating': 0.0,
          'numberOfReviews': 0,
        });
      }

      await _firestore.collection('users').doc(uid).set(userData);

      // Create role-specific collection document
      if (role == 'patient') {
        await _firestore.collection('patients').doc(uid).set({
          'userId': uid,
          'healthMetrics': [],
          'appointments': [],
          'prescriptions': [],
        });
      } else if (role == 'doctor') {
        await _firestore.collection('doctors').doc(uid).set({
          'userId': uid,
          'appointments': [],
          'patients': [],
          'schedule': {},
        });
      }
    } catch (e) {
      print('Error creating user profile: $e');
      throw e;
    }
  }

  // Appointments
  Future<List<AppointmentModel>> getDoctorAppointments(String doctorId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .get();

      return snapshot.docs
          .map((doc) => AppointmentModel.fromMap(
              {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Get doctor appointments error: $e');
      return [];
    }
  }

  Future<bool> createAppointment(AppointmentModel appointment) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointment.id)
          .set(appointment.toMap());
      return true;
    } catch (e) {
      print('Create appointment error: $e');
      return false;
    }
  }

  // Health Metrics
  Future<void> addHealthMetric(String patientId, HealthMetric metric) async {
    try {
      await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('healthMetrics')
          .add(metric.toMap());
    } catch (e) {
      print('Add health metric error: $e');
    }
  }

  Future<List<HealthMetric>> getPatientHealthMetrics(String patientId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('healthMetrics')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map(
              (doc) => HealthMetric.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Get health metrics error: $e');
      return [];
    }
  }

  // User role and verification
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'];
      }
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  Future<bool> isDoctorVerified(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['status'] == 'active';
      }
      return false;
    } catch (e) {
      print('Error checking doctor verification: $e');
      return false;
    }
  }

  // Get system statistics
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final patients = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .get();

      final doctors = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();

      final pendingDoctors = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('status', isEqualTo: 'pending')
          .get();

      final todayStart = DateTime.now().startOfDay;
      final appointments = await _firestore
          .collection('appointments')
          .where('dateTime', isGreaterThanOrEqualTo: todayStart)
          .where('dateTime', isLessThan: todayStart.add(Duration(days: 1)))
          .get();

      return {
        'totalPatients': patients.size,
        'totalDoctors': doctors.size,
        'pendingDoctors': pendingDoctors.size,
        'todayAppointments': appointments.size,
      };
    } catch (e) {
      print('Error getting system stats: $e');
      return {
        'totalPatients': 0,
        'totalDoctors': 0,
        'pendingDoctors': 0,
        'todayAppointments': 0,
      };
    }
  }

  // Get pending doctor verifications
  Future<List<DoctorModel>> getPendingDoctors() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs
          .map((doc) => DoctorModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting pending doctors: $e');
      return [];
    }
  }

  // Verify doctor
  Future<bool> verifyDoctor(String doctorId) async {
    try {
      await _firestore.collection('users').doc(doctorId).update({
        'status': 'active',
        'verifiedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error verifying doctor: $e');
      return false;
    }
  }

  // Reject doctor
  Future<bool> rejectDoctor(String doctorId, String reason) async {
    try {
      await _firestore.collection('users').doc(doctorId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error rejecting doctor: $e');
      return false;
    }
  }

  // Get users by role
  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (role == 'patient') {
          return PatientModel.fromMap(data) as UserModel;
        } else if (role == 'doctor') {
          return DoctorModel.fromMap(data) as UserModel;
        } else if (role == 'admin') {
          return AdminModel.fromMap(data) as UserModel;
        } else {
          return UserModel.fromMap(data);
        }
      }).toList();
    } catch (e) {
      print('Error getting users by role: $e');
      return [];
    }
  }

  // Suspend user
  Future<bool> suspendUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': 'suspended',
        'suspendedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error suspending user: $e');
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // Get system activity logs
  Future<List<Map<String, dynamic>>> getActivityLogs({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('activity_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();
    } catch (e) {
      print('Error getting activity logs: $e');
      return [];
    }
  }

  // Log system activity
  Future<void> logActivity({
    required String action,
    required String userId,
    required String description,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _firestore.collection('activity_logs').add({
        'action': action,
        'userId': userId,
        'description': description,
        'additionalData': additionalData,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  // Get system analytics
  Future<Map<String, dynamic>> getSystemAnalytics() async {
    try {
      // Get data for the last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));

      final appointments = await _firestore
          .collection('appointments')
          .where('dateTime', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .get();

      final newUsers = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .get();

      final completedAppointments = appointments.docs
          .where((doc) => doc.data()['status'] == 'completed')
          .length;

      return {
        'totalAppointments': appointments.size,
        'completedAppointments': completedAppointments,
        'newUsers': newUsers.size,
        // Add more analytics as needed
      };
    } catch (e) {
      print('Error getting system analytics: $e');
      return {};
    }
  }
}

extension DateTimeExtension on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);
}
