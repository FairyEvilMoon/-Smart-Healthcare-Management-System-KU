import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthcare_system_ku/models/appointment_model.dart';
import 'package:healthcare_system_ku/models/patient_model.dart';
import 'package:healthcare_system_ku/providers/auth_provider.dart';
import 'package:healthcare_system_ku/services/appointment_service.dart';
import 'package:healthcare_system_ku/services/prescription_service.dart';

class PrescriptionFormScreen extends ConsumerStatefulWidget {
  final PatientModel patient;
  final AppointmentModel? appointment;

  const PrescriptionFormScreen({
    Key? key,
    required this.patient,
    this.appointment,
  }) : super(key: key);

  @override
  ConsumerState<PrescriptionFormScreen> createState() =>
      _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState
    extends ConsumerState<PrescriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _medications = [];
  bool _isLoading = false;
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Write Prescription'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Text(
              'Patient: ${widget.patient.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 24),
            TextFormField(
              controller: _diagnosisController,
              decoration: InputDecoration(
                labelText: 'Diagnosis',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter diagnosis' : null,
              maxLines: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Medications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            ..._medications.asMap().entries.map((entry) {
              final index = entry.key;
              final medication = entry.value;
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Medication ${index + 1}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _medications.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                      Text(
                        '${medication['name']} - ${medication['dosage']}',
                      ),
                      Text(
                        'Instructions: ${medication['instructions']}',
                      ),
                      Text(
                        'Duration: ${medication['duration']}',
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            ElevatedButton.icon(
              onPressed: _showAddMedicationDialog,
              icon: Icon(Icons.add),
              label: Text('Add Medication'),
            ),
            SizedBox(height: 24),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Additional Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _savePrescription,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Save Prescription'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddMedicationDialog() async {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final instructionsController = TextEditingController();
    final durationController = TextEditingController();

    final medication = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Medication'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Medication Name',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: dosageController,
                decoration: InputDecoration(
                  labelText: 'Dosage',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: instructionsController,
                decoration: InputDecoration(
                  labelText: 'Instructions',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: durationController,
                decoration: InputDecoration(
                  labelText: 'Duration',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isEmpty ||
                  dosageController.text.isEmpty ||
                  instructionsController.text.isEmpty ||
                  durationController.text.isEmpty) {
                return;
              }
              Navigator.pop(context, {
                'name': nameController.text,
                'dosage': dosageController.text,
                'instructions': instructionsController.text,
                'duration': durationController.text,
              });
            },
            child: Text('Add'),
          ),
        ],
      ),
    );

    if (medication != null) {
      setState(() {
        _medications.add(medication);
      });
    }
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate() || _medications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider).value;
      final prescriptionService = PrescriptionService();

      await prescriptionService.createPrescription({
        'patientId': widget.patient.uid,
        'doctorId': user?.uid,
        'appointmentId': widget.appointment?.id,
        'diagnosis': _diagnosisController.text,
        'medications': _medications,
        'notes': _notesController.text,
      });

      if (widget.appointment != null) {
        await AppointmentService().updateAppointmentStatus(
          widget.appointment!.id,
          'completed',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prescription saved successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
