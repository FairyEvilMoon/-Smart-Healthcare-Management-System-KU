import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class AddClinicalNotesScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const AddClinicalNotesScreen({
    Key? key,
    required this.patientId,
    required this.patientName,
  }) : super(key: key);

  @override
  _AddClinicalNotesScreenState createState() => _AddClinicalNotesScreenState();
}

class _AddClinicalNotesScreenState extends State<AddClinicalNotesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _treatmentPlanController = TextEditingController();
  final _notesController = TextEditingController();
  final Map<String, TextEditingController> _vitalControllers = {
    'temperature': TextEditingController(),
    'heartRate': TextEditingController(),
    'bloodPressureSystolic': TextEditingController(),
    'bloodPressureDiastolic': TextEditingController(),
    'respiratoryRate': TextEditingController(),
    'oxygenSaturation': TextEditingController(),
  };
  bool _isLoading = false;
  String? _currentNoteId;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _loadExistingNote();
    _diagnosisController.addListener(_autoSave);
    _symptomsController.addListener(_autoSave);
    _treatmentPlanController.addListener(_autoSave);
    _notesController.addListener(_autoSave);
    _vitalControllers
        .forEach((_, controller) => controller.addListener(_autoSave));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clinical Notes - ${widget.patientName}'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () => _saveNotes(showSnackbar: true),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPatientInfo(),
                    SizedBox(height: 16),
                    _buildVitalSigns(),
                    SizedBox(height: 16),
                    _buildClinicalNotes(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPatientInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(widget.patientName[0]),
                  radius: 24,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patientName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        DateFormat('MMMM dd, yyyy').format(DateTime.now()),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSigns() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vital Signs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _vitalControllers['temperature'],
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Temperature (°C)',
                      prefixIcon: Icon(Icons.thermostat),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _vitalControllers['heartRate'],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Heart Rate (BPM)',
                      prefixIcon: Icon(Icons.favorite),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _vitalControllers['bloodPressureSystolic'],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Systolic',
                      prefixIcon: Icon(Icons.speed),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _vitalControllers['bloodPressureDiastolic'],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Diastolic',
                      prefixIcon: Icon(Icons.speed),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _vitalControllers['respiratoryRate'],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Respiratory Rate',
                      prefixIcon: Icon(Icons.air),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _vitalControllers['oxygenSaturation'],
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'O₂ Saturation (%)',
                      prefixIcon: Icon(Icons.water_drop),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicalNotes() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clinical Notes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _diagnosisController,
              decoration: InputDecoration(
                labelText: 'Diagnosis',
                prefixIcon: Icon(Icons.medical_information),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _symptomsController,
              decoration: InputDecoration(
                labelText: 'Symptoms',
                prefixIcon: Icon(Icons.sick),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _treatmentPlanController,
              decoration: InputDecoration(
                labelText: 'Treatment Plan',
                prefixIcon: Icon(Icons.medical_services),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Additional Notes',
                prefixIcon: Icon(Icons.note),
                hintText: 'Add any additional observations or notes',
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  void _autoSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(Duration(seconds: 2), () {
      _saveNotes(showSnackbar: false);
    });
  }

  Future<void> _loadExistingNote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Add doctor role check
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.data()?['role'] != 'doctor') {
        throw 'Unauthorized access';
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('doctor_notes')
          .where('patientId', isEqualTo: widget.patientId)
          .where('doctorId', isEqualTo: currentUser.uid)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        _currentNoteId = snapshot.docs.first.id;

        setState(() {
          _diagnosisController.text = data['diagnosis'] ?? '';
          _symptomsController.text = data['symptoms'] ?? '';
          _treatmentPlanController.text = data['treatmentPlan'] ?? '';
          _notesController.text = data['notes'] ?? '';

          if (data['vitalSigns'] != null) {
            final vitals = data['vitalSigns'] as Map<String, dynamic>;
            _vitalControllers['temperature']?.text =
                vitals['temperature']?.toString() ?? '';
            _vitalControllers['heartRate']?.text =
                vitals['heartRate']?.toString() ?? '';
            _vitalControllers['bloodPressureSystolic']?.text =
                vitals['bloodPressureSystolic']?.toString() ?? '';
            _vitalControllers['bloodPressureDiastolic']?.text =
                vitals['bloodPressureDiastolic']?.toString() ?? '';
            _vitalControllers['respiratoryRate']?.text =
                vitals['respiratoryRate']?.toString() ?? '';
            _vitalControllers['oxygenSaturation']?.text =
                vitals['oxygenSaturation']?.toString() ?? '';
          }
        });
      }
    } catch (e) {
      print('Error loading notes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveNotes({bool showSnackbar = true}) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw 'Not authenticated';

      // Add doctor role check
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.data()?['role'] != 'doctor') {
        throw 'Unauthorized access';
      }

      final noteData = {
        'patientId': widget.patientId,
        'doctorId': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'diagnosis': _diagnosisController.text.trim(),
        'symptoms': _symptomsController.text.trim(),
        'treatmentPlan': _treatmentPlanController.text.trim(),
        'notes': _notesController.text.trim(),
        'vitalSigns': {
          'temperature': _vitalControllers['temperature']!.text.isNotEmpty
              ? double.tryParse(_vitalControllers['temperature']!.text)
              : null,
          'heartRate': _vitalControllers['heartRate']!.text.isNotEmpty
              ? int.tryParse(_vitalControllers['heartRate']!.text)
              : null,
          'bloodPressureSystolic': _vitalControllers['bloodPressureSystolic']!
                  .text
                  .isNotEmpty
              ? int.tryParse(_vitalControllers['bloodPressureSystolic']!.text)
              : null,
          'bloodPressureDiastolic': _vitalControllers['bloodPressureDiastolic']!
                  .text
                  .isNotEmpty
              ? int.tryParse(_vitalControllers['bloodPressureDiastolic']!.text)
              : null,
          'respiratoryRate':
              _vitalControllers['respiratoryRate']!.text.isNotEmpty
                  ? int.tryParse(_vitalControllers['respiratoryRate']!.text)
                  : null,
          'oxygenSaturation':
              _vitalControllers['oxygenSaturation']!.text.isNotEmpty
                  ? double.tryParse(_vitalControllers['oxygenSaturation']!.text)
                  : null,
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (_currentNoteId != null) {
        await FirebaseFirestore.instance
            .collection('doctor_notes')
            .doc(_currentNoteId)
            .update(noteData);
      } else {
        final docRef = await FirebaseFirestore.instance
            .collection('doctor_notes')
            .add(noteData);
        _currentNoteId = docRef.id;
      }

      if (showSnackbar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notes saved'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving notes: $e');
      if (showSnackbar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving notes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
