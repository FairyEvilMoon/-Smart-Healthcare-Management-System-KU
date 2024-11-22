import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medical_record_model.dart';

class MedicalRecordsUtils {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate a single medical record
  static Future<void> createSampleMedicalRecord({
    required String patientId,
    required String doctorId,
  }) async {
    try {
      final record = MedicalRecord(
        id: '',
        patientId: patientId,
        doctorId: doctorId,
        dateCreated: DateTime.now(),
        lastUpdated: DateTime.now(),
        diagnosis: 'Hypertension Stage 1',
        symptoms: 'Headache, dizziness, shortness of breath',
        prescriptions: [
          Prescription(
            medication: 'Lisinopril',
            dosage: '10mg',
            frequency: 'Once daily',
            duration: '30 days',
            instructions: 'Take in the morning with or without food',
            prescribedDate: DateTime.now(),
          ),
          Prescription(
            medication: 'Amlodipine',
            dosage: '5mg',
            frequency: 'Once daily',
            duration: '30 days',
            instructions: 'Take in the evening with food',
            prescribedDate: DateTime.now(),
          ),
        ],
        attachmentUrls: [],
        treatmentPlan:
            'Monitor blood pressure daily, maintain low-sodium diet, regular exercise',
        labResults: {
          'Blood Pressure': '140/90 mmHg',
          'Heart Rate': '78 bpm',
          'Cholesterol': '220 mg/dL',
        },
        allergies: ['Penicillin', 'Sulfa drugs'],
        existingConditions: ['Mild obesity', 'Family history of heart disease'],
        notes:
            'Patient is responding well to initial treatment. Follow-up in 2 weeks.',
        vitalSigns: VitalSigns(
          temperature: 37.2,
          heartRate: 78,
          bloodPressureSystolic: 140,
          bloodPressureDiastolic: 90,
          respiratoryRate: 16,
          oxygenSaturation: 98,
          height: 175,
          weight: 85,
        ),
      );

      await _firestore.collection('medical_records').add(record.toFirestore());
    } catch (e) {
      print('Error creating sample medical record: $e');
      rethrow;
    }
  }

  // Generate multiple sample medical records
  static Future<void> createMultipleSampleRecords({
    required String patientId,
    required String doctorId,
    int count = 5,
  }) async {
    final List<String> conditions = [
      'Common Cold',
      'Influenza',
      'Allergic Rhinitis',
      'Bronchitis',
      'Gastritis',
      'Migraine',
      'Lower Back Pain',
      'Anxiety',
      'Insomnia',
      'Dermatitis'
    ];

    final List<String> medications = [
      'Amoxicillin',
      'Ibuprofen',
      'Loratadine',
      'Omeprazole',
      'Sertraline',
      'Albuterol',
      'Metformin',
      'Atorvastatin',
      'Metoprolol',
      'Hydrochlorothiazide'
    ];

    final List<String> symptoms = [
      'Fever, cough, sore throat',
      'Body aches, fatigue, headache',
      'Sneezing, runny nose, itchy eyes',
      'Persistent cough, chest discomfort',
      'Abdominal pain, nausea',
      'Severe headache, sensitivity to light',
      'Chronic back pain, stiffness',
      'Restlessness, worry, difficulty concentrating',
      'Difficulty falling asleep, daytime fatigue',
      'Skin rash, itching, redness'
    ];

    for (int i = 0; i < count; i++) {
      final recordDate = DateTime.now().subtract(Duration(days: i * 30));
      final conditionIndex = i % conditions.length;

      try {
        final record = MedicalRecord(
          id: '',
          patientId: patientId,
          doctorId: doctorId,
          dateCreated: recordDate,
          lastUpdated: recordDate,
          diagnosis: conditions[conditionIndex],
          symptoms: symptoms[conditionIndex],
          prescriptions: [
            Prescription(
              medication: medications[i % medications.length],
              dosage: '${(i + 1) * 5}mg',
              frequency: 'Twice daily',
              duration: '14 days',
              instructions: 'Take with food and plenty of water',
              prescribedDate: recordDate,
            ),
          ],
          attachmentUrls: [],
          treatmentPlan: 'Rest, adequate hydration, follow-up in 2 weeks',
          labResults: {
            'Temperature': '${36.5 + (i * 0.1)}°C',
            'Blood Pressure': '${120 + i}/${80 + i} mmHg',
            'Heart Rate': '${70 + i} bpm',
          },
          allergies: ['Penicillin'],
          existingConditions: ['None'],
          notes: 'Regular follow-up recommended',
          vitalSigns: VitalSigns(
            temperature: 36.5 + (i * 0.1),
            heartRate: 70 + i,
            bloodPressureSystolic: 120 + i,
            bloodPressureDiastolic: 80 + i,
            respiratoryRate: 16,
            oxygenSaturation: 98,
            height: 175,
            weight: 80 + (i * 0.5),
          ),
        );

        await _firestore
            .collection('medical_records')
            .add(record.toFirestore());
        print('Created medical record ${i + 1} of $count');
      } catch (e) {
        print('Error creating medical record ${i + 1}: $e');
      }
    }
  }

