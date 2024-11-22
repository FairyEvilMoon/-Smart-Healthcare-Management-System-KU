import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:healthcare_ku/models/medical_record_model.dart';
import 'package:healthcare_ku/services/auth_service.dart';
import 'package:healthcare_ku/services/medical_record_service.dart';
import 'dart:io';

class AddMedicalRecordScreen extends StatefulWidget {
  final String patientId;

  const AddMedicalRecordScreen({
    Key? key,
    required this.patientId,
  }) : super(key: key);

  @override
  _AddMedicalRecordScreenState createState() => _AddMedicalRecordScreenState();
}

class _AddMedicalRecordScreenState extends State<AddMedicalRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final MedicalRecordService _recordService = MedicalRecordService();
  final AuthService _authService = AuthService();

  final List<File> _attachments = [];
  final List<Prescription> _prescriptions = [];

  String _diagnosis = '';
  String _symptoms = '';
  String _treatmentPlan = '';
  Map<String, dynamic> _labResults = {};
  List<String> _allergies = [];
  List<String> _existingConditions = [];
  String _notes = '';

  // Vital Signs
  double? _temperature;
  int? _heartRate;
  int? _bloodPressureSystolic;
  int? _bloodPressureDiastolic;
  int? _respiratoryRate;
  double? _oxygenSaturation;
  double? _height;
  double? _weight;

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medical Record'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDiagnosisSection(),
                    _buildVitalSignsSection(),
                    _buildPrescriptionsSection(),
                    _buildAttachmentsSection(),
                    _buildLabResultsSection(),
                    _buildTreatmentPlanSection(),
                    _buildAllergiesSection(),
                    _buildExistingConditionsSection(),
                    _buildNotesSection(),
                    const SizedBox(height: 20),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDiagnosisSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Diagnosis & Symptoms',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Diagnosis',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter diagnosis' : null,
          onSaved: (value) => _diagnosis = value ?? '',
        ),
        const SizedBox(height: 10),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Symptoms',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter symptoms' : null,
          onSaved: (value) => _symptoms = value ?? '',
        ),
      ],
    );
  }

  Widget _buildVitalSignsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text('Vital Signs', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Temperature (°C)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) => _temperature = double.tryParse(value ?? ''),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Heart Rate (bpm)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) => _heartRate = int.tryParse(value ?? ''),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Blood Pressure (systolic)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) =>
                    _bloodPressureSystolic = int.tryParse(value ?? ''),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Blood Pressure (diastolic)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) =>
                    _bloodPressureDiastolic = int.tryParse(value ?? ''),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrescriptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Prescriptions',
                style: Theme.of(context).textTheme.titleLarge),
            TextButton.icon(
              onPressed: _addPrescription,
              icon: const Icon(Icons.add),
              label: const Text('Add Prescription'),
            ),
          ],
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _prescriptions.length,
          itemBuilder: (context, index) {
            return Card(
              child: ListTile(
                title: Text(_prescriptions[index].medication),
                subtitle: Text(
                    '${_prescriptions[index].dosage} - ${_prescriptions[index].frequency}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removePrescription(index),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Attachments', style: Theme.of(context).textTheme.titleLarge),
            TextButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.attach_file),
              label: const Text('Add Attachment'),
            ),
          ],
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _attachments.length,
          itemBuilder: (context, index) {
            return Card(
              child: ListTile(
                title: Text(_attachments[index].path.split('/').last),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeAttachment(index),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLabResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Lab Results', style: Theme.of(context).textTheme.titleLarge),
            TextButton.icon(
              onPressed: _addLabResult,
              icon: const Icon(Icons.add),
              label: const Text('Add Result'),
            ),
          ],
        ),
        // Display existing lab results
        ..._labResults.entries.map(
          (entry) => Card(
            child: ListTile(
              title: Text(entry.key),
              subtitle: Text(entry.value.toString()),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _removeLabResult(entry.key),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentPlanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text('Treatment Plan', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Treatment Plan',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter treatment plan' : null,
          onSaved: (value) => _treatmentPlan = value ?? '',
        ),
      ],
    );
  }

  Widget _buildAllergiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Allergies', style: Theme.of(context).textTheme.titleLarge),
            TextButton.icon(
              onPressed: _addAllergy,
              icon: const Icon(Icons.add),
              label: const Text('Add Allergy'),
            ),
          ],
        ),
        Wrap(
          spacing: 8.0,
          children: _allergies
              .map(
                (allergy) => Chip(
                  label: Text(allergy),
                  onDeleted: () => _removeAllergy(allergy),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildExistingConditionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Existing Conditions',
                style: Theme.of(context).textTheme.titleLarge),
            TextButton.icon(
              onPressed: _addExistingCondition,
              icon: const Icon(Icons.add),
              label: const Text('Add Condition'),
            ),
          ],
        ),
        Wrap(
          spacing: 8.0,
          children: _existingConditions
              .map(
                (condition) => Chip(
                  label: Text(condition),
                  onDeleted: () => _removeExistingCondition(condition),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text('Notes', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Additional Notes',
            border: OutlineInputBorder(),
          ),
          onSaved: (value) => _notes = value ?? '',
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitForm,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Save Medical Record'),
        ),
      ),
    );
  }

  // Helper Methods
  void _addPrescription() async {
    final TextEditingController medicationController = TextEditingController();
    final TextEditingController dosageController = TextEditingController();
    final TextEditingController frequencyController = TextEditingController();
    final TextEditingController durationController = TextEditingController();
    final TextEditingController instructionsController =
        TextEditingController();

    final result = await showDialog<Prescription>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Prescription'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: medicationController,
                  decoration: const InputDecoration(labelText: 'Medication'),
                ),
                TextField(
                  controller: dosageController,
                  decoration: const InputDecoration(labelText: 'Dosage'),
                ),
                TextField(
                  controller: frequencyController,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                ),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(labelText: 'Duration'),
                ),
                TextField(
                  controller: instructionsController,
                  decoration: const InputDecoration(labelText: 'Instructions'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final prescription = Prescription(
                  medication: medicationController.text,
                  dosage: dosageController.text,
                  frequency: frequencyController.text,
                  duration: durationController.text,
                  instructions: instructionsController.text,
                  prescribedDate: DateTime.now(),
                );
                Navigator.of(context).pop(prescription);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _prescriptions.add(result);
      });
    }
  }

  void _removePrescription(int index) {
    setState(() {
      _prescriptions.removeAt(index);
    });
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          _attachments.addAll(
            result.paths.map((path) => File(path!)).toList(),
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking files: $e')),
      );
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _addLabResult() async {
    final TextEditingController testNameController = TextEditingController();
    final TextEditingController resultController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Lab Result'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: testNameController,
                decoration: const InputDecoration(labelText: 'Test Name'),
              ),
              TextField(
                controller: resultController,
                decoration: const InputDecoration(labelText: 'Result'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'testName': testNameController.text,
                  'result': resultController.text,
                });
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _labResults[result['testName']!] = result['result'];
      });
    }
  }

  void _removeLabResult(String key) {
    setState(() {
      _labResults.remove(key);
    });
  }

  void _addAllergy() async {
    final TextEditingController controller = TextEditingController();

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Allergy'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Allergy'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _allergies.add(result);
      });
    }
  }

  void _removeAllergy(String allergy) {
    setState(() {
      _allergies.remove(allergy);
    });
  }

  void _addExistingCondition() async {
    final TextEditingController controller = TextEditingController();

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Existing Condition'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Condition'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _existingConditions.add(result);
      });
    }
  }

  void _removeExistingCondition(String condition) {
    setState(() {
      _existingConditions.remove(condition);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _formKey.currentState!.save();

      // Get current doctor ID
      final String patientId = FirebaseAuth.instance.currentUser!.uid;
      final String doctorId = "placeholder_doctor_id";

      // Create the medical record
      final record = MedicalRecord(
        id: '', // Will be set by Firestore
        patientId: patientId,
        doctorId: doctorId,
        dateCreated: DateTime.now(),
        lastUpdated: DateTime.now(),
        diagnosis: _diagnosis,
        symptoms: _symptoms,
        prescriptions: _prescriptions,
        attachmentUrls: [], // Will be populated after uploading files
        treatmentPlan: _treatmentPlan,
        labResults: _labResults,
        allergies: _allergies,
        existingConditions: _existingConditions,
        notes: _notes,
        vitalSigns: VitalSigns(
          temperature: _temperature,
          heartRate: _heartRate,
          bloodPressureSystolic: _bloodPressureSystolic,
          bloodPressureDiastolic: _bloodPressureDiastolic,
          respiratoryRate: _respiratoryRate,
          oxygenSaturation: _oxygenSaturation,
          height: _height,
          weight: _weight,
        ),
      );

      // Create the medical record first
      final recordId = await _recordService.createMedicalRecord(record);

      // Upload attachments
      for (final file in _attachments) {
        await _recordService.uploadAttachment(recordId, file);
      }

      // Show success message and pop back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medical record saved successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving medical record: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
