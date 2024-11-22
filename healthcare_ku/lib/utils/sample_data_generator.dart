// lib/utils/sample_data_generator.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/doctor_model.dart';

class SampleDataGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addSampleDoctors() async {
    final List<Map<String, dynamic>> sampleDoctors = [
      {
        'email': 'cardio.smith@example.com',
        'password': 'doctor123', // You should use more secure passwords
        'name': 'Dr. John Smith',
        'specialization': 'Cardiology',
        'licenseNumber': 'CAR123456',
        'phoneNumber': '+1234567890',
        'availability': _generateDefaultAvailability(),
      },
      {
        'email': 'neuro.johnson@example.com',
        'password': 'doctor123',
        'name': 'Dr. Sarah Johnson',
        'specialization': 'Neurology',
        'licenseNumber': 'NEU789012',
        'phoneNumber': '+1234567891',
        'availability': _generateDefaultAvailability(),
      },
      {
        'email': 'pedia.williams@example.com',
        'password': 'doctor123',
        'name': 'Dr. Michael Williams',
        'specialization': 'Pediatrics',
        'licenseNumber': 'PED345678',
        'phoneNumber': '+1234567892',
        'availability': _generateDefaultAvailability(),
      },
      // Add more sample doctors as needed
    ];

    for (var doctorData in sampleDoctors) {
      try {
        // Create Authentication account
        final UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: doctorData['email'],
          password: doctorData['password'],
        );

        // Create doctor document in Firestore
        final doctor = DoctorModel(
          uid: userCredential.user!.uid,
          email: doctorData['email'],
          name: doctorData['name'],
          specialization: doctorData['specialization'],
          licenseNumber: doctorData['licenseNumber'],
          phoneNumber: doctorData['phoneNumber'],
          status: 'approved', // Set as approved for sample data
          availability: doctorData['availability'],
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(doctor.toMap());
      } catch (e) {
        print('Error adding doctor: ${doctorData['email']} - $e');
      }
    }
  }

  List<String> _generateDefaultAvailability() {
    // Generate availability slots for next 30 days
    final List<String> slots = [];
    final now = DateTime.now();

    for (int day = 0; day < 30; day++) {
      final date = now.add(Duration(days: day));
      // Skip weekends
      if (date.weekday != DateTime.saturday &&
          date.weekday != DateTime.sunday) {
        // Add morning slots
        slots.add('${DateFormat('yyyy-MM-dd').format(date)} 09:00');
        slots.add('${DateFormat('yyyy-MM-dd').format(date)} 10:00');
        slots.add('${DateFormat('yyyy-MM-dd').format(date)} 11:00');
        // Add afternoon slots
        slots.add('${DateFormat('yyyy-MM-dd').format(date)} 14:00');
        slots.add('${DateFormat('yyyy-MM-dd').format(date)} 15:00');
        slots.add('${DateFormat('yyyy-MM-dd').format(date)} 16:00');
      }
    }
    return slots;
  }
}