  // Create realistic chronic condition records
  static Future<void> createChronicConditionRecords({
    required String patientId,
    required String doctorId,
  }) async {
    // Diabetes management records
    final diabetesRecords = [
      {
        'diagnosis': 'Type 2 Diabetes Mellitus',
        'symptoms': 'Polyuria, polydipsia, fatigue',
        'medication': 'Metformin',
        'dosage': '1000mg',
        'labResults': {
          'Fasting Blood Sugar': '180 mg/dL',
          'HbA1c': '7.8%',
          'Blood Pressure': '138/88 mmHg'
        }
      },
      {
        'diagnosis': 'Type 2 Diabetes Mellitus - Follow up',
        'symptoms': 'Improved energy levels, normal thirst',
        'medication': 'Metformin',
        'dosage': '1000mg',
        'labResults': {
          'Fasting Blood Sugar': '145 mg/dL',
          'HbA1c': '7.2%',
          'Blood Pressure': '132/84 mmHg'
        }
      },
      {
        'diagnosis': 'Type 2 Diabetes Mellitus - Routine Check',
        'symptoms': 'Well controlled symptoms',
        'medication': 'Metformin',
        'dosage': '1000mg',
        'labResults': {
          'Fasting Blood Sugar': '130 mg/dL',
          'HbA1c': '6.8%',
          'Blood Pressure': '128/82 mmHg'
        }
      }
    ];

    int daysAgo = 180; // Start from 6 months ago
    for (var recordData in diabetesRecords) {
      final recordDate = DateTime.now().subtract(Duration(days: daysAgo));

      try {
        final record = MedicalRecord(
          id: '',
          patientId: patientId,
          doctorId: doctorId,
          dateCreated: recordDate,
          lastUpdated: recordDate,
          diagnosis: recordData['diagnosis'] as String,
          symptoms: recordData['symptoms'] as String,
          prescriptions: [
            Prescription(
              medication: recordData['medication'] as String,
              dosage: recordData['dosage'] as String,
              frequency: 'Twice daily',
              duration: '90 days',
              instructions: 'Take with meals',
              prescribedDate: recordDate,
            ),
          ],
          attachmentUrls: [],
          treatmentPlan:
              'Continue current medication, maintain diet and exercise routine, monitor blood sugar daily',
          labResults: recordData['labResults'] as Map<String, dynamic>,
          allergies: ['Sulfonylureas'],
          existingConditions: ['Type 2 Diabetes Mellitus', 'Hypertension'],
          notes:
              'Patient adhering to treatment plan. Lifestyle modifications showing positive results.',
          vitalSigns: VitalSigns(
            temperature: 36.6,
            heartRate: 76,
            bloodPressureSystolic: int.parse((recordData['labResults']
                    as Map<String, dynamic>)['Blood Pressure']
                .split('/')[0]),
            bloodPressureDiastolic: int.parse((recordData['labResults']
                    as Map<String, dynamic>)['Blood Pressure']
                .split('/')[1]),
            respiratoryRate: 16,
            oxygenSaturation: 98,
            height: 175,
            weight: 82,
          ),
        );

        await _firestore
            .collection('medical_records')
            .add(record.toFirestore());
        print('Created chronic condition record for date: $recordDate');
      } catch (e) {
        print('Error creating chronic condition record: $e');
      }

      daysAgo -= 60; // Next record 2 months later
    }
  }

  // Usage example in your app:
  static Future<void> generateSampleData({
    required String patientId,
    required String doctorId,
  }) async {
    // Create a mix of general and chronic condition records
    await createMultipleSampleRecords(
      patientId: patientId,
      doctorId: doctorId,
      count: 3,
    );
    await createChronicConditionRecords(
      patientId: patientId,
      doctorId: doctorId,
    );
  }
}
